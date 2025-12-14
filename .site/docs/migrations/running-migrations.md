---
sidebar_position: 3
---

# Running Migrations

## Programmatic Usage

Use `MigrationRunner` to run migrations in code:

```dart
import 'package:ormed/migrations.dart';

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

// Create ledger to track applied migrations
final ledger = SqlMigrationLedger(
  driver,
  tableName: '_orm_migrations',
);
await ledger.ensureInitialized();

// Create runner
final runner = MigrationRunner(
  schemaDriver: driver,
  ledger: ledger,
  migrations: descriptors,
);

// Apply all pending migrations
await runner.applyAll();

// Or apply with a limit
await runner.applyAll(limit: 5);

// Rollback last batch
await runner.rollback();

// Rollback multiple batches
await runner.rollback(steps: 3);

// Check status
final statuses = await runner.status();
for (final status in statuses) {
  print('${status.id}: ${status.isApplied ? 'Applied' : 'Pending'}');
}
```

## Ledger API

The ledger tracks which migrations have been applied:

```dart
final ledger = SqlMigrationLedger(driver, tableName: 'orm_migrations');
await ledger.ensureInitialized();

// Get next batch number
final batch = await ledger.nextBatchNumber();

// Log applied migration
await ledger.logApplied(
  descriptor,
  DateTime.now().toUtc(),
  batch: batch,
);

// Using ConnectionManager
final managedLedger = SqlMigrationLedger.managed(
  connectionName: 'primary',
  tableName: 'orm_migrations',
);
await managedLedger.ensureInitialized();
```

## Migration Registry

The CLI maintains a registry file to track available migrations:

```dart
// lib/src/database/migrations.dart

// <ORM-MIGRATION-IMPORTS>
import 'migrations/m_20241201000000_create_users_table.dart';
import 'migrations/m_20241201000100_create_posts_table.dart';
// </ORM-MIGRATION-IMPORTS>

final List<MigrationEntry> _entries = [
  // <ORM-MIGRATION-REGISTRY>
  MigrationEntry(
    id: MigrationId.parse('m_20241201000000_create_users_table'),
    migration: const CreateUsersTable(),
  ),
  MigrationEntry(
    id: MigrationId.parse('m_20241201000100_create_posts_table'),
    migration: const CreatePostsTable(),
  ),
  // </ORM-MIGRATION-REGISTRY>
];

List<MigrationDescriptor> buildMigrations() =>
    MigrationEntry.buildDescriptors(_entries);
```

The marker comments allow the CLI to automatically insert new migrations.

## Troubleshooting

### Migration Already Applied

```
Error: Migration X has already been applied
```

Use `migrate:status` to check applied migrations. Roll back first if you need to re-run.

### Checksum Mismatch

```
Error: Migration checksum doesn't match recorded value
```

A migration was modified after being applied. Either:
- Revert changes to the migration file
- Create a new migration with the changes

### Foreign Key Constraint Failed

Ensure:
- Parent tables are created before child tables
- Child tables are dropped before parent tables
- Foreign key columns match the referenced column type
