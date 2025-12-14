---
sidebar_position: 6
---

# Model Factories

Model factories provide a convenient way to generate test data for your ORM models with deterministic seeding, field overrides, and persistence integration.

## Quick Start

```dart
// Generate test data
final userData = Model.factory<User>().values();
print(userData); // {'id': 42, 'email': 'User_email_1234', ...}

// Create a model instance (not persisted)
final user = Model.factory<User>().make();

// Create and persist
final savedUser = await Model.factory<User>().create(context: queryContext);
```

## Enabling Factory Support

Add `ModelFactoryCapable` mixin to your model:

```dart
@OrmModel(table: 'users')
class User extends Model<User> with ModelFactoryCapable {
  const User({required this.id, required this.email, this.name});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;
  final String? name;
}
```

The generator detects `ModelFactoryCapable` anywhere in the inheritance chain.

### Inheritance Support

```dart
// Base class with factory support
@OrmModel(table: 'base_items')
class BaseItem extends Model<BaseItem> with ModelFactoryCapable {
  const BaseItem({required this.id, this.name});

  @OrmField(isPrimaryKey: true)
  final int id;
  final String? name;
}

// Derived class automatically gets factory support
@OrmModel(table: 'special_items')
class SpecialItem extends BaseItem {
  const SpecialItem({required super.id, super.name, this.tags});
  final List<String>? tags;
}

// Both work:
final base = Model.factory<BaseItem>().make();
final special = Model.factory<SpecialItem>().make();
```

## Factory Builder API

| Method | Description |
|--------|-------------|
| `values()` | Returns the generated column map |
| `value(field)` | Returns a single generated value |
| `make({registry})` | Creates a model instance without persisting |
| `makeMany({registry})` | Creates multiple model instances without persisting |
| `create({context, returning})` | Creates and persists the model |
| `createMany({context, returning})` | Creates and persists multiple models |
| `withOverrides(map)` | Sets multiple field overrides |
| `withField(field, value)` | Sets a single field override |
| `withGenerator(field, fn)` | Replaces the generator for a field |
| `seed(int)` | Sets deterministic seed for reproducibility |
| `reset()` | Clears generated values for fresh generation |
| `count(n)` | Sets number of models to create with `makeMany`/`createMany` |
| `state(map)` | Applies a state transformation |
| `stateUsing(fn)` | Applies a closure-based state transformation |
| `sequence([...])` | Cycles attribute sets across batch creation |
| `sequenceUsing(fn)` | Generates attributes based on index |
| `afterMaking(fn)` | Registers callback after `make()` |
| `afterCreating(fn)` | Registers callback after `create()` |
| `trashed([timestamp])` | Marks model as soft-deleted |

## Field Overrides

Override specific fields while letting others be generated:

```dart
final user = Model.factory<User>()
    .withOverrides({
      'email': 'admin@example.com',
      'role': 'admin',
    })
    .make();

// Or override a single field
final user = Model.factory<User>()
    .withField('email', 'test@example.com')
    .make();
```

## Deterministic Seeding

Use seeds for reproducible test data:

```dart
// Same seed = same output
final first = Model.factory<User>().seed(42).values();
final second = Model.factory<User>().seed(42).values();
assert(first['email'] == second['email']);

// Different seeds = different output
final third = Model.factory<User>().seed(99).values();
assert(first['email'] != third['email']);
```

## Batch Creation

Create multiple models at once using `count()`:

```dart
// Create 3 users without persisting
final users = Model.factory<User>()
    .count(3)
    .makeMany();

// Create and persist 5 users
final savedUsers = await Model.factory<User>()
    .count(5)
    .createMany(context: queryContext);

// Combine with seed for reproducibility
final users = Model.factory<User>()
    .seed(42)
    .count(10)
    .makeMany();
```

## State Transformations

Apply named state modifications to models:

```dart
// Apply attribute overrides via state
final admin = Model.factory<User>()
    .state({'role': 'admin', 'active': true})
    .make();

// Chain multiple states (applied in order)
final suspendedAdmin = Model.factory<User>()
    .state({'role': 'admin'})
    .state({'suspended': true})
    .make();

// Use closure for computed states
final user = Model.factory<User>()
    .stateUsing((attrs) => {
      'email': '${attrs['name']}@example.com'.toLowerCase(),
    })
    .make();
```

## Sequences

Cycle through attribute values when creating multiple models:

```dart
// Alternate between roles
final users = Model.factory<User>()
    .count(4)
    .sequence([
      {'role': 'admin'},
      {'role': 'user'},
    ])
    .makeMany();
// Results: admin, user, admin, user

// Use generator for index-based values
final users = Model.factory<User>()
    .count(3)
    .sequenceUsing((index) => {'email': 'user_$index@test.com'})
    .makeMany();
// Results: user_0@..., user_1@..., user_2@...
```

## Callbacks

Execute code after models are made or created:

