# DTO Migration Guide

This guide explains how to migrate from the legacy sentinel-based insert/update pattern to the new DTO-based approach.

## Overview

The ORM now generates type-safe DTOs (Data Transfer Objects) for each model:
- `$ModelInsertDto` - For INSERT operations (omits auto-increment PK)
- `$ModelUpdateDto` - For UPDATE operations (all fields optional)
- `$ModelPartial` - For partial projections (all fields nullable)

These DTOs provide better type safety and eliminate the need for sentinel values.

## Why Migrate?

The legacy approach relied on:
- `insertable` and `updatable` field annotations to control mutation behavior
- `defaultDartValue` to provide sentinel values for auto-increment fields
- Magic sentinel filtering in the repository layer

The new DTO approach:
- Eliminates sentinel values entirely
- Provides clear, type-safe interfaces for mutations
- Separates concerns between queried data (`$Model`) and mutation inputs (DTOs)

## Migration Examples

### Insert Operations

**Legacy approach (still works):**
```dart
// Uses sentinel value (id: 0) that gets filtered out
final user = $User(
  id: 0,  // Sentinel - will be auto-generated
  email: 'user@example.com',
  active: true,
);
await repository.insert(user);
```

**New DTO approach (recommended):**
```dart
// No id field - clearer intent
const dto = UserInsertDto(
  email: 'user@example.com',
  active: true,
);
await repository.insert(dto);
```

### Update Operations

**Legacy approach (still works):**
```dart
final user = await repository.find(1);
user.email = 'new@example.com';
await repository.update(user);
```

**New DTO approach (recommended):**
```dart
// Only update specific fields
const dto = UserUpdateDto(
  email: 'new@example.com',
);
await repository.update(dto, where: {'id': 1});
```

### Upsert Operations

**Legacy approach:**
```dart
final user = $User(
  id: existingId ?? 0,
  email: 'user@example.com',
  active: true,
);
await repository.upsert(user);
```

**New DTO approach:**
```dart
// Insert or update based on email uniqueness
const dto = UserInsertDto(
  email: 'user@example.com',
  active: true,
);
await repository.upsert(dto, uniqueBy: ['email']);
```

### Using Maps

You can also use plain maps for simple cases:

```dart
// Insert with map
await repository.insert({
  'email': 'user@example.com',
  'active': true,
});

// Update with map
await repository.update(
  {'email': 'new@example.com'},
  where: {'id': 1},
);
```

## Deprecated Annotations

The following annotation parameters are deprecated:

### `insertable`
```dart
// Deprecated
@OrmField(insertable: false)
final String computedField;

// New approach: Field is simply not included in InsertDto
```

### `updatable`
```dart
// Deprecated
@OrmField(updatable: false)
final String immutableField;

// New approach: Field is simply not included in UpdateDto
```

### `defaultDartValue`
```dart
// Deprecated
@OrmField(autoIncrement: true, defaultDartValue: 0)
final int id;

// New approach: Use InsertDto which doesn't include auto-increment fields
```

## Backward Compatibility

The legacy sentinel-based approach continues to work. You can migrate incrementally:

1. Start using DTOs for new code
2. Gradually migrate existing insert/update calls
3. Remove deprecated annotations when ready

The old annotations are still honored for backward compatibility but will be removed in a future major version.

## Generated DTO Examples

For a model like:
```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({
    this.id,
    required this.email,
    this.active = false,
    this.name,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;
  
  final String email;
  final bool active;
  final String? name;
}
```

The generator creates:

```dart
// InsertDto - id is omitted (auto-increment)
class UserInsertDto implements InsertDto<$User> {
  const UserInsertDto({
    this.email,
    this.active,
    this.name,
  });

  final String? email;
  final bool? active;
  final String? name;

  @override
  Map<String, Object?> toMap() => {
    if (email != null) 'email': email,
    if (active != null) 'active': active,
    if (name != null) 'name': name,
  };
}

// UpdateDto - all fields optional
class UserUpdateDto implements UpdateDto<$User> {
  const UserUpdateDto({
    this.id,
    this.email,
    this.active,
    this.name,
  });

  final int? id;
  final String? email;
  final bool? active;
  final String? name;

  @override
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    if (email != null) 'email': email,
    if (active != null) 'active': active,
    if (name != null) 'name': name,
  };
}

// Partial - for selective queries
class UserPartial implements PartialEntity<$User> {
  const UserPartial({
    this.id,
    this.email,
    this.active,
    this.name,
  });

  final int? id;
  final String? email;
  final bool? active;
  final String? name;

  @override
  $User toEntity() {
    if (email == null) {
      throw StateError('Missing required field: email');
    }
    return $User(
      id: id ?? 0,
      email: email!,
      active: active ?? false,
      name: name,
    );
  }
}
```

## Partial Projections

Partial projections allow you to query a subset of columns and receive type-safe partial objects instead of full models.

### Using getPartial()

```dart
// Query only the columns you need
final partials = await context.query<User>()
  .select(['id', 'email', 'name'])
  .getPartial(UserPartial.fromRow);

for (final partial in partials) {
  print('User: ${partial.email}');
  // partial.id, partial.email, partial.name are available
  // Other fields are null
}
```

### Using firstPartial()

```dart
final partial = await context.query<User>()
  .where('id', 1)
  .select(['id', 'email'])
  .firstPartial(UserPartial.fromRow);

if (partial != null) {
  print('Found user: ${partial.email}');
}
```

### Converting Partial to Full Entity

```dart
final partial = await context.query<User>()
  .where('id', 1)
  .firstPartial(UserPartial.fromRow);

if (partial != null) {
  try {
    // Convert to full entity (validates required fields)
    final user = partial.toEntity();
    print('User ID: ${user.id}');
  } on StateError catch (e) {
    // Thrown if required fields are missing
    print('Missing required fields: ${e.message}');
  }
}
```

### Benefits of Partial Projections

- **Type safety**: Partial classes have all fields nullable, making it clear which data may be missing
- **Memory efficiency**: Only selected columns are fetched
- **Explicit validation**: `toEntity()` validates required fields before conversion
- **IDE support**: Full autocomplete and type checking

## Summary

| Feature | Legacy | New (DTO) |
|---------|--------|-----------|
| Insert new record | `$User(id: 0, ...)` | `UserInsertDto(...)` |
| Update existing | `$User` or map | `UserUpdateDto(...)` or map |
| Upsert | `$User` with sentinel | `UserInsertDto(...)` with `uniqueBy` |
| Partial select | N/A | `getPartial(UserPartial.fromRow)` |
| Type safety | Weak (sentinels) | Strong (dedicated types) |

We recommend migrating to DTOs for new code while the legacy approach remains available for backward compatibility.

