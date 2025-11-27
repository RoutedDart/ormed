import 'package:ormed/migrations.dart';

/// Snapshot of a migration persisted inside the ledger table.
class AppliedMigrationRecord {
  AppliedMigrationRecord({
    required this.id,
    required this.checksum,
    required this.appliedAt,
    required this.batch,
  });

  final MigrationId id;
  final String checksum;
  final DateTime appliedAt;
  final int batch;
}

/// Storage abstraction for recording applied migrations.
abstract class MigrationLedger {
  /// Ensures the ledger storage is initialized (e.g., creates tables).
  Future<void> ensureInitialized();

  /// Returns all applied migrations ordered by application time ascending.
  Future<List<AppliedMigrationRecord>> readApplied();

  /// Adds an applied migration entry to the ledger and assigns a batch number.
  Future<void> logApplied(
    MigrationDescriptor descriptor,
    DateTime appliedAt, {
    required int batch,
  });

  /// Removes the migration entry from the ledger (used during rollbacks).
  Future<void> remove(MigrationId id);

  /// Determines the next batch number to use when logging migrations.
  Future<int> nextBatchNumber();
}
