# Examples & Recipes

This chapter provides end-to-end walkthroughs demonstrating how the routed ORM
pieces work together.

## End-to-End SQLite Workflow

1. **Dependencies** (`pubspec.yaml`)
   ```yaml
   dependencies:
     orm_core:
     ormed_sqlite:
   dev_dependencies:
     build_runner:
     orm_cli:
   ```
2. **Model (`lib/user.dart`)**
   ```dart
   import 'package:ormed/ormed.dart';
   part 'user.orm.dart';

   @OrmModel(table: 'users')
   class User extends Model<User> {
     const User({required this.id, required this.email});

     @OrmField(isPrimaryKey: true)
     final int id;
     final String email;
   }
   ```
3. **Generate** - `dart run build_runner build --delete-conflicting-outputs`.
   This also produces `lib/orm_registry.g.dart` which exports
   `buildOrmRegistry()`. Import it (`import 'package:your_app/orm_registry.g.dart';`)
   to get a `ModelRegistry` pre-populated with every generated model.

   If you want the registry in a different location (for example `lib/generated/`),
   add a `build.yaml` alongside `pubspec.yaml` that configures the builder:

   ```yaml
   targets:
     $default:
       builders:
         orm_core|orm_registry:
           options:
             output: lib/generated/orm_registry.g.dart
   ```

   The path is relative to the package root and defaults to `lib/orm_registry.g.dart`.
4. **Bootstrap CLI** - `dart run orm_cli:init` (creates `orm.yaml`, registry, and migrations directory).
5. **Create/Apply migrations** - `dart run orm_cli:make --name create_users`, edit the file, then `dart run orm_cli:apply`.
6. **Query** - reuse the generated models inside `QueryContext`:

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'user.dart';
import 'user.orm.dart';

Future<void> main() async {
  final registry = ModelRegistry()
    ..register(UserOrmDefinition.definition);

  final adapter = SqliteDriverAdapter.file('app.sqlite');
  final context = QueryContext(registry: registry, driver: adapter);

  await context.repository<User>().insertMany([
    const User(id: 1, email: 'example@example.com'),
  ], returning: true);

  final emails = (await context.query<User>().orderBy('id').get())
      .map((user) => user.email)
      .join(', ');
  print('Users: $emails');
  await adapter.close();
}
```
   Extending `Model<User>` is optional but saves you from manually adding the
   attribute/connection mixins and unlocks the built-in persistence helpers
   described later in this guide.

> **Helper tip** – If you prefer not to pass `context` around, bind the global
> resolver once:
>
> ```dart
> Model.bindConnectionResolver(resolveConnection: (_) => context);
> final created = await Model.create<User>(const User(id: 2, email: 'hi@routed.dev'));
> final models = await Model.query<User>().orderBy('id').get();
> print('Users: ${models.length}');
> ```
>
> This delegates to the same repositories/query builders under the hood while
> keeping sample code concise. Call `Model.unbindConnectionResolver()` when
> you're done (e.g., in tests).

> **CLI preview** - `orm_cli` prints a "change set" before each migration runs,
> highlighting columns/indexes/foreign keys that will be created or dropped.

## Connecting to File-Based SQLite via ConnectionFactory

```dart
final factory = ConnectionFactory(connectors: {
  'sqlite': () => SqliteConnector(),
});

