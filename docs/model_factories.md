# Model Factories

Model factories provide a convenient way to generate test data for your ORM models.
They support deterministic seeding, field overrides, custom generators, and
integration with the ORM's persistence layer.

## Quick Start

```dart
import 'package:ormed/ormed.dart';
import 'user.dart';
import 'user.orm.dart';

void main() {
  // Generate test data
  final userData = UserModelFactory.factory().values();
  print(userData); // {'id': 42, 'email': 'User_email_1234', ...}

  // Create a model instance (not persisted)
  final user = UserModelFactory.factory().make();
  print(user.email);

  // Create and persist a model
  final savedUser = await UserModelFactory.factory().create(context: queryContext);
}
```

## Enabling Factory Support

To use factories, your model must mix in `ModelFactoryCapable`:

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User extends Model<User> with ModelFactoryCapable {
  const User({required this.id, required this.email, this.name});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(isUnique: true)
  final String email;

  final String? name;
}
```

The generator detects `ModelFactoryCapable` anywhere in the inheritance chain,
so base classes can include it for all derived models.

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

## Generated Factory Helpers

When you add `ModelFactoryCapable`, the generator creates:

### `UserModelFactory` Class

```dart
class UserModelFactory {
  // Access the model definition
  static ModelDefinition<User> get definition => UserOrmDefinition.definition;

  // Access the codec for serialization
  static ModelCodec<User> get codec => definition.codec;

  // Convert maps to/from models
  static User fromMap(Map<String, Object?> map) => definition.fromMap(map);
  static Map<String, Object?> toMap(User model) => definition.toMap(model);

  // Register with a ModelRegistry
  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  // Get a connection-bound helper
  static ModelFactoryConnection<User> withConnection(QueryContext context) =>
      ModelFactoryConnection<User>(definition: definition, context: context);

  // Get a factory builder for test data generation
  static ModelFactoryBuilder<User> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<User>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}
```

### Extension on Model

```dart
extension UserModelFactoryExtension on User {
  static ModelFactoryBuilder<User> factory({
    GeneratorProvider? generatorProvider,
  }) => UserModelFactory.factory(generatorProvider: generatorProvider);
}
```

## Using the Factory Builder

### Basic Usage

```dart
// Get a factory builder
final factory = UserModelFactory.factory();

// Or via Model.factory<T>()
final factory = Model.factory<User>();

// Generate column values
final values = factory.values();
// {'id': 123, 'email': 'User_email_4567', 'name': 'User_name_8901', ...}

// Get a single value
final email = factory.value('email');

// Create an instance (not persisted)
final user = factory.make();

// Create and persist
final savedUser = await factory.create(context: queryContext);
```

### Field Overrides

Override specific fields while letting others be generated:

```dart
final user = UserModelFactory.factory()
    .withOverrides({
      'email': 'admin@example.com',
      'role': 'admin',
    })
    .make();

// Or override a single field
final user = UserModelFactory.factory()
    .withField('email', 'test@example.com')
    .make();
```

### Deterministic Seeding

Use seeds for reproducible test data:

```dart
// Same seed = same output
final first = UserModelFactory.factory().seed(42).values();
final second = UserModelFactory.factory().seed(42).values();
assert(first['email'] == second['email']);

// Different seeds = different output
final third = UserModelFactory.factory().seed(99).values();
assert(first['email'] != third['email']);
```

### Custom Field Generators

Replace the default generator for specific fields:

```dart
final factory = UserModelFactory.factory()
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

The generator callback receives:
- `field` — The `FieldDefinition` with column metadata
- `context` — A `ModelFactoryGenerationContext` with the definition, random instance, overrides, and seed

### Resetting State

Clear generated values to produce new ones:

```dart
final factory = UserModelFactory.factory().seed(42);
final first = factory.values();

factory.reset();
final second = factory.values(); // New random values (same seed resets too)
```

## Factory Builder API

| Method | Description |
|--------|-------------|
| `values()` | Returns the generated column map |
| `value(field)` | Returns a single generated value |
| `make({registry})` | Creates a model instance without persisting |
| `create({context, returning})` | Creates and persists the model |
| `withOverrides(map)` | Sets multiple field overrides |
| `withField(field, value)` | Sets a single field override |
| `withGenerator(field, fn)` | Replaces the generator for a field |
| `seed(int)` | Sets deterministic seed for reproducibility |
| `reset()` | Clears generated values for fresh generation |

