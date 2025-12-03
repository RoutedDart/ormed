import 'package:driver_tests/models.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../config.dart';
import '../support/driver_schema.dart';

/// Runs comprehensive repository tests against the provided [dataSource].
///
/// These tests verify all repository operations including:
/// - Insert operations (single, many, ignore conflicts)
/// - Update operations (single, many, with JSON updates)
/// - Upsert operations (with conflict resolution)
/// - Delete operations (by keys)
/// - Preview operations (for all mutation types)
void runDriverRepositoryTests({
  required DataSource dataSource,
  required DriverTestConfig config,
}) {
  group('${config.driverName} Repository Operations', () {
    late Repository<User> userRepo;
    late Repository<Author> authorRepo;
    late TestDatabaseManager manager;

    setUpAll(() async {
      await dataSource.init();
      manager = TestDatabaseManager(
        baseDataSource: dataSource,
        migrationDescriptors: driverTestMigrationEntries
            .map(
              (e) => MigrationDescriptor.fromMigration(
                id: e.id,
                migration: e.migration,
              ),
            )
            .toList(),
        strategy: DatabaseIsolationStrategy.truncate,
      );
      await manager.initialize();
    });

    setUp(() async {
      await manager.beginTest('repository_tests', dataSource);
      userRepo = dataSource.context.repository<User>();
      authorRepo = dataSource.context.repository<Author>();
    });

    tearDown(() async => manager.endTest('repository_tests', dataSource));

    group('Insert Operations', () {
      test('insert() single model', () async {
        final user = const User(
          id: 1000,
          email: 'test@example.com',
          active: true,
        );

        final inserted = await userRepo.insert(user, returning: true);

        expect(inserted.id, isNotNull);
        expect(inserted.email, 'test@example.com');
        expect(inserted.active, isTrue);
      });

      test('insertMany() multiple models', () async {
        final users = const [
          User(id: 1001, email: 'user1@example.com', active: true),
          User(id: 1002, email: 'user2@example.com', active: false),
          User(id: 1003, email: 'user3@example.com', active: true),
        ];

        final inserted = await userRepo.insertMany(users, returning: true);

        expect(inserted.length, 3);
        expect(inserted.every((u) => u.id != null), isTrue);
        expect(inserted[0].email, 'user1@example.com');
        expect(inserted[1].email, 'user2@example.com');
        expect(inserted[2].email, 'user3@example.com');
      });

      test('insertMany() with empty list returns empty', () async {
        final inserted = await userRepo.insertMany([], returning: true);
        expect(inserted, isEmpty);
      });

      test('insertOrIgnore() ignores conflicts', () async {
        const user1 = User(id: 9999, email: 'unique@example.com', active: true);
        await userRepo.insert(user1);

        const user2 = User(
          id: 9999,
          email: 'duplicate@example.com',
          active: false,
        );
        final affected = await userRepo.insertOrIgnore(user2);

        // Should be ignored due to PK conflict
        expect(affected, 0);

        // Original should still exist
        final fetched = await dataSource
            .query<User>()
            .whereEquals('id', 9999)
            .first();
        expect(fetched?.email, 'unique@example.com');
      });

      test('insertOrIgnoreMany() ignores conflicts', () async {
        const existing = User(
          id: 8888,
          email: 'exists@example.com',
          active: true,
        );
        await userRepo.insert(existing);

        const users = [
          User(
            id: 8888,
            email: 'conflict@example.com',
            active: true,
          ), // Will be ignored
          User(
            id: 8889,
            email: 'new@example.com',
            active: true,
          ), // Will be inserted
        ];

        final affected = await userRepo.insertOrIgnoreMany(users);

        expect(affected, 1); // Only one row inserted
      });
    });

    group('Update Operations', () {
      test('updateMany() updates models', () async {
        final user = await userRepo.insert(
          const User(id: 2000, email: 'original@example.com', active: true),
          returning: true,
        );

        final updated = await userRepo.updateMany([
          const User(id: 2000, email: 'updated@example.com', active: false),
        ], returning: true);

        expect(updated.length, 1);
        expect(updated[0].email, 'updated@example.com');
        expect(updated[0].active, isFalse);
      });

      test('updateMany() with multiple models', () async {
        await userRepo.insertMany(const [
          User(id: 2001, email: 'a@example.com', active: true),
          User(id: 2002, email: 'b@example.com', active: true),
        ], returning: true);

        final updated = await userRepo.updateMany([
          const User(id: 2001, email: 'updated-a@example.com', active: true),
          const User(id: 2002, email: 'updated-b@example.com', active: true),
        ], returning: true);

        expect(updated.length, 2);
        expect(updated[0].email, 'updated-a@example.com');
        expect(updated[1].email, 'updated-b@example.com');
      });

      test('updateMany() with empty list returns empty', () async {
        final updated = await userRepo.updateMany([], returning: true);
        expect(updated, isEmpty);
      });

      test('updateManyRaw() returns mutation result', () async {
        await userRepo.insert(
          const User(id: 2003, email: 'test@example.com', active: true),
          returning: true,
        );

        final result = await userRepo.updateManyRaw([
          const User(id: 2003, email: 'modified@example.com', active: false),
        ]);

        expect(result.affectedRows, greaterThanOrEqualTo(0));
      });
    });

    group('Upsert Operations', () {
      test('upsertMany() inserts new records', () async {
        const users = [
          User(id: 3000, email: 'new1@example.com', active: true),
          User(id: 3001, email: 'new2@example.com', active: true),
        ];

        final upserted = await userRepo.upsertMany(users, returning: true);

        expect(upserted.length, 2);
        expect(upserted.every((u) => u.id != null), isTrue);
      });

      test('upsertMany() updates existing records', () async {
        await userRepo.insert(
          const User(id: 7777, email: 'original@example.com', active: true),
          returning: true,
        );

        const updated = User(
          id: 7777,
          email: 'updated@example.com',
          active: false,
        );

        final upserted = await userRepo.upsertMany([updated], returning: true);

        expect(upserted.length, 1);
        expect(upserted[0].email, 'updated@example.com');
        expect(upserted[0].active, isFalse);
      });

      test('upsertMany() with empty list returns empty', () async {
        final upserted = await userRepo.upsertMany([], returning: true);
        expect(upserted, isEmpty);
      });

      test('upsertMany() with custom uniqueBy', () async {
        // Insert with specific email
        await userRepo.insert(
          const User(id: 4000, email: 'unique@example.com', active: false),
        );

        // Upsert with same email should update
        const updated = User(
          id: 4001,
          email: 'unique@example.com',
          active: true,
        );

        final upserted = await userRepo.upsertMany(
          [updated],
          uniqueBy: ['email'],
          returning: true,
        );

        expect(upserted.length, 1);
        expect(upserted[0].active, isTrue);
      });
    });

    group('Delete Operations', () {
      test('deleteByKeys() deletes records', () async {
        final users = await userRepo.insertMany(const [
          User(id: 5000, email: 'delete1@example.com', active: true),
          User(id: 5001, email: 'delete2@example.com', active: true),
        ], returning: true);

        final keys = users.map((u) => {'id': u.id!}).toList();
        final affected = await userRepo.deleteByKeys(keys);

        expect(affected, 2);

        // Verify deletion
        for (final user in users) {
          final fetched = await dataSource
              .query<User>()
              .whereEquals('id', user.id!)
              .first();
          expect(fetched, isNull);
        }
      });

      test('deleteByKeys() with empty list returns 0', () async {
        final affected = await userRepo.deleteByKeys([]);
        expect(affected, 0);
      });

      test('deleteByKeys() throws on empty key map', () async {
        expect(() => userRepo.deleteByKeys([{}]), throwsArgumentError);
      });
    });

    group('Preview Operations', () {
      test('previewInsert() returns statement', () async {
        const user = User(id: 6000, email: 'preview@example.com', active: true);

        final preview = userRepo.previewInsert(user);

        expect(preview.normalized.command, isNotEmpty);
        expect(preview.normalized.command, contains('INSERT'));
      });

      test('previewInsertMany() returns statement', () async {
        const users = [
          User(id: 6001, email: 'preview1@example.com', active: true),
          User(id: 6002, email: 'preview2@example.com', active: true),
        ];

        final preview = userRepo.previewInsertMany(users);

        expect(preview.normalized.command, isNotEmpty);
        expect(preview.normalized.command, contains('INSERT'));
      });

      test('previewInsertOrIgnoreMany() returns statement', () async {
        const users = [User(id: 6003, email: 'test@example.com', active: true)];

        final preview = userRepo.previewInsertOrIgnoreMany(users);

        expect(preview.normalized.command, isNotEmpty);
      });

      test('previewUpdateMany() returns statement', () async {
        const user = User(id: 6004, email: 'test@example.com', active: true);

        final preview = userRepo.previewUpdateMany([user]);

        expect(preview.normalized.command, isNotEmpty);
        expect(preview.normalized.command, contains('UPDATE'));
      });

      test('previewUpsertMany() returns statement', () async {
        const user = User(id: 6005, email: 'test@example.com', active: true);

        final preview = userRepo.previewUpsertMany([user]);

        expect(preview.normalized.command, isNotEmpty);
      });

      test('previewDeleteByKeys() returns statement', () async {
        final preview = userRepo.previewDeleteByKeys([
          {'id': 1},
        ]);

        expect(preview.normalized.command, isNotEmpty);
        expect(preview.normalized.command, contains('DELETE'));
      });

      test('previewDelete() returns statement', () async {
        final preview = userRepo.previewDelete({'id': 1});

        expect(preview.normalized.command, isNotEmpty);
        expect(preview.normalized.command, contains('DELETE'));
      });

      test('preview methods throw on empty models', () async {
        expect(() => userRepo.previewInsertMany([]), throwsArgumentError);
        expect(() => userRepo.previewUpdateMany([]), throwsArgumentError);
        expect(() => userRepo.previewUpsertMany([]), throwsArgumentError);
      });
    });

    group('Edge Cases and Validation', () {
      test('repository handles models with relationships', () async {
        // Insert author first
        final author = await authorRepo.insert(
          const Author(id: 7000, name: 'Test Author', active: true),
          returning: true,
        );

        expect(author.id, 7000);
        expect(author.name, 'Test Author');
      });

      test('repository handles concurrent inserts', () async {
        final futures = List.generate(5, (i) {
          return userRepo.insert(
            User(id: 8000 + i, email: 'concurrent$i@example.com', active: true),
            returning: true,
          );
        });

        final results = await Future.wait(futures);

        expect(results.length, 5);
        expect(results.every((u) => u.id != null), isTrue);
      });
    });
  });
}