final adapter = SqliteDriverAdapter.custom(
  config: const DatabaseConfig(driver: 'sqlite', options: {'path': 'app.db'}),
  connections: factory,
);
```

- Swap `options` for `{'memory': true}` to run ephemeral tests.
- Register additional connectors in the factory to prepare for Postgres or
  MySQL once those adapters exist.

## Running Migrations with orm_cli

### SQLite Project

1. Initialize scaffolding - `dart run orm_cli:init`.
2. Create a migration - `dart run orm_cli:make --name create_users_table`.
3. Edit the generated file (under `database/migrations/`).
4. Apply pending migrations - `dart run orm_cli:apply`.
5. Verify status / ledger - `dart run orm_cli:status`.
6. Roll back if needed - `dart run orm_cli:rollback`.

### Postgres Project

1. Start Postgres locally (`docker compose up postgres` inside
   `packages/orm/ormed_postgres/`) or provide `POSTGRES_URL`.
2. Update `pubspec.yaml` to include `ormed_postgres`.
3. Configure `orm.yaml`:
   ```yaml
   driver:
     type: postgres
     options:
       url: ${POSTGRES_URL:-postgres://postgres:postgres@localhost:6543/orm_test}
   migrations:
     directory: database/migrations
     registry: database/migrations.dart
     ledger_table: orm_migrations
   ```
4. Run the same CLI commands (`init`, `make`, `apply`, `status`, `rollback`).
   The driver adapter handles ledger creation and schema diff previews against
   the Postgres server.

### Workspace Playground

This repository contains `orm_playground/`, a tiny Dart app wired to SQLite and
preloaded with migrations. You can run the CLI against it from the workspace
root without changing directories:

```
dart run packages/orm/orm_cli/bin/orm.dart apply --config orm_playground/orm.yaml
```

After applying migrations, inspect the data via
`dart run orm_playground/bin/orm_playground.dart`. The playground uses
`PlaygroundDatabase` (exported from `package:orm_playground/orm_playground.dart`)
to register a connection through `ConnectionManager` and then issues ad-hoc
queries with `connection.table('users')`.

## Postgres + QueryContext Example

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

import 'user.dart';
import 'user.orm.dart';

Future<void> main() async {
  final adapter = PostgresDriverAdapter.custom(
    config: const DatabaseConfig(
      driver: 'postgres',
      options: {'url': 'postgres://postgres:postgres@localhost:6543/orm_test'},
    ),
  );

  final context = QueryContext(
    registry: ModelRegistry()..register(UserOrmDefinition.definition),
    driver: adapter,
  );

  await context.repository<User>().insert(const User(id: 1, email: 'pg@routed.dev'));
  print((await context.query<User>().first())?.email);
  await adapter.close();
}
```

## Observability Example

```dart
final context = QueryContext(registry: registry, driver: adapter);
StructuredQueryLogger.printing(pretty: true).attach(context);
await context.query<User>().whereEquals('id', 1).first();
```

Outputs:
```json
{
  "type": "query",
  "model": "User",
  "sql": "SELECT \"id\", \"email\" FROM \"users\" WHERE \"id\" = ?",
  "parameters": [1],
  "duration_ms": 0.42
}
```

## Manual Join Recipe

```dart
final recentPosts = await context
    .query<Post>()
    .join('authors', (join) {
      join.on('authors.id', '=', 'posts.author_id');
      join.where('authors.active', true);
    })
    .joinRelation('tags')
    .selectRaw('authors.name AS author_name')
    .selectRaw('rel_tags_0.label AS tag_label')
    .orderBy('posts.published_at', descending: true)
    .limit(5)
    .rows();

final summaries = recentPosts.map((row) {
  final model = row.model;
  final author = row.row['author_name'];
  final tag = row.row['tag_label'];
  return '${model.title} by $author (${tag ?? 'untagged'})';
});
```

`joinSub` / `leftJoinSub` can layer aggregations, while Postgres adapters also
support `joinLateral` for correlation-heavy queries. Use `joinRelation` to reuse
relation metadata (pivots, morph columns, etc.) when you need SQL JOINs instead
of eager loading the relation.

## Testing Tips

- Use `InMemoryQueryExecutor` from `orm_core/testing` to exercise the query
  builder without a real database.
- Attach listeners to `QueryContext.onQuery` / `.onMutation` in tests to assert
  behavior (e.g., that certain filters were applied).
- For migrations, call `MigrationRunner` with a fake ledger/driver to verify
  ordering logic before connecting to SQLite or another driver.
- For Postgres integration tests, reuse `PostgresTestHarness` (under
  `packages/orm/ormed_postgres/test/support`) which spins up a schema per test
  using `POSTGRES_URL` or the bundled docker-compose file.
## Seeding Data with OrmSeeder

`package:orm_core/testing/seeder.dart` ships a lightweight helper for
integration tests or demos:

```dart
import 'package:orm_core/testing/seeder.dart';

final connection = await factory.register(...).connection();
final seeder = OrmSeeder(connection);

await seeder.truncate('users');
final admin = await seeder.insert(
  User(email: 'admin@example.com', name: 'Admin', active: true),
);
await seeder.insertMany([
  Post(userId: admin.id!, title: 'Hello', body: '...'),
  Post(userId: admin.id!, title: 'Another', body: '...'),
]);
```

Under the hood it reuses repositories (`connection.repository<T>()`) and
invokes driver-specific SQL for `truncate`, so your tests stay portable across
SQLite/MySQL/Postgres.
## Multi-tenant playground

The playground includes a multi-tenant `orm.yaml` with `default`/`analytics`
connections plus `orm_playground/bin/multi_tenant_demo.dart`. After you’ve run
migrations for each connection (e.g. `orm apply` and
`orm apply --connection analytics`), run the demo script:

```bash
dart run orm_playground/bin/multi_tenant_demo.dart
```

The script registers different SQLite files, seeds only empty datasets, and
prints per-tenant user counts through `UserModelFactory.withConnection`.

## Auto-registering connections from orm.yaml

`orm_cli` already relies on `registerConnectionsFromConfig` to bootstrap
`ConnectionManager.defaultManager` for every entry in `orm.yaml`. Each driver
package (`ormed_sqlite`, `ormed_mysql`, `ormed_postgres`, `ormed_mongo`) registers
itself with `DriverRegistry`, so the helper simply selects the right callback,
registers the tenant, and returns an `OrmConnectionHandle`.

You can reuse the same helper in your application or playground without wiring
up each driver manually:

```dart
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:your_app/user.dart';
import 'package:yaml/yaml.dart';

Future<void> main() async {
  final root = Directory.current;
  final configFile = File('orm.yaml');
  final yaml = loadYaml(configFile.readAsStringSync());
  final config = OrmProjectConfig.fromYaml(yaml);

  final handle = await registerConnectionsFromConfig(
    root: root,
    config: config,
    targetConnection: 'analytics',
  );

  await handle.use((connection) async {
    print('Analytics rows: ${await connection.query<User>().count()}');
  });
}
```

`registerConnectionsFromConfig` returns the handle for the requested connection,
and every tenant also becomes available through `ConnectionManager.defaultManager`
once registration completes.