```dart
// Run code after make()
final user = Model.factory<User>()
    .afterMaking((user) {
      print('Created user: ${user.email}');
    })
    .make();

// Run async code after create()
final user = await Model.factory<User>()
    .afterCreating((user) async {
      await sendWelcomeEmail(user);
    })
    .create(context: queryContext);

// Chain multiple callbacks
Model.factory<User>()
    .afterMaking((u) => logMade(u))
    .afterMaking((u) => validateUser(u))
    .afterCreating((u) => notifyAdmins(u))
    .create(context: queryContext);
```

## Soft-Deleted Models

Create models that are already soft-deleted:

```dart
// Create a trashed model (uses current timestamp)
final deletedUser = Model.factory<User>()
    .trashed()
    .make();

// With custom deletion timestamp
final deletedUser = Model.factory<User>()
    .trashed(DateTime(2024, 1, 15))
    .make();

// Persist a soft-deleted model
final saved = await Model.factory<User>()
    .trashed()
    .create(context: queryContext);
```

## Custom Field Generators

Replace the default generator for specific fields:

```dart
final factory = Model.factory<User>()
    .withGenerator('email', (field, context) {
      final suffix = context.random.nextInt(1000);
      return 'user_$suffix@test.example.com';
    })
    .withGenerator('createdAt', (field, context) {
      return DateTime(2024, 1, 1).add(
        Duration(days: context.random.nextInt(365)),
      );
    });

final user = factory.make();
```

### Carbon/CarbonInterface Fields

For models using `Carbon` or `CarbonInterface` fields, the factory automatically generates appropriate values:

```dart
// Carbon fields are generated automatically
final post = Model.factory<Post>().make();
print(post.publishedAt); // Carbon instance within 24 hours of now

// Override with specific Carbon value
final factory = Model.factory<Post>()
    .withGenerator('publishedAt', (field, context) {
      return Carbon.parse('2024-06-15 10:30:00');
    });

// Or use Carbon's fluent API
final factory = Model.factory<Post>()
    .withGenerator('publishedAt', (field, context) {
      return Carbon.now().subDays(context.random.nextInt(30));
    });
```

## Default Value Generation

The `DefaultFieldGeneratorProvider` generates values based on field types:

| Type | Generated Value |
|------|-----------------|
| `int` | Random 1-1000 |
| `double`, `num` | Random 0-1000.0 |
| `bool` | Random true/false |
| `String` | `"ModelName_fieldName_XXXX"` |
| `DateTime` | Now + random seconds (0-86400) |
| `Carbon`, `CarbonInterface` | `Carbon.now()` + random seconds (0-86400) |
| `Map<K,V>` | Empty map `{}` |
| `List<T>` | Empty list `[]` |
| Nullable types | 50% chance of `null` |

Auto-increment fields and fields with `defaultValueSql` are skipped unless explicitly overridden.

## Custom Generator Providers

Create a custom provider for specialized data generation:

```dart
class FakerGeneratorProvider extends GeneratorProvider {
  const FakerGeneratorProvider();

  @override
  Object? generate<TModel>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  ) {
    final faker = Faker(seed: context.seed);

    if (field.name == 'email') return faker.internet.email();
    if (field.name == 'name') return faker.person.name();
    if (field.name == 'phone') return faker.phoneNumber.us();

    // Fall back to default
    return const DefaultFieldGeneratorProvider().generate(field, context);
  }
}

// Use the custom provider
final factory = Model.factory<User>(
  generatorProvider: const FakerGeneratorProvider(),
);
```

## Testing Patterns

### Seeded Tests for Reproducibility

```dart
test('processes user data consistently', () {
  const testSeed = 12345;

  final user = Model.factory<User>()
      .seed(testSeed)
      .withOverrides({'role': 'admin'})
      .make();

  expect(processUser(user), expectedResult);
});
```

### Factory Helpers for Common Scenarios

```dart
// test/factories/user_factory.dart
ModelFactoryBuilder<User> adminUser() =>
    Model.factory<User>().withOverrides({
      'role': 'admin',
      'active': true,
    });

ModelFactoryBuilder<User> inactiveUser() =>
    Model.factory<User>().withOverrides({
      'active': false,
    });

// In tests:
final admin = adminUser().make();
final inactive = inactiveUser().withField('email', 'test@example.com').make();
```

### Cross-Model References

```dart
// Generate consistent foreign keys
final userId = Model.factory<User>().seed(1).value('id') as int;

final post = Model.factory<Post>()
    .withOverrides({'userId': userId, 'title': 'Test Post'})
    .make();
```

### Batch Generation

```dart
Future<List<User>> createUsers(QueryContext context, int count) async {
  final users = <User>[];
  for (var i = 0; i < count; i++) {
    final user = await Model.factory<User>()
        .seed(i)
        .withField('email', 'user_$i@test.com')
        .create(context: context);
    users.add(user);
  }
  return users;
}
```

## Connection-Bound Helpers

Use `withConnection` to get query and repository access:

```dart
final helper = UserModelFactory.withConnection(queryContext);

// Query builder
final users = await helper.query()
    .whereEquals('active', true)
    .get();

// Repository
final repo = helper.repository();
await repo.insert(user);
```
