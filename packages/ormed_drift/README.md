# ormed_drift

Use Ormed's query builder and reactive watchers with a Drift executor. Code
generation remains optional: Ormed can query an ad-hoc table directly while
Drift continues to provide its own typed database API.

## Installation

```yaml
dependencies:
  ormed: ^0.3.0
  ormed_drift: ^0.1.0
  drift: ^2.34.0
```

## Usage modes

### Direct / codegen-free usage

```dart
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_drift/ormed_drift.dart';

final driver = DriftDriverAdapter(
  NativeDatabase.memory(),
  closeDelegate: true,
);
final driftDb = drift.DatabaseConnection(driver.driftExecutor);
final ormed = await OrmDatabase.connect(driver: driver);

final users = ormed.table('users').watch();
```

### Generated / model-backed usage

Pass the generated registry when the application wants typed Ormed models in
addition to Drift's generated database API:

```dart
import 'package:drift/native.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_drift/ormed_drift.dart';
import 'package:your_app/src/models/user.orm.dart';

final registry = buildOrmRegistry();
final driver = DriftDriverAdapter(
  NativeDatabase.memory(),
  closeDelegate: true,
);
final database = await OrmDatabase.connect(
  driver: driver,
  registry: registry,
);
final users = await database.query<User>().get();
```

## PostgreSQL

Drift's PostgreSQL executor can use the same adapter. Add `drift_postgres` to
the application, then pass its `PgDatabase` directly. The adapter detects the
PostgreSQL dialect automatically; the named constructor is also available
when the executor is wrapped or its dialect cannot be inferred at startup.

```dart
import 'package:drift_postgres/drift_postgres.dart';
import 'package:ormed_drift/ormed_drift.dart';
import 'package:postgres/postgres.dart';

final driver = DriftDriverAdapter(
  PgDatabase(
    endpoint: Endpoint(
      host: 'localhost',
      database: 'catalog',
      username: 'postgres',
      password: 'postgres',
    ),
  ),
  closeDelegate: true,
);
// Equivalent when an explicit profile is preferred:
// final driver = DriftDriverAdapter.postgres(executor);
final database = await OrmDatabase.connect(driver: driver);
```

The PostgreSQL profile supplies PostgreSQL query/schema grammar, `$1`
placeholder conversion, affected-row handling, conflict-ignore SQL, schema
introspection, and Ormed migration execution. PostgreSQL support is
native/server-side; browser and Worker builds keep the SQLite/LibSQL path and
do not import the PostgreSQL transport.

For a backend with an explicit synchronization operation, pass it as the
adapter callback. For example, with `drift_libsql`:

```dart
final libsql = DriftLibsqlDatabase(
  localReplicaPath,
  syncUrl: tursoUrl,
  authToken: tursoToken,
  readYourWrites: true,
);
final driver = DriftDriverAdapter(
  libsql,
  closeDelegate: true,
  synchronize: libsql.sync,
);
final db = await OrmDatabase.connect(driver: driver);

// Pull remote changes and refresh Ormed watchers.
await driver.sync();
```

Both APIs must use the same `DriftDriverAdapter`. Writes made through either
the Drift executor or Ormed are then published to Ormed watchers, with direct
Drift transactions publishing only after commit.

Schema ownership stays with Ormed. The example applies an Ormed migration to
the Drift-backed database before it starts querying:

```dart
await database.migrate([
  MigrationEntry.named(
    'm_20260824000000_create_authors',
    const CreateAuthorsMigration(),
  ),
]);
```

## Run the example

The package includes an executable integration example covering Drift writes,
Ormed writes, committed transactions, and rollback behavior:

```sh
dart run example/main.dart
```

`DriftDriverAdapter` wraps Drift's `QueryExecutor` API, so the integration is
intentionally isolated in this optional package. It does not make writes made
through an unrelated executor or database connection observable.

## Related packages

| Package | Use it for |
| --- | --- |
| [`ormed`](https://pub.dev/packages/ormed) | Core runtime, models, queries, and migrations |
| [`ormed_sqlite`](https://pub.dev/packages/ormed_sqlite) | Native and browser SQLite |
| [`ormed_postgres`](https://pub.dev/packages/ormed_postgres) | Native PostgreSQL driver |
| [`ormed_cli`](https://pub.dev/packages/ormed_cli) | Scaffolding and migration commands |
| [`drift`](https://pub.dev/packages/drift) | Typed database APIs and executors |
