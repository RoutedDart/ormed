# ormed

`ormed` provides the strongly typed foundation for routed's upcoming ORM:
annotations, metadata types, codec abstractions, and a source-gen powered model
builder inspired by Eloquent, GORM, SQLAlchemy, and ActiveRecord.

## Features

- `@OrmModel`, `@OrmField`, and `@OrmRelation` annotations to describe tables,
  columns, and relationships directly in Dart code.
- Code generation that emits `ModelDefinition`, `FieldDefinition`, and
  `ModelCodec` helpers for every annotated class.
- `ValueCodec` + `ValueCodecRegistry` so drivers can translate between driver
  payloads (e.g., Postgres binary) and rich Dart objects.
- Driver-aware schema hints so the same blueprint can emit `jsonb` on Postgres
  while staying `TEXT` elsewhere via `driverOverride`/`driverSqlType`, plus
  driver-scoped codec overlays with `ValueCodecRegistry.forDriver`.
- `ModelRegistry` utilities that let frameworks register/lookup models at
  runtime without static globals.
- `QueryContext`, fluent `Query<T>` builder, relation loader, and an
  `InMemoryQueryExecutor` for tests to validate chaining, eager loading, and
  pagination without a real database.

## Getting started

1. Add `ormed` to the root `pubspec.yaml` (already included inside this
   workspace) then run `dart pub get`.
2. Annotate your model and add a `part` directive:

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User {
  const User({required this.id, required this.email, this.preferences});

  @OrmField(isPrimaryKey: true)
  final String id;

  @OrmField(codec: JsonMapCodec)
  final Map<String, Object?>? preferences;

  final String email;
}
```

3. Run the builder:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This produces `user.orm.dart` containing a `ModelDefinition<User>`, generated
codec, and helpers accessible via `UserOrmDefinition.definition`.

## Usage

```dart
final registry = ValueCodecRegistry.standard()
  ..registerCodecFor(JsonMapCodec, const JsonMapCodec());

final definition = UserOrmDefinition.definition;
final row = definition.toMap(User(id: '1', email: 'dev@example.com'));
final decoded = definition.fromMap(row, registry: registry);

final models = ModelRegistry()..register(definition);
print(models.expect<User>().tableName); // "users"
```

See `/example` for a compilable todo model plus CLI usage.

## Driver-specific overrides and codecs

Multi-database projects often need different column types or default
expressions per driver. Use the fluent helpers on `ColumnBuilder` to keep a
single migration definition:

```dart
builder.create('events', (table) {
  table.json('metadata')
    ..nullable()
    ..driverType('postgres', const ColumnType.jsonb());

  table.string('locale')
    ..driverOverride('postgres', collation: '"und-x-icu"');

  table.timestamp('synced_at', timezoneAware: true)
    ..driverDefault('postgres', expression: "timezone('UTC', now())");
});
```

The same plan now emits `JSONB` + Postgres-specific collations while SQLite
continues to use `TEXT`. At runtime, register codecs scoped to each driver so
repositories pick up the right encode/decode behavior automatically:

```dart
final baseRegistry = ValueCodecRegistry.standard()
  ..registerCodecFor(JsonMapCodec, const JsonMapCodec());

baseRegistry
  .forDriver('postgres')
  .registerCodec(key: 'UuidValue', codec: const PostgresUuidCodec());

final adapter = PostgresDriverAdapter.custom(
  config: postgresConfig,
  codecRegistry: baseRegistry,
);

final context = QueryContext(
  registry: modelRegistry,
  driver: adapter,
);
// context.codecRegistry now resolves driver-specific codecs transparently.
```

`QueryContext` automatically scopes any registry (your custom one or the
driver's default) to `adapter.metadata.name`, so you never need to branch in
model code to pick the correct codec.

## Schema inspector

All driver adapters implement the `SchemaDriver` contract, so you can inspect the
live database catalog without writing raw SQL. Wrap any driver in the
`SchemaInspector` helper to mirror Laravel's schema builder ergonomics:

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

Future<void> main() async {
  final adapter = SqliteDriverAdapter.inMemory();
  final inspector = SchemaInspector(adapter as SchemaDriver);

  final hasUsers = await inspector.hasTable('users');
  final emailType = await inspector.columnType('users', 'email');
  final columns = await adapter.listColumns('posts');
  final indexes = await adapter.listIndexes('posts');

  print('Users table exists? $hasUsers');
  print('users.email column type: $emailType');
  print('posts columns: ${columns.map((c) => c.name)}');
  print('posts indexes: ${indexes.map((i) => i.name)}');
  await adapter.close();
}
```

These APIs power future tooling (migration diffs, CLI diagnostics, etc.) and are
available on every routed ORM driver.

## Next steps

- Driver adapters will consume the generated `ModelDefinition`s to build SQL or
  document queries.
- `orm_migrations` will share the same metadata to guarantee schema drift
  detection and reversible migrations.
