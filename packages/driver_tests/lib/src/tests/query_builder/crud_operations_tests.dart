import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void runCrudOperationsTests(  DataSource dataSource,
    DriverTestConfig config,
    )  {
  group('CRUD Operations', () {
    

    setUp(() async {
      
      // Thoroughly clean all test data before each test
      try {
        // Try using adapter's executeRaw if available
        final adapter = dataSource.connection.driver;
        if (adapter is SchemaDriver) {
          await (adapter as dynamic).executeRaw('DELETE FROM users');
        } else {
          throw UnsupportedError('Not a SchemaDriver');
        }
      } catch (e) {
        // Fallback: fetch all and delete one by one
        try {
          final allUsers = await Model.query<User>().get();
          for (final user in allUsers) {
            await Model.query<User>().destroy(user.id);
          }
        } catch (_) {
          // Last resort: use delete without WHERE
          await Model.query<User>().delete();
        }
      }
    });

    

    group('Create Operations', () {
      test('create() - creates and returns single record', () async {
        final user = await Model.query<User>()
            .create({'name': 'John Doe', 'email': 'john@example.com'});

        expect(user, isA<User>());
        expect(user.name, equals('John Doe'));
        expect(user.email, equals('john@example.com'));
        expect(user.id, isNotNull);
      });

      test('createMany() - creates multiple records', () async {
        final users = await Model.query<User>().createMany([
          {'name': 'John Doe', 'email': 'john@example.com'},
          {'name': 'Jane Smith', 'email': 'jane@example.com'},
        ]);

        expect(users, hasLength(2));
        expect(users[0].name, equals('John Doe'));
        expect(users[1].name, equals('Jane Smith'));
      });

      test('firstOrCreate() - finds existing record', () async {
        final existing = await Model.query<User>()
            .create({'name': 'John Doe', 'email': 'john@example.com'});

        final found = await Model.query<User>().firstOrCreate(
          {'email': 'john@example.com'},
          {'name': 'John Doe'},
        );

        expect(found.id, equals(existing.id));
        expect(found.name, equals('John Doe'));
      });

      test('firstOrCreate() - creates new record when not found', () async {
        final user = await Model.query<User>().firstOrCreate(
          {'email': 'new@example.com'},
          {'name': 'New User'},
        );

        expect(user.id, isNotNull);
        expect(user.email, equals('new@example.com'));
        expect(user.name, equals('New User'));
      });

      test('updateOrCreate() - updates existing record', () async {
        await Model.query<User>()
            .create({'name': 'John Doe', 'email': 'john@example.com'});

        final updated = await Model.query<User>().updateOrCreate(
          {'email': 'john@example.com'},
          {'name': 'John Updated'},
        );

        expect(updated.name, equals('John Updated'));
        expect(updated.email, equals('john@example.com'));

        final count = await Model.query<User>().count();
        expect(count, equals(1));
      });

      test('updateOrCreate() - creates record when not found', () async {
        final created = await Model.query<User>().updateOrCreate(
          {'email': 'new@example.com'},
          {'name': 'New User'},
        );

        expect(created.id, isNotNull);
        expect(created.email, equals('new@example.com'));
        expect(created.name, equals('New User'));
      });
    });

    group('Update Operations', () {
      test('update() - updates matching records', () async {
        await Model.query<User>().createMany([
          {'name': 'John Doe', 'email': 'john@example.com'},
          {'name': 'Jane Smith', 'email': 'jane@example.com'},
        ]);

        final affected = await Model.query<User>()
            .where('email',  'john@example.com')
            .update({'name': 'John Updated'});

        expect(affected, equals(1));

        final updated = await Model.query<User>()
            .where('email', 'john@example.com')
            .first();
        expect(updated?.name, equals('John Updated'));
      });

      test('increment() - increments numeric field', () async {
        final user = await Model.query<User>().create({
          'name': 'John',
          'email': 'john@example.com',
          'active': true,
          'age': 0
        });

        await Model.query<User>().where('id', user.id).increment('age');

        final updated = await Model.query<User>().find(user.id);
        expect(updated?.age, equals(1));
      });

      test('increment() - increments by custom amount', () async {
        final user = await Model.query<User>().create({
          'name': 'John',
          'email': 'john@example.com',
          'active': true,
          'age': 0
        });

        await Model.query<User>()
            .where('id', user.id)
            .increment('age', 5);

        final updated = await Model.query<User>().find(user.id);
        expect(updated?.age, equals(5));
      });

      test('decrement() - decrements numeric field', () async {
        final user = await Model.query<User>().create({
          'name': 'John',
          'email': 'john@example.com',
          'active': true,
          'age': 10
        });

        await Model.query<User>().where('id', user.id).decrement('age');

        final updated = await Model.query<User>().find(user.id);
        expect(updated?.age, equals(9));
      });

      test('decrement() - decrements by custom amount', () async {
        final user = await Model.query<User>().create({
          'name': 'John',
          'email': 'john@example.com',
          'active': true,
          'age': 10
        });

        await Model.query<User>()
            .where('id', user.id)
            .decrement('age', 3);

        final updated = await Model.query<User>().find(user.id);
        expect(updated?.age, equals(7));
      });
    });

    group('Delete Operations', () {
      test('delete() - deletes matching records', () async {
        await Model.query<User>().createMany([
          {'name': 'John Doe', 'email': 'john@example.com'},
          {'name': 'Jane Smith', 'email': 'jane@example.com'},
        ]);

        final deleted =
            await Model.query<User>().where('email', 'john@example.com').delete();

        expect(deleted, equals(1));
        expect(await Model.query<User>().count(), equals(1));
      });

      test('destroy() - deletes by ID', () async {
        final user = await Model.query<User>()
            .create({'name': 'John Doe', 'email': 'john@example.com', 'active': true});

        final deleted = await Model.query<User>().destroy(user.id);

        expect(deleted, equals(1));
        expect(await Model.query<User>().find(user.id), isNull);
      });

      test('destroy() - deletes multiple IDs', () async {
        final users = await Model.query<User>().createMany([
          {'name': 'John Doe', 'email': 'john@example.com', 'active': true},
          {'name': 'Jane Smith', 'email': 'jane@example.com', 'active': true},
        ]);

        final deleted =
            await Model.query<User>().destroy([users[0].id, users[1].id]);

        expect(deleted, equals(2));
        expect(await Model.query<User>().count(), equals(0));
      });
    });

    group('Upsert Operations', () {
      // TODO: Implement upsert() method
      test('upsert() - inserts new records', () async {
        // await Model.query<User>().upsert(
        //   [
        //     {'email': 'john@example.com', 'name': 'John Doe', 'active': true},
        //     {'email': 'jane@example.com', 'name': 'Jane Smith', 'active': true},
        //   ],
        //   ['email'],
        //   ['name'],
        // );
        //
        // expect(await Model.query<User>().count(), equals(2));
        // final john =
        //     await Model.query<User>().where('email', 'john@example.com').first();
        // expect(john?.name, equals('John Doe'));
      }, skip: 'upsert not yet implemented');

      test('upsert() - updates existing records', () async {
        // await Model.query<User>()
        //     .create({'email': 'john@example.com', 'name': 'John Original', 'active': true});
        //
        // await Model.query<User>().upsert(
        //   [
        //     {'email': 'john@example.com', 'name': 'John Updated', 'active': true},
        //   ],
        //   ['email'],
        //   ['name'],
        // );
        //
        // expect(await Model.query<User>().count(), equals(1));
        // final john =
        //     await Model.query<User>().where('email', 'john@example.com').first();
        // expect(john?.name, equals('John Updated'));
      }, skip: 'upsert not yet implemented');

      test('upsert() - mixed insert and update', () async {
        // await Model.query<User>()
        //     .create({'email': 'john@example.com', 'name': 'John Original', 'active': true});
        //
        // await Model.query<User>().upsert(
        //   [
        //     {'email': 'john@example.com', 'name': 'John Updated', 'active': true},
        //     {'email': 'jane@example.com', 'name': 'Jane New', 'active': true},
        //   ],
        //   ['email'],
        //   ['name'],
        // );
        //
        // expect(await Model.query<User>().count(), equals(2));
        // final john =
        //     await Model.query<User>().where('email', 'john@example.com').first();
        // expect(john?.name, equals('John Updated'));
        // final jane =
        //     await Model.query<User>().where('email', 'jane@example.com').first();
        // expect(jane?.name, equals('Jane New'));
      }, skip: 'upsert not yet implemented');
    });

    group('Retrieval Operations', () {
      test('sole() - returns single matching record', () async {
        await Model.query<User>()
            .create({'name': 'John Doe', 'email': 'john@example.com'});

        final user =
            await Model.query<User>().where('email', 'john@example.com').sole();

        expect(user.name, equals('John Doe'));
      });

      test('sole() - throws when multiple records match', () async {
        await Model.query<User>().createMany([
          {'name': 'John Doe', 'email': 'john@example.com'},
          {'name': 'Jane Smith', 'email': 'jane@example.com'},
        ]);

        expect(
          () => Model.query<User>().sole(),
          throwsA(isA<MultipleRecordsFoundException>()),
        );
      });

      test('sole() - throws when no records match', () async {
        expect(
          () => Model.query<User>().where('email', 'notfound@example.com').sole(),
          throwsA(isA<ModelNotFoundException>()),
        );
      });

      test('value() - returns single column value', () async {
        await Model.query<User>()
            .create({'name': 'John Doe', 'email': 'john@example.com'});

        final name =
            await Model.query<User>().where('email', 'john@example.com').value(
                  'name',
                );

        expect(name, equals('John Doe'));
      });

      test('value() - returns null when no match', () async {
        final name = await Model.query<User>()
            .where('email', 'notfound@example.com')
            .value('name');

        expect(name, isNull);
      });
    });

    group('Existence Operations', () {
      test('exists() - returns true when records exist', () async {
        await Model.query<User>()
            .create({'name': 'John Doe', 'email': 'john@example.com'});

        final exists =
            await Model.query<User>().where('email', 'john@example.com').exists();

        expect(exists, isTrue);
      });

      test('exists() - returns false when no records exist', () async {
        final exists = await Model.query<User>()
            .where('email', 'notfound@example.com')
            .exists();

        expect(exists, isFalse);
      });

      test('doesntExist() - returns false when records exist', () async {
        await Model.query<User>()
            .create({'name': 'John Doe', 'email': 'john@example.com'});

        final doesntExist = await Model.query<User>()
            .where('email', 'john@example.com')
            .doesntExist();

        expect(doesntExist, isFalse);
      });

      test('doesntExist() - returns true when no records exist', () async {
        final doesntExist = await Model.query<User>()
            .where('email', 'notfound@example.com')
            .doesntExist();

        expect(doesntExist, isTrue);
      });
    });
  });
}
