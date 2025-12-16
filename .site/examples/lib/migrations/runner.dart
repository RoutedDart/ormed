// Migration runner examples
import 'package:ormed/ormed.dart';

import 'basic.dart';

// #region migration-runner
Future<void> runMigrationsProgrammatically(DriverAdapter driver) async {
  // #region migration-runner-entries
  final entries = [
    MigrationEntry(
      id: MigrationId.parse('m_20241201000000_create_users_table'),
      migration: const CreateUsersTable(),
    ),
    MigrationEntry(
      id: MigrationId.parse('m_20241201000100_create_posts_table'),
      migration: const CreatePostsTable(),
    ),
  ];

  // Build descriptors (sorted by timestamp)
  final descriptors = MigrationEntry.buildDescriptors(entries);
  // #endregion migration-runner-entries

  // #region migration-runner-ledger
  // Create ledger to track applied migrations
  final ledger = SqlMigrationLedger(
    driver,
    tableName: '_orm_migrations',
  );
  await ledger.ensureInitialized();
  // #endregion migration-runner-ledger

  // #region migration-runner-runner
  // Create runner
  final runner = MigrationRunner(
    schemaDriver: driver,
    ledger: ledger,
    migrations: descriptors,
  );
  // #endregion migration-runner-runner

  // #region migration-runner-apply
  // Apply all pending migrations
  await runner.applyAll();

  // Or apply with a limit
  await runner.applyAll(limit: 5);
  // #endregion migration-runner-apply

  // #region migration-runner-rollback
  // Rollback last batch
  await runner.rollback();

  // Rollback multiple batches
  await runner.rollback(steps: 3);
  // #endregion migration-runner-rollback

  // #region migration-runner-status
  // Check status
  final statuses = await runner.status();
  for (final status in statuses) {
    print('${status.id}: ${status.isApplied ? 'Applied' : 'Pending'}');
  }
  // #endregion migration-runner-status
}
// #endregion migration-runner

// #region migration-ledger
Future<void> ledgerApiExample(DriverAdapter driver) async {
  final ledger = SqlMigrationLedger(driver, tableName: 'orm_migrations');
  await ledger.ensureInitialized();

  // Get next batch number
  final batch = await ledger.nextBatchNumber();

  // Log applied migration
  // await ledger.logApplied(
  //   descriptor,
  //   DateTime.now().toUtc(),
  //   batch: batch,
  // );

  // Using ConnectionManager
  // final managedLedger = SqlMigrationLedger.managed(
  //   connectionName: 'primary',
  //   tableName: 'orm_migrations',
  // );
  // await managedLedger.ensureInitialized();
}
// #endregion migration-ledger

// #region migration-registry
// lib/src/database/migrations.dart
//
// // <ORM-MIGRATION-IMPORTS>
// import 'migrations/m_20241201000000_create_users_table.dart';
// import 'migrations/m_20241201000100_create_posts_table.dart';
// // </ORM-MIGRATION-IMPORTS>
//
// final List<MigrationEntry> _entries = [
//   // <ORM-MIGRATION-REGISTRY>
//   MigrationEntry(
//     id: MigrationId.parse('m_20241201000000_create_users_table'),
//     migration: const CreateUsersTable(),
//   ),
//   MigrationEntry(
//     id: MigrationId.parse('m_20241201000100_create_posts_table'),
//     migration: const CreatePostsTable(),
//   ),
//   // </ORM-MIGRATION-REGISTRY>
// ];
//
// List<MigrationDescriptor> buildMigrations() =>
//     MigrationEntry.buildDescriptors(_entries);
// #endregion migration-registry
