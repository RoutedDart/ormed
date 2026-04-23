# ormed_sqlite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

SQLite driver adapter for the ormed ORM. Implements the `DriverAdapter` contract, compiling query plans into SQL and executing them via `package:sqlite3`.

## Features

- In-memory and file-based SQLite databases
- Conditional web and Flutter web support through `sqlite3_web`
- Full transaction support with nested savepoints
- Schema introspection and migration support
- JSON operations via SQLite's JSON1 extension
- Window functions (SQLite 3.25.0+)
- Full-text search (FTS5) and spatial indexes (R*Tree)
- Carbon/DateTime timezone-aware handling

## Installation

```yaml
dependencies:
  ormed: ^0.2.0
  ormed_sqlite: ^0.3.0
```

## Quick Start

```dart
import 'package:your_app/src/database/datasource.dart';

Future<void> main() async {
  final ds = createDataSource(connection: 'default');
  await ds.init();

  final rows = await ds.connection.driver.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);

  await ds.dispose();
}
```

Generated apps should use `ormed init` scaffolding (`lib/src/database/config.dart` +
`datasource.dart`) as the primary runtime entrypoint.

## Web and Flutter web

The same `package:ormed_sqlite` import can be used on web builds. On web,
`SqliteDriverAdapter` routes through the browser worker-backed implementation
provided by `ormed_sqlite_web`.

You must provide:

- `workerUri`: the compiled JS worker entrypoint
- `wasmUri`: a `sqlite3.wasm` file compatible with `package:sqlite3`

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

Future<void> main() async {
  final registry = ModelRegistry();
  final ds = DataSource(
    registry.sqliteFileDataSourceOptions(
      path: 'app.sqlite',
      name: 'web',
      workerUri: 'worker.js',
      wasmUri: 'sqlite3.wasm',
    ),
  );

  await ds.init();
  await ds.connection.driver.executeRaw(
    'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email TEXT NOT NULL)',
  );
  await ds.dispose();
}
```

Worker entrypoint:

```dart
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() {
  runSqliteWebWorker();
}
```

See [`example/web`](./example/web) for a complete browser example.

### Low-level adapter usage

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

Future<void> main() async {
  final adapter = SqliteDriverAdapter.inMemory();
  final context = QueryContext(registry: ModelRegistry(), driver: adapter);

  await adapter.executeRaw(
    'CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT NOT NULL)',
  );
  await context.table('users').insert({'email': 'example@example.com'});
  await adapter.close();
}
```

## Adapter Constructors

```dart
// In-memory database (data lost on close)
SqliteDriverAdapter.inMemory()

// File-based database
SqliteDriverAdapter.file('/path/to/database.sqlite')

// Web / Flutter web
SqliteDriverAdapter.file(
  'app.sqlite',
  options: {
    'workerUri': 'worker.js',
    'wasmUri': 'sqlite3.wasm',
  },
)

// Custom configuration
SqliteDriverAdapter.custom(config: DatabaseConfig(
  driver: 'sqlite',
  options: {
    'memory': true,  // or 'path': '/path/to/db.sqlite'
  },
))
```

## DataSource Helper Extensions

```dart
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:your_app/src/models/user.orm.dart';

Future<void> main() async {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
  final path = env.string('DB_PATH', fallback: 'database/app.sqlite');

  final ds = DataSource(
    registry.sqliteFileDataSourceOptions(path: path, name: 'default'),
  );
  await ds.init();

  final rows = await ds.connection.driver.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);

  await ds.dispose();
}
```

## Environment Variables

Common env vars used by generated SQLite config:

- `DB_PATH` (fallback usually `database/<app>.sqlite`)

Example `.env`:

```bash
DB_PATH=database/app.sqlite
```

## Named DataSources (recommended)

Use named `DataSource` instances for multi-database apps:

```dart
final primary = DataSource(
  myModelRegistry.sqliteFileDataSourceOptions(
    path: 'database/app.sqlite',
    name: 'primary',
  ),
);

final analytics = DataSource(
  myModelRegistry.sqliteFileDataSourceOptions(
    path: 'database/analytics.sqlite',
    name: 'analytics',
  ),
);

await primary.init();
await analytics.init();

final users = await primary.query<\$User>().get();
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

## Web Example

The package includes a browser example under [`example/web`](./example/web).

From `packages/ormed_sqlite/`:

```bash
dart run example/tool/fetch_sqlite3_wasm.dart
dart compile js example/web/main.dart -O4 -o example/web/main.js
dart compile js example/web/worker.dart -O4 -o example/web/worker.js
python3 -m http.server --directory example 8080
```

Then open `http://localhost:8080/web/`.

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
