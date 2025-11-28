# Migrations, Ledger, and CLI

Schema changes are managed by a combination of `orm_core`'s migration runtime
(`MigrationRunner`, `MigrationLedger`, `SqlMigrationLedger`) and the standalone
`ormed_cli` package for scaffolding/automation.

## Runtime Concepts

- **Migration** - A Dart class extending `Migration` from `orm_core`. Override
  `up` and `down` to build a `SchemaPlan` via `SchemaBuilder`.
- **MigrationDescriptor** - Produced by `MigrationDescriptor.fromMigration`; it
  stores the migration ID, checksum, and compiled plans for both directions.
- **MigrationLedger** - Interface used to record applied migrations inside the
  database (default implementation: `SqlMigrationLedger`).
- **MigrationRunner** - Applies/rolls back descriptors by piping their plans
  into a `SchemaDriver` while updating the ledger.

### Ledger API

```dart
final ledger = SqlMigrationLedger(driverAdapter, tableName: 'orm_migrations');
await ledger.ensureInitialized();
final batch = await ledger.nextBatchNumber();
await ledger.logApplied(
  descriptor,
  DateTime.now().toUtc(),
  batch: batch,
);

// When you already have a named connection registered via ConnectionManager:
final managedLedger = SqlMigrationLedger.managed(
  connectionName: 'primary',
  tableName: 'orm_migrations',
);
await managedLedger.ensureInitialized();
```

`SqlMigrationLedger` now supports a manager-backed mode, which lets you plug it
directly into an `OrmConnection` registered with the global
`ConnectionManager`. The helper takes care of quoting identifiers based on the
underlying driver metadata and ensures the ledger runs on the same connection
that migrations use.

### MigrationRunner

```dart
final runner = MigrationRunner(
  schemaDriver: driverAdapter,
  ledger: ledger,
  migrations: descriptors,
);

await runner.applyAll(limit: 5);
await runner.rollback(steps: 1);
final statuses = await runner.status();
```

The runner enforces checksum validation (detects drift), keeps migrations
ordered by timestamp, and records `MigrationAction`s (operation, duration,
reporting).

## ORM CLI (`ormed_cli`)

The CLI wraps the runtime and exposes developer-friendly commands. It lives in
`packages/orm/ormed_cli` and ships an executable named `orm`.

### Configuration (`orm.yaml`)

```yaml
default_connection: primary
connections:
  primary:
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
      default_class: DatabaseSeeder
  analytics:
    driver:
      type: sqlite
      options:
        database: database.analytics.sqlite
    migrations:
      directory: database/migrations
      registry: database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema.sql
    seeds:
      directory: database/seeders
      registry: database/seeders.dart
      default_class: DatabaseSeeder
```

- `default_connection` selects which connection is used when `--connection` is
  omitted.
- `connections` stores named driver/migrations/seed blocks that can override the
  database file, ledger table, schema dump, etc.
- `driver`, `migrations`, and `seeds` keep their previous responsibilities
  inside each named connection.

Use `--connection <name>` (e.g., `orm apply --connection analytics`) to target a
specific tenant. Every command that touches the database now exposes the same
option, so you can apply migrations, rollback, or seed any connection without
switching config files.

> The CLI automatically walks up from the current working directory looking for
> the nearest `orm.yaml`, so running `dart run ormed_cli:apply` inside a package
> that contains `orm.yaml` “just works”. Use `--config` only when you need to
> override the detected file.

### Commands

| Command | Description |
| --- | --- |
| `orm init` | Creates `orm.yaml`, `database/migrations.dart`, and the migrations directory with marker comments used for registration. |
| `orm make --name create_users_table` | Generates a timestamped migration file + registers it in `database/migrations.dart`. |
| `orm apply [--limit N]` | Loads descriptors via the registry, registers a connection through `ConnectionManager`, and applies pending migrations using a `SqlMigrationLedger.managed(...)` tied to that connection. |
| `orm rollback [--steps N]` | Rolls back the most recently applied migrations. |
| `orm status` | Prints the status of each descriptor (applied timestamp or pending). |

All commands accept `--config <path>` (or `-c`) so you can target a specific
`orm.yaml`. This is handy inside workspaces—e.g. running `orm apply` against
`orm_playground/orm.yaml` while your current working directory is the workspace
root.
### Schema Diff & Change Set Preview

Beginning with `ormed_cli` vNext, every `apply`/`rollback` invocation captures a
`SchemaSnapshot`, computes a diff via `SchemaDiffer`, and prints a readable
"change set" before executing SQL. This mirrors the output seen in
`packages/orm/ormed_cli/test/migration_commands_test.dart` and helps you catch
breaking drops or unexpected renames **before** they hit the database.

