# Immutable Model Pattern

## Overview

Ormed uses an **immutable model pattern** where user-defined model classes are simple, immutable data classes with `final` fields and `const` constructors. The ORM generates tracked wrapper classes that add attribute tracking, change detection, and relationship management.

## User-Defined Models

Your model classes should be immutable:

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({
    required this.id,
    required this.email,
    required this.name,
  });

  @OrmField(isPrimaryKey: true)
  final int id;
  
  final String email;
  final String name;
}
```

### Best Practices

- ✅ Use `final` fields for all properties
- ✅ Use `const` constructors when possible
- ✅ Keep models free of mutable state
- ✅ Don't call `setAttribute`, `getAttribute`, etc. on manually created instances
- ❌ Avoid mutable fields
- ❌ Avoid complex logic in model classes

## Generated Tracked Models

The code generator creates a `_$UserModel` class that:

1. Extends your immutable `User` class
2. Adds attribute tracking via `ModelAttributes` mixin
3. Adds connection management via `ModelConnection` mixin
4. Adds relationship management via `ModelRelations` mixin
5. Overrides property getters to read from the attribute store
6. Provides setters that update the attribute store

```dart
// Generated code (simplified)
class _$UserModel extends User 
    with ModelAttributes, ModelConnection, ModelRelations {
  _$UserModel({
    required int id,
    required String email,
    required String name,
  }) : super(id: id, email: email, name: name) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'name': name,
    });
  }
  
  @override
  int get id => getAttribute<int>('id') ?? super.id;
  set id(int value) => setAttribute('id', value);
  
  // ... other fields
}
```

## Working with Models

### Queries Return Tracked Models

When you query the database, you get back tracked model instances:

```dart
// This returns a _$UserModel instance, typed as User
final user = await Model.query<User>().where('id', 1).first();

// The instance has attribute tracking initialized
print(user.exists); // true
print(user.isDirty()); // false

// You can modify attributes
user.setAttribute('name', 'New Name');
print(user.isDirty()); // true

// Save changes back to database
await user.save();
```

### Manual Instances Don't Have Tracking

```dart
// This creates a plain User instance
final user = User(id: 1, email: 'test@example.com', name: 'Test');

// These methods are available but won't work properly:
user.setAttribute('name', 'Changed'); // ⚠️ Works, but not tracked properly
print(user.isDirty()); // false - no tracking initialized

// Instead, use queries or repositories:
final trackedUser = await Model.create<User>({
  'id': 1,
  'email': 'test@example.com',
  'name': 'Test',
});
print(trackedUser.isDirty()); // false - tracking initialized!
```

## Attribute Tracking Features

Tracked model instances support:

### Reading and Writing Attributes

```dart
final user = await Users.query().find(1);

// Read attributes
final email = user.getAttribute<String>('email');
final allAttrs = user.getAttributes();

// Write attributes
user.setAttribute('name', 'New Name');
user.replaceAttributes({'name': 'Name', 'email': 'new@example.com'});
```

### Change Detection

```dart
final user = await Users.query().find(1);

print(user.isDirty()); // false - just loaded

user.setAttribute('name', 'Changed');
print(user.isDirty()); // true
print(user.isDirty('name')); // true
print(user.isDirty('email')); // false

print(user.getOriginal('name')); // Original value
print(user.getDirty()); // Map of changed attributes
```

### Mass Assignment

```dart
final user = await Users.query().find(1);

// Respects fillable/guarded rules
user.fill({'name': 'New Name', 'email': 'new@example.com'});

// Bypasses fillable/guarded rules
user.forceFill({'name': 'New Name', 'id': 999});
```

### Persistence

```dart
final user = await Users.query().find(1);

user.setAttribute('name', 'Changed');
await user.save(); // Persist changes

await user.delete(); // Delete record
await user.refresh(); // Reload from database
```

## Why This Pattern?

### Benefits

1. **Immutability** - User models are simple, predictable data classes
2. **Type Safety** - Dart's type system helps catch errors at compile time
3. **Separation of Concerns** - Business logic separated from ORM internals
4. **Testability** - Easy to create test instances without ORM setup
5. **Performance** - Tracking only when needed (on query results)

### Trade-offs

- Need to use queries/repositories to get tracked instances
- Can't modify attributes on manually created instances (by design)
- Generated code adds some complexity (but it's hidden from users)

## Common Patterns

### Creating New Records

```dart
// Option 1: Use Model.create (returns tracked instance)
final user = await Model.create<User>({
  'email': 'test@example.com',
  'name': 'Test User',
});

// Option 2: Use repository (preferred for bulk operations)
final users = await dataSource.repo<User>().insertMany([
  User(id: 1, email: 'test1@example.com', name: 'User 1'),
  User(id: 2, email: 'test2@example.com', name: 'User 2'),
]);
```

### Updating Records

```dart
// Option 1: Query, modify, save
final user = await Users.query().find(1);
user.setAttribute('name', 'New Name');
await user.save();

// Option 2: Direct update via query builder
await Users.query()
  .where('id', 1)
  .update({'name': 'New Name'});
```

### Working with Relations

```dart
final user = await Users.query()
  .withRelation('posts')
  .find(1);

// Check if relation is loaded
if (user.relationLoaded('posts')) {
  final posts = user.getRelation<List<Post>>('posts');
  print('User has ${posts.length} posts');
}

// Load relation lazily
final posts = await user.posts();
```

## Troubleshooting

### "Methods don't work on manually created instances"

✅ **Solution**: Use queries, repositories, or `Model.create()` to get tracked instances.

```dart
// ❌ Won't work properly
final user = User(id: 1, email: 'test@example.com', name: 'Test');
user.setAttribute('name', 'Changed'); // No tracking!

// ✅ Works correctly
final user = await Users.query().find(1);
user.setAttribute('name', 'Changed'); // Tracked!
```

### "How do I test models without database?"

✅ **Solution**: User-defined models are simple data classes - just create them directly for tests:

```dart
test('user model has email', () {
  final user = User(id: 1, email: 'test@example.com', name: 'Test');
  expect(user.email, 'test@example.com');
});
```

For testing with ORM features, use `TestDatabaseManager` (see testing.md).

### "Can I make fields mutable?"

❌ **Not recommended**. The immutable pattern ensures predictability and proper change tracking. If you need mutable state, use attributes:

```dart
// ❌ Don't do this
class User extends Model<User> {
  User({required this.id, required this.email});
  
  final int id;
  String email; // Mutable - breaks pattern!
}

// ✅ Do this instead
final user = await Users.query().find(1);
user.setAttribute('email', 'new@example.com');
await user.save();
```

## See Also

- [Models](models.md) - Complete model documentation
- [Query Builder](query_builder.md) - Querying models
- [Relations](relations.md) - Working with relationships
- [Testing](testing.md) - Testing with models

