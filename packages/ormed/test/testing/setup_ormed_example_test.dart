import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';
import '../../../driver_tests/lib/src/models/active_user.dart';

/// Example demonstrating consolidated testing approaches with Ormed.
///
/// Ormed provides two main approaches for database testing:
/// 1. `ormedGroup()` - Simple, declarative approach (RECOMMENDED)
/// 2. `setUpOrmed()` + `ormedTest()` - For fine-grained control with custom managers
/// 3. Manual setup - For complete control
void main() {
  // APPROACH 1: ormedGroup() - Simple and declarative (RECOMMENDED)
  // This is the easiest way to set up database testing
  group('RECOMMENDED: Using ormedGroup()', () {
    // Create DataSource at initialization time (not lazy)
    final dataSource = DataSource(
      DataSourceOptions(
        name: 'test_group_1',
        driver: SqliteDriverAdapter.inMemory(),
        entities: [ActiveUserOrmDefinition.definition],
      ),
    );

    setUpAll(() async {
      await dataSource.init();
      DataSource.setDefault(dataSource);
    });

    tearDownAll(() async {
      await dataSource.dispose();
    });

    ormedGroup(
      'User CRUD operations',
      dataSource: dataSource,
      migrations: [CreateUsersTableMigration()],
      refreshStrategy:
          DatabaseRefreshStrategy.truncate, // Clean data between tests
      () {
        test('can create a user', () async {
          final user = ActiveUser(name: 'Alice', email: 'alice@example.com');
          await dataSource.repo<ActiveUser>().insert(user);

          final count = await dataSource.query<ActiveUser>().count();
          expect(count, 1);
        });

        test('database is clean between tests', () async {
          // With truncate strategy, previous test's data is cleared
          final count = await dataSource.query<ActiveUser>().count();
          expect(count, 0);
        });

        test('can create multiple users', () async {
          // Create some test data
          final user1 = ActiveUser(name: 'Bob', email: 'bob@example.com');
          final user2 = ActiveUser(
            name: 'Charlie',
            email: 'charlie@example.com',
          );

          await dataSource.repo<ActiveUser>().insertMany([user1, user2]);

          final count = await dataSource.query<ActiveUser>().count();
          expect(count, 2);
        });
      },
    );
  });

  // APPROACH 2: setUpOrmed() + ormedTest() - For advanced scenarios
  // Note: This approach requires some additional infrastructure that's not fully implemented yet
  // For now, use ormedGroup() which provides similar functionality
  //
  // group('ADVANCED: Using setUpOrmed()', () {
  //   final dataSource = DataSource(
  //     DataSourceOptions(
  //       name: 'test_group_2',
  //       driver: SqliteDriverAdapter.inMemory(),
  //       entities: [ActiveUserOrmDefinition.definition],
  //     ),
  //   );
  //
  //   setUpAll(() async {
  //     await dataSource.init();
  //   });
  //
  //   tearDownAll(() async {
  //     await dataSource.dispose();
  //   });
  //
  //   setUpOrmed(
  //     dataSource: dataSource,
  //     runMigrations: (ds) async {
  //       final migration = CreateUsersTableMigration();
  //       final plan = migration.plan(MigrationDirection.up);
  //       final schemaDriver = ds.connection.driver as SchemaDriver;
  //       await schemaDriver.applySchemaPlan(plan);
  //     },
  //     strategy: DatabaseIsolationStrategy.transaction,
  //     parallel: false,
  //   );
  //
  //   ormedTest('changes in one test', () async {
  //     final user = ActiveUser(name: 'Temp', email: 'temp@example.com');
  //     await user.save();
  //
  //     final count = await ActiveUserOrmDefinition.query().count();
  //     expect(count, 1);
  //   });
  //
  //   ormedTest('are isolated from other tests', () async {
  //     // Database is automatically managed based on isolation strategy
  //     final count = await ActiveUserOrmDefinition.query().count();
  //     expect(count, 0);
  //   });
  // });

  // APPROACH 3: Manual setup with standard test() - For complete control
  group('MANUAL: Traditional approach', () {
    late DataSource manualDataSource;

    setUpAll(() async {
      manualDataSource = DataSource(
        DataSourceOptions(
          name: 'manual_test',
          driver: SqliteDriverAdapter.inMemory(),
          entities: [ActiveUserOrmDefinition.definition],
        ),
      );
      await manualDataSource.init();

      // Run migrations manually
      final migration = CreateUsersTableMigration();
      final plan = migration.plan(MigrationDirection.up);
      final schemaDriver = manualDataSource.connection.driver as SchemaDriver;
      await schemaDriver.applySchemaPlan(plan);
    });

    tearDownAll(() async {
      await manualDataSource.dispose();
    });

    test('can use standard test() with manual setup', () async {
      final user = ActiveUser(name: 'Manual', email: 'manual@example.com');
      await manualDataSource.repo<ActiveUser>().insert(user);

      final count = await manualDataSource.query<ActiveUser>().count();
      expect(count, 1);
    });

    test('manual cleanup required between tests', () async {
      // Note: Without ormedGroup or setUpOrmed, data persists between tests
      final count = await manualDataSource.query<ActiveUser>().count();
      expect(count, 1); // Still has data from previous test
    });
  });
}

// Sample migration for the example
class CreateUsersTableMigration extends Migration {
  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('active_users', (table) {
      table.id();
      table.string('name').nullable();
      table.string('email');
      table.json('settings');
      table.timestamp('deleted_at').nullable();
      table.timestamps();
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('active_users');
  }
}
