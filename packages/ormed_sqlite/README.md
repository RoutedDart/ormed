# ormed_sqlite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

SQLite driver adapter for the ormed ORM. Implements the `DriverAdapter` contract, compiling query plans into SQL and executing them via `package:sqlite3`.

## Features

- In-memory and file-based SQLite databases
- Full transaction support with nested savepoints
- Schema introspection and migration support
- JSON operations via SQLite's JSON1 extension
- Window functions (SQLite 3.25.0+)
- Full-text search (FTS5) and spatial indexes (R*Tree)
- Carbon/DateTime timezone-aware handling

## Installation

```yaml
dependencies:
  ormed: any
  ormed_sqlite: any
```

## Quick Start

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() async {
  // In-memory database
  final adapter = SqliteDriverAdapter.inMemory();
  
  // Or file-based
  // final adapter = SqliteDriverAdapter.file('app.sqlite');
  
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
  final context = QueryContext(registry: registry, driver: adapter);

  // Create schema
  await adapter.executeRaw(
    'CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT NOT NULL)',
  );

  // Use repository
  final repository = context.repository<\$User>();
  await repository.insert(\$User(id: 1, email: 'example@example.com'));

  final users = await context.query<\$User>().get();
  print(users.first.email);
  
  await adapter.close();
}
```

## Adapter Constructors

```dart
// In-memory database (data lost on close)
SqliteDriverAdapter.inMemory()

// File-based database
SqliteDriverAdapter.file('/path/to/database.sqlite')

// Custom configuration
SqliteDriverAdapter.custom(config: DatabaseConfig(
  driver: 'sqlite',
  options: {
    'memory': true,  // or 'path': '/path/to/db.sqlite'
  },
))
```

## Connection Registration

Register connections for use across your application:

```dart
registerSqliteOrmConnection(
  name: 'my_connection',
  database: DatabaseConfig(
    driver: 'sqlite',
    options: {'path': 'app.sqlite'},
  ),
  registry: myModelRegistry,
);

// Use via ConnectionManager
await ConnectionManager.instance.use('my_connection', (conn) async {
  final users = await conn.query<\$User>().get();
});
```

## Driver Capabilities

| Capability | Supported |
|------------|-----------|
| Joins (inner, left, cross) | ✅ |
| Transactions with savepoints | ✅ |
| RETURNING clause | ✅ |
| Schema introspection | ✅ |
| Raw SQL execution | ✅ |
| JSON operations | ✅ |
| Relation aggregates | ✅ |
| Case-insensitive LIKE | ✅ |
| Database management | ✅ |
| Foreign key constraints | ✅ |

## Type Mappings

| Dart Type | SQLite Type |
|-----------|-------------|
| `int` | INTEGER |
| `bool` | INTEGER (0/1) |
| `double` | REAL |
| `String` | TEXT |
| `DateTime` | TEXT (ISO8601) |
| `Carbon` | TEXT (ISO8601 with timezone) |
| `List<int>` | BLOB |
| `Map` | TEXT (JSON) |

## SQLite-Specific Column Types

```dart
import 'package:ormed_sqlite/migrations.dart';

schema.create('files', (table) {
  table.id();
  table.blob('content');     // BLOB column
  table.real('score');       // REAL column
  table.numeric('amount');   // NUMERIC column
});
```

## Transactions

```dart
await adapter.transaction(() async {
  await adapter.executeRaw('INSERT INTO users (email) VALUES (?)', ['a@b.com']);
  await adapter.executeRaw('INSERT INTO users (email) VALUES (?)', ['c@d.com']);
  // Automatically commits on success, rolls back on exception
});

// Nested transactions use savepoints
await adapter.transaction(() async {
  await adapter.transaction(() async {
    // Inner transaction uses SAVEPOINT
  });
});
```

## JSON Operations

SQLite JSON1 extension functions are supported:

```dart
final users = await ds.query<\$User>()
    .whereJson('preferences', '$.theme', 'dark')
    .get();

await ds.query<\$User>()
    .whereEquals('id', 1)
    .jsonSet('preferences', '$.notifications', true);
```

## Schema Introspection

```dart
// List tables
final tables = await adapter.listTables();

// Get column info
final columns = await adapter.listColumns('users');

// Get indexes
final indexes = await adapter.listIndexes('users');
```

## Testing Helpers

```dart
// Raw SQL for test setup
await adapter.executeRaw('CREATE TABLE ...');
await adapter.executeRaw('INSERT INTO ...');

// Truncate with auto-increment reset
await adapter.truncateTable('users');

// Foreign key control
await adapter.disableForeignKeyConstraints();
// ... do work ...
await adapter.enableForeignKeyConstraints();
```

## Full-Text Search (FTS5)

```dart
schema.create('articles', (table) {
  table.id();
  table.string('title');
  table.text('body');
  
  // Creates FTS5 virtual table with triggers
  table.fullTextIndex(['title', 'body']);
});
```

## Related Packages

| Package | Description |
|---------|-------------|
| `ormed` | Core ORM library |
| `ormed_postgres` | PostgreSQL driver |
| `ormed_mysql` | MySQL/MariaDB driver |
| `ormed_cli` | CLI tool for migrations |
