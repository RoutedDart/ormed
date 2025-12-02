// /// Example demonstrating how to use TestSchemaManager in driver tests
// ///
// /// This example shows:
// /// - Creating a test schema manager for driver tests
// /// - Setting up and tearing down schema
// /// - Using the new seeder classes
// /// - Different seeding strategies
// /// - Migration status inspection
//
// import 'package:ormed/ormed.dart';
// import 'package:ormed/testing.dart';
// import 'package:driver_tests/driver_tests.dart';
// import 'package:test/test.dart';
//
// /// Example 1: Basic setup and teardown with TestSchemaManager
// void exampleBasicSetup() {
//   group('Basic TestSchemaManager usage', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     setUpAll(() async {
//       // Assume you have a way to create a test connection
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//
//       // Create the manager with driver test migrations
//       manager = createDriverTestSchemaManager(driver);
//
//       // Set up the schema (run all migrations)
//       await manager.setup();
//     });
//
//     tearDownAll(() async {
//       // Tear down the schema (rollback all migrations)
//       await manager.teardown();
//       await connection.close();
//     });
//
//     test('schema is ready', () async {
//       // Your test code here
//       final users = await connection.repository<User>().findAll();
//       expect(users, isEmpty); // No data seeded yet
//     });
//   });
// }
//
// /// Example 2: Using seeders with TestSchemaManager
// void exampleWithSeeders() {
//   group('TestSchemaManager with seeders', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     setUpAll(() async {
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//
//       manager = createDriverTestSchemaManager(driver);
//       await manager.setup();
//
//       // Seed the complete test graph
//       await seedDriverTestGraph(manager, connection);
//     });
//
//     tearDownAll(() async {
//       await manager.teardown();
//       await connection.close();
//     });
//
//     test('users are seeded', () async {
//       final users = await connection.repository<User>().findAll();
//       expect(users, hasLength(3)); // buildDefaultUsers() creates 3 users
//     });
//
//     test('posts are seeded with relationships', () async {
//       final posts = await connection.repository<Post>().findAll();
//       expect(posts, hasLength(3)); // buildDefaultPosts() creates 3 posts
//     });
//   });
// }
//
// /// Example 3: Selective seeding
// void exampleSelectiveSeeding() {
//   group('Selective seeding', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     setUpAll(() async {
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//
//       manager = createDriverTestSchemaManager(driver);
//       await manager.setup();
//     });
//
//     tearDownAll(() async {
//       await manager.teardown();
//       await connection.close();
//     });
//
//     test('seed only users and posts', () async {
//       // Seed specific models
//       await manager.seed(connection, [
//         UserSeeder.new,
//         PostSeeder.new,
//       ]);
//
//       final users = await connection.repository<User>().findAll();
//       final posts = await connection.repository<Post>().findAll();
//
//       expect(users, hasLength(3));
//       expect(posts, hasLength(3));
//     });
//   });
// }
//
// /// Example 4: Using seeder registry for flexible seeding
// void exampleSeederRegistry() {
//   group('Seeder registry', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     setUpAll(() async {
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//
//       manager = createDriverTestSchemaManager(driver);
//       await manager.setup();
//     });
//
//     tearDownAll(() async {
//       await manager.teardown();
//       await connection.close();
//     });
//
//     test('run specific seeders by name', () async {
//       // Use the registry to run specific seeders
//       await runSeederRegistry(
//         connection,
//         driverTestSeederRegistry,
//         names: ['UserSeeder', 'AuthorSeeder'],
//         log: (message) => print(message),
//       );
//
//       final users = await connection.repository<User>().findAll();
//       final authors = await connection.repository<Author>().findAll();
//
//       expect(users, hasLength(3));
//       expect(authors, hasLength(2));
//     });
//   });
// }
//
// /// Example 5: Reset schema between tests
// void exampleResetBetweenTests() {
//   group('Reset schema strategy', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     setUp(() async {
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//
//       manager = createDriverTestSchemaManager(driver);
//
//       // Reset schema for each test (tear down and set up)
//       await manager.reset();
//
//       // Seed fresh data
//       await manager.seed(connection, [UserSeeder.new]);
//     });
//
//     tearDown() async {
//       // Optional: explicit teardown
//       await manager.teardown();
//     });
//
//     test('first test has fresh data', () async {
//       final users = await connection.repository<User>().findAll();
//       expect(users, hasLength(3));
//
//       // Modify data
//       await connection.repository<User>().query().delete();
//       final remainingUsers = await connection.repository<User>().findAll();
//       expect(remainingUsers, isEmpty);
//     });
//
//     test('second test also has fresh data', () async {
//       // Schema was reset in setUp
//       final users = await connection.repository<User>().findAll();
//       expect(users, hasLength(3)); // Fresh data again
//     });
//   });
// }
//
// /// Example 6: Using pretend mode to debug seeders
// void examplePretendMode() {
//   group('Pretend mode', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     setUpAll(() async {
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//
//       manager = createDriverTestSchemaManager(driver);
//       await manager.setup();
//     });
//
//     tearDownAll(() async {
//       await manager.teardown();
//       await connection.close();
//     });
//
//     test('preview seeder queries', () async {
//       // Use pretend mode to see what queries would be executed
//       final statements = await manager.seedWithPretend(
//         connection,
//         [UserSeeder.new],
//         pretend: true,
//       );
//
//       print('Queries that would be executed:');
//       for (var i = 0; i < statements.length; i++) {
//         final entry = statements[i];
//         final normalized = entry.preview.normalized;
//         print('${i + 1}. ${normalized.command}');
//         if (normalized.parameters.isNotEmpty) {
//           print('   Parameters: ${normalized.parameters}');
//         }
//       }
//
//       // Verify no actual data was inserted
//       final users = await connection.repository<User>().findAll();
//       expect(users, isEmpty);
//     });
//   });
// }
//
// /// Example 7: Checking migration status
// void exampleMigrationStatus() {
//   group('Migration status', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//
//     setUp(() async {
//       // driver = (await createYourTestConnection()).driver as SchemaDriver;
//       manager = createDriverTestSchemaManager(driver);
//     });
//
//     test('check status before and after setup', () async {
//       // Check status before setup
//       var status = await manager.status();
//       print('Before setup:');
//       for (final migration in status) {
//         print(
//           '  ${migration.descriptor.id.slug}: ${migration.applied ? "applied" : "pending"}',
//         );
//       }
//
//       // Set up schema
//       await manager.setup();
//
//       // Check status after setup
//       status = await manager.status();
//       print('\nAfter setup:');
//       for (final migration in status) {
//         final appliedText = migration.applied
//             ? 'applied at ${migration.appliedAt}'
//             : 'pending';
//         print('  ${migration.descriptor.id.slug}: $appliedText');
//       }
//
//       // All migrations should be applied
//       expect(status.every((m) => m.applied), isTrue);
//
//       // Clean up
//       await manager.teardown();
//     });
//   });
// }
//
// /// Example 8: Custom user suffix for parallel tests
// void exampleCustomUserSuffix() {
//   group('Custom user suffix', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     setUpAll(() async {
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//
//       manager = createDriverTestSchemaManager(driver);
//       await manager.setup();
//     });
//
//     tearDownAll(() async {
//       await manager.teardown();
//       await connection.close();
//     });
//
//     test('seed users with custom suffix', () async {
//       // Seed with a unique suffix to avoid conflicts in parallel tests
//       final suffix = 'test_${DateTime.now().millisecondsSinceEpoch}';
//
//       await manager.seed(connection, [
//         (_) => UserSeeder(connection, suffix: suffix),
//       ]);
//
//       final users = await connection.repository<User>().findAll();
//       expect(users, hasLength(3));
//       expect(users.first.email, contains(suffix));
//     });
//   });
// }
//
// /// Example 9: Migrating from old pattern to new pattern
// void exampleMigrationFromOldPattern() {
//   group('Old vs New pattern comparison', () {
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     setUp(() async {
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//     });
//
//     test('old pattern (before TestSchemaManager)', () async {
//       // OLD WAY:
//       // final runner = MigrationRunner(
//       //   schemaDriver: driver,
//       //   ledger: SqlMigrationLedger(driver as DriverAdapter),
//       //   migrations: driverTestMigrations,
//       // );
//       // await runner.applyAll();
//       // ... run tests ...
//       // final status = await runner.status();
//       // final appliedCount = status.where((m) => m.applied).length;
//       // if (appliedCount > 0) {
//       //   await runner.rollback(steps: appliedCount);
//       // }
//       // await _purgeDriverTestSchema(driver);
//
//       // NEW WAY:
//       final manager = createDriverTestSchemaManager(driver);
//       await manager.setup();
//       // ... run tests ...
//       await manager.teardown();
//       // Much cleaner!
//     });
//   });
// }
//
// /// Example 10: Complete test suite setup
// void exampleCompleteSetup() {
//   group('Complete driver tests with TestSchemaManager', () {
//     late TestSchemaManager manager;
//     late SchemaDriver driver;
//     late OrmConnection connection;
//
//     // One-time setup
//     setUpAll(() async {
//       registerDriverTestFactories();
//
//       // connection = await createYourTestConnection();
//       // driver = connection.driver as SchemaDriver;
//
//       manager = createDriverTestSchemaManager(driver);
//       await manager.setup();
//     });
//
//     // One-time teardown
//     tearDownAll(() async {
//       await manager.teardown();
//       await connection.close();
//     });
//
//     // Per-test setup (transaction-based isolation)
//     setUp(() async {
//       await connection.beginTransaction();
//       await manager.seed(connection, [DriverTestGraphSeeder.new]);
//     });
//
//     // Per-test teardown (rollback transaction)
//     tearDown(() async {
//       await connection.rollback();
//     });
//
//     test('query users', () async {
//       final users = await connection.repository<User>().findAll();
//       expect(users, hasLength(3));
//     });
//
//     test('query posts with authors', () async {
//       final posts = await connection
//           .repository<Post>()
//           .query()
//           .with_(['author'])
//           .findAll();
//
//       expect(posts, hasLength(3));
//       for (final post in posts) {
//         expect(post.author, isNotNull);
//       }
//     });
//
//     test('filter active users', () async {
//       final activeUsers = await connection
//           .repository<User>()
//           .query()
//           .whereEquals('active', true)
//           .findAll();
//
//       expect(activeUsers, hasLength(2)); // 2 out of 3 users are active
//     });
//   });
// }
//
// void main() {
//   // Run all examples
//   exampleBasicSetup();
//   exampleWithSeeders();
//   exampleSelectiveSeeding();
//   exampleSeederRegistry();
//   exampleResetBetweenTests();
//   examplePretendMode();
//   exampleMigrationStatus();
//   exampleCustomUserSuffix();
//   exampleMigrationFromOldPattern();
//   exampleCompleteSetup();
// }
