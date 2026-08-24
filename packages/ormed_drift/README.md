# ormed_drift

Use Ormed's query builder and reactive watchers with a Drift executor. Code
generation remains optional: Ormed can query an ad-hoc table directly while
Drift continues to provide its own typed database API.

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
