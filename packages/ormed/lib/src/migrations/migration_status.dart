import 'package:meta/meta.dart';
import 'package:ormed/migrations.dart';

/// Status information for a migration when listing history.
class MigrationStatus {
  const MigrationStatus({
    required this.descriptor,
    required this.applied,
    this.appliedAt,
    this.batch,
  });

  final MigrationDescriptor descriptor;
  final bool applied;
  final DateTime? appliedAt;
  final int? batch;
}

/// High-level summary returned after applying or rolling back migrations.
class MigrationReport {
  const MigrationReport(this.actions);

  final List<MigrationAction> actions;

  bool get isEmpty => actions.isEmpty;
}

/// Describes a single migration action that occurred.
@immutable
class MigrationAction {
  const MigrationAction({
    required this.descriptor,
    required this.operation,
    required this.appliedAt,
    required this.duration,
  });

  final MigrationDescriptor descriptor;
  final MigrationOperation operation;
  final DateTime appliedAt;
  final Duration duration;
}

/// Supported operations tracked inside a [MigrationAction].
enum MigrationOperation { apply, rollback }
