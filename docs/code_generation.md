# Model & Code Generation

The routed ORM uses source generation to produce strongly typed models and
metadata. Start from plain Dart classes annotated with `@OrmModel` and let
`build_runner` produce definitions consumed by the runtime.

## Defining Models

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users', schema: 'public')
class User extends Model<User> {
  const User({required this.id, required this.email, this.profile});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(isUnique: true)
  final String email;

  @OrmRelation(
    kind: RelationKind.hasOne,
    target: Profile,
    foreignKey: 'user_id',
    localKey: 'id',
  )
  final Profile? profile;
}
```

Extending `Model<User>` is optional but recommended because it bundles the
attribute bag, connection hooks, and built-in persistence helpers directly onto
your class. Plain Dart classes without the base (or with manual mixins)
continue to work exactly as before, so you can adopt the new base incrementally.

Annotate relationships with `@OrmRelation` and override column names or codecs
via `@OrmField` properties (e.g., `codecType`, `columnName`, `isNullable`).

## Running the Generator

Add the builder to your `build.yaml` or simply run:

```
dart run build_runner build --delete-conflicting-outputs
```

The generator emits:

- `<model>.orm.dart` with a `ModelDefinition<T>` (field metadata, relations,
  codecs) and a `ModelCodec<T>` used during serialization.
- A `<model>ModelFactory` helper class that re-exports `definition`, the codec,
  `fromMap`, `toMap`, and `registerWith(ModelRegistry)` so callers can materialize
  models without reaching through the longer `OrmDefinition` extension.
- Use `ModelFactory.withConnection(context)` to bind a `QueryContext` to the
  definition and get a ready-to-use `Query` / `Repository` without calling a
  connection decorator for each operation.
- Extension helpers such as `UserOrmDefinition.definition` for registration.

## Model Registry

At runtime you register generated definitions with `ModelRegistry` so the query
builder and repository know how to encode/decode instances.

```dart
final registry = ModelRegistry()
  ..register(UserOrmDefinition.definition)
  ..register(ProfileOrmDefinition.definition);
```

## Value Codecs

Every column maps to a `ValueCodec`. Default codecs cover primitive types,
booleans, lists, maps, and `DateTime`. Override per field via
`@OrmField(codecType: 'MyCustomCodec')` and register the codec type with the
registry:

```dart
registry.codecRegistry.registerCodecFor(MyCustomCodec, const MyCustomCodec());
```

## Factory Helpers & Test Data

Every model trained by the generator also registers a factory helper so you
can call `Model.factory<MyModel>()` and get a builder that knows its
metadata, default generators, and relation defaults. Use the builder to
generate raw column maps or fully instantiated models without wiring codecs
yourself.

```dart
final userData = Model.factory<AttributeUser>()
  .seed(42)
  .withOverrides({'id': 1, 'role': 'admin'})
  .values();

final user = Model.factory<AttributeUser>().make();
final email = Model.factory<AttributeUser>().value('email');
```

The builder has hooks for
`withOverrides`, `withField`, `withGenerator`, and `seed` so your tests can
reuse the same randomness or force specific columns when needed. The default
provider emits primitive data (strings, ints, datetimes, etc.), and you can
swap it out via `Model.factory<MyModel>(generatorProvider: MyGeneratorProvider())` to
tap into `package:property_testing`, Faker-style providers, or your own schema-aware
provider.

You only get a factory builder for models that mix in `ModelFactoryCapable` (the
generator detects the mixin anywhere in the inheritance chain). Models without
that mixin cannot resolve `Model.factory` and receive a clear `StateError`
prompting the mixin addition.

### Example: modeling inheritance

```dart
@OrmModel(table: 'base_items')
class BaseItem extends Model<BaseItem> with ModelFactoryCapable {
  const BaseItem({required this.id, this.name});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String? name;
}

@OrmModel(table: 'special_items')
class SpecialItem extends BaseItem {
  const SpecialItem({required super.id, super.name, this.tags});

  final List<String>? tags;
}
```

Because `SpecialItem` inherits from `BaseItem`, the generator now collects the
`id`/`name` fields defined on the parent class even though only the derived
class is annotated with `@OrmModel`. The emitted factory helper therefore
knows about the inherited fields and the new `tags` column, and `Model.factory<SpecialItem>()`
works just like it does for the base type.

### Example: factory inheritance

```dart
class BaseItem<T extends Model<T>> extends Model<T> with ModelFactoryCapable {
  const BaseItem({required this.id, this.name});

  final int id;
  final String? name;
}

