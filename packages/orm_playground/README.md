# ORM Playground

This package is a miniature app that exercises the routed ORM end-to-end. It
ships with:

- A pre-populated `database/migrations.dart` registry.
- An `orm.yaml` configuration that points at `database.sqlite`.
- Demo entrypoints showcasing the new `DataSource` API.

## Quick Start with DataSource

The playground now uses the modern `DataSource` API for cleaner, more ergonomic
database access:

```dart
import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';

void main() async {
  final database = PlaygroundDatabase();
  final ds = await database.dataSource();

  // Query data
  final users = await ds.query<User>().get();
  final posts = await ds.query<Post>()
      .withRelation('author')
      .orderBy('created_at', descending: true)
      .limit(10)
      .get();

  // Use repositories
  await ds.repo<User>().insert(
    User(email: 'new@example.com', name: 'New User'),
  );

  // Transactions
  await ds.transaction(() async {
    await ds.repo<User>().insert(user);
    await ds.repo<Post>().insert(post);
  });

  // Ad-hoc table queries
  final logs = await ds.table('audit_logs')
      .whereEquals('action', 'login')
      .get();

  await database.dispose();
}
```

## Running Migrations

From the `orm_playground` directory, run the CLI commands:

```bash
# Apply migrations to default connection
dart run ormed_cli:orm migrate

# Apply migrations to a specific connection
dart run ormed_cli:orm migrate --connection analytics

# Check migration status
dart run ormed_cli:orm migrate:status

# Rollback the last migration batch
dart run ormed_cli:orm migrate:rollback

# Describe current schema (updates schema.sql dump)
dart run ormed_cli:orm schema:describe

# Run seeders
dart run ormed_cli:orm seed
dart run ormed_cli:orm seed --connection analytics
```

Alternatively, from the workspace root, use `--config` to point at this package:

```bash
dart run packages/ormed_cli/bin/orm.dart migrate --config packages/orm_playground/orm.yaml
```

## Exploring the Data

After applying migrations, run the playground binary to inspect rows:

```bash
cd packages/orm_playground

# Run the main demo
dart run bin/orm_playground.dart

# Enable SQL logging
dart run bin/orm_playground.dart --sql

# Seed before running the demo
dart run bin/orm_playground.dart --seed DemoContentSeeder
```

By default the SQLite database lives at `database.sqlite`. Set
`PLAYGROUND_DB=/absolute/path/to/db.sqlite` before running the binary if you
want to point at a different file.

## Multi-tenant Demo

The package defines `default` and `analytics` connections in `orm.yaml` and
exposes `bin/multi_tenant_demo.dart` to demonstrate multi-database scenarios
using the `DataSource` API.

### Discovering Available Tenants

Use `tenantNames` to dynamically discover connections defined in `orm.yaml`
instead of hardcoding tenant names:

```dart
final database = PlaygroundDatabase();

// Get all tenant names from configuration
for (final tenant in database.tenantNames) {
  final ds = await database.dataSource(tenant: tenant);
  final userCount = await ds.query<User>().count();
  print('Tenant "$tenant" has $userCount users');
}

await database.dispose();
```

### Working with Multiple Tenants

```dart
final database = PlaygroundDatabase();

// Get DataSource instances for different tenants
final mainDs = await database.dataSource(tenant: 'default');
final analyticsDs = await database.dataSource(tenant: 'analytics');

// Query tenant-specific data
final mainUsers = await mainDs.query<User>().get();
final analyticsUsers = await analyticsDs.query<User>().get();

// Each DataSource operates independently
await mainDs.transaction(() async {
  await mainDs.repo<Tag>().insert(tag);
  // This tag only exists in the main database
});

await database.dispose();
```

### Running the Demo

First, run migrations to each connection:

```bash
cd packages/orm_playground

# Apply to default connection
dart run ormed_cli:orm migrate

# Apply to analytics connection
dart run ormed_cli:orm migrate --connection analytics

# Optionally seed both connections
dart run ormed_cli:orm seed
dart run ormed_cli:orm seed --connection analytics

# Run the multi-tenant demo
dart run bin/multi_tenant_demo.dart
```

The script automatically discovers tenants from `orm.yaml`, seeds any empty
connections, and prints per-tenant summaries demonstrating data isolation:

```
Available tenants: default, analytics

--- Tenant Summary ---
Tenant "default" has 2 users.
  Users: playground@routed.dev, guest@routed.dev
  Posts: 2
Tenant "analytics" has 2 users.
  Users: playground@routed.dev, guest@routed.dev
  Posts: 4

--- Tenant Isolation Demo ---
Default tenant users: 2
Analytics tenant users: 2
...
Transaction completed - tenants remain isolated.
```

## PlaygroundDatabase API

`PlaygroundDatabase` provides a simple wrapper around the `DataSource` API:

| Property/Method | Description |
|-----------------|-------------|
| `tenantNames` | Returns all connection names defined in `orm.yaml` |
| `dataSource({tenant})` | Returns a `DataSource` for the specified tenant (cached) |
| `dispose()` | Releases all managed data sources |

The helper loads `orm.yaml` and automatically creates `DataSource` instances
for each requested tenant. Data sources are cached, so multiple calls with the
same tenant return the same instance.

## DataSource Features

The `DataSource` class exposes these key methods:

| Method | Description |
|--------|-------------|
| `query<T>()` | Typed query builder for the model |
| `repo<T>()` | Repository for CRUD operations |
| `transaction<R>(callback)` | Execute operations atomically |
| `table(name)` | Ad-hoc query builder for raw tables |
| `pretend(action)` | Capture SQL without executing |
| `beforeExecuting(callback)` | Hook into SQL execution |
| `enableQueryLog()` / `queryLog` | Query logging utilities |
| `dispose()` | Clean up resources |

See `docs/data_source.md` for complete documentation.

## Configuration

The `orm.yaml` defines connection blocks for each tenant:

```yaml
default_connection: default
connections:
  default:
    driver:
      type: sqlite
      options:
        database: database.sqlite
    migrations:
      directory: database/migrations
      registry: database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema.sql
    seeds:
      directory: database/seeders
      registry: database/seeders.dart
  analytics:
    driver:
      type: sqlite
      options:
        database: database.analytics.sqlite
    # ... same structure as default
```

Add new connections by defining additional entries under `connections:`. The
`tenantNames` property will automatically include them.
