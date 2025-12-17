// Factory examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import '../models/user.dart';
import '../models/user.orm.dart';

// #region factory-quickstart
Future<void> factoryQuickStart(QueryContext context) async {
  // Generate test data
  final userData = Model.factory<$User>().values();
  print(userData); // {'id': 42, 'email': 'User_email_1234', ...}

  // Create a model instance (not persisted)
  final user = Model.factory<$User>().make();

  // Create and persist
  final savedUser = await Model.factory<$User>().create(context: context);
}
// #endregion factory-quickstart

// #region factory-field-overrides
void fieldOverridesExample() {
  final user = Model.factory<$User>()
      .withOverrides({
        'email': 'admin@example.com',
        'role': 'admin',
      })
      .make();

  // Or override a single field
  final user2 = Model.factory<$User>()
      .withField('email', 'test@example.com')
      .make();
}
// #endregion factory-field-overrides

// #region factory-seeding
void seedingExample() {
  // Same seed = same output
  final first = Model.factory<$User>().seed(42).values();
  final second = Model.factory<$User>().seed(42).values();
  assert(first['email'] == second['email']);

  // Different seeds = different output
  final third = Model.factory<$User>().seed(99).values();
  assert(first['email'] != third['email']);
}
// #endregion factory-seeding

// #region factory-batch
Future<void> batchCreationExample(QueryContext context) async {
  // Create 3 users without persisting
  final users = Model.factory<$User>()
      .count(3)
      .makeMany();

  // Create and persist 5 users
  final savedUsers = await Model.factory<$User>()
      .count(5)
      .createMany(context: context);

  // Combine with seed for reproducibility
  final seededUsers = Model.factory<$User>()
      .seed(42)
      .count(10)
      .makeMany();
}
// #endregion factory-batch

// #region factory-states
void stateTransformationsExample() {
  // Apply attribute overrides via state
  final admin = Model.factory<$User>()
      .state({'role': 'admin', 'active': true})
      .make();

  // Chain multiple states (applied in order)
  final suspendedAdmin = Model.factory<$User>()
      .state({'role': 'admin'})
      .state({'suspended': true})
      .make();

  // Use closure for computed states
  final user = Model.factory<$User>()
      .stateUsing((attrs) => {
        'email': '${attrs['name']}@example.com'.toString().toLowerCase(),
      })
      .make();
}
// #endregion factory-states

// #region factory-sequences
void sequenceExamples() {
  // Alternate between roles
  final users = Model.factory<$User>()
      .count(4)
      .sequence([
        {'role': 'admin'},
        {'role': 'user'},
      ])
      .makeMany();
  // Results: admin, user, admin, user

  // Use generator for index-based values
  final indexedUsers = Model.factory<$User>()
      .count(3)
      .sequenceUsing((index) => {'email': 'user_$index@test.com'})
      .makeMany();
  // Results: user_0@..., user_1@..., user_2@...
}
// #endregion factory-sequences

// #region factory-callbacks
Future<void> callbackExamples(QueryContext context) async {
  // #region factory-callbacks-afterMaking
  // Run code after make()
  Model.factory<$User>()
      .afterMaking((user) {
        print('Created user: ${user.email}');
      })
      .make();
  // #endregion factory-callbacks-afterMaking

  // #region factory-callbacks-afterCreating
  // Run async code after create()
  await Model.factory<$User>()
      .afterCreating((user) async {
        // await sendWelcomeEmail(user);
        print('Persisted user: ${user.id}');
      })
      .create(context: context);
  // #endregion factory-callbacks-afterCreating

  // #region factory-callbacks-chain
  // Chain multiple callbacks
  await Model.factory<$User>()
      .afterMaking((u) => print('Made: ${u.email}'))
      .afterMaking((u) => print('Validated'))
      .afterCreating((u) => print('Saved: ${u.id}'))
      .create(context: context);
  // #endregion factory-callbacks-chain
}
// #endregion factory-callbacks

// #region factory-trashed
void trashedExamples() {
  // Create a trashed model (uses current timestamp)
  final deletedUser = Model.factory<$User>()
      .trashed()
      .make();

  // With custom deletion timestamp
  final customTrashed = Model.factory<$User>()
      .trashed(DateTime(2024, 1, 15))
      .make();
}
// #endregion factory-trashed

