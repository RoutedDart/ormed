import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';
import 'package:driver_tests/src/models/active_user.dart';

/// Test demonstrating transaction-based test isolation
void main() {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'transaction_test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: [ActiveUserOrmDefinition.definition],
    ),
  );

  setUpAll(() async {
    await dataSource.init();

    // Run migrations
    final migration = CreateUsersTable();
    final plan = migration.plan(MigrationDirection.up);
    final schemaDriver = dataSource.connection.driver as SchemaDriver;
    await schemaDriver.applySchemaPlan(plan);
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  group('Transaction rollback for test isolation', () {
    setUp(() async {
      // Begin transaction before each test
      await dataSource.beginTransaction();
    });

    tearDown(() async {
      // Rollback after each test
      await dataSource.rollback();
    });

    test('test 1: inserts data', () async {
      final user = await dataSource.repo<ActiveUser>().insert(
        ActiveUser(name: 'Test1', email: 'test1@example.com'),
        returning: true,
      );

      expect(user.id, isNotNull);

      final count = await dataSource.query<ActiveUser>().count();
      expect(count, 1);
    });

    test('test 2: database is clean (rollback worked)', () async {
      // Previous test's data should be rolled back
      final count = await dataSource.query<ActiveUser>().count();
      expect(count, 0);
    });

    test('test 3: can insert again', () async {
      final user = await dataSource.repo<ActiveUser>().insert(
        ActiveUser(name: 'Test3', email: 'test3@example.com'),
        returning: true,
      );

      expect(user.id, isNotNull);

      final count = await dataSource.query<ActiveUser>().count();
      expect(count, 1);
    });
  });

  group('Using ormedGroup with transaction strategy', () {
    ormedGroup(
      'Transaction isolation via ormedGroup',
      dataSource: dataSource,
      migrations: [], // Already migrated
      refreshStrategy: DatabaseRefreshStrategy.migrateWithTransactions,
      () {
        test('test 1: inserts data', () async {
          final user = await dataSource.repo<ActiveUser>().insert(
            ActiveUser(name: 'Group1', email: 'group1@example.com'),
            returning: true,
          );

          expect(user.id, isNotNull);

          final count = await dataSource.query<ActiveUser>().count();
          expect(count, 1);
        });

        test('test 2: database is clean (automatic rollback)', () async {
          // ormedGroup with migrateWithTransactions should rollback
          final count = await dataSource.query<ActiveUser>().count();
          expect(count, 0);
        });
      },
    );
  });

  group('Manual transaction control', () {
    test('can manually control transactions', () async {
      await dataSource.beginTransaction();

      final user = await dataSource.repo<ActiveUser>().insert(
        ActiveUser(name: 'Manual', email: 'manual@example.com'),
        returning: true,
      );

      expect(user.id, isNotNull);

      // Rollback
      await dataSource.rollback();

      // Data should not exist
      final count = await dataSource.query<ActiveUser>().count();
      expect(count, 0);
    });

    test('can commit transactions', () async {
      await dataSource.beginTransaction();

      final user = await dataSource.repo<ActiveUser>().insert(
        ActiveUser(name: 'Committed', email: 'committed@example.com'),
        returning: true,
      );

      expect(user.id, isNotNull);

      // Commit
      await dataSource.commit();

      // Data should exist
      final count = await dataSource.query<ActiveUser>().count();
      expect(count, 1);

      // Clean up
      await dataSource.repo<ActiveUser>().deleteByKeys([
        {'id': user.id},
      ]);
    });
  });
}

class CreateUsersTable extends Migration {
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
