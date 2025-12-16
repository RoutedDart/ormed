/// Seeder events for ormed.
///
/// These events are emitted during database seeding operations.
library;

import '../events/event_bus.dart';

/// Base class for seeder events.
abstract class SeederEvent extends Event {
  SeederEvent({super.timestamp});
}

/// Event emitted when seeding starts.
class SeedingStartedEvent extends SeederEvent {
  SeedingStartedEvent({required this.seederNames, super.timestamp});

  /// Names of seeders to run.
  final List<String> seederNames;
}

/// Event emitted when seeding completes.
class SeedingCompletedEvent extends SeederEvent {
  SeedingCompletedEvent({
    required this.count,
    required this.duration,
    super.timestamp,
  });

  /// Number of seeders run.
  final int count;

  /// Total duration.
  final Duration duration;
}

/// Event emitted when a single seeder starts.
class SeederStartedEvent extends SeederEvent {
  SeederStartedEvent({
    required this.seederName,
    required this.index,
    required this.total,
    super.timestamp,
  });

  /// Name of the seeder class.
  final String seederName;

  /// 1-based index of current seeder.
  final int index;

  /// Total seeders to run.
  final int total;
}

/// Event emitted when a single seeder completes.
class SeederCompletedEvent extends SeederEvent {
  SeederCompletedEvent({
    required this.seederName,
    required this.duration,
    this.recordsCreated,
    super.timestamp,
  });

  /// Name of the seeder class.
  final String seederName;

  /// Duration of the seeder.
  final Duration duration;

  /// Number of records created, if tracked.
  final int? recordsCreated;
}

/// Event emitted when a seeder fails.
class SeederFailedEvent extends SeederEvent {
  SeederFailedEvent({
    required this.seederName,
    required this.error,
    this.stackTrace,
    super.timestamp,
  });

  /// Name of the seeder class.
  final String seederName;

  /// The error that occurred.
  final Object error;

  /// Stack trace if available.
  final StackTrace? stackTrace;
}
