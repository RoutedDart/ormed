import 'package:ormed/migrations.dart';

import '../events/event_bus.dart';
import 'migration_events.dart';

/// Coordinates applying and rolling back migrations using a [SchemaDriver]
/// and ledger store.
typedef MigrationPlanResolver =
    Future<SchemaPlan> Function(
      MigrationDescriptor descriptor,
      MigrationDirection direction,
    );

class MigrationRunner {
  MigrationRunner({
    required SchemaDriver schemaDriver,
    required MigrationLedger ledger,
    required List<MigrationDescriptor> migrations,
    MigrationPlanResolver? planResolver,
    String? defaultSchema,
    bool emitEvents = true,
    EventBus? events,
  }) : _schemaDriver = schemaDriver,
       _ledger = ledger,
       _migrations = List.unmodifiable(
         (List<MigrationDescriptor>.from(migrations)..sort(_byMigrationId)),
       ),
       _descriptorById = {
         for (final descriptor in migrations)
           descriptor.id.toString(): descriptor,
       },
       _planResolver = planResolver ?? _defaultPlanResolver,
       _defaultSchema = defaultSchema,
       _emitEvents = emitEvents,
       _events = events ?? EventBus.instance;

  final SchemaDriver _schemaDriver;
  final MigrationLedger _ledger;
  final List<MigrationDescriptor> _migrations;
  final Map<String, MigrationDescriptor> _descriptorById;
  final MigrationPlanResolver _planResolver;
  final String? _defaultSchema;
  final bool _emitEvents;
  final EventBus _events;

