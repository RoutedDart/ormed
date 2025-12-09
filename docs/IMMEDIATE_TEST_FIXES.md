# Immediate Test Fixes

## Problem
Several tests are failing because they expect attribute system to work, but direct instantiation doesn't provide it.

## Failing Tests

### 1. `change_tracking_tests.dart:105`
```dart
test('returns null for attributes not tracked when no original', () async {
  final user = User(
    id: 1,
    email: 'test@example.com',
    active: true,
  );
  
  user.setAttribute('name', 'Test');
  expect(user.getOriginal('name'), 'Test');  // FAILS - returns null
});
```

**Issue**: Direct instantiation `User(...)` doesn't initialize attribute tracking

**Fix Options**:
1. Change test to use database operation: `await Users.create(...)`
2. Manually call `user.attachModelDefinition(Users.definition)`
3. Document that this is expected behavior for direct instantiation

### 2. `convenience_methods_tests.dart:34` - `exists` test
```dart
test('marks as existing after save', () async {
  final user = User(id: 1, email: 'test@example.com', active: true);
  await dataSource.repo<User>().insert(user);
  
  final fetched = await dataSource.context.query<User>()
      .where('id', 1)
      .first();
      
  expect(fetched!.exists, true);  // FAILS - exists is false
});
```

**Issue**: Model loaded from DB isn't being marked as existing

**Fix**: Ensure `fromMap()` calls `markAsExisting()` after decoding

### 3. `convenience_methods_tests.dart:199` - `hasAttribute` test
```dart
test('returns true for existing attributes', () async {
  await dataSource.repo<User>().insert(User(...));
  
  final user = await dataSource.context.query<User>()
      .where('id', 1)
      .first();
      
  expect(user.hasAttribute('name'), true);  // FAILS - returns false
});
```

**Issue**: Model loaded from DB doesn't have attributes attached

**Fix**: Ensure `fromMap()` properly attaches attributes

### 4. `convenience_methods_tests.dart:271` - Another `hasAttribute` test
Same issue as #3.

## Root Cause Analysis

The current implementation has a disconnect:

1. **Mixins are on base class**: `Model` has `ModelAttributes` mixin
2. **But attributes aren't initialized**: Direct instantiation doesn't set up attribute map
3. **Database operations should initialize**: But `fromMap()` may not be properly setting up attributes

## Immediate Fixes (Without Architecture Change)

### Fix 1: Update `ModelDefinition.fromMap()` to ensure proper initialization

```dart
// In model_definition.dart
TModel fromMap(Map<String, Object?> data, {ValueCodecRegistry? registry}) {
  final model = codec.decode(data, registry ?? ValueCodecRegistry.instance);
  
  if (model is ModelAttributes) {
    model.attachModelDefinition(this);
    
    // ENSURE attributes are populated from the data map
    for (final field in fields) {
      if (data.containsKey(field.columnName)) {
        model.setAttribute(field.name, data[field.columnName]);
      }
    }
    
    if (usesSoftDeletes) {
      model.attachSoftDeleteColumn(metadata.softDeleteColumn);
    }
  }
  
  if (model is Model) {
    model.syncOriginal();
    model.markAsExisting();  // CRITICAL: Mark as existing!
  }
  
  return model;
}
```

### Fix 2: Update tests to use proper instantiation

For tests that need attribute tracking:

```dart
// ❌ Bad - Direct instantiation
final user = User(id: 1, email: 'test');
user.setAttribute('name', 'Test');
expect(user.getOriginal('name'), 'Test');  // Won't work

// ✅ Good - Use factory or DB operation
final user = await Users.create({'id': 1, 'email': 'test'});
user.setAttribute('name', 'Test');
expect(user.getOriginal('name'), 'Test');  // Works!
```

### Fix 3: Add helper method to manually initialize attributes

```dart
// In Model class
void initializeAttributes() {
  if (this is ModelAttributes) {
    final attrs = this as ModelAttributes;
    final definition = ModelRegistry.instance.getDefinition<TModel>();
    attrs.attachModelDefinition(definition);
    // Populate attributes from current property values
    // ...
  }
}
```

## Long-term Solution

See `ARCHITECTURE_DECISION_REMOVE_MIXINS_FROM_BASE_MODEL.md` for the proper fix:
- Remove mixins from base `Model` class
- Generate wrapper classes with mixins
- Clear separation between value objects and ORM entities

## Recommended Action

1. **Immediate**: Fix `fromMap()` to properly initialize and mark models
2. **Short-term**: Update failing tests to use DB operations for attribute tests
3. **Long-term**: Implement the architecture decision document

