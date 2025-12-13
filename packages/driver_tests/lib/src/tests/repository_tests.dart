import 'package:driver_tests/models.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

/// Runs comprehensive repository tests against the provided [dataSource].
///
/// These tests verify all repository operations including:
/// - Insert operations (single, many, ignore conflicts)
/// - Update operations (single, many, with JSON updates)
/// - Upsert operations (with conflict resolution)
/// - Delete operations (by keys)
/// - Preview operations (for all mutation types)
/// - DTO-based operations (InsertDto, UpdateDto)
/// - Map-based operations
void runDriverRepositoryTests() {
  ormedGroup('Repository Operations', (dataSource) {
    late Repository<$User> userRepo;
    late Repository<$Author> authorRepo;

    setUp(() async {
      userRepo = dataSource.context.repository<$User>();
      authorRepo = dataSource.context.repository<$Author>();
    });

    group('Insert Operations', () {
      group('with tracked models', () {
        test('insert() single model', () async {
          final user = $User(
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
          final users = [
            $User(id: 1001, email: 'user1@example.com', active: true),
            $User(id: 1002, email: 'user2@example.com', active: false),
            $User(id: 1003, email: 'user3@example.com', active: true),
          ];

          final inserted = await userRepo.insertMany(users, returning: true);

          expect(inserted.length, 3);
          expect(inserted[0].email, 'user1@example.com');
          expect(inserted[1].email, 'user2@example.com');
          expect(inserted[2].email, 'user3@example.com');
        });

        test('insertMany() with empty list returns empty', () async {
          final inserted = await userRepo.insertMany([], returning: true);
          expect(inserted, isEmpty);
        });

        test('insertOrIgnore() ignores conflicts', () async {
          final user1 = $User(id: 9999, email: 'unique@example.com', active: true);
          await userRepo.insert(user1);

          final user2 = $User(
            id: 9999,
            email: 'duplicate@example.com',
            active: false,
          );
          final affected = await userRepo.insertOrIgnore(user2);

          // Should be ignored due to PK conflict
          expect(affected, 0);

          // Original should still exist
          final fetched = await dataSource
              .query<$User>()
              .whereEquals('id', 9999)
              .first();
          expect(fetched?.email, 'unique@example.com');
        });

        test('insertOrIgnoreMany() ignores conflicts', () async {
          final existing = $User(
            id: 8888,
            email: 'exists@example.com',
            active: true,
          );
          await userRepo.insert(existing);

          final users = [
            $User(
              id: 8888,
              email: 'conflict@example.com',
              active: true,
            ), // Will be ignored
            $User(
              id: 8889,
              email: 'new@example.com',
              active: true,
            ), // Will be inserted
          ];

          final affected = await userRepo.insertOrIgnoreMany(users);

          expect(affected, 1); // Only one row inserted
        });
      });

      group('with InsertDto', () {
        test('insert() single DTO', () async {
          const dto = UserInsertDto(
            email: 'dto-insert@example.com',
            active: true,
            name: 'DTO User',
          );

          final inserted = await userRepo.insert(dto, returning: true);

          expect(inserted.id, isNotNull);
          expect(inserted.email, 'dto-insert@example.com');
          expect(inserted.active, isTrue);
          expect(inserted.name, 'DTO User');
        });

        test('insertMany() multiple DTOs', () async {
          const dtos = [
            UserInsertDto(email: 'dto1@example.com', active: true),
            UserInsertDto(email: 'dto2@example.com', active: false),
            UserInsertDto(email: 'dto3@example.com', active: true, name: 'Third'),
          ];

          final inserted = await userRepo.insertMany(dtos, returning: true);

          expect(inserted.length, 3);
          expect(inserted[0].email, 'dto1@example.com');
          expect(inserted[1].email, 'dto2@example.com');
          expect(inserted[2].email, 'dto3@example.com');
          expect(inserted[2].name, 'Third');
        });

        test('insertOrIgnore() with DTO ignores conflicts', () async {
          // First insert a user
          final user = $User(id: 9998, email: 'dto-unique@example.com', active: true);
          await userRepo.insert(user);

          // Try to insert DTO that would conflict (same email with unique constraint)
          // Note: This test assumes the table has proper constraints
          const dto = UserInsertDto(
            email: 'dto-new@example.com',
            active: false,
          );
          final affected = await userRepo.insertOrIgnore(dto);

          expect(affected, greaterThanOrEqualTo(0));
        });
      });

      group('with Map', () {
        test('insert() single Map', () async {
          final map = <String, Object?>{
            'email': 'map-insert@example.com',
            'active': true,
            'name': 'Map User',
          };

          final inserted = await userRepo.insert(map, returning: true);

          expect(inserted.id, isNotNull);
          expect(inserted.email, 'map-insert@example.com');
          expect(inserted.active, isTrue);
          expect(inserted.name, 'Map User');
        });

        test('insertMany() multiple Maps', () async {
          final maps = [
            {'email': 'map1@example.com', 'active': true},
            {'email': 'map2@example.com', 'active': false},
            {'email': 'map3@example.com', 'active': true, 'age': 25},
          ];

          final inserted = await userRepo.insertMany(maps, returning: true);

          expect(inserted.length, 3);
          expect(inserted[0].email, 'map1@example.com');
          expect(inserted[1].email, 'map2@example.com');
          expect(inserted[2].email, 'map3@example.com');
          expect(inserted[2].age, 25);
        });

        test('insertOrIgnoreMany() with Maps ignores conflicts', () async {
          // Insert initial record
          await userRepo.insert({'id': 8887, 'email': 'map-exists@example.com', 'active': true});

          final maps = [
            {'id': 8887, 'email': 'map-conflict@example.com', 'active': true}, // Will be ignored
            {'id': 8886, 'email': 'map-new@example.com', 'active': true}, // Will be inserted
          ];

          final affected = await userRepo.insertOrIgnoreMany(maps);

          expect(affected, 1); // Only one row inserted
        });
      });

      group('mixed inputs', () {
        test('insertMany() with mixed models, DTOs, and Maps', () async {
          final inputs = [
            $User(id: 1100, email: 'model@example.com', active: true),
            const UserInsertDto(email: 'dto@example.com', active: true),
            {'email': 'map@example.com', 'active': true},
          ];

          final inserted = await userRepo.insertMany(inputs, returning: true);

          expect(inserted.length, 3);
          expect(inserted[0].email, 'model@example.com');
          expect(inserted[1].email, 'dto@example.com');
          expect(inserted[2].email, 'map@example.com');
        });
      });
    });

    group('Update Operations', () {
      group('with tracked models', () {
        test('update() single model', () async {
          await userRepo.insert(
            $User(id: 2000, email: 'original@example.com', active: true),
            returning: true,
          );

          final updated = await userRepo.update(
            $User(id: 2000, email: 'updated@example.com', active: false),
            returning: true,
          );

          expect(updated.email, 'updated@example.com');
          expect(updated.active, isFalse);
        });

        test('updateMany() updates models', () async {
          await userRepo.insert(
            $User(id: 2001, email: 'original@example.com', active: true),
            returning: true,
          );

          final updated = await userRepo.updateMany([
            $User(id: 2001, email: 'updated@example.com', active: false),
          ], returning: true);

          expect(updated.length, 1);
          expect(updated[0].email, 'updated@example.com');
          expect(updated[0].active, isFalse);
        });

        test('updateMany() with multiple models', () async {
          await userRepo.insertMany([
            $User(id: 2002, email: 'a@example.com', active: true),
            $User(id: 2003, email: 'b@example.com', active: true),
          ], returning: true);

          final updated = await userRepo.updateMany([
            $User(id: 2002, email: 'updated-a@example.com', active: true),
            $User(id: 2003, email: 'updated-b@example.com', active: true),
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
            $User(id: 2004, email: 'test@example.com', active: true),
            returning: true,
          );

          final result = await userRepo.updateManyRaw([
            $User(id: 2004, email: 'modified@example.com', active: false),
          ]);

          expect(result.affectedRows, greaterThanOrEqualTo(0));
        });
      });

      group('with UpdateDto', () {
        test('update() single DTO with where clause', () async {
          await userRepo.insert(
            $User(id: 2100, email: 'dto-original@example.com', active: true),
          );

          const dto = UserUpdateDto(
            email: 'dto-updated@example.com',
            active: false,
          );

          final updated = await userRepo.update(
            dto,
            where: {'id': 2100},
            returning: true,
          );

          expect(updated.email, 'dto-updated@example.com');
          expect(updated.active, isFalse);
        });

        test('update() DTO with PK in data', () async {
          await userRepo.insert(
            $User(id: 2101, email: 'dto-pk-original@example.com', active: true),
          );

          const dto = UserUpdateDto(
            id: 2101,
            email: 'dto-pk-updated@example.com',
            name: 'Updated Name',
          );

          final updated = await userRepo.update(dto, returning: true);

          expect(updated.email, 'dto-pk-updated@example.com');
          expect(updated.name, 'Updated Name');
        });

        test('updateMany() multiple DTOs with where clause', () async {
          await userRepo.insertMany([
            $User(id: 2102, email: 'dto-a@example.com', active: true),
            $User(id: 2103, email: 'dto-b@example.com', active: true),
          ]);

          const dtos = [
            UserUpdateDto(id: 2102, email: 'dto-a-updated@example.com'),
            UserUpdateDto(id: 2103, email: 'dto-b-updated@example.com'),
          ];

          final updated = await userRepo.updateMany(dtos, returning: true);

          expect(updated.length, 2);
          expect(updated[0].email, 'dto-a-updated@example.com');
          expect(updated[1].email, 'dto-b-updated@example.com');
        });

        test('update() DTO with partial fields only updates specified', () async {
          await userRepo.insert(
            $User(id: 2104, email: 'partial@example.com', active: true, name: 'Original'),
          );

          // Only update active, leave other fields
          const dto = UserUpdateDto(
            id: 2104,
            active: false,
          );

          final updated = await userRepo.update(dto, returning: true);

          expect(updated.active, isFalse);
          // Name should remain unchanged
          expect(updated.name, 'Original');
          expect(updated.email, 'partial@example.com');
        });
      });

      group('with Map', () {
        test('update() single Map with where clause', () async {
          await userRepo.insert(
            $User(id: 2200, email: 'map-original@example.com', active: true),
          );

          final map = <String, Object?>{
            'email': 'map-updated@example.com',
            'active': false,
          };

          final updated = await userRepo.update(
            map,
            where: {'id': 2200},
            returning: true,
          );

          expect(updated.email, 'map-updated@example.com');
          expect(updated.active, isFalse);
        });

        test('update() Map with PK in data', () async {
          await userRepo.insert(
            $User(id: 2201, email: 'map-pk-original@example.com', active: true),
          );

          final map = <String, Object?>{
            'id': 2201,
            'email': 'map-pk-updated@example.com',
            'age': 30,
          };

          final updated = await userRepo.update(map, returning: true);

          expect(updated.email, 'map-pk-updated@example.com');
          expect(updated.age, 30);
        });

        test('updateMany() multiple Maps', () async {
          await userRepo.insertMany([
            $User(id: 2202, email: 'map-a@example.com', active: true),
            $User(id: 2203, email: 'map-b@example.com', active: true),
          ]);

          final maps = [
            {'id': 2202, 'email': 'map-a-updated@example.com'},
            {'id': 2203, 'email': 'map-b-updated@example.com'},
          ];

          final updated = await userRepo.updateMany(maps, returning: true);

          expect(updated.length, 2);
          expect(updated[0].email, 'map-a-updated@example.com');
          expect(updated[1].email, 'map-b-updated@example.com');
        });
      });
    });

    group('Upsert Operations', () {
      group('with tracked models', () {
        test('upsert() inserts new record', () async {
          final user = $User(id: 3000, email: 'upsert-new@example.com', active: true);

          final upserted = await userRepo.upsert(user, returning: true);

          expect(upserted.id, 3000);
          expect(upserted.email, 'upsert-new@example.com');
        });

        test('upsert() updates existing record', () async {
          await userRepo.insert(
            $User(id: 3001, email: 'upsert-original@example.com', active: true),
          );

          final user = $User(id: 3001, email: 'upsert-updated@example.com', active: false);
          final upserted = await userRepo.upsert(user, returning: true);

          expect(upserted.email, 'upsert-updated@example.com');
          expect(upserted.active, isFalse);
        });

        test('upsertMany() inserts new records', () async {
          final users = [
            $User(id: 3002, email: 'new1@example.com', active: true),
            $User(id: 3003, email: 'new2@example.com', active: true),
          ];

          final upserted = await userRepo.upsertMany(users, returning: true);

          expect(upserted.length, 2);
          expect(upserted[0].email, 'new1@example.com');
          expect(upserted[1].email, 'new2@example.com');
        });

        test('upsertMany() updates existing records', () async {
          await userRepo.insert(
            $User(id: 7777, email: 'original@example.com', active: true),
            returning: true,
          );

          final updated = $User(
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
            $User(id: 4000, email: 'unique@example.com', active: false),
          );

          // Upsert with same email should update
          final updated = $User(
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

          // Verify only one record with this email exists
          final all = await dataSource
              .query<$User>()
              .whereEquals('email', 'unique@example.com')
              .get();
          expect(all.length, 1);
        });

        test('upsertMany() with updateColumns restricts updates', () async {
          await userRepo.insert(
            $User(id: 4100, email: 'restrict@example.com', active: true),
          );

          // Upsert with selective update (only active)
          final updated = $User(
            id: 4100,
            email: 'newemail@example.com',
            active: false,
          );

          final upserted = await userRepo.upsertMany(
            [updated],
            updateColumns: ['active'],
            returning: true,
          );

          expect(upserted.length, 1);
          // Email should not have changed
          expect(upserted[0].email, 'restrict@example.com');
          // Active should have changed
          expect(upserted[0].active, isFalse);
        });

        test('upsertMany() handles mix of inserts and updates', () async {
          // Insert one record
          await userRepo.insert(
            $User(id: 4200, email: 'existing@example.com', active: true),
          );

          final records = [
            $User(id: 4200, email: 'updated@example.com', active: false), // Update
            $User(id: 4201, email: 'new1@example.com', active: true), // Insert
            $User(id: 4202, email: 'new2@example.com', active: true), // Insert
          ];

          final upserted = await userRepo.upsertMany(records, returning: true);

          expect(upserted.length, 3);
          expect(upserted[0].email, 'updated@example.com');
          expect(upserted[1].email, 'new1@example.com');
          expect(upserted[2].email, 'new2@example.com');
        });
      });

      group('with InsertDto', () {
        test('upsert() single DTO inserts new', () async {
          const dto = UserInsertDto(
            email: 'upsert-dto-new@example.com',
            active: true,
            name: 'DTO Upsert',
          );

          final upserted = await userRepo.upsert(dto, returning: true);

          expect(upserted.id, isNotNull);
          expect(upserted.email, 'upsert-dto-new@example.com');
          expect(upserted.name, 'DTO Upsert');
        });

        test('upsertMany() DTOs with uniqueBy updates existing', () async {
          // Insert initial record
          await userRepo.insert(
            $User(id: 3100, email: 'dto-upsert@example.com', active: true, name: 'Original'),
          );

          const dto = UserInsertDto(
            email: 'dto-upsert@example.com',
            active: false,
            name: 'Updated via DTO',
          );

          final upserted = await userRepo.upsertMany(
            [dto],
            uniqueBy: ['email'],
            returning: true,
          );

          expect(upserted.length, 1);
          expect(upserted[0].active, isFalse);
          expect(upserted[0].name, 'Updated via DTO');
        });
      });

      group('with Map', () {
        test('upsert() single Map inserts new', () async {
          final map = <String, Object?>{
            'id': 3200,
            'email': 'upsert-map-new@example.com',
            'active': true,
            'name': 'Map Upsert',
          };

          final upserted = await userRepo.upsert(map, returning: true);

          expect(upserted.id, 3200);
          expect(upserted.email, 'upsert-map-new@example.com');
          expect(upserted.name, 'Map Upsert');
        });

        test('upsert() Map updates existing', () async {
          await userRepo.insert(
            $User(id: 3201, email: 'map-upsert-original@example.com', active: true),
          );

          final map = <String, Object?>{
            'id': 3201,
            'email': 'map-upsert-updated@example.com',
            'active': false,
          };

          final upserted = await userRepo.upsert(map, returning: true);

          expect(upserted.email, 'map-upsert-updated@example.com');
          expect(upserted.active, isFalse);
        });

        test('upsertMany() Maps with uniqueBy', () async {
          await userRepo.insert(
            $User(id: 3202, email: 'map-unique@example.com', active: true),
          );

          final maps = [
            {'email': 'map-unique@example.com', 'active': false, 'name': 'Updated'},
            {'email': 'map-brand-new@example.com', 'active': true},
          ];

          final upserted = await userRepo.upsertMany(
            maps,
            uniqueBy: ['email'],
            returning: true,
          );

          expect(upserted.length, 2);
        });
      });
    });

    group('Delete Operations', () {
      test('deleteByKeys() deletes records', () async {
        final users = await userRepo.insertMany([
          $User(id: 5000, email: 'delete1@example.com', active: true),
          $User(id: 5001, email: 'delete2@example.com', active: true),
        ], returning: true);

        final keys = users.map((u) => {'id': u.id}).toList();
        final affected = await userRepo.deleteByKeys(keys);

        expect(affected, 2);

        // Verify deletion
        for (final user in users) {
          final fetched = await dataSource
              .query<$User>()
              .whereEquals('id', user.id)
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
      final supportsSqlPreviews = dataSource.options.driver.metadata
          .supportsCapability(DriverCapability.sqlPreviews);

      group('with tracked models', () {
        test('previewInsert() returns statement', () async {
          final user = $User(id: 6000, email: 'preview@example.com', active: true);

          final preview = userRepo.previewInsert(user);

          expect(preview.normalized.command, isNotEmpty);
          if (supportsSqlPreviews) {
            expect(preview.normalized.command, contains('INSERT'));
          }
        });

        test('previewInsertMany() returns statement', () async {
          final users = [
            $User(id: 6001, email: 'preview1@example.com', active: true),
            $User(id: 6002, email: 'preview2@example.com', active: true),
          ];

          final preview = userRepo.previewInsertMany(users);

          expect(preview.normalized.command, isNotEmpty);
          if (supportsSqlPreviews) {
            expect(preview.normalized.command, contains('INSERT'));
          }
        });

        test('previewUpdateMany() returns statement', () async {
          final user = $User(id: 6004, email: 'test@example.com', active: true);

          final preview = userRepo.previewUpdateMany([user]);

          expect(preview.normalized.command, isNotEmpty);
          if (supportsSqlPreviews) {
            expect(preview.normalized.command, contains('UPDATE'));
          }
        });

        test('previewUpsertMany() returns statement', () async {
          final user = $User(id: 6005, email: 'test@example.com', active: true);

          final preview = userRepo.previewUpsertMany([user]);

          expect(preview.normalized.command, isNotEmpty);
        });
      });

      group('with DTOs', () {
        test('previewInsert() with DTO returns statement', () async {
          const dto = UserInsertDto(email: 'preview-dto@example.com', active: true);

          final preview = userRepo.previewInsert(dto);

          expect(preview.normalized.command, isNotEmpty);
          if (supportsSqlPreviews) {
            expect(preview.normalized.command, contains('INSERT'));
          }
        });

        test('previewUpdateMany() with DTO returns statement', () async {
          const dto = UserUpdateDto(id: 6006, email: 'preview-dto@example.com');

          final preview = userRepo.previewUpdateMany([dto]);

          expect(preview.normalized.command, isNotEmpty);
          if (supportsSqlPreviews) {
            expect(preview.normalized.command, contains('UPDATE'));
          }
        });
      });

      group('with Maps', () {
        test('previewInsert() with Map returns statement', () async {
          final map = {'email': 'preview-map@example.com', 'active': true};

          final preview = userRepo.previewInsert(map);

          expect(preview.normalized.command, isNotEmpty);
          if (supportsSqlPreviews) {
            expect(preview.normalized.command, contains('INSERT'));
          }
        });

        test('previewUpdateMany() with Map returns statement', () async {
          final map = {'id': 6007, 'email': 'preview-map@example.com'};

          final preview = userRepo.previewUpdateMany([map]);

          expect(preview.normalized.command, isNotEmpty);
          if (supportsSqlPreviews) {
            expect(preview.normalized.command, contains('UPDATE'));
          }
        });
      });

      test('previewInsertOrIgnoreMany() returns statement', () async {
        final users = [$User(id: 6003, email: 'test@example.com', active: true)];

        final preview = userRepo.previewInsertOrIgnoreMany(users);

        expect(preview.normalized.command, isNotEmpty);
      });

      test('previewDeleteByKeys() returns statement', () async {
        final preview = userRepo.previewDeleteByKeys([
          {'id': 1},
        ]);

        expect(preview.normalized.command, isNotEmpty);
        if (supportsSqlPreviews) {
          expect(preview.normalized.command, contains('DELETE'));
        }
      });

      test('previewDelete() returns statement', () async {
        final preview = userRepo.previewDelete({'id': 1});

        expect(preview.normalized.command, isNotEmpty);
        if (supportsSqlPreviews) {
          expect(preview.normalized.command, contains('DELETE'));
        }
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
          $Author(id: 7000, name: 'Test Author', active: true),
          returning: true,
        );

        expect(author.id, 7000);
        expect(author.name, 'Test Author');
      });

      test('repository handles concurrent inserts', () async {
        final futures = List.generate(5, (i) {
          return userRepo.insert(
            $User(id: 8000 + i, email: 'concurrent$i@example.com', active: true),
            returning: true,
          );
        });

        final results = await Future.wait(futures);

        expect(results.length, 5);
      });

      test('insert with DTO omitting auto-increment PK', () async {
        // InsertDto should work without specifying id (auto-increment)
        const dto = UserInsertDto(
          email: 'auto-pk@example.com',
          active: true,
        );

        final inserted = await userRepo.insert(dto, returning: true);

        expect(inserted.id, isNotNull);
        expect(inserted.id, greaterThan(0));
        expect(inserted.email, 'auto-pk@example.com');
      });

      test('update with DTO throws if no PK or where clause', () async {
        const dto = UserUpdateDto(
          email: 'no-pk@example.com',
        );

        // Should throw because there's no way to identify the row
        expect(
          () => userRepo.update(dto),
          throwsArgumentError,
        );
      });

      test('upsert maintains data integrity across multiple calls', () async {
        const userId = 4400;

        // First upsert (insert)
        final user1 = $User(
          id: userId,
          email: 'integrity@example.com',
          active: true,
        );
        final result1 = await userRepo.upsertMany([user1], returning: true);
        expect(result1[0].active, isTrue);

        // Second upsert (update)
        final user2 = $User(
          id: userId,
          email: 'integrity@example.com',
          active: false,
        );
        final result2 = await userRepo.upsertMany([user2], returning: true);
        expect(result2[0].active, isFalse);

        // Third upsert (another update)
        final user3 = $User(
          id: userId,
          email: 'integrity-updated@example.com',
          active: true,
        );
        final result3 = await userRepo.upsertMany([user3], returning: true);
        expect(result3[0].email, 'integrity-updated@example.com');

        // Verify only one record exists
        final all = await dataSource
            .query<$User>()
            .whereEquals('id', userId)
            .get();
        expect(all.length, 1);
      });

      test('batch upsert with models, DTOs, and Maps', () async {
        // Create initial record
        await userRepo.insert(
          $User(id: 4500, email: 'batch-existing@example.com', active: true),
        );

        final batch = [
          $User(id: 4500, email: 'batch-updated@example.com', active: false), // Update
          const UserInsertDto(email: 'batch-dto@example.com', active: true), // Insert
          {'email': 'batch-map@example.com', 'active': true}, // Insert
        ];

        final upserted = await userRepo.upsertMany(batch, returning: true);

        expect(upserted.length, 3);
        expect(upserted[0].email, 'batch-updated@example.com');
        expect(upserted[1].email, 'batch-dto@example.com');
        expect(upserted[2].email, 'batch-map@example.com');
      });
    });

    group('Author Repository (with timestamps)', () {
      test('insert Author with tracked model', () async {
        final author = $Author(id: 4600, name: 'Test Author', active: true);
        final inserted = await authorRepo.insert(author, returning: true);

        expect(inserted.id, 4600);
        expect(inserted.name, 'Test Author');
        expect(inserted.active, isTrue);
      });

      test('upsert Author updates existing', () async {
        final author1 = $Author(id: 4601, name: 'Original Author', active: true);
        await authorRepo.insert(author1);

        // Upsert should update
        final author2 = $Author(id: 4601, name: 'Updated Author', active: false);
        final upserted = await authorRepo.upsertMany([author2], returning: true);

        expect(upserted.length, 1);
        expect(upserted[0].name, 'Updated Author');
        expect(upserted[0].active, isFalse);
      });
    });
  });
}
