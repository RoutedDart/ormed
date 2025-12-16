/// Migration events for ormed.
///
/// These events are emitted during migration operations.
library;

import '../events/event_bus.dart';
import '../blueprint/migration.dart' show MigrationDirection;

// Re-export MigrationDirection for convenience
export '../blueprint/migration.dart' show MigrationDirection;

/// Base class for migration events.
abstract class MigrationEvent extends Event {
  MigrationEvent({super.timestamp});
}

/// Event emitted when a migration batch starts.
class MigrationBatchStartedEvent extends MigrationEvent {
  MigrationBatchStartedEvent({
    required this.direction,
    required this.count,
    this.batch,
    super.timestamp,
  });

  /// Whether applying or rolling back.
  final MigrationDirection direction;

  /// Number of migrations to process.
  final int count;

  /// Batch number (for apply operations).
  final int? batch;
}

/// Event emitted when a migration batch completes.
class MigrationBatchCompletedEvent extends MigrationEvent {
  MigrationBatchCompletedEvent({
    required this.direction,
    required this.count,
    required this.duration,
    super.timestamp,
  });

  /// Whether applied or rolled back.
  final MigrationDirection direction;

  /// Number of migrations processed.
  final int count;

  /// Total duration of the batch.
  final Duration duration;
}

/// Event emitted when a single migration starts.
class MigrationStartedEvent extends MigrationEvent {
  MigrationStartedEvent({
    required this.migrationId,
    required this.migrationName,
    required this.direction,
    required this.index,
    required this.total,
    super.timestamp,
  });

  /// The migration ID.
  final String migrationId;

  /// Human-readable migration name.
  final String migrationName;

  /// Whether applying or rolling back.
  final MigrationDirection direction;

  /// 1-based index of current migration in batch.
  final int index;

  /// Total migrations in batch.
  final int total;
}

/// Event emitted when a single migration completes.
class MigrationCompletedEvent extends MigrationEvent {
  MigrationCompletedEvent({
    required this.migrationId,
    required this.migrationName,
    required this.direction,
    required this.duration,
    super.timestamp,
  });

  /// The migration ID.
  final String migrationId;

  /// Human-readable migration name.
  final String migrationName;

  /// Whether applied or rolled back.
  final MigrationDirection direction;

  /// Duration of the migration.
  final Duration duration;
}

/// Event emitted when a migration fails.
class MigrationFailedEvent extends MigrationEvent {
  MigrationFailedEvent({
    required this.migrationId,
    required this.migrationName,
    required this.direction,
    required this.error,
    this.stackTrace,
    super.timestamp,
  });

  /// The migration ID.
  final String migrationId;

  /// Human-readable migration name.
  final String migrationName;

  /// Whether applying or rolling back.
  final MigrationDirection direction;

  /// The error that occurred.
  final Object error;

  /// Stack trace if available.
  final StackTrace? stackTrace;
}
