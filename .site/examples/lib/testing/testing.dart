// Testing examples for documentation
// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../models/post.dart';
import '../models/post.orm.dart';
import '../models/comment.dart';
import '../models/comment.orm.dart';
import '../orm_registry.g.dart';

// #region testing-basic-setup
Future<void> basicTestSetup() async {
  late DataSource dataSource;

  // setUp
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test_db',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // test
  final user = $User(id: 0, name: 'Test', email: 'test@example.com');
  await dataSource.repo<$User>().insert(user);

  final found = await dataSource
      .query<$User>()
      .whereEquals('email', 'test@example.com')
      .first();
  print('Found: ${found?.name}');

  // tearDown
  await dataSource.dispose();
}
// #endregion testing-basic-setup

// #region testing-in-memory
Future<void> inMemoryExecutorExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // The SQLite in-memory driver automatically:
  // - Generates auto-increment IDs
  // - Enforces foreign keys (when enabled by the driver)
  // - Starts from a fresh database per DataSource instance
  // - Supports basic query operations
}
// #endregion testing-in-memory

// #region testing-seeder
class UserSeeder extends Seeder {
  @override
  Future<void> run(DataSource dataSource) async {
    final users = [
      $User(id: 0, name: 'Admin', email: 'admin@example.com'),
      $User(id: 0, name: 'User', email: 'user@example.com'),
    ];

    for (final user in users) {
      await dataSource.repo<$User>().insert(user);
    }
  }
}

Future<void> seederExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  final seeder = UserSeeder();
  await seeder.run(dataSource);
}
// #endregion testing-seeder

// #region testing-real-db
Future<void> realDatabaseExample() async {
  late DataSource dataSource;
  late String testDbPath;

  // setUp
  testDbPath = 'test_${DateTime.now().millisecondsSinceEpoch}.db';

  dataSource = DataSource(
    DataSourceOptions(
      name: 'integration_test',
      driver: SqliteDriverAdapter.file(testDbPath),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // test...

  // tearDown
  await dataSource.dispose();
  final file = File(testDbPath);
  if (await file.exists()) {
    await file.delete();
  }
}
// #endregion testing-real-db

// #region testing-migration-harness
// For migration-driven test setups with FK-safe cleanup:
// Use setUpOrmed from package:ormed/testing.dart
//
// setUpOrmed(
//   dataSource: myDataSource,
//   migrationDescriptors: [
//     MigrationDescriptor.fromMigration(
//       id: MigrationId(DateTime.utc(2024, 1, 1), 'create_users'),
//       migration: CreateUsersTable(),
//     ),
//   ],
//   seeders: [UserSeeder.new],
//   strategy: DatabaseIsolationStrategy.migrateWithTransactions,
//   parallel: true,
// );
//
// ormedTest('creates a user', () async {
//   final user = $User(id: 0, name: 'Ada', email: 'ada@test.com');
//   await dataSource.repo<$User>().insert(user);
//   expect(user.id, isNotNull);
// });
// #endregion testing-migration-harness

// #region testing-static-helpers
Future<void> staticHelpersExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // First DataSource initialized becomes default, or:
  dataSource.setAsDefault();

  // Now static helpers work
  await Users.query().get();
}
// #endregion testing-static-helpers

// #region testing-relations
Future<void> testingRelationsExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: [
        UserOrmDefinition.definition,
        PostOrmDefinition.definition,
        CommentOrmDefinition.definition,
      ],
    ),
  );
  await dataSource.init();

  final user = $User(id: 0, name: 'Author', email: 'author@example.com');
  await dataSource.repo<$User>().insert(user);

  final post = $Post(id: 0, title: 'Test Post', authorId: user.id);
  await dataSource.repo<$Post>().insert(post);

  // Test eager loading
  final users = await dataSource.query<$User>().with_(['posts']).get();
  print('Posts count: ${users.first.posts?.length}');
}
// #endregion testing-relations

// #region testing-parallel
Future<void> parallelTestingExample() async {
  // Unique name per test suite
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  // Each test gets isolated database
}
// #endregion testing-parallel

// #region testing-best-practices-in-memory
// Use SQLite in-memory for unit tests - fast and isolated
void inMemoryBestPractice() {
  // driver: SqliteDriverAdapter.inMemory()
}
// #endregion testing-best-practices-in-memory

// #region testing-best-practices-real-db
// Use Real Databases for Integration Tests - More realistic
void realDbBestPractice() {
  // driver: SqliteDriverAdapter.file('test.db')
}
// #endregion testing-best-practices-real-db

// #region testing-keep-isolated
Future<void> keepTestsIsolated() async {
  late DataSource dataSource;

  // setUp - fresh database for each test
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  // test 1 - This test's data won't affect test 2
  // ...

  // test 2 - Starts with clean database
  // ...
}
// #endregion testing-keep-isolated

// #region testing-factories
Future<void> useFactoriesForTestData(DataSource dataSource) async {
  for (var i = 0; i < 100; i++) {
    await Model.factory<User>()
        .seed(i)
        .withField('email', 'user_$i@test.com')
        .create(context: dataSource.context);
  }

  final count = await dataSource.query<$User>().count();
  // expect(count, equals(100));
}
// #endregion testing-factories

// #region testing-success-failure
Future<void> testBothSuccessAndFailure(DataSource dataSource) async {
  // test success case
  await dataSource.repo<$User>().insert(
    $User(id: 0, name: 'Test', email: 'test@example.com'),
  );

  // test failure case - throws on duplicate email
  // expect(
  //   () => dataSource.repo<$User>().insert(
  //     $User(id: 0, name: 'Test2', email: 'test@example.com'),
  //   ),
  //   throwsException,
  // );
}
// #endregion testing-success-failure

// #region testing-example-suite
Future<void> exampleTestSuite() async {
  late DataSource dataSource;

  // #region testing-example-suite-setup
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  // #endregion testing-example-suite-setup

  // #region testing-example-suite-tests

  // group('User model', () {
  //   test('can create user', () async {
  final user = $User(id: 0, name: 'Test', email: 'test@example.com');
  await dataSource.repo<$User>().insert(user);
  // expect(user.id, isNotNull);
  //   });

  //   test('can find user by id', () async {
  final found = await dataSource.query<$User>().find(user.id);
  // expect(found?.email, equals('test@example.com'));
  //   });

  //   test('can update user', () async {
  user.setAttribute('email', 'updated@example.com');
  await dataSource.repo<$User>().update(user);
  final updated = await dataSource.query<$User>().find(user.id);
  // expect(updated?.email, equals('updated@example.com'));
  //   });

  //   test('can delete user', () async {
  await dataSource.repo<$User>().delete(user);
  final deleted = await dataSource.query<$User>().find(user.id);
  // expect(deleted, isNull);
  //   });
  // });

  // #endregion testing-example-suite-tests

  // #region testing-example-suite-teardown
  await dataSource.dispose();
  // #endregion testing-example-suite-teardown
}

// #endregion testing-example-suite