// #region factory-custom-generators
void customGeneratorExamples() {
  final factory = Model.factory<$User>()
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
}
// #endregion factory-custom-generators

// #region factory-custom-provider
class FakerGeneratorProvider extends GeneratorProvider {
  const FakerGeneratorProvider();

  @override
  Object? generate<TModel extends OrmEntity>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  ) {
    // Custom logic based on field name
    if (field.name == 'email') return 'faker_${context.random.nextInt(1000)}@test.com';
    if (field.name == 'name') return 'User ${context.random.nextInt(100)}';
    if (field.name == 'phone') return '+1-555-${context.random.nextInt(10000).toString().padLeft(4, '0')}';

    // Fall back to default
    return const DefaultFieldGeneratorProvider().generate(field, context);
  }
}

void customProviderExample() {
  // Use the custom provider
  final factory = Model.factory<$User>(
    generatorProvider: const FakerGeneratorProvider(),
  );
  final user = factory.make();
}
// #endregion factory-custom-provider

// #region factory-testing-patterns
void testingPatterns() {
  // Seeded test for reproducibility
  const testSeed = 12345;
  final user = Model.factory<$User>()
      .seed(testSeed)
      .withOverrides({'role': 'admin'})
      .make();
  // Can assert on deterministic values

  // Factory helpers for common scenarios
  ModelFactoryBuilder<$User> adminUser() =>
      Model.factory<$User>().withOverrides({
        'role': 'admin',
        'active': true,
      });

  ModelFactoryBuilder<$User> inactiveUser() =>
      Model.factory<$User>().withOverrides({
        'active': false,
      });

  // Use factory helpers
  final admin = adminUser().make();
  final inactive = inactiveUser().withField('email', 'test@example.com').make();
}
// #endregion factory-testing-patterns

// #region factory-carbon-fields
void carbonFieldsExample() {
  // Carbon fields are generated automatically
  // final post = Model.factory<Post>().make();
  // print(post.publishedAt); // Carbon instance within 24 hours of now

  // Override with specific Carbon value
  // final factory = Model.factory<Post>()
  //     .withGenerator('publishedAt', (field, context) {
  //       return Carbon.parse('2024-06-15 10:30:00');
  //     });

  // Or use Carbon's fluent API
  // final factory = Model.factory<Post>()
  //     .withGenerator('publishedAt', (field, context) {
  //       return Carbon.now().subDays(context.random.nextInt(30));
  //     });
}
// #endregion factory-carbon-fields

// #region factory-seeded-test
void seededTestExample() {
  const testSeed = 12345;

  final user = Model.factory<$User>()
      .seed(testSeed)
      .withOverrides({'role': 'admin'})
      .make();

  // expect(processUser(user), expectedResult);
}
// #endregion factory-seeded-test

// #region factory-helpers
ModelFactoryBuilder<$User> adminUser() =>
    Model.factory<$User>().withOverrides({
      'role': 'admin',
      'active': true,
    });

ModelFactoryBuilder<$User> inactiveUser() =>
    Model.factory<$User>().withOverrides({
      'active': false,
    });

// In tests:
void useFactoryHelpers() {
  final admin = adminUser().make();
  final inactive = inactiveUser().withField('email', 'test@example.com').make();
}
// #endregion factory-helpers

// #region factory-cross-model
void crossModelReferencesExample() {
  // Generate consistent foreign keys
  final userId = Model.factory<$User>().seed(1).value('id') as int;

  // final post = Model.factory<Post>()
  //     .withOverrides({'userId': userId, 'title': 'Test Post'})
  //     .make();
}
// #endregion factory-cross-model

// #region factory-batch-generation
Future<List<$User>> createUsers(QueryContext context, int count) async {
  final users = <$User>[];
  for (var i = 0; i < count; i++) {
    final user = await Model.factory<$User>()
        .seed(i)
        .withField('email', 'user_$i@test.com')
        .create(context: context);
    users.add(user);
  }
  return users;
}
// #endregion factory-batch-generation

// #region factory-connection-bound
void connectionBoundHelpersExample(QueryContext queryContext) {
  // final helper = UserModelFactory.withConnection(queryContext);

  // Query builder
  // final users = await helper.query()
  //     .whereEquals('active', true)
  //     .get();

  // Repository
  // final repo = helper.repository();
  // await repo.insert(user);
}
// #endregion factory-connection-bound
