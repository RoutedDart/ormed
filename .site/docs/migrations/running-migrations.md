---
sidebar_position: 3
---

# Running Migrations

## Programmatic Usage

Use `MigrationRunner` to run migrations in code:

```dart file=../../examples/lib/migrations/runner.dart#migration-runner

```

## Ledger API

The ledger tracks which migrations have been applied:

```dart file=../../examples/lib/migrations/runner.dart#migration-ledger
```

## Migration Registry

The CLI maintains a registry file to track available migrations:

```dart file=../../examples/lib/migrations/runner.dart#migration-registry
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
