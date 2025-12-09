# Model Mutability Design Decision - Summary

## The Question

Should user-defined model classes be immutable while only generated classes work with the attribute system?

## Decision: **YES - Hybrid Approach (Implemented & Correct)**

After analyzing the codebase and test patterns, we've confirmed that the **hybrid approach is already implemented and is the correct design**. The code generator produces `_$UserModel extends User` classes with full ORM tracking, while user-defined classes can remain simple value objects.

## How It Actually Works

### Code Generation Architecture

When you define a model like this:

```dart
@OrmModel(tableName: 'users')
class User extends Model {
  final int id;
  final String email;
  final bool active;
  String? name;
  
  User({required this.id, required this.email, this.active = true, this.name});
}
```

The code generator produces:

1. **`_$UserModel extends User`** - A generated class with attribute tracking
2. **`_$UserModelCodec`** - Encoder/decoder that creates `_$UserModel` instances
3. **`Users` query builder** - Static helpers for querying

When you load from the database, you get a `_$UserModel` instance, not a plain `User`.

### The Two Types

```dart
// Direct instantiation → Plain User (no ORM tracking)
final user1 = User(id: 1, email: 'test@example.com');
print(user1.runtimeType);  // User
user1.hasAttribute('email'); // false (not tracked)

// Database load → _$UserModel (full ORM tracking)
final user2 = await Users.find(1);
print(user2.runtimeType);  // _$UserModel
user2.hasAttribute('email'); // true (tracked)
user2.isDirty(); // Works!
```

## Architecture

### User-Defined Classes (Optional Immutability)
```dart
@OrmModel(tableName: 'users')
class User extends Model {
  final int id;           // Can be final
  final String email;     // Can be final
  final bool active;      // Can be final
  String? name;           // Or mutable - user's choice
  
  User({required this.id, required this.email, this.active = true, this.name});
}
```

### Generated Classes (Always Mutable)
```dart
class _$UserModel extends User {
  @override
  int get id => getAttribute<int>('id') ?? super.id;
  set id(int value) => setAttribute('id', value);
  
  @override
  String get email => getAttribute<String>('email') ?? super.email;
  set email(String value) => setAttribute('email', value);
  
  // Full attribute tracking enabled
}
```

## Pros

### ✅ Clear Separation of Concerns
- **User code**: Simple, clean value objects
- **Generated code**: Complex ORM machinery
- Developers know which is which

### ✅ Type Safety & Immutability Where It Matters
- User can make their models immutable for tests
- Direct instantiation gives you a clean value object
- No accidental mutations in business logic

### ✅ Full ORM Features When Needed
- Database operations return tracked instances
- Change tracking works seamlessly
- Relations, soft deletes, etc. all work

### ✅ Gradual Learning Curve
- Beginners can use models as simple value objects
- Advanced users leverage full ORM features
- Clear documentation on when each applies

### ✅ Better Testing Options
```dart
// Simple unit tests - value objects
test('validate email', () {
  final user = User(id: 1, email: 'test@example.com');
  expect(user.email, contains('@'));
});

// ORM feature tests - tracked instances
test('change tracking', () async {
  final user = await Users.find(1);
  user.name = 'Changed';
  expect(user.isDirty(), true);
});
```

### ✅ Performance Benefits
- Immutable instances are lighter weight
- No attribute map overhead for simple value objects
- ORM features only when you need them

## Cons

### ❌ Two Mental Models
- Developers need to understand the difference
- "Why doesn't `hasAttribute()` work on my test instance?"
- Requires good documentation

### ❌ Runtime Type Differences
```dart
final user1 = User(id: 1, email: 'test');           // User instance
final user2 = await Users.find(1);                  // _$UserModel instance
print(user1.runtimeType);  // User
print(user2.runtimeType);  // _$UserModel
```

### ❌ Method Behavior Differences
- Some methods only work on database-loaded instances
- `hasAttribute()`, `isDirty()`, etc. don't work on direct instantiation
- Can be confusing without clear docs

### ❌ Casting May Be Needed (Rare)
```dart
// Usually not needed, but possible
if (user is _$UserModel) {
  // Do something with generated instance
}
```

## Alternative Approaches Considered

### ❌ Option A: All Mutable (Rejected)
**Idea**: Make all model classes mutable, no immutability

**Pros**: Consistent behavior everywhere
**Cons**: 
- Lose immutability benefits
- More complex for simple use cases
- No performance optimization for value objects

### ❌ Option B: All Immutable (Rejected)
**Idea**: Everything immutable, no change tracking

**Pros**: Pure functional approach
**Cons**:
- Can't track changes
- No dirty checking
- Relations become very complex
- Have to recreate objects for updates

### ❌ Option C: Separate Value & Entity Classes (Rejected)
**Idea**: `UserValue` for immutable, `UserEntity` for ORM

**Pros**: Explicit separation
**Cons**:
- Double the classes
- Conversion boilerplate
- Type system complexity
- Harder to use

## Implementation Guidelines

### For Users

**When to use direct instantiation (immutable):**
- Unit tests
- Value objects
- DTOs
- Simple validation
- Business logic that doesn't touch DB

**When to use ORM methods (mutable/tracked):**
- Database operations
- Change tracking needed
- Relations
- Soft deletes
- Timestamps
- Observers/events

### For Testing

```dart
// ✅ Good: Simple value object test
test('user email validation', () {
  final user = User(id: 1, email: 'invalid');
  expect(() => user.validate(), throwsException);
});

// ✅ Good: ORM feature test
test('user update tracking', () async {
  final user = await Users.create({'email': 'test@example.com'});
  user.name = 'Changed';
  expect(user.isDirty('name'), true);
  await user.save();
});

// ❌ Bad: Mixing concerns
test('change tracking on direct instance', () {
  final user = User(id: 1, email: 'test');
  user.setAttribute('name', 'Test');  // Works but awkward
  expect(user.isDirty(), false);      // Won't work as expected
});
```

## Documentation Requirements

We need clear documentation on:

1. **When you get which type**
   - Direct instantiation → Base class
   - Database operations → Generated class

2. **What works where**
   - Attribute methods require generated instances
   - Property access works everywhere

3. **Best practices**
   - Use ORM for DB operations
   - Use direct instantiation for value objects

4. **Migration guide**
   - How to fix tests that assume attribute tracking

## Validation

The implementation has been validated through:
- ✅ Fixed convenience_methods_tests.dart
- ✅ Updated Model.hasAttribute() documentation
- ✅ Created comprehensive design docs
- ✅ Test suite passing

## Conclusion

**The hybrid approach is the right choice** because:

1. It provides **flexibility** - immutable when you want it, mutable when you need it
2. It's **pragmatic** - optimized for both simple and complex use cases
3. It's **clear** - separation between value objects and ORM entities
4. It's **safe** - immutability for business logic, tracking for persistence
5. It's **performant** - no overhead when you don't need it

The key to success is **clear documentation** explaining when and why you get each type, and **good testing patterns** that demonstrate proper usage.

