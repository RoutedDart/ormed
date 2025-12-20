import 'package:artisanal/artisanal.dart';
import 'package:ormed/ormed.dart';

/// Subscribes to core events and mirrors them to CLI output.
class CliEventReporter {
  CliEventReporter({required Console io, EventBus? events})
    : _io = io,
      _events = events ?? EventBus.instance;

  final Console _io;
  final EventBus _events;
  final List<void Function()> _subscriptions = [];

  /// Listen for migration lifecycle events.
  void listenToMigrations() {
    _subscriptions
      ..add(_events.on<MigrationBatchStartedEvent>(_onMigrationBatchStarted))
      ..add(_events.on<MigrationStartedEvent>(_onMigrationStarted))
      ..add(_events.on<MigrationCompletedEvent>(_onMigrationCompleted))
      ..add(_events.on<MigrationFailedEvent>(_onMigrationFailed))
      ..add(
        _events.on<MigrationBatchCompletedEvent>(_onMigrationBatchCompleted),
      );
  }

  /// Listen for seeding lifecycle events.
  void listenToSeeders() {
    _subscriptions
      ..add(_events.on<SeedingStartedEvent>(_onSeedingStarted))
      ..add(_events.on<SeederStartedEvent>(_onSeederStarted))
      ..add(_events.on<SeederCompletedEvent>(_onSeederCompleted))
      ..add(_events.on<SeederFailedEvent>(_onSeederFailed))
      ..add(_events.on<SeedingCompletedEvent>(_onSeedingCompleted));
  }

  /// Remove all event listeners.
  void dispose() {
    for (final unsubscribe in _subscriptions) {
      unsubscribe();
    }
    _subscriptions.clear();
  }

  void _onMigrationBatchStarted(MigrationBatchStartedEvent event) {
    final action = event.direction == MigrationDirection.up
        ? 'Applying'
        : 'Rolling back';
    final batchText = event.batch != null ? ' (batch ${event.batch})' : '';
    _io.info('$action ${event.count} migration(s)$batchText...');
  }

  void _onMigrationStarted(MigrationStartedEvent event) {
    final direction = event.direction == MigrationDirection.up ? 'up' : 'down';
    _io.writeln(
      '${_io.style.muted('•')} [${event.index}/${event.total}] ${_io.style.emphasize(event.migrationId)} ${_io.style.muted('($direction)')}',
    );
  }

  void _onMigrationCompleted(MigrationCompletedEvent event) {
    final verb = event.direction == MigrationDirection.up
        ? 'Applied'
        : 'Rolled back';
    _io.writeln(
      '${_io.style.success('✓')} $verb ${_io.style.emphasize(event.migrationId)} ${_io.style.muted('(${_formatDuration(event.duration)})')}',
    );
  }

  void _onMigrationFailed(MigrationFailedEvent event) {
    _io.error(
      '${_io.style.error('✗')} Migration ${event.migrationId} failed: ${event.error}',
    );
  }

  void _onMigrationBatchCompleted(MigrationBatchCompletedEvent event) {
    final verb = event.direction == MigrationDirection.up
        ? 'Applied'
        : 'Rolled back';
    _io.success(
      '$verb ${event.count} migration(s) in ${_formatDuration(event.duration)}',
    );
  }

  void _onSeedingStarted(SeedingStartedEvent event) {
    final names = event.seederNames.join(', ');
    _io.info('Seeding: $names');
  }

  void _onSeederStarted(SeederStartedEvent event) {
    _io.writeln(
      '${_io.style.muted('•')} [${event.index}/${event.total}] ${event.seederName}',
    );
  }

  void _onSeederCompleted(SeederCompletedEvent event) {
    final recordsSuffix = event.recordsCreated == null
        ? ''
        : ' ${_io.style.muted('+${event.recordsCreated} records')}';
    _io.writeln(
      '${_io.style.success('✓')} Seeded ${event.seederName} ${_io.style.muted('(${_formatDuration(event.duration)})')}$recordsSuffix',
    );
  }

  void _onSeederFailed(SeederFailedEvent event) {
    _io.error(
      '${_io.style.error('✗')} Seeder ${event.seederName} failed: ${event.error}',
    );
  }

  void _onSeedingCompleted(SeedingCompletedEvent event) {
    _io.success(
      'Seeded ${event.count} seeder(s) in ${_formatDuration(event.duration)}',
    );
  }

  String _formatDuration(Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms < 1000) {
      return '${ms}ms';
    }
    final seconds = (ms / 1000).toStringAsFixed(2);
    return '${seconds}s';
  }
}