## Default Value Generation

The `DefaultFieldGeneratorProvider` generates values based on field types:

| Type | Generated Value |
|------|-----------------|
| `int` | Random 1-1000 |
| `double`, `num` | Random 0-1000.0 |
| `bool` | Random true/false |
| `String` | `"ModelName_fieldName_XXXX"` |
| `DateTime` | Now + random seconds (0-86400) |
| `Map<K,V>` | Empty map `{}` |
| `List<T>` | Empty list `[]` |
| Nullable types | 50% chance of `null` |

Auto-increment fields and fields with `defaultValueSql` are skipped by default
unless explicitly overridden.

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

    // Fall back to default behavior
    return const DefaultFieldGeneratorProvider().generate(field, context);
  }
}

// Use the custom provider
final factory = UserModelFactory.factory(
  generatorProvider: const FakerGeneratorProvider(),
);
```

## Connection-Bound Helpers

Use `withConnection` to get query and repository access:

```dart
final helper = UserModelFactory.withConnection(queryContext);

// Query builder bound to the model
final users = await helper.query()
    .whereEquals('active', true)
    .get();

// Repository for CRUD operations
final repo = helper.repository();
await repo.insert(user);
```

This is useful when you need both factory generation and querying in tests:

```dart
void main() {
  late QueryContext context;
  late ModelFactoryConnection<User> users;

  setUp(() async {
    context = await createTestContext();
    users = UserModelFactory.withConnection(context);
  });

  test('finds active users', () async {
    // Create test data
    await UserModelFactory.factory()
        .withOverrides({'active': true, 'email': 'active@test.com'})
        .create(context: context);

    await UserModelFactory.factory()
        .withOverrides({'active': false, 'email': 'inactive@test.com'})
        .create(context: context);

    // Query using the connection helper
    final active = await users.query()
        .whereEquals('active', true)
        .get();

    expect(active, hasLength(1));
    expect(active.first.email, 'active@test.com');
  });
}
```

## Testing Patterns

### Seeded Tests for Reproducibility

```dart
test('processes user data consistently', () {
  const testSeed = 12345;

  final user = UserModelFactory.factory()
      .seed(testSeed)
      .withOverrides({'role': 'admin'})
      .make();

  // Test behavior with deterministic data
  expect(processUser(user), expectedResult);
});
```

### Factory Helpers for Common Scenarios

```dart
// test/factories/user_factory.dart
ModelFactoryBuilder<User> adminUser() =>
    UserModelFactory.factory().withOverrides({
      'role': 'admin',
      'active': true,
    });

ModelFactoryBuilder<User> inactiveUser() =>
    UserModelFactory.factory().withOverrides({
      'active': false,
    });

// In tests:
final admin = adminUser().make();
final inactive = inactiveUser().withField('email', 'test@example.com').make();
```

### Cross-Model References

```dart
// Generate consistent foreign keys
final userId = UserModelFactory.factory().seed(1).value('id') as int;

final post = PostModelFactory.factory()
    .withOverrides({'userId': userId, 'title': 'Test Post'})
    .make();

final comment = CommentModelFactory.factory()
    .withOverrides({'postId': post.id, 'authorId': userId})
    .make();
```

### Batch Generation

```dart
Future<List<User>> createUsers(QueryContext context, int count) async {
  final users = <User>[];
  for (var i = 0; i < count; i++) {
    final user = await UserModelFactory.factory()
        .seed(i) // Different seed per user
        .withField('email', 'user_$i@test.com')
        .create(context: context);
    users.add(user);
  }
  return users;
}
```

## Error Handling

### Model Not Registered

If you see:
```
StateError: No definition registered for User. Ensure the generated
ORM helper is imported so it can register itself.
```

Make sure you:
1. Import the generated `.orm.dart` file
2. The model mixes in `ModelFactoryCapable`

### Model Doesn't Extend Model

If you call `create()` on a factory for a class that doesn't extend `Model`:
```
StateError: Cannot persist User because it does not extend Model.
```

Use `make()` instead for non-Model classes, or ensure your class extends `Model<T>`.

## See Also

- [Code Generation](code_generation.md) — Model annotations and generated code
- [Query Builder](query_builder.md) — Querying generated models
- [Data Source](data_source.md) — Runtime database access patterns