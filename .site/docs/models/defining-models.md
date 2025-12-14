---
sidebar_position: 1
---

# Defining Models

Models in Ormed are Dart classes annotated with `@OrmModel` that map to database tables.

## Basic Model

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User extends Model<User> {
  const User({
    required this.id,
    required this.email,
    this.name,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;
  final String? name;
}
```

After running `dart run build_runner build`, this generates:
- `$User` - Tracked model class with change tracking
- `UserOrmDefinition` - Model metadata and static helpers
- `$UserPartial` - Partial entity for projections
- `UserInsertDto` / `UserUpdateDto` - Data transfer objects

## Model Annotation Options

```dart
@OrmModel(
  table: 'users',           // Required: table name
  hidden: ['password'],     // Fields hidden from serialization
  fillable: ['email'],      // Fields that can be mass-assigned
  guarded: ['id'],          // Fields protected from mass-assignment
  casts: {                  // Custom column casting
    'createdAt': 'datetime',
  },
)
class User extends Model<User> { ... }
```

## Field Annotations

### Primary Key

```dart
@OrmField(isPrimaryKey: true)
final int id;

// Auto-increment (default for integer PKs)
@OrmField(isPrimaryKey: true, autoIncrement: true)
final int id;

// UUID primary key
@OrmField(isPrimaryKey: true)
final String id;
```

### Column Options

```dart
// Custom column name
@OrmField(column: 'user_email')
final String email;

// Default value in SQL
@OrmField(defaultValueSql: '1')
final bool active;

// Nullable field
final String? name;  // Automatically nullable in DB
```

### Custom Codecs

For complex types, use value codecs:

```dart
@OrmField(codec: JsonMapCodec)
final Map<String, Object?>? metadata;

@OrmField(codec: UuidCodec)
final UuidValue id;
```

Define your codec:

```dart
class JsonMapCodec extends ValueCodec<Map<String, Object?>> {
  const JsonMapCodec();

  @override
  Map<String, Object?> decode(Object? value) {
    if (value == null) return {};
    if (value is String) return jsonDecode(value) as Map<String, Object?>;
    return value as Map<String, Object?>;
  }

  @override
  Object? encode(Map<String, Object?> value) => jsonEncode(value);
}
```

## Generated Code

### Tracked Model (`$User`)

The generated `$User` class is the "tracked" version of your model with:
- Change tracking for dirty fields
- Relationship accessors
- Model lifecycle methods

```dart
// The generated class
final user = $User(id: 1, email: 'john@example.com');

// Modify and track changes
user.name = 'John Doe';
print(user.isDirty);  // true
print(user.dirtyFields);  // ['name']
```

### Definition (`UserOrmDefinition`)

Provides static helpers and model metadata:

```dart
// Access the model definition
final definition = UserOrmDefinition.definition;
print(definition.tableName);  // 'users'
print(definition.primaryKey.name);  // 'id'

// Static query helpers
final users = await UserOrmDefinition.all();
final user = await UserOrmDefinition.find(1);
```

### Partial Entity (`$UserPartial`)

For projecting specific columns:

```dart
final partial = await dataSource.query<$User>()
    .select(['id', 'email'])
    .firstPartial();

print(partial.id);     // Available
print(partial.email);  // Available
// partial.name is not available (not selected)
```

### DTOs

Data transfer objects for insert/update operations:

```dart
// Insert DTO
final insertDto = UserInsertDto(email: 'new@example.com');
await repo.insert(insertDto);

// Update DTO
final updateDto = UserUpdateDto(name: 'New Name');
await repo.update(updateDto, where: {'id': 1});
```

## Best Practices

1. **Use const constructors** - Helps with immutability and tree-shaking
2. **Define all fields as final** - Models are immutable by design
3. **Use nullable types** for optional fields - Clearer intent
4. **Keep models focused** - One model per table
5. **Use DTOs** for partial updates - More explicit than tracked models
