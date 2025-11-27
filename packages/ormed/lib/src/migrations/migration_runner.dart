import 'package:ormed/migrations.dart';

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
  }) : _schemaDriver = schemaDriver,
       _ledger = ledger,
       _migrations = List.unmodifiable(
         (List<MigrationDescriptor>.from(migrations)..sort(_byMigrationId)),
       ),
       _descriptorById = {
         for (final descriptor in migrations)
           descriptor.id.toString(): descriptor,
       },
       _planResolver = planResolver ?? _defaultPlanResolver;

  final SchemaDriver _schemaDriver;
  final MigrationLedger _ledger;
  final List<MigrationDescriptor> _migrations;
  final Map<String, MigrationDescriptor> _descriptorById;
  final MigrationPlanResolver _planResolver;

  /// Applies all pending migrations (or up to [limit]).
  Future<MigrationReport> applyAll({int? limit}) async {
    if (limit != null && limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be >= 1');
    }

    await _ledger.ensureInitialized();
    final applied = await _ledger.readApplied();
    final appliedById = {
      for (final record in applied) record.id.toString(): record,
    };
    final batch = await _ledger.nextBatchNumber();

    final actions = <MigrationAction>[];
    for (final descriptor in _migrations) {
      final key = descriptor.id.toString();
      final existing = appliedById[key];
      if (existing != null) {
        if (existing.checksum != descriptor.checksum) {
          throw StateError(
            'Migration ${descriptor.id} checksum mismatch. Expected ${descriptor.checksum} but ledger has ${existing.checksum}.',
          );
        }
        continue;
      }
      if (limit != null && actions.length >= limit) {
        break;
      }

      final appliedAt = DateTime.now().toUtc();
      final stopwatch = Stopwatch()..start();
      final plan = await _planResolver(descriptor, MigrationDirection.up);
      await _schemaDriver.applySchemaPlan(plan);
      stopwatch.stop();
      await _ledger.logApplied(descriptor, appliedAt, batch: batch);
      actions.add(
        MigrationAction(
          descriptor: descriptor,
          operation: MigrationOperation.apply,
          appliedAt: appliedAt,
          duration: stopwatch.elapsed,
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
    await _ledger.ensureInitialized();
    final applied = await _ledger.readApplied();
    if (applied.isEmpty) {
      return const MigrationReport([]);
    }
    final targets = applied.reversed.take(steps).toList();
    final actions = <MigrationAction>[];

    for (final record in targets) {
      final descriptor = _descriptorById[record.id.toString()];
      if (descriptor == null) {
        throw StateError(
          'No migration descriptor registered for ${record.id}.',
        );
      }
      final stopwatch = Stopwatch()..start();
      final plan = await _planResolver(descriptor, MigrationDirection.down);
      await _schemaDriver.applySchemaPlan(plan);
      stopwatch.stop();
      await _ledger.remove(record.id);
      actions.add(
        MigrationAction(
          descriptor: descriptor,
          operation: MigrationOperation.rollback,
          appliedAt: DateTime.now().toUtc(),
          duration: stopwatch.elapsed,
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
