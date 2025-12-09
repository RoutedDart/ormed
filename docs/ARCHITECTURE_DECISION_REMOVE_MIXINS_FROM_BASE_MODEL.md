# Architecture Decision: Remove Mixins from Base Model Class

## Status
**PROPOSED** - Awaiting implementation

## Context

Currently, the `Model` base class includes three mixins:
- `ModelAttributes` - Attribute storage and tracking
- `ModelConnection` - Connection awareness
- `ModelRelations` - Relation management

This creates confusion because:

1. **Same class, different behavior**:
   ```dart
   final user1 = User(id: 1, email: 'test');  // No attributes!
   final user2 = await Users.find(1);         // Has attributes!
   // Both are User instances, but behave differently
   ```

2. **Failing tests**: Methods like `hasAttribute()`, `isDirty()` don't work on directly instantiated models

3. **Unclear API**: Users don't know which methods work where

4. **Documentation burden**: Have to explain "it only works if loaded from DB"

## Decision

**Remove mixins from base `Model` class and add them only to generated classes.**

### Before (Current)
```dart
// Base class
abstract class Model<TModel extends Model<TModel>>
    with ModelAttributes, ModelConnection, ModelRelations {
  const Model();
}

// User-defined
@OrmModel(tableName: 'users')
class User extends Model<User> {
  final int id;
  final String email;
  User({required this.id, required this.email});
}

// NO generated wrapper class
// Everything happens via mixins on the base class
```

### After (Proposed)
```dart
// Base class - CLEAN, no mixins
abstract class Model<TModel extends Model<TModel>> {
  const Model();
  
  // Core static helpers remain
  static Query<TModel> query<TModel>() { ... }
  static Future<TModel> find<TModel>(id) { ... }
  // etc.
}

// User-defined - IMMUTABLE VALUE OBJECT
@OrmModel(tableName: 'users')
class User extends Model<User> {
  final int id;           // Can be final!
  final String email;     // Can be final!
  
  const User({required this.id, required this.email});
}

// GENERATED wrapper class - MUTABLE, with ORM features
class _$UserModel extends User
    with ModelAttributes, ModelConnection, ModelRelations {
  _$UserModel({required super.id, required super.email});
  
  // Override getters/setters to use attributes
  @override
  int get id => getAttribute<int>('id') ?? super.id;
  set id(int value) => setAttribute('id', value);
  
  @override
  String get email => getAttribute<String>('email') ?? super.email;
  set email(String value) => setAttribute('email', value);
}
```

## Consequences

### ✅ Benefits

1. **Crystal clear separation**:
   - `User` = immutable value object
   - `_$UserModel` = mutable ORM entity
   - No confusion

2. **Type safety**:
   ```dart
   final User user1 = User(id: 1, email: 'test');       // Clean value object
   final _$UserModel user2 = await Users.find(1);       // ORM entity
   // Different types, different behavior!
   ```

3. **Tests work as expected**:
   ```dart
   test('hasAttribute', () async {
     final user = await Users.create({'email': 'test@example.com'});
     expect(user.hasAttribute('email'), true);  // WORKS - it's _$UserModel
   });
   ```

4. **Immutability for user classes**:
   ```dart
   // Users can make their models truly immutable
   class User extends Model<User> {
     final int id;        // Final - can't change
     final String email;  // Final - can't change
   }
   ```

5. **Performance**: Direct instantiation has zero ORM overhead

6. **Explicit APIs**:
   ```dart
   // Methods that need tracking can require the generated type
   void someMethod(_$UserModel user) {
     user.isDirty();  // Guaranteed to work
   }
   ```

### ❌ Drawbacks

1. **More generated code**: Need to generate full wrapper classes

2. **Type differences visible**:
   ```dart
   print(user.runtimeType);  // Either User or _$UserModel
   ```

3. **Migration burden**: Existing code may need adjustments

4. **Generated file size**: Larger .orm.dart files

5. **Casting may be needed sometimes**:
   ```dart
   if (model is _$UserModel) {
     model.isDirty();  // Only works after cast
   }
   ```

## Implementation Plan

### Phase 1: Generate Wrapper Classes
1. Update `model_generator.dart` to generate `_$ModelName` classes
2. Add mixins to generated classes, not base class
3. Override all properties with getters/setters using attributes

### Phase 2: Update Model Base Class
1. Remove mixins from `Model` base class
2. Keep static helper methods
3. Update documentation

### Phase 3: Update ModelDefinition
1. Change `fromMap()` to return generated class instance
2. Update factory methods
3. Ensure all DB operations return tracked instances

### Phase 4: Update Tests
1. Fix tests that expect attributes on direct instances
2. Add tests for both value object and ORM behaviors
3. Update documentation and examples

### Phase 5: Migration Guide
1. Document breaking changes
2. Provide migration examples
3. Update all documentation

## Alternatives Considered

### Alternative 1: Keep Current Design
- Pro: No breaking changes
- Con: Continues confusion, unclear APIs

### Alternative 2: Two Separate Class Hierarchies
```dart
class UserValue { }           // Value object
class UserEntity extends UserValue with ORM { }  // ORM
```
- Pro: Explicit separation
- Con: Double classes, conversion boilerplate, complexity

### Alternative 3: Builder Pattern
```dart
final user = User.builder()
  .id(1)
  .email('test')
  .build();  // Returns tracked instance
```
- Pro: Explicit creation
- Con: Verbose, non-idiomatic Dart, builder fatigue

## Decision Rationale

The proposed approach (remove mixins from base, add to generated) provides:

1. **Best of both worlds**: Clean value objects + full ORM
2. **Dart-idiomatic**: Uses constructors, not builders
3. **Type safe**: Compiler helps catch errors
4. **Clear mental model**: Two types, two behaviors
5. **Incremental adoption**: Users can migrate gradually

## References

- `docs/DESIGN_DECISION_MODEL_MUTABILITY.md` - Original mutability decision
- `docs/QUICK_REFERENCE_MODEL_INSTANTIATION.md` - Usage guide
- `packages/ormed/lib/src/model.dart` - Current implementation
- `packages/ormed/lib/src/builder/model_generator.dart` - Generator code

## Notes

This is a **breaking change** but aligns with the original design intent documented in `DESIGN_DECISION_MODEL_MUTABILITY.md`. The current implementation was a temporary compromise that mixed both approaches.

## Next Steps

1. Review this decision with team
2. Get approval for breaking change
3. Implement in feature branch
4. Update all tests and documentation
5. Create migration guide
6. Release as major version bump

