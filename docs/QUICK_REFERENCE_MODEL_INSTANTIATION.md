# Quick Reference: Model Instantiation

> **⚠️ STATUS**: This describes the TARGET architecture after implementing the decision in `ARCHITECTURE_DECISION_REMOVE_MIXINS_FROM_BASE_MODEL.md`. Current implementation mixes both approaches.

## 🎯 Golden Rule

**Direct instantiation** = Immutable value object (limited ORM features)
**Database operations** = Mutable tracked instance (full ORM features)

## When You Get Which

| How You Create It | Type You Get | Attribute Tracking |
|------------------|--------------|-------------------|
| `User(id: 1, email: 'test')` | `User` | ❌ No |
| `await Users.find(1)` | `_$UserModel` | ✅ Yes |
| `await Users.query().get()` | `List<_$UserModel>` | ✅ Yes |
| `await user.posts` | `List<_$PostModel>` | ✅ Yes |
| `UserModelFactory.factory().make()` | `_$UserModel` | ✅ Yes |

## What Works Where

### ✅ Works on Both
```dart
user.id
user.email
user.name
```

### ⚠️ Only Works on Database-Loaded Instances
```dart
user.hasAttribute('email')    // ❌ Direct: false | ✅ DB: true
user.isDirty()                // ❌ Direct: false | ✅ DB: works
user.getOriginal()            // ❌ Direct: null  | ✅ DB: works
user.fill({...})              // ❌ Direct: nop   | ✅ DB: works
await user.save()             // ⚠️  Direct: insert | ✅ DB: update
await user.posts              // ❌ Direct: fails | ✅ DB: works
```

## Quick Examples

### For Simple Tests (Value Objects)
```dart
test('email validation', () {
  // ✅ Direct instantiation is fine
  final user = User(id: 1, email: 'test@example.com');
  expect(user.email, contains('@'));
});
```

### For ORM Feature Tests
```dart
test('change tracking', () async {
  // ✅ Load from database
  final user = await Users.find(1);
  user.name = 'Changed';
  expect(user.isDirty(), true);
});
```

### For Factories
```dart
test('factory pattern', () async {
  // ✅ Use model factory
  final user = await UserModelFactory.factory().create();
  expect(user.hasAttribute('email'), true);
});
```

## Common Mistakes

### ❌ Wrong
```dart
test('hasAttribute', () {
  final user = User(id: 1, email: 'test');
  expect(user.hasAttribute('email'), true); // FAILS - no attributes
});
```

### ✅ Right
```dart
test('hasAttribute', () async {
  final user = await Users.create({'email': 'test@example.com'});
  expect(user.hasAttribute('email'), true); // WORKS
});
```

## When to Use Which

| Use Case | Approach |
|----------|----------|
| Unit tests of business logic | Direct instantiation |
| DTOs / Value objects | Direct instantiation |
| Query database | `Users.query()` |
| Fetch by ID | `Users.find(id)` |
| Track changes | Load from DB first |
| Use relations | Load from DB first |
| Test ORM features | Load from DB or use factory |
| Create & insert | Either (but DB methods track) |

## Pro Tips

1. **Don't mix paradigms** - If you need change tracking, load from DB
2. **Use factories for tests** - Best of both worlds
3. **Check the docs** - Methods document if they need tracked instances
4. **Trust the types** - All API signatures use base class (`User`)
5. **Runtime is smart** - You get the right type automatically

## Need Help?

See full documentation:
- `docs/model_instantiation_design.md` - Complete design explanation
- `docs/DESIGN_DECISION_MODEL_MUTABILITY.md` - Decision rationale
- `packages/ormed/lib/src/model.dart` - See method documentation

