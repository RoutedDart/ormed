---
sidebar_position: 5
---

# Examples & Recipes

End-to-end walkthroughs demonstrating how Ormed pieces work together.

## End-to-End SQLite Workflow

### 1. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  ormed:
  ormed_sqlite:
dev_dependencies:
  build_runner:
  ormed_cli:
```

### 2. Model (`lib/user.dart`)

```dart file=../../examples/lib/models/user.dart#basic-model
```

### 3. Generate

```bash
dart run build_runner build --delete-conflicting-outputs
```

This produces `lib/orm_registry.g.dart` with `bootstrapOrm()` (and other helpers).

### 4. Bootstrap CLI

```bash
dart run ormed_cli:orm init
```

Creates `orm.yaml`, registry, and migrations directory.

### 5. Create/Apply Migrations

```bash
dart run ormed_cli:orm make --name create_users --create --table users
# Edit the generated file
dart run ormed_cli:orm migrate
```

### 6. Query

```dart file=../../examples/lib/examples/workflows.dart#sqlite-query
```

## Static Helpers Pattern

Bind a global resolver for cleaner code:

```dart file=../../examples/lib/examples/workflows.dart#static-helpers-pattern
```

## QueryContext (Advanced)

```dart file=../../examples/lib/examples/workflows.dart#query-context-example
```

## Observability Example

```dart file=../../examples/lib/examples/workflows.dart#observability-example
```

Output:
```json
{
  "type": "query",
  "model": "User",
  "sql": "SELECT \"id\", \"email\" FROM \"users\" WHERE \"id\" = ?",
  "parameters": [1],
  "duration_ms": 0.42
}
```

## Working with Relations

### Eager Loading

```dart file=../../examples/lib/examples/workflows.dart#eager-loading-example
```

### Eager Loading Aggregates

```dart file=../../examples/lib/examples/workflows.dart#eager-aggregates-example
```

### Lazy Loading

```dart file=../../examples/lib/examples/workflows.dart#lazy-loading
```

### Lazy Loading Aggregates

```dart file=../../examples/lib/examples/workflows.dart#lazy-loading-aggregates
```

### Relation Mutations

```dart file=../../examples/lib/examples/workflows.dart#relation-mutations
```

### Batch Loading

```dart file=../../examples/lib/examples/workflows.dart#batch-loading
```

### Preventing Lazy Loading

```dart file=../../examples/lib/examples/workflows.dart#prevent-lazy-loading
```

## Manual Join Recipe

```dart file=../../examples/lib/examples/workflows.dart#manual-join
```

## Seeding Data

```dart file=../../examples/lib/examples/workflows.dart#seeding-data
```

## Testing Tips

- Use `SqliteDriverAdapter.inMemory()` for fast tests without a real database
- Attach listeners to `context.onQuery`/`.onMutation` to assert behavior
- For migrations, use `MigrationRunner` with a fake ledger to verify ordering
- For Postgres integration tests, use `PostgresTestHarness` which spins up a schema per test
