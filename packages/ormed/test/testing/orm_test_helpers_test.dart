import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

/// Test demonstrating ormedGroup usage
void main() {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'test_orm_helpers',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
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
    'User CRUD operations with migrate',
    dataSource: dataSource,
    migrations: [CreateUsersTable()],
    refreshStrategy: DatabaseRefreshStrategy.migrate,
    () {
      test('can create and retrieve users', () async {
        final user = await dataSource.repo<ActiveUser>().insert(
          ActiveUser(name: 'Alice', email: 'alice@test.com'),
          returning: true,
        );

        expect(user.id, isNotNull);
        expect(user.name, equals('Alice'));

        final count = await dataSource.query<ActiveUser>().count();
        expect(count, equals(1));
      });

      test('can update users', () async {
        final user = await dataSource.repo<ActiveUser>().insert(
          ActiveUser(name: 'Bob', email: 'bob@test.com'),
          returning: true,
        );
        final userId = user.id!;

        // Update via updateMany
        final updated = ActiveUser(
          id: userId,
          name: 'Bob Updated',
          email: user.email,
        );
        await dataSource.repo<ActiveUser>().updateMany([updated]);

        final count = await dataSource
            .query<ActiveUser>()
            .whereEquals('name', 'Bob Updated')
            .count();
        expect(count, equals(1));
      });

      test('can delete users', () async {
        final user = await dataSource.repo<ActiveUser>().insert(
          ActiveUser(name: 'Charlie', email: 'charlie@test.com'),
          returning: true,
        );
        final userId = user.id!;

        await dataSource.repo<ActiveUser>().deleteByKeys([
          {'id': userId},
        ]);

        final count = await dataSource
            .query<ActiveUser>()
            .whereEquals('id', userId)
            .count();
        expect(count, equals(0));
      });
    },
  );

  ormedGroup(
    'Database refresh strategies',
    dataSource: dataSource,
    migrations: [CreateUsersTable()],
    refreshStrategy: DatabaseRefreshStrategy.truncate,
    () {
      test('changes persist within test', () async {
        final user = await dataSource.repo<ActiveUser>().insert(
          ActiveUser(name: 'Temporary', email: 'temp@test.com'),
          returning: true,
        );

        expect(user.id, isNotNull);

        final count = await dataSource.query<ActiveUser>().count();
        expect(count, equals(1));
      });

      test('database is clean in next test', () async {
        // With truncate strategy, previous test's data is cleared
        final count = await dataSource.query<ActiveUser>().count();
        expect(count, equals(0));
      });
    },
  );
}

// Sample migration
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
