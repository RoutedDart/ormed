# Immutable Models Implementation Plan

## Goal
Make user-defined model classes immutable and ensure the attribute system only works with generated class bindings.

## Changes

### 1. Base Model Class Changes
- Remove `ModelAttributes` mixin from base `Model` class
- Remove `ModelConnection` mixin from base `Model` class  
- Remove `ModelRelations` mixin from base `Model` class
- Keep only core static methods for querying
- Base Model becomes a simple abstract class with minimal API

### 2. Generated Model Changes
- Generated classes will extend from base Model
- Generated classes will mix in `ModelAttributes`, `ModelConnection`, `ModelRelations`
- Generated classes will be the "tracked" variants that work with the ORM
- Generated classes will have proper attribute tracking initialized

### 3. User Model Class Changes
- User classes should be simple, immutable data classes
- Properties should be final
- Constructor only (no setters)
- No mixin inclusions
- Can use const constructors

### 4. Extensions for Convenience
- Use extensions on user model types to provide ORM methods
- Extensions can delegate to generated model classes
- Provides familiar API while enforcing immutability

### 5. Query Return Types
- Queries return the generated tracked model types
- These are the only types that support attribute operations
- User can still access properties normally (read-only)

## Hybrid Approach (Practical Implementation)

### Before
```dart
class User extends Model<User> {
  final int id;
  final String email;
  String? name; // mutable if not final!
  
  User({required this.id, required this.email, this.name});
}
```

### After - User models remain extending Model but with final fields
```dart
// User defined class - immutable with final fields
@OrmModel(table: 'users')
class User extends Model<User> {
  final int id;
  final String email;
  final String? name;
  
  const User({required this.id, required this.email, this.name});
}

// Generated tracked class (in user.orm.dart)
class _$UserModel extends User {
  _$UserModel({
    required int id,
    required String email,
    String? name,
  }) : super(id: id, email: email, name: name) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'name': name,
    });
  }
  
  // Override getters to use attribute tracking
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  // Provide setters that work with attribute system
  set id(int value) => setAttribute('id', value);
  
  @override
  String get email => getAttribute<String>('email') ?? super.email;
  set email(String value) => setAttribute('email', value);
  
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;
  set name(String? value) => setAttribute('name', value);
  
  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserModelDefinition);
  }
}
```

### Key Points:
1. User models still extend Model but **must use final fields** (enforced by const constructor)
2. Generated `_$ModelModel` subclass overrides getters/setters to use attribute tracking
3. Only the generated tracked model instances support `setAttribute`, `getAttribute`, etc.
4. User creates: `const User(id: 1, email: 'test@example.com')` - immutable
5. ORM returns: `_$UserModel` instances - tracked and mutable via attributes
6. Tests like `user.hasAttribute('email')` only work on `_$UserModel` instances

## Implementation Order

1. ✅ Create this plan document
2. ✅ Create new base classes/mixins for tracked models (already exist as mixins)
3. ⏳ Update Model base class to remove mixins
4. ⏳ Update code generator to create tracked model classes
5. ⏳ Regenerate all test models
6. ⏳ Update query builder to ensure it returns tracked types
7. ⏳ Fix failing tests
8. Update documentation

## Current Analysis

### What exists:
- ModelAttributes mixin (has attribute tracking)
- ModelConnection mixin (has connection methods)
- ModelRelations mixin (has relation methods)
- Model base class (currently mixes in all three)
- Generator creates `_$ModelModel` subclasses that override getters/setters

### What needs to change:
- Model base class KEEPS the mixins (for backward compatibility and functionality)
- User-defined models extend Model BUT must use **final fields only** (const constructors)
- Generated `_$ModelModel` classes extend user model and override getters/setters
- Generated classes already have all mixins (inherited from Model base)
- Only generated `_$ModelModel` instances use attribute tracking effectively
- Codec decode() ALREADY returns generated model type (_$ModelModel) ✅
- All queries ALREADY return generated model type (_$ModelModel) ✅
- **Main change needed**: Documentation and enforcement of final fields in user models

## Benefits

- ✅ Clear separation: user models are immutable data, ORM models are tracked
- ✅ No confusion about when attribute methods work
- ✅ Type safety: only tracked models have attribute operations
- ✅ Better IDE support and autocomplete
- ✅ Easier to reason about: changes only happen through ORM
- ✅ No accidental mutations on plain instances

## Migration Notes

Since we haven't released yet:
- No versioning needed
- Can make breaking changes freely
- Tests need to be updated to use tracked types
- Example code needs updating

