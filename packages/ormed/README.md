# ormed

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

A strongly-typed ORM (Object-Relational Mapping) core for Dart, inspired by Eloquent (Laravel), GORM, SQLAlchemy, and ActiveRecord. Combines compile-time code generation with runtime flexibility for type-safe database operations.

## Features

- **Annotations**: `@OrmModel`, `@OrmField`, `@OrmRelation`, `@OrmScope`, `@OrmEvent` to describe tables, columns, relationships, and behaviors
- **Code Generation**: Emits `ModelDefinition`, `FieldDefinition`, `ModelCodec`, DTOs, and tracked model classes
- **Query Builder**: Fluent, type-safe queries with filtering, ordering, pagination, aggregates, and eager loading
- **Relationships**: HasOne, HasMany, BelongsTo, ManyToMany, and polymorphic relations (MorphOne, MorphMany)
- **Migrations**: Schema builder with Laravel-style table blueprints and driver-specific overrides
- **Value Codecs**: Custom type serialization with driver-scoped codec registries
- **Soft Deletes**: Built-in support with `withTrashed()`, `onlyTrashed()` scopes
- **Event System**: Model lifecycle events (Creating, Created, Updating, Updated, Deleting, Deleted)
- **Testing**: `TestDatabaseManager` with database isolation strategies

## Installation

```yaml
dependencies:
  ormed: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
```

## Quick Start

### 1. Define a Model

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User {
  const User({required this.id, required this.email, this.name});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(isUnique: true)
  final String email;

  final String? name;
}
```

### 2. Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

This produces `user.orm.dart` with:
- `UserOrmDefinition.definition` - Model metadata
- `$User` - Tracked model class with dirty checking
- `$UserInsertDto`, `$UserUpdateDto` - Mutation DTOs
- `$UserCodec` - Encode/decode helpers

### 3. Use the ORM

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() async {
  final ds = DataSource(DataSourceOptions(
    driver: SqliteDriverAdapter.inMemory(),
    entities: [UserOrmDefinition.definition],
  ));
  await ds.init();

  // Insert
  await ds.repo<$User>().insert($UserInsertDto(email: 'dev@example.com'));

  // Query
  final users = await ds.query<$User>()
      .whereEquals('email', 'dev@example.com')
      .get();

  // Update
  await ds.repo<$User>().update(
    $UserUpdateDto(name: 'Developer'),
    where: {'id': 1},
  );

  // Delete
  await ds.repo<$User>().deleteByIds([1]);
}
```

## Annotations

### `@OrmModel`

```dart
@OrmModel(
  table: 'users',
  schema: 'public',           // Optional schema/namespace
  softDeletes: true,          // Enable soft deletes
  primaryKey: 'id',           // Alternative to @OrmField(isPrimaryKey: true)
  fillable: ['email', 'name'], // Mass assignment whitelist
  guarded: ['role'],          // Mass assignment blacklist
  hidden: ['password'],       // Hidden from serialization
  connection: 'analytics',    // Connection name override
)
```

### `@OrmField`

```dart
@OrmField(
  columnName: 'user_email',   // Custom column name
  isPrimaryKey: true,
  autoIncrement: true,
  isNullable: true,
  isUnique: true,
  isIndexed: true,
  codec: JsonMapCodec,        // Custom value codec
  columnType: ColumnType.text, // Override column type
  defaultValueSql: 'NOW()',   // SQL default expression
  driverOverrides: {...},     // Per-driver customizations
)
```

### `@OrmRelation`

```dart
// One-to-One (foreign key on related table)
@OrmRelation.hasOne(related: Profile, foreignKey: 'user_id')
final Profile? profile;

// One-to-Many
@OrmRelation.hasMany(related: Post, foreignKey: 'author_id')
final List<Post> posts;

// Inverse relation
@OrmRelation.belongsTo(related: User, foreignKey: 'user_id')
final User author;

// Many-to-Many
@OrmRelation.manyToMany(
  related: Tag,
  pivot: 'post_tags',
  foreignPivotKey: 'post_id',
  relatedPivotKey: 'tag_id',
)
final List<Tag> tags;

// Polymorphic
@OrmRelation.morphMany(related: Comment, morphName: 'commentable')
final List<Comment> comments;
```

