import 'dart:async';

import '../connection/orm_connection.dart';
import '../events/event_bus.dart';
import '../migrations/seeder.dart';
import '../query/query.dart';
import 'seeder_events.dart';

/// Result of a single seeder execution.
class SeederAction {
  const SeederAction({required this.name, required this.duration});

  /// Name of the seeder (typically the class name).
  final String name;

  /// How long the seeder took to run.
  final Duration duration;
}

/// Summary of a seeding run.
class SeedingReport {
  const SeedingReport(this.actions);

  /// Individual seeder executions.
  final List<SeederAction> actions;

  /// Whether no seeders were executed.
  bool get isEmpty => actions.isEmpty;
}

/// Runs seeders and emits lifecycle events.
class SeederRunner {
  SeederRunner({EventBus? events, bool emitEvents = true})
    : _events = events ?? EventBus.instance,
      _emitEvents = emitEvents;

  final EventBus _events;
  final bool _emitEvents;

  /// Execute seeders on the provided [connection].
  ///
  /// [seeders] is the registry of available seeders. [names] can be used to
  /// target specific seeders; otherwise the first registry entry runs.
  ///
  /// When [pretend] is true, queries are collected via `connection.pretend`
  /// and passed to [onPretendQueries] for logging/inspection.
  Future<SeedingReport> run({
    required OrmConnection connection,
    required List<SeederRegistration> seeders,
    List<String>? names,
    bool pretend = false,
    void Function(OrmConnection connection)? beforeRun,
    void Function(String message)? log,
    void Function(List<QueryLogEntry> entries)? onPretendQueries,
  }) async {
    if (seeders.isEmpty) {
      throw StateError('No seeders registered.');
    }

    final lookup = {for (final entry in seeders) entry.name: entry.factory};
    final queue = (names == null || names.isEmpty)
        ? <String>[seeders.first.name]
        : List<String>.from(names);

    beforeRun?.call(connection);

    final actions = <SeederAction>[];
    final runStopwatch = Stopwatch()..start();
    var completedCount = 0;
    StreamSubscription<SeederCompletedEvent>? completedSubscription;

    if (_emitEvents) {
      completedSubscription = _events.stream<SeederCompletedEvent>().listen((
        _,
      ) {
        completedCount++;
      });
    }

    if (_emitEvents) {
      _events.emit(SeedingStartedEvent(seederNames: List.unmodifiable(queue)));
    }

    for (var i = 0; i < queue.length; i++) {
      final target = queue[i];
      final factory = lookup[target];
      if (factory == null) {
        throw StateError('Seeder $target is not registered.');
      }

      if (_emitEvents) {
        _events.emit(
          SeederStartedEvent(
            seederName: target,
            index: i + 1,
            total: queue.length,
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      try {
        if (pretend) {
          final statements = await connection.pretend(() async {
            final seeder = factory(connection);
            seeder.attachEventBus(_events);
            await seeder.run();
          });
          if (onPretendQueries != null) {
            onPretendQueries(statements);
          }
        } else {
          final seeder = factory(connection)..attachEventBus(_events);
          await seeder.run();
          log?.call('[seeded] $target');
        }

        stopwatch.stop();
        actions.add(SeederAction(name: target, duration: stopwatch.elapsed));

        if (_emitEvents) {
          _events.emit(
            SeederCompletedEvent(
              seederName: target,
              duration: stopwatch.elapsed,
            ),
          );
        }
      } catch (error, stackTrace) {
        stopwatch.stop();
        if (_emitEvents) {
          _events.emit(
            SeederFailedEvent(
              seederName: target,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
        rethrow;
      }
    }

    runStopwatch.stop();

    if (_emitEvents) {
      _events.emit(
        SeedingCompletedEvent(
          count: completedCount > 0 ? completedCount : actions.length,
          duration: runStopwatch.elapsed,
        ),
      );
      await completedSubscription?.cancel();
    }

    return SeedingReport(actions);
  }
}
