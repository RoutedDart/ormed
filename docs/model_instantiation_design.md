# Model Instantiation and Attribute System Design

## Overview

This document explains the design decision for model instantiation and how the attribute tracking system works.

## The Problem

We need to balance two competing requirements:
1. **Immutability**: Users want simple, immutable value objects for testing and type safety
2. **Change Tracking**: The ORM needs mutable objects with attribute tracking for features like dirty checking, soft deletes, and relation management

## Design Decision: Hybrid Approach

### User-Defined Classes: Immutable (Optional)

Users can define their model classes with `final` fields:

```dart
@OrmModel(tableName: 'users')
class User extends Model {
  final int id;
  final String email;
  final bool active;
  final String? name;
  
  User({
    required this.id,
    required this.email,
    this.active = true,
    this.name,
  });
}
```

**Advantages:**
- Clean, simple code
- Type-safe and immutable
- Easy to test
- Works well for value objects

### Generated Classes: Mutable with Attribute Tracking

The code generator creates a `_$UserModel` class that extends `User`:

```dart
class _$UserModel extends User {
  _$UserModel({
    required int id,
    required String email,
    required bool active,
    String? name,
  }) : super(
         id: id,
         email: email,
         active: active,
         name: name,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'active': active,
      'name': name,
    });
  }

  // Mutable getters/setters that use attribute system
  @override
  int get id => getAttribute<int>('id') ?? super.id;
  set id(int value) => setAttribute('id', value);
  
  // ... other fields
}
```

**Advantages:**
- Full change tracking
- Dirty checking works
- Soft deletes work
- Relation management works
- Casts and mutators work

## When You Get Which Type

### Database Operations → Generated Class (`_$UserModel`)

```dart
// ✅ Returns _$UserModel with attribute tracking
final user = await Users.find(1);
print(user.hasAttribute('email')); // true

// ✅ Query returns _$UserModel instances
final users = await Users.query().where('active', true).get();
users.first.isDirty(); // works

// ✅ Relations return _$UserModel instances
final post = await Posts.find(1);
final author = await post.author; // _$UserModel with tracking
```

### Direct Instantiation → Base Class (`User`)

```dart
// ❌ Returns plain User without attribute tracking
final user = User(
  id: 1,
  email: 'test@example.com',
  active: true,
);
print(user.hasAttribute('email')); // false
user.isDirty(); // always false (no tracking)
```

## Best Practices

### For Testing

**Option 1: Use factories (recommended)**
```dart
test('user creation', () async {
  final user = await UserModelFactory.factory().create();
  expect(user.hasAttribute('email'), true); // ✅ Works
});
```

**Option 2: Load from database**
```dart
test('user creation', () async {
  await dataSource.repo<User>().insert(User(
    id: 1,
    email: 'test@example.com',
    active: true,
  ));
  
  final user = await Users.find(1);
  expect(user.hasAttribute('email'), true); // ✅ Works
});
```

**Option 3: Direct instantiation (limited features)**
```dart
test('user validation', () {
  // For simple value object testing
  final user = User(
    id: 1,
    email: 'test@example.com',
    active: true,
  );
  expect(user.email, 'test@example.com'); // ✅ Works
  expect(user.hasAttribute('email'), false); // ❌ Doesn't work (expected)
});
```

### For Application Code

Always use query methods to get tracked instances:

```dart
// ✅ Good
final user = await Users.find(1);
user.name = 'New Name';
await user.save(); // Tracks changes

// ❌ Bad for ORM features (but ok for value objects)
final user = User(id: 1, email: 'test@example.com');
user.setAttribute('name', 'New Name'); // Won't work as expected
```

## Methods That Require Generated Classes

These methods **only work** on instances returned from database operations:

### Attribute System
- `hasAttribute()`
- `getAttribute()`
- `setAttribute()`
- `getAttributes()`
- `setAttributes()`
- `replaceAttributes()`
- `fill()`
- `forceFill()`

### Change Tracking
- `isDirty()`
- `isClean()`
- `getDirty()`
- `wasChanged()`
- `getChanges()`
- `syncOriginal()`
- `getOriginal()`

### ORM Features
- `save()` (with dirty checking)
- `delete()` (with soft deletes)
- `refresh()`
- `fresh()`
- Relation lazy loading
- Relation caching
- Mutators and casts

## Type Signatures

All ORM methods use the base class in their type signatures:

```dart
class Users {
  // Returns User, but actually _$UserModel at runtime
  static Future<User?> find(Object id) => ...;
  
  // Returns Query<User>, but instances are _$UserModel at runtime
  static Query<User> query() => ...;
}
```

This provides:
- Clean API (no implementation details leak)
- Type safety (everything is typed as `User`)
- Runtime behavior (attribute tracking works)

## Migration Guide

If you have tests that directly instantiate models and use attribute methods:

**Before:**
```dart
test('fill attributes', () {
  final user = User(id: 1, email: 'test@example.com');
  user.fill({'name': 'Test'}); // ❌ Doesn't work
  expect(user.getAttribute('name'), 'Test'); // ❌ Fails
});
```

**After (Option 1 - Use factory):**
```dart
test('fill attributes', () async {
  final user = await UserModelFactory.factory().make();
  user.fill({'name': 'Test'}); // ✅ Works
  expect(user.getAttribute('name'), 'Test'); // ✅ Works
});
```

**After (Option 2 - Load from DB):**
```dart
test('fill attributes', () async {
  final user = await Users.create({
    'email': 'test@example.com',
    'name': 'Original',
  });
  
  user.fill({'name': 'Test'}); // ✅ Works
  expect(user.getAttribute('name'), 'Test'); // ✅ Works
});
```

**After (Option 3 - Test differently):**
```dart
test('fill attributes', () {
  final user = User(id: 1, email: 'test@example.com');
  
  // Instead of testing attribute system, test the actual properties
  // (assuming you make User mutable for this use case)
  expect(user.email, 'test@example.com'); // ✅ Works
});
```

## Summary

| Aspect | User Class | Generated Class |
|--------|-----------|-----------------|
| **Instantiation** | Direct: `User(...)` | Via ORM: `Users.find()` |
| **Mutability** | Optional (can be immutable) | Always mutable |
| **Attribute Tracking** | ❌ No | ✅ Yes |
| **Change Tracking** | ❌ No | ✅ Yes |
| **ORM Features** | ❌ Limited | ✅ Full |
| **Use Case** | Value objects, simple tests | Database operations, full ORM |

**Golden Rule**: If you need ORM features (change tracking, relations, etc.), always get your instances from database query methods, not direct instantiation.

