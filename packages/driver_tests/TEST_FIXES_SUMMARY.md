# Test Fixes for hasAttribute() and getOriginal()

## Problem

The user identified that tests were incorrectly expecting `hasAttribute()` to return `true` for model attributes that were set via constructor, but were not tracked in the `ModelAttributes` system.

## Root Cause

When a Model is constructed using the constructor:
```dart
final user = User(
  id: 1,
  email: 'test@example.com',
  active: true,
);
```

The values are set on the final fields of the model, but they are NOT tracked in the `ModelAttributes` Expando-based storage system. The `ModelAttributes` system only tracks values that are:
1. Loaded from the database (via the model factory/hydration process)
2. Explicitly set via `setAttribute()`, `fill()`, `forceFill()`, etc.

Therefore, calling `hasAttribute('email')` on a constructor-created model returns `false` because the email value was never added to the attributes tracking map.

## Changes Made

### 1. `/packages/driver_tests/lib/src/tests/query_builder/convenience_methods_tests.dart`

**Changed test**: "hasAttribute() works with new models"

**Before**:
```dart
test('works with new models', () {
  final user = User(
    id: 1,
    email: 'test@example.com',
    active: true,
  );

  expect(user.hasAttribute('email'), true);  // WRONG - email not tracked!
  expect(user.hasAttribute('nonexistent'), false);
});
```

**After**:
```dart
test('works with new models after setting attributes', () {
  final user = User(
    id: 1,
    email: 'test@example.com',
    active: true,
  );

  // Set an attribute explicitly
  user.setAttribute('name', 'Test Name');

  expect(user.hasAttribute('name'), true);  // CORRECT - name is tracked
  expect(user.hasAttribute('nonexistent'), false);
});
```

**Rationale**: The test now explicitly uses `setAttribute()` to add a tracked attribute, then verifies that `hasAttribute()` correctly identifies it.

### 2. `/packages/driver_tests/lib/src/tests/query_builder/change_tracking_tests.dart`

**Changed test**: "getOriginal() returns current values when no original tracked"

**Before**:
```dart
test('returns current values when no original tracked', () async {
  final user = User(
    id: 1,
    email: 'test@example.com',
    name: 'Test',
    active: true,
  );

  // No original tracked for new model
  expect(user.getOriginal('name'), 'Test');  // WRONG - not tracked!
  expect(user.getOriginal('email'), 'test@example.com');  // WRONG - not tracked!
});
```

**After**:
```dart
test('returns null for attributes not tracked when no original', () async {
  final user = User(
    id: 1,
    email: 'test@example.com',
    name: 'Test',
    active: true,
  );

  // No original tracked for new model with constructor-set values
  // These values are not in the attributes tracking system
  expect(user.getOriginal('name'), null);
  expect(user.getOriginal('email'), null);

  // If we set an attribute, it still has no original
  user.setAttribute('age', 25);
  expect(user.getOriginal('age'), null);
});
```

**Rationale**: The test now correctly expects `null` for untracked attributes. It also demonstrates that even when setting an attribute via `setAttribute()`, there's no "original" value until the model is synced (e.g., after loading from database).

## How hasAttribute() SHOULD Be Used

### ✅ Correct Usage

```dart
// 1. After fetching from database - attributes are populated
final user = await dataSource.query<User>().where('id', 1).first();
print(user.hasAttribute('email'));  // true - loaded from DB

// 2. After explicitly setting via setAttribute
final newUser = User(id: 1, email: 'test@example.com');
newUser.setAttribute('name', 'John');
print(newUser.hasAttribute('name'));  // true - explicitly set

// 3. After using fill() or forceFill()
newUser.fill({'age': 25});
print(newUser.hasAttribute('age'));  // true - fill uses setAttribute internally
```

### ❌ Incorrect Usage

```dart
// Constructor values are NOT tracked
final user = User(id: 1, email: 'test@example.com', name: 'John');
print(user.hasAttribute('email'));  // false - constructor values not tracked!
print(user.hasAttribute('name'));   // false - constructor values not tracked!
```

## Impact

These changes make the tests realistic and correct. They now accurately test the behavior of the `ModelAttributes` tracking system rather than making incorrect assumptions about constructor-set values.

The other tests that fetch models from the database first (before checking `hasAttribute`) are already correct and don't need changes.