@OrmModel(table: 'special_items')
class SpecialItem extends BaseItem<SpecialItem> {
  const SpecialItem({required super.id, super.name, this.tags});

  final List<String>? tags;
}
```

`SpecialItem` inherits `ModelFactoryCapable` through `BaseItem`, so the generator
still emits `SpecialItemModelFactory` and registers its definition. You can
now call `Model.factory<SpecialItem>()` and override the new `tags` column even
though only the base class is annotated with `@OrmModel`.


## Attribute Bag Runtime

Generated models now include a synthesized subclass that proxies every
getter/setter through an attribute map backed by `ModelAttributes`. When you
extend `Model<T>` you inherit that mixin automatically, and annotation-only
classes still get it because the subclass wires everything up for you. This
lets runtime helpers interact with column data without adding boilerplate
fields.

- Constructors call `replaceAttributes({...})` so instances that you create
  manually stay in sync with the attribute bag.
- When a model is hydrated via `ModelDefinition.fromMap` or the query builder,
  the attribute bag is populated automatically and the instance remembers its
  `ModelDefinition` (available via `modelDefinition`).
- Use `getAttribute<T>('column_name')` / `setAttribute('column_name', value)`
  inside your own mixins to read or override state.

Because the attribute bag is per-instance, you can layer behaviors (casts,
custom getters, etc.) without having to declare extra `final` fields on the
base class.

## Metadata-aware attribute helpers

`@OrmModel` exposes `hidden`, `visible`, `fillable`, `guarded`, `casts`,
`driverAnnotations`, and `primaryKey` for this reason: the generated
`ModelDefinition` keeps a `ModelAttributesMetadata` instance and every runtime
helper (codec, serializer, user API) consults that metadata. That means you can
declare global defaults and shadow them with `@OrmField` overrides when a
single column needs to act differently.

Use the `primaryKey` list when your model uses a composite key (junction or
through tables are common examples). The generator now reads that list before
it falls back to an `id` field, so you can point at the column names (or Dart
field names) that participate in the key without duplicating `isPrimaryKey`
flags on each field:

```dart
@OrmModel(
  table: 'post_tags',
  primaryKey: ['post_id', 'tag_id'],
)
class PostTag {
  const PostTag({required this.postId, required this.tagId});

  @OrmField(columnName: 'post_id')
  final int postId;

  @OrmField(columnName: 'tag_id')
  final int tagId;
}
```

Field-level `@OrmField(isPrimaryKey: true)` annotations remain valid and are
merged with the `primaryKey` list, so you can mix per-field overrides with the
list when you want to highlight a single column while still advertising a
composite key.

The runtime helpers now mirror Laravel’s guardrails:

- `Model.fill(...)` respects the `fillable`/`guarded` lists plus field-level
  overrides and throws `MassAssignmentException` when strict mode rejects
  attributes.
- `Model.fillIfAbsent(...)` only fills missing entries, while `Model.forceFill`
  temporarily disables guarding via an `unguarded` context.
- `Model.toArray()` / `Model.toJson()` filter attributes through `hidden` +
  `visible` and honor per-column `casts` entries when encoding the payload.
- Use `Map<String, Object?>.filteredByAttributes(metadata, definition.fields)`
  when you need to sanitize a raw payload before handing it to `Model.fill`.

Because `ModelAttributesMetadata` owns the metadata, downstream drivers and
helpers (playgrounds, seeders, repositories) can inspect `definition.metadata`
and never worry about stale configuration. The generated helpers are the
preferred surface for building polymorphic models, but you can still call
`setAttribute` / `getAttribute` when you need low-level control.

## Connection-Aware Models

Generated subclasses also mix in `ModelConnection`, so any model hydrated
through a `QueryContext`/`OrmConnection` automatically exposes the active
resolver via `model.connectionResolver` (and the raw driver via
`model.connection`). That means domain helpers can run follow-up queries
without threading contexts manually:

```dart
final author = await connection.query<Author>().first();
if (author is ModelConnection && author.hasConnection) {
  final posts = await author.connectionResolver!
      .queryFromDefinition(PostOrmDefinition.definition)
      .whereEquals('author_id', author.id)
      .get();
}
```

When models are instantiated manually (e.g., `const User(...)`) no connection
is attached, but as soon as they flow through the repository/query APIs they
receive the resolver automatically.

## Soft Deletes & Connection Awareness

Soft deletes no longer require a manual `deletedAt` property. Add the
`SoftDeletes` mixin (or set `@OrmModel(softDeletes: true)`), and the generator
will:

1. Mark the soft delete column in `ModelDefinition.metadata` (defaulting to
   `deleted_at`, or use `softDeletesColumn` to override).
2. Expose `deletedAt`/`trashed` getters that read from the attribute bag.
3. Register the global scope automatically so `QueryContext` filters out
   trashed rows unless you call `withTrashed()` / `onlyTrashed()` / `restore()`.

If your `@OrmModel` mixes in `SoftDeletes` but omits a field, the generator
adds a virtual column in the metadata so drivers know which column to touch.

Every generated subclass also mixes in (or inherits via `Model<T>`)
`ModelConnection`. During hydration, `QueryContext` calls
`attachConnectionResolver(this)`, so you can inspect the active driver
(`model.connection`) or even run follow-up queries via
`model.connectionResolver` when implementing rich domain helpers.

```dart
@OrmModel(table: 'comments')
class Comment extends Model<Comment> with SoftDeletes {
  const Comment({required this.id, required this.body});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String body;
}
```

Prefer extending `Model<T>` for the best experience, but the legacy
mixins-only approach remains supported and the generator still emits the
synthesized subclass with the necessary runtime helpers when needed.

## Model Helper APIs

After registering your definitions, call `Model.bindConnectionResolver` to
describe how the ORM should obtain a `ConnectionResolver` (typically a
`QueryContext` or `OrmConnection`). Every `Model<T>` then gains Laravel-style
helpers:

```dart
final registry = ModelRegistry()
  ..registerModel(UserOrmDefinition.definition);