Example:

```
Migration 2024_01_01_000000_create_users_table (up) change set:
  + Create table users
      - columns: active, email, id
  SQL statements: 1
```

### Registry Markers

`database/migrations.dart` contains markers so the CLI can insert imports and
registration entries:

```dart
// <ORM-MIGRATION-IMPORTS>
// </ORM-MIGRATION-IMPORTS>

final List<MigrationDescriptor> _migrations = [
  // <ORM-MIGRATION-REGISTRY>
  // </ORM-MIGRATION-REGISTRY>
];
```

Migration entries look like:

```dart
MigrationDescriptor.fromMigration(
  id: MigrationId.parse('2025_01_01_000000_create_users_table'),
  migration: const CreateUsersTable(),
),
```

### Running in CI

Because `ormed_cli` is pure Dart, you can run migrations during deploys. For
SQLite projects the default configuration works out of the box. For Postgres,
ensure `POSTGRES_URL` or the `driver.options.url` value points at an accessible
database before invoking the CLI.

```
export POSTGRES_URL=postgres://postgres:postgres@db.internal/orm_prod
dart run ormed_cli:apply --limit 10
```

## Schema Builder Cheatsheet

- `schema.create('users', (table) { ... })`
- `table.increments('id')`, `table.uuid('id')`, `table.string('name')`,
  `table.boolean('active').defaultValue(true)`
- `table.unsignedBigInteger('user_id')` for unsigned PK references
- `table.char('code', length: 8)`, `table.tinyText('excerpt')`,
  `table.ulid('device_ulid')`, `table.rememberToken()`
- `table.ipAddress()`, `table.macAddress()`, `table.year('fiscal_year')`
- `table.geometry('location')`, `table.geography('region')`, `table.point('origin')`,
  `table.multiPolygon('regions')`,
  `table.vector('embedding', dimensions: 3)` (falls back to JSON on MariaDB),
  `table.computed('code_slug', 'lower(code)', stored: true)`
- Relations: `table.foreign(['user_id'], references: 'users', referencedColumns: ['id'], onDelete: ReferenceAction.cascade)`
  (or chain fluent helpers: `table.foreign([...]).onDelete(ReferenceAction.cascade)`)
- Altering tables: `schema.table('users', (table) { table.renameColumn('email', 'primary_email'); table.dropColumn('nickname'); })`
- Index helpers: `table.index([...])`, `table.unique([...])`, `table.primary([...])`,
  `table.fullText([...])`, `table.spatialIndex([...])`,
  `table.rawIndex('lower(email)', name: 'users_email_lower_index')`
  - SQLite-specific options are available via
    `SqliteFullTextOptions` (tokenizers/prefixes) and
    `SqliteSpatialIndexOptions` (bounding columns, trigger control).

`table.fullText(...)` compiles to driver-specific full-text support: Postgres emits
`USING GIN` indexes backed by `to_tsvector(...)`, MySQL uses native FULLTEXT
indexes, and SQLite now builds an FTS5 virtual table + triggers so the content stays
in sync automatically. Spatial indexes behave similarly: Postgres uses GiST,
MySQL/MariaDB use `SPATIAL INDEX`, and SQLite provisions an `rtree` virtual table
with triggers to keep the bounding columns synchronized.
- Raw SQL: `schema.raw('VACUUM')`

### Mongo document migrations

`SchemaBuilder` exposes helpers for document-specific commands that target MongoDB
collections, indexes, and validators. These mutations compile through
`MongoSchemaDialect`, which produces `DocumentStatementPayload`s that are executed
by `ormed_mongo` without translating to SQL text.

```dart
final builder = SchemaBuilder();

builder.createCollection(
  'users',
  validator: {
    'email': {'\$exists': true},
    'role': {'\$in': ['user', 'admin']},
  },
  options: {'capped': true, 'size': 1048576},
);

builder.createIndex(
  collection: 'users',
  keys: {'email': 1},
  options: {'unique': true},
);

builder.modifyValidator(
  collection: 'users',
  validator: {
    'active': {'\$type': 'bool'},
  },
);
```

Use `dropIndex` or `dropCollection` to remove legacy structures, and rely on
`modifyValidator` when you need to adjust validator rules mid-flight. `SchemaPlan`
previews still surface these operations in the CLI so you can confirm changes
before they execute.

Refer to the generated `SchemaPlan` via `MigrationDescriptor.up/down` for tests
or diffing. Common Laravel conveniences like `nullableTimestamps()`,
`datetimes()`, `numericMorphs()/uuidMorphs()/ulidMorphs()`, and chaining
`table.foreign(...).onDelete(...)` all work out of the box.
