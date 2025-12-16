---
sidebar_position: 5
---

# Migration & Seeding Events

Migrations and seeders emit structured events through the shared `EventBus`. Subscribe once to stream progress to logs, metrics, or tracing.

## Migration Lifecycle

Events (all emitted by `MigrationRunner`):
- `MigrationBatchStartedEvent` / `MigrationBatchCompletedEvent`
- `MigrationStartedEvent` / `MigrationCompletedEvent`
- `MigrationFailedEvent` (includes `error` and `stackTrace`)

Example listener + runner setup:

```dart file=../../examples/lib/events/migration_events.dart#migration-event-listeners
```

## Seeding Lifecycle

Events (emitted by `SeederRunner` and database seeders):
- `SeedingStartedEvent` / `SeedingCompletedEvent`
- `SeederStartedEvent` / `SeederCompletedEvent`
- `SeederFailedEvent`

Example with a custom seeder and event hooks:

```dart file=../../examples/lib/events/migration_events.dart#seeding-event-listeners
```

Tips:
- Use the same `EventBus` for migrations, seeders, and runtime queries to correlate logs.
- `SeederFailedEvent` fires before the error is rethrown—log here, then let your process fail.
- Combine with `pretend: true` on `SeederRunner.run` to capture SQL without mutating the database.