  /// Applies all pending migrations (or up to [limit]).
  Future<MigrationReport> applyAll({int? limit}) async {
    if (limit != null && limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be >= 1');
    }

    final schema = _defaultSchema;
    if (schema != null) {
      await _schemaDriver.setCurrentSchema(schema);
    }

    await _ledger.ensureInitialized();
    final applied = await _ledger.readApplied();
    final appliedById = {
      for (final record in applied) record.id.toString(): record,
    };
    // Also index by timestamp for backward compatibility with old naming format
    final appliedByTimestamp = {
      for (final record in applied) record.id.timestamp.toString(): record,
    };
    final batch = await _ledger.nextBatchNumber();

    // Collect pending migrations first
    final pending = <MigrationDescriptor>[];
    for (final descriptor in _migrations) {
      final key = descriptor.id.toString();
      final existing =
          appliedById[key] ??
          appliedByTimestamp[descriptor.id.timestamp.toString()];
      if (existing != null) {
        if (existing.checksum != descriptor.checksum) {
          throw StateError(
            'Migration ${descriptor.id} checksum mismatch. Expected ${descriptor.checksum} but ledger has ${existing.checksum}.',
          );
        }
        continue;
      }
      pending.add(descriptor);
      if (limit != null && pending.length >= limit) {
        break;
      }
    }

    if (pending.isEmpty) {
      return const MigrationReport([]);
    }

    // Emit batch started event
    final batchStopwatch = Stopwatch()..start();
    if (_emitEvents) {
      _events.emit(
        MigrationBatchStartedEvent(
          direction: MigrationDirection.up,
          count: pending.length,
          batch: batch,
        ),
      );
    }

    final actions = <MigrationAction>[];
    for (var i = 0; i < pending.length; i++) {
      final descriptor = pending[i];
      final migrationId = descriptor.id.toString();
      final migrationName = descriptor.id.slug;

      // Emit migration started
      if (_emitEvents) {
        _events.emit(
          MigrationStartedEvent(
            migrationId: migrationId,
            migrationName: migrationName,
            direction: MigrationDirection.up,
            index: i + 1,
            total: pending.length,
          ),
        );
      }

      final appliedAt = DateTime.now().toUtc();
      final stopwatch = Stopwatch()..start();

      try {
        final plan = await _planResolver(descriptor, MigrationDirection.up);
        await _schemaDriver.applySchemaPlan(plan);
        stopwatch.stop();
        await _ledger.logApplied(descriptor, appliedAt, batch: batch);

        // Emit migration completed
        if (_emitEvents) {
          _events.emit(
            MigrationCompletedEvent(
              migrationId: migrationId,
              migrationName: migrationName,
              direction: MigrationDirection.up,
              duration: stopwatch.elapsed,
            ),
          );
        }

        actions.add(
          MigrationAction(
            descriptor: descriptor,
            operation: MigrationOperation.apply,
            appliedAt: appliedAt,
            duration: stopwatch.elapsed,
          ),
        );
      } catch (error, stackTrace) {
        stopwatch.stop();
        // Emit migration failed
        if (_emitEvents) {
          _events.emit(
            MigrationFailedEvent(
              migrationId: migrationId,
              migrationName: migrationName,
              direction: MigrationDirection.up,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
        rethrow;
      }
    }

    batchStopwatch.stop();
    if (_emitEvents) {
      _events.emit(
        MigrationBatchCompletedEvent(
          direction: MigrationDirection.up,
          count: actions.length,
          duration: batchStopwatch.elapsed,
        ),
      );
    }

    return MigrationReport(actions);
  }

  /// Rolls back the most recently applied migrations.
  Future<MigrationReport> rollback({int steps = 1}) async {
    if (steps < 1) {
      throw ArgumentError.value(steps, 'steps', 'Must be >= 1');
    }

    final schema = _defaultSchema;
    if (schema != null) {
      await _schemaDriver.setCurrentSchema(schema);
    }

    await _ledger.ensureInitialized();
    final applied = await _ledger.readApplied();
    if (applied.isEmpty) {
      return const MigrationReport([]);
    }
    final targets = applied.reversed.take(steps).toList();

    // Emit batch started
    final batchStopwatch = Stopwatch()..start();
    if (_emitEvents) {
      _events.emit(
        MigrationBatchStartedEvent(
          direction: MigrationDirection.down,
          count: targets.length,
          batch: null,
        ),
      );
    }

    final actions = <MigrationAction>[];

    for (var i = 0; i < targets.length; i++) {
      final record = targets[i];
      final descriptor = _descriptorById[record.id.toString()];
      if (descriptor == null) {
        throw StateError(
          'No migration descriptor registered for ${record.id}.',
        );
      }

      final migrationId = descriptor.id.toString();
      final migrationName = descriptor.id.slug;

      // Emit migration started
      if (_emitEvents) {
        _events.emit(
          MigrationStartedEvent(
            migrationId: migrationId,
            migrationName: migrationName,
            direction: MigrationDirection.down,
            index: i + 1,
            total: targets.length,
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      try {
        final plan = await _planResolver(descriptor, MigrationDirection.down);
        await _schemaDriver.applySchemaPlan(plan);
        stopwatch.stop();
        await _ledger.remove(record.id);

        // Emit migration completed
        if (_emitEvents) {
          _events.emit(
            MigrationCompletedEvent(
              migrationId: migrationId,
              migrationName: migrationName,
              direction: MigrationDirection.down,
              duration: stopwatch.elapsed,
            ),
          );
        }

        actions.add(
          MigrationAction(
            descriptor: descriptor,
            operation: MigrationOperation.rollback,
            appliedAt: DateTime.now().toUtc(),
            duration: stopwatch.elapsed,
          ),
        );
      } catch (error, stackTrace) {
        stopwatch.stop();
        // Emit migration failed
        if (_emitEvents) {
          _events.emit(
            MigrationFailedEvent(
              migrationId: migrationId,
              migrationName: migrationName,
              direction: MigrationDirection.down,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
        rethrow;
      }
    }

    batchStopwatch.stop();
    if (_emitEvents) {
      _events.emit(
        MigrationBatchCompletedEvent(
          direction: MigrationDirection.down,
          count: actions.length,
          duration: batchStopwatch.elapsed,
        ),
      );
    }

    return MigrationReport(actions);
  }

  /// Returns the status of all known migrations.
  Future<List<MigrationStatus>> status() async {
    await _ledger.ensureInitialized();
    final applied = await _ledger.readApplied();
    final appliedById = {
      for (final record in applied) record.id.toString(): record,
    };

    return _migrations
        .map((descriptor) {
          final record = appliedById[descriptor.id.toString()];
          return MigrationStatus(
            descriptor: descriptor,
            applied: record != null,
            appliedAt: record?.appliedAt,
            batch: record?.batch,
          );
        })
        .toList(growable: false);
  }

  static int _byMigrationId(MigrationDescriptor a, MigrationDescriptor b) =>
      a.id.timestamp.compareTo(b.id.timestamp);

  static Future<SchemaPlan> _defaultPlanResolver(
    MigrationDescriptor descriptor,
    MigrationDirection direction,
  ) async =>
      direction == MigrationDirection.up ? descriptor.up : descriptor.down;
}
