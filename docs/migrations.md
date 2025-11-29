# Migrations

Migrations are version-controlled database schema changes that allow you to modify your database structure over time in a consistent and reversible way. Each migration defines a set of changes to apply in the `up` method and the inverse operations to revert those changes in the `down` method.

> **See also:** [CLI Reference](cli.md) for complete command documentation and [Schema Builder](schema.md) for detailed API reference.

## Table of Contents
- [Introduction](#introduction)
- [Creating Migrations](#creating-migrations)
- [Writing Migrations](#writing-migrations)
- [Running Migrations](#running-migrations)
- [Runtime Concepts](#runtime-concepts)
- [Troubleshooting](#troubleshooting)

## Introduction

Migrations solve a fundamental problem in application development: how to evolve your database schema safely across different environments and team members. Instead of manually running SQL statements or modifying database structures directly, migrations provide a programmatic way to define schema changes that can be version-controlled, reviewed, and deployed consistently.

Ormed migrations support both SQL databases (SQLite, PostgreSQL, MySQL) and document databases (MongoDB), providing a unified API for schema management across different storage backends. The migration system automatically tracks which migrations have been applied to prevent duplicate execution, generates checksums to detect unauthorized modifications, and provides commands for both applying and rolling back changes.

When you create a migration, Ormed generates a timestamped file that ensures migrations run in chronological order. This timestamp-based ordering is critical for maintaining consistency across development, staging, and production environments where different team members may be creating migrations simultaneously.

## Creating Migrations

The CLI provides commands to generate migration files with proper timestamps and boilerplate code. These commands create new Dart files in your migrations directory and automatically register them in your migration registry.

### Basic Migration Generation

To create a blank migration, use the `make:migration` command with a descriptive name that explains what the migration does:

```bash
dart run orm make:migration --name create_users_table
```

This generates a timestamped file like `2024_11_29_143052_create_users_table.dart` containing a migration class with empty `up` and `down` methods that you'll fill in with your schema changes.

### Table Creation Migrations

When creating a new table, you can use the `--create` flag to generate a migration pre-populated with table creation boilerplate:

```bash
dart run orm make:migration --name create_posts_table --create
```

### Table Modification Migrations

For migrations that modify an existing table, use the `--table` flag to indicate which table you're altering:

```bash
dart run orm make:migration --name add_status_to_users --table users
```

This generates migration code that uses `schema.table()` instead of `schema.create()`, signaling that you're modifying an existing structure.

### Migration Naming and Ordering

Migration files use a timestamp prefix in the format `YYYY_MM_DD_HHMMSS_slug`, for example `2024_11_29_143052_create_users_table.dart`. This timestamp serves two purposes: it uniquely identifies each migration and determines the execution order. Migrations always run in chronological order based on these timestamps, ensuring that dependencies between migrations (such as foreign keys requiring parent tables to exist first) are respected.

Choose descriptive names that clearly indicate what the migration does. Good names include `create_users_table`, `add_email_index_to_users`, `remove_deprecated_status_column`, or `add_foreign_key_to_posts`. Avoid vague names like `update_schema` or `migration_v2`.

## Writing Migrations

A migration is a Dart class that extends the `Migration` base class and implements two required methods: `up` and `down`. The `up` method defines the forward changes you want to apply to your database schema, while the `down` method defines how to reverse those changes if you need to roll back.

### Basic Structure

Every migration follows this fundamental structure:

```dart
import 'package:ormed/migrations.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.integer('id').primaryKey();
      table.string('email').unique();
      table.string('name');
      table.timestamp('created_at').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
```

The `SchemaBuilder` parameter provides a fluent API for defining schema changes in a database-agnostic way. Whether you're using SQLite, PostgreSQL, MySQL, or MongoDB, the same schema builder code will compile to the appropriate native operations for your driver. This abstraction allows you to write migrations once and run them on any supported database.

Always implement both the `up` and `down` methods to ensure your migrations are reversible. The `up` method runs when applying migrations, and the `down` method runs during rollbacks. A properly written `down` method should completely undo everything the `up` method does, leaving the database in the same state it was before the migration ran.

### Creating Tables

The `schema.create()` method defines a new table along with its columns, constraints, and indexes. The callback function receives a table builder that you use to specify the table's structure:

```dart
@override
void up(SchemaBuilder schema) {
  schema.create('posts', (table) {
    table.integer('id').primaryKey().autoIncrement();
    table.string('title');
    table.text('content');
    table.integer('author_id');
    table.boolean('published').defaultValue(false);
    table.timestamp('created_at').nullable();
    table.timestamp('updated_at').nullable();
    
    table.foreignKey(['author_id'])
      .references('users', ['id'])
      .onDelete(ForeignKeyAction.cascade)
      .onUpdate(ForeignKeyAction.restrict);
    
    table.index(['author_id', 'published']);
  });
}

@override
void down(SchemaBuilder schema) {
  schema.drop('posts', ifExists: true);
}
```

When creating tables, consider the order of operations carefully. Foreign key constraints require that referenced tables already exist, so you must create parent tables before child tables. In the example above, the `posts` table references `users` via the `author_id` foreign key, so the migration that creates the `users` table must have an earlier timestamp.

The `down` method uses `schema.drop()` to remove the table. The `ifExists: true` parameter prevents errors if the table has already been dropped or never existed, making your rollback operations more robust and idempotent.

Indexes defined on table creation help optimize query performance from the start. Add indexes to columns that will be frequently used in WHERE clauses, JOIN conditions, or ORDER BY statements. The composite index on `['author_id', 'published']` in the example above would speed up queries that filter posts by both author and publication status.

### Modifying Tables

Use `schema.table()` to alter existing tables:

```dart
@override
void up(SchemaBuilder schema) {
  schema.table('posts', (table) {
    // Add new columns
    table.string('slug').nullable();
    table.integer('view_count').defaultValue(0);
    
    // Add indexes
    table.index(['slug']).unique();
    table.index(['view_count']);
    
    // Rename column
    table.renameColumn('content', 'body');
  });
}

@override
void down(SchemaBuilder schema) {
  schema.table('posts', (table) {
    // Reverse the changes
    table.renameColumn('body', 'content');
    table.dropColumn('view_count');
    table.dropColumn('slug');
  });
}
```

**Common table modifications:**
- `table.string('column')` - Add new column
- `table.dropColumn('column')` - Remove column
- `table.renameColumn('old', 'new')` - Rename column
- `table.index([...])` - Add index
- `table.dropIndex('index_name')` - Remove index
- `table.foreignKey([...])` - Add foreign key constraint
- `table.dropForeignKey('constraint_name')` - Remove foreign key

**Important:** When adding non-nullable columns to tables with existing data, either:
1. Make the column nullable: `table.string('slug').nullable()`
2. Provide a default value: `table.string('status').defaultValue('draft')`

### Available Column Types

Ormed supports a wide range of column types that map to appropriate native types for each database driver:

**Numeric Types:**
```dart
table.integer('count');                           // INT
table.bigInteger('large_count');                  // BIGINT
table.smallInteger('tiny_count');                 // SMALLINT
table.tinyInteger('status_code');                 // TINYINT
table.unsignedBigInteger('user_id');              // UNSIGNED BIGINT
table.decimal('price').precision(10, 2);          // DECIMAL(10,2)
table.float('rating');                            // FLOAT
table.double('latitude');                         // DOUBLE
table.increments('id');                           // Auto-increment primary key
```

**String Types:**
```dart
table.string('name');                             // VARCHAR(255)
table.string('code').length(10);                  // VARCHAR(10)
table.text('description');                        // TEXT
table.tinyText('excerpt');                        // TINYTEXT
table.mediumText('article');                      // MEDIUMTEXT
table.longText('content');                        // LONGTEXT
table.char('code', length: 8);                    // CHAR(8) - fixed length
```

**Date/Time Types:**
```dart
table.date('birth_date');                         // DATE
table.time('start_time');                         // TIME
table.timestamp('created_at');                    // TIMESTAMP
table.datetime('scheduled_at');                   // DATETIME
table.year('fiscal_year');                        // YEAR (MySQL)
```

**Boolean:**
```dart
table.boolean('active');                          // BOOLEAN/TINYINT(1)
```

**Binary Data:**
```dart
table.binary('data');                             // BLOB/BYTEA
table.blob('file_content');                       // BLOB
```

**JSON:**
```dart
table.json('metadata');                           // JSON (varies by driver)
table.jsonb('settings');                          // JSONB (PostgreSQL)
```

**Identifiers:**
```dart
table.uuid('id');                                 // UUID
table.ulid('device_ulid');                        // ULID stored as string
```

**Specialized Types:**
```dart
table.ipAddress('ip');                            // IP address
table.macAddress('mac');                          // MAC address
table.geometry('location');                       // Spatial (PostGIS)
table.point('coordinates');                       // Point geometry
table.polygon('boundary');                        // Polygon geometry
table.vector('embedding', dimensions: 3);         // Vector embeddings
```

**Note:** Driver support varies. MongoDB stores most types as BSON equivalents, while SQL databases have native column types.

### Column Modifiers

Chain modifiers to customize column behavior:

```dart
table.string('email')
  .nullable()                              // Allow NULL values
  .defaultValue('user@example.com')        // Set default value
  .unique()                                // Add unique constraint
  .primaryKey()                            // Mark as primary key
  .autoIncrement()                         // Auto-increment (integers only)
  .unsigned()                              // Unsigned (integers only)
  .length(100);                            // Max length (strings)
```

**Common modifier combinations:**

```dart
// Auto-increment primary key
table.integer('id').primaryKey().autoIncrement();

// Nullable with default
table.string('status').nullable().defaultValue('pending');

// Unique non-null column
table.string('username').unique();

// Foreign key column
table.unsignedBigInteger('user_id');

// Decimal with precision
table.decimal('price').precision(10, 2).unsigned();

// Timestamp with default
table.timestamp('created_at').defaultValue('CURRENT_TIMESTAMP');
```

**Modifier order doesn't matter** - chain them in any order for readability.

### Indexes

Indexes improve query performance for columns used in WHERE, JOIN, and ORDER BY clauses:

**Basic Indexes:**
```dart
// Single column index
table.index(['email']);

// Multi-column (composite) index
table.index(['user_id', 'created_at']);

// Unique index (enforces uniqueness)
table.index(['username']).unique();
// Or shorthand:
table.unique(['username']);

// Named index (for easier management)
table.index(['email']).name('idx_user_email');
```

**Specialized Indexes:**
```dart
// Full-text search index
table.fullText(['title', 'content']);

// Spatial index (for geometry columns)
table.spatialIndex(['location']);

// Primary key index
table.primary(['id']);

// Raw index with expression
table.rawIndex('lower(email)', name: 'users_email_lower_index');
```

**Dropping Indexes:**
```dart
table.dropIndex('idx_user_email');     // Drop by name
table.dropUnique(['username']);        // Drop unique constraint
table.dropPrimary();                   // Drop primary key
```

**Index Tips:**
- Add indexes to foreign key columns for better JOIN performance
- Use composite indexes when querying multiple columns together
- Order matters in composite indexes: `['user_id', 'created_at']` ≠ `['created_at', 'user_id']`
- Don't over-index: each index slows down INSERT/UPDATE operations
- Test query performance with EXPLAIN to verify index usage

### Foreign Keys

Foreign keys enforce referential integrity between tables:

**Basic Foreign Key:**
```dart
// Single column foreign key
table.foreignKey(['user_id'])
  .references('users', ['id'])
  .onDelete(ForeignKeyAction.cascade)
  .onUpdate(ForeignKeyAction.restrict);
```

**Composite Foreign Key:**
```dart
// Multi-column foreign key
table.foreignKey(['tenant_id', 'user_id'])
  .references('users', ['tenant_id', 'id']);
```

**Foreign Key Actions:**
```dart
// When parent row is deleted/updated
.onDelete(ForeignKeyAction.cascade)      // Delete child rows
.onDelete(ForeignKeyAction.restrict)     // Prevent deletion if children exist
.onDelete(ForeignKeyAction.setNull)      // Set foreign key to NULL
.onDelete(ForeignKeyAction.noAction)     // No action (check deferred)

.onUpdate(ForeignKeyAction.cascade)      // Update child foreign keys
.onUpdate(ForeignKeyAction.restrict)     // Prevent update if children exist
```

**Named Foreign Keys:**
```dart
table.foreignKey(['user_id'])
  .references('users', ['id'])
  .name('fk_posts_user_id')
  .onDelete(ForeignKeyAction.cascade);
```

**Dropping Foreign Keys:**
```dart
table.dropForeignKey('fk_posts_user_id');
```

**Best Practices:**
- Create parent tables before child tables
- Drop child tables before parent tables
- Use `cascade` for dependent data (e.g., post comments)
- Use `restrict` to prevent accidental deletions
- Use `setNull` for optional relationships with nullable foreign keys
- Always add indexes to foreign key columns for performance

### MongoDB Collections

MongoDB migrations use collection-specific methods instead of table schemas:

**Creating Collections:**
```dart
@override
void up(SchemaBuilder schema) {
  // Basic collection
  schema.createCollection('users');
  
  // Collection with JSON Schema validator
  schema.createCollection(
    'users',
    validator: {
      '\$jsonSchema': {
        'bsonType': 'object',
        'required': ['email', 'name'],
        'properties': {
          'email': {
            'bsonType': 'string',
            'pattern': '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$'
          },
          'name': {'bsonType': 'string'},
          'age': {'bsonType': 'int', 'minimum': 0}
        }
      }
    },
  );
  
  // Capped collection (fixed size)
  schema.createCollection(
    'logs',
    options: {
      'capped': true,
      'size': 1048576,      // 1MB
      'max': 5000           // Max documents
    }
  );
}
```

**Creating Indexes:**
```dart
// Single field index
schema.createIndex(
  collection: 'users',
  keys: {'email': 1},              // 1 = ascending, -1 = descending
  options: {'unique': true},
);

// Compound index
schema.createIndex(
  collection: 'posts',
  keys: {'author_id': 1, 'created_at': -1},
);

// Text search index
schema.createIndex(
  collection: 'articles',
  keys: {'title': 'text', 'content': 'text'},
);

// Geospatial index
schema.createIndex(
  collection: 'locations',
  keys: {'coordinates': '2dsphere'},
);
```

**Modifying Collections:**
```dart
// Update validator rules
schema.modifyValidator(
  collection: 'users',
  validator: {
    '\$jsonSchema': {
      'required': ['email', 'name', 'status'],
      'properties': {
        'status': {'enum': ['active', 'inactive']}
      }
    }
  },
);
```

**Dropping Collections/Indexes:**
```dart
@override
void down(SchemaBuilder schema) {
  schema.dropIndex(
    collection: 'users',
    indexName: 'email_1',
  );
  
  schema.dropCollection('users');
}
```

**MongoDB Migration Tips:**
- Validators are optional but recommended for data consistency
- Use indexes on frequently queried fields
- Compound indexes should match query patterns
- MongoDB allows schema-less collections, but validators help prevent bugs
- Capped collections are useful for logs and time-series data

## Running Migrations

### Using the CLI

**Apply pending migrations:**
```bash
# Apply all pending migrations
dart run orm migrate:apply

# Apply only next 5 migrations
dart run orm migrate:apply --limit 5

# Apply to specific connection
dart run orm migrate:apply --connection analytics
```

**Rollback migrations:**
```bash
# Rollback last batch
dart run orm migrate:rollback

# Rollback last 3 batches
dart run orm migrate:rollback --steps 3

# Rollback specific connection
dart run orm migrate:rollback --connection analytics
```

**Check migration status:**
```bash
# See which migrations are pending/applied
dart run orm migrate:status

# Check specific connection
dart run orm migrate:status --connection analytics
```

**Other commands:**
```bash
# Fresh database (drop all tables and re-run migrations)
dart run orm migrate:fresh

# Reset (rollback all and re-run)
dart run orm migrate:reset

# Refresh (rollback and re-apply)
dart run orm migrate:refresh
```

### Programmatically

```dart
import 'package:ormed/migrations.dart';

final runner = MigrationRunner(
  driver: connection.driver,
  migrations: [
    MigrationEntry(
      id: MigrationId.parse('2024_11_29_143052_create_users_table'),
      migration: const CreateUsersTable(),
    ),
  ],
);

// Apply all pending migrations
await runner.migrate();

// Rollback last batch
await runner.rollback();
```



## Troubleshooting

### Migration Already Applied

```
Error: Migration X has already been applied
```

Use `migrate:status` to check applied migrations.

### Checksum Mismatch

```
Error: Migration checksum doesn't match recorded value
```

Migration was modified after being applied. Revert changes or create a new migration.

### Foreign Key Constraint Failed

Ensure parent table exists before creating foreign key, and drop dependent tables before dropping parent tables.

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
`packages/ormed_cli` and ships an executable named `orm`.

For complete CLI documentation including all options and examples, see the
[CLI Reference](cli.md).

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
