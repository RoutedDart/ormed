# Attribute Tracking in Ormed

## Overview

Ormed models support two modes of operation:

1. **Plain instances** - Created with regular constructors `User(...)`
2. **ORM-managed instances** - Created by queries, factories, or codec decoding

## The Difference

### Plain Instances

```dart
final user = User(
  id: 1,
  email: 'test@example.com',
  active: true,
);

// ❌ These will NOT work correctly:
user.hasAttribute('email');  // Returns false (no tracking)
user.getAttribute('name');    // Returns null (no tracking)
user.isDirty();              // May not work as expected
```

**Why?** Plain instances use the user-defined `User` class constructor, which creates a simple Dart object with final fields. No attribute tracking infrastructure is initialized.

### ORM-Managed Instances

```dart
// Query from database
final user = await Users.query().where('id', 1).first();

// ✅ These work correctly:
user.hasAttribute('email');   // true
user.getAttribute('name');     // Actual value
user.isDirty();               // Tracks changes correctly
user.fill({'name': 'New'});   // Works with guards
```

**Why?** The ORM's codec creates instances of `_$UserModel` (the generated subclass) which:
- Initializes attribute tracking via `_attachOrmRuntimeMetadata()`
- Overrides getters to read from the attribute map
- Overrides setters to update the attribute map
- Maintains original values for change detection

## Generated Code Structure

When you annotate a model with `@OrmModel`, the code generator creates:

```dart
// Your user-defined class - simple, no tracking
class User extends Model<User> {
  const User({required this.id, required this.email});
  final int id;
  final String email;
}

// Generated subclass - has tracking
class _$UserModel extends User {
  _$UserModel({required int id, required String email})
    : super(id: id, email: email) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email});
  }
  
  @override
  int get id => getAttribute<int>('id') ?? super.id;
  
  set id(int value) => setAttribute('id', value);
  
  // ... more overrides
}
```

## When to Use Each

### Use Plain Instances When:

- Creating DTOs for API responses
- Building test fixtures that don't need ORM features
- Constructing objects for immediate insertion
- You only need the basic data structure

```dart
// Fine for simple insertion
final user = User(id: 1, email: 'test@example.com', active: true);
await dataSource.repo<User>().insert(user);
```

### Use ORM-Managed Instances When:

- You need attribute tracking (`hasAttribute`, `getAttribute`)
- You need change detection (`isDirty`, `getOriginal`)
- You want fillable/guarded protection (`fill`, `forceFill`)
- You're working with queried models
- You want to use model events or observers

```dart
// Get ORM-managed instance
final user = await Users.query().where('id', 1).first();

// Now all features work
user.fill({'name': 'New Name'});  // Respects fillable
user.setAttribute('age', 30);      // Tracked
if (user.isDirty()) {
  await user.save();               // Persist changes
}
```

## Common Pitfalls

### ❌ Pitfall 1: Testing with Plain Instances

```dart
test('hasAttribute returns true', () {
  final user = User(id: 1, email: 'test@example.com', active: true);
  
  // This will FAIL - plain instance has no tracking
  expect(user.hasAttribute('email'), true);
});
```

**Fix:** Fetch from database or use the model factory:

```dart
test('hasAttribute returns true', () async {
  await dataSource.repo<User>().insert(
    User(id: 1, email: 'test@example.com', active: true)
  );
  
  final user = await Users.query().where('id', 1).first();
  
  // This works - ORM-managed instance
  expect(user.hasAttribute('email'), true);
});
```

### ❌ Pitfall 2: Expecting change tracking on new instances

```dart
final user = User(id: 1, email: 'test@example.com', active: true);
user.setAttribute('name', 'Test');

// ❌ May not work as expected
expect(user.isDirty(), true);
```

**Fix:** Only ORM-managed instances track changes properly.

### ❌ Pitfall 3: Using fill() on plain instances

```dart
final user = User(id: 1, email: 'original@example.com', active: true);

// This might not respect fillable rules properly
user.fill({'name': 'Test', 'email': 'new@example.com'});
```

**Fix:** Use ORM-managed instances for fill operations.

## Design Rationale

**Why not make User abstract and force factory usage?**

1. **Flexibility**: Sometimes you just need a simple DTO
2. **Testing**: Easier to create test fixtures
3. **Performance**: Plain instances are lightweight
4. **Familiarity**: Matches how other ORMs work (e.g., Laravel Eloquent)

**Why not always initialize tracking?**

1. **Const constructors**: Can't run initialization code
2. **Performance**: Tracking has overhead
3. **Simplicity**: Not all use cases need tracking

## Best Practices

### ✅ DO: Use static query methods to get ORM-managed instances

```dart
final user = await Users.find(1);
final users = await Users.where('active', '=', true).get();
```

### ✅ DO: Use plain instances for simple insertions

```dart
await dataSource.repo<User>().insert(
  User(id: 1, email: 'test@example.com', active: true)
);
```

### ✅ DO: Document when methods require ORM-managed instances

```dart
/// Sets user attributes.
/// 
/// Note: Only works correctly on ORM-managed instances (fetched from database).
void updateUser(User user, Map<String, Object?> data) {
  user.fill(data);
}
```

### ❌ DON'T: Mix plain and ORM-managed instances expecting same behavior

```dart
final plain = User(id: 1, email: 'test@example.com', active: true);
final managed = await Users.find(1);

// These behave differently!
plain.hasAttribute('email');    // false
managed.hasAttribute('email');  // true
```

## Summary

- **Plain instances** (`User(...)`) are simple, lightweight, no tracking
- **ORM-managed instances** (from queries) have full attribute tracking
- Use `hasAttribute()` to check if tracking is initialized
- Most ORM features only work on ORM-managed instances
- This design provides flexibility while avoiding hidden complexity

---

When in doubt: **If you need ORM features, fetch from the database.**

