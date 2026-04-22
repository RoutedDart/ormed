# ormed_sqlite_web

Browser SQLite adapter for Ormed.

`ormed_sqlite_web` uses `ormed_sqlite_core` to compile SQLite-compatible SQL
and executes statements through `sqlite3_web` workers. This package is intended
for web and Flutter web apps that want a dedicated browser adapter instead of
overloading the native `ormed_sqlite` package.

## Installation

```yaml
dependencies:
  ormed: ^0.2.0
  ormed_sqlite_web: ^0.1.0
```

## Quick start with Ormed

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart';

Future<void> main() async {
  final registry = ModelRegistry();
  final ds = DataSource(
    registry.sqliteWebDataSourceOptions(
      name: 'web',
      database: 'app.sqlite',
      workerUri: 'worker.dart.js',
      wasmUri: 'sqlite3.wasm',
    ),
  );

  await ds.init();
  final rows = await ds.connection.driver.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);
  await ds.dispose();
}
```

## Worker entrypoint

Create a dedicated worker entrypoint compiled separately from your main app:

```dart
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart';

void main() {
  runSqliteWebWorker();
}
```

Compile that file to JavaScript and serve it alongside your web app.

## Using `DataSource`

### Helper extensions

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart';

Future<void> main() async {
  final registry = ModelRegistry();
  final dataSource = DataSource(
    registry.sqliteWebDataSourceOptions(
      name: 'web',
      database: 'app.sqlite',
      workerUri: 'worker.dart.js',
      wasmUri: 'sqlite3.wasm',
      implementation: 'recommended',
    ),
  );

  await dataSource.init();
  await dataSource.dispose();
}
```

### `DataSource(DataSourceOptions(...))` direct adapter style

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart';

Future<void> main() async {
  final registry = ModelRegistry();

  final adapter = SqliteWebDriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'sqlite_web',
      options: {
        'database': 'app.sqlite',
        'workerUri': 'worker.dart.js',
        'wasmUri': 'sqlite3.wasm',
      },
    ),
  );

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'web',
      driver: adapter,
      registry: registry,
    ),
  );

  await dataSource.init();
  await dataSource.dispose();
}
```

## Connection options

Required:

- `database` or `databaseName`
- `workerUri` or `worker_uri`
- `wasmUri` / `wasm_uri` / `wasmModule`

Optional:

- `implementation` or `mode`:
  - `recommended`
  - `in_memory_local`
  - `in_memory_shared`
  - `indexed_db_unsafe_local`
  - `indexed_db_unsafe_worker`
  - `indexed_db_shared`
  - `opfs_with_external_locks`
  - `opfs_atomics`
  - `opfs_shared`
- `onlyOpenVfs` / `only_open_vfs` (default: `false`)
- explicit `SqliteWebTransport` injection when constructing the adapter/helper

## Notes

- This package is browser-oriented. VM usage should inject a custom
  `SqliteWebTransport` for testing.
- Transactions are implemented with `sqlite3_web` exclusive locks and SQLite
  `BEGIN` / `SAVEPOINT` statements.
- Schema dump/load helpers are not exposed for browser storage backends.