final context = QueryContext(registry: registry, driver: adapter);

Model.bindConnectionResolver(resolveConnection: (_) => context);

final user = await Model.create<User>(const User(id: 1, email: 'hi@routed.dev'));
await user.refresh();
await user.delete();
await user.restore();

final emails = await Model.query<User>().orderBy('id').get();
```

- `Model.query<T>()`, `Model.all<T>()`, and `Model.create<T>(model)` give you a
  zero-boilerplate entry point into the query builder and repositories.
- Instance helpers (`save`, `delete`, `forceDelete`, `restore`, `refresh`) use
  the attached resolver when possible, falling back to the configured default.
- `ModelRegistry.registerModel()` is a convenience extension that mirrors
  `.register()` but reads more clearly when working with `Model<T>` subclasses.

These helpers are entirely opt-in—you can always keep using
`QueryContext`/`Repository` directly, especially when you need explicit control
over transactions, eager loading, or bulk mutations. Call
`Model.unbindConnectionResolver()` when you're done (e.g., in tests) to clear
the global binding.

## Driver-Specific Field Overrides

Sometimes a field needs to behave differently depending on the active driver
(for example, `jsonb` on Postgres vs. `TEXT` on SQLite). Use the
`driverOverrides` map on `@OrmField` to declare per-driver overrides for column
types, default expressions, or codecs. Keys must match the driver metadata name
(`driver.metadata.name`), typically lowercase.

```dart
@OrmField(
  columnType: 'TEXT',
  driverOverrides: {
    'postgres': OrmDriverFieldOverride(
      columnType: 'jsonb',
      codec: PostgresPayloadCodec,
    ),
    'sqlite': OrmDriverFieldOverride(
      columnType: 'TEXT',
      codec: SqlitePayloadCodec,
    ),
  },
)
final Map<String, Object?> payload;
```

The generator serializes these overrides into every `FieldDefinition`. At
runtime, `QueryBuilder`, `Repository`, and `ValueCodecRegistry` automatically
consult the override that matches the active driver, so your application code
never needs to branch on driver names manually. Register the driver-specific
codecs once on the adapter and they flow through `QueryContext`:

```dart
final adapter = SqliteDriverAdapter.inMemory();
adapter.codecs
  ..registerCodecFor(PostgresPayloadCodec, const PostgresPayloadCodec())
  ..registerCodecFor(SqlitePayloadCodec, const SqlitePayloadCodec());

final context = QueryContext(
  registry: registry,
  driver: adapter,
  codecRegistry: adapter.codecs,
);

await context.repository<DriverOverrideEntry>().insert(
  const DriverOverrideEntry(id: 1, payload: {'theme': 'dark'}),
);
```

## Validation & Constraints

`ModelDefinition` exposes metadata such as `fields`, `relations`
`primaryKeyField`, and indexes. Use these for:

- Validating mutation requests (repositories throw when required keys are
  missing).
- Generating migrations (future integration will diff the model graph against
  the database schema).

## Tips

- Keep model constructors `const` when possible to simplify build outputs.
- Use `@OrmField(ignore: true)` for computed properties you don't want in the
  database but still need for relation traversal.
- Re-run `build_runner` whenever annotations change; the generated files are not
  meant to be edited manually.