## Query Builder

```dart
final posts = await ds.query<$Post>()
    // Filtering
    .whereEquals('status', 'published')
    .whereIn('category_id', [1, 2, 3])
    .whereNull('deleted_at')
    .whereBetween('views', 100, 1000)
    .whereHas('comments', (q) => q.whereEquals('approved', true))
    
    // Eager loading
    .with_(['author', 'tags'])
    .withCount('comments')
    
    // Ordering & Pagination
    .orderByDesc('created_at')
    .limit(20)
    .offset(40)
    
    // Execute
    .get();

// Aggregates
final count = await ds.query<$Post>().count();
final avgViews = await ds.query<$Post>().avg('views');

// Pagination
final page = await ds.query<$Post>().paginate(page: 2, perPage: 15);
```

## Migrations

```dart
class CreateUsersTable extends Migration {
  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.id();                              // bigIncrements primary key
      table.string('email').unique();
      table.string('name').nullable();
      table.boolean('active').defaultValue(true);
      table.timestamps();                      // created_at, updated_at
      table.softDeletes();                     // deleted_at
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users');
  }
}
```

### Column Types

| Method | Description |
|--------|-------------|
| `id()` | Auto-incrementing big integer primary key |
| `string(name, length?)` | VARCHAR column |
| `text(name)` | TEXT column |
| `integer(name)` / `bigInteger(name)` | Integer columns |
| `decimal(name, precision?, scale?)` | Decimal column |
| `boolean(name)` | Boolean column |
| `dateTime(name)` / `timestamp(name)` | DateTime columns |
| `json(name)` / `jsonb(name)` | JSON columns |
| `binary(name)` | Binary/BLOB column |
| `enum_(name, values)` | Enum column |

### Column Modifiers

```dart
table.string('locale')
    .nullable()
    .unique()
    .defaultValue('en')
    .comment('User locale')
    .driverType('postgres', ColumnType.jsonb())  // Per-driver type
    .driverDefault('postgres', "'{}'::jsonb");   // Per-driver default
```

## Value Codecs

Custom type serialization for database ↔ Dart conversion:

```dart
class UuidCodec extends ValueCodec<UuidValue> {
  const UuidCodec();

  @override
  UuidValue? decode(Object? value) =>
      value == null ? null : UuidValue.fromString(value as String);

  @override
  Object? encode(UuidValue? value) => value?.uuid;
}

// Register globally
ValueCodecRegistry.instance.registerCodecFor(UuidCodec, const UuidCodec());

// Or per-driver
ValueCodecRegistry.instance.forDriver('postgres')
    .registerCodec(key: 'UuidValue', codec: const PostgresUuidCodec());
```

## Repository Operations

```dart
final repo = ds.repo<$User>();

// Create
await repo.insert($UserInsertDto(email: 'new@example.com'));
await repo.insertMany([dto1, dto2, dto3]);

// Read
final user = await repo.find(1);
final all = await repo.all();
final first = await repo.first();

// Update (accepts DTOs, models, or maps)
await repo.update(dto, where: {'id': 1});
await repo.update(dto, where: (q) => q.whereEquals('email', 'old@example.com'));

// Delete
await repo.delete(model);
await repo.deleteByIds([1, 2, 3]);

// Upsert
await repo.upsert(dto, uniqueBy: ['email']);
```

## Transactions

```dart
await ds.transaction(() async {
  await ds.repo<$User>().insert(userDto);
  await ds.repo<$Profile>().insert(profileDto);
  // Automatically rolls back on exception
});
```

## Related Packages

| Package | Description |
|---------|-------------|
| `ormed_sqlite` | SQLite driver adapter |
| `ormed_postgres` | PostgreSQL driver adapter |
| `ormed_mysql` | MySQL/MariaDB driver adapter |
| `ormed_cli` | CLI tool for migrations and scaffolding |

## Examples

See the `example/` directory and `packages/orm_playground` for comprehensive usage examples.
