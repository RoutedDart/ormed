import 'package:driver_tests/models.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

/// Runs comprehensive tests for repository input variations.
///
/// These tests verify that the repository accepts various input types for mutations:
/// - Tracked models (`$Model`)
/// - InsertDto (`$ModelInsertDto`)
/// - UpdateDto (`$ModelUpdateDto`)
/// - Partials (`$ModelPartial`) - primarily for where clauses
/// - Raw maps (`Map<String, Object?>`)
void runRepositoryInputVariationsTests() {
  ormedGroup('Repository Input Variations', (dataSource) {
    late Repository<$User> userRepo;

    setUp(() async {
      userRepo = dataSource.context.repository<$User>();
    });

    group('Insert Operations - Input Variations', () {
      group('insert() accepts:', () {
        test('tracked model (\$User)', () async {
          final user = $User(email: 'tracked@test.com', active: true);

          final result = await userRepo.insert(user);
          expect(result, isA<$User>());
          expect(result.email, 'tracked@test.com');
          expect(result.id, isNotNull);
        });

        test('InsertDto (UserInsertDto)', () async {
          const dto = UserInsertDto(email: 'dto-insert@test.com', active: true);

          final result = await userRepo.insert(dto);
          expect(result, isA<$User>());
          expect(result.email, 'dto-insert@test.com');
          expect(result.id, isNotNull);
        });

        test('UpdateDto (UserUpdateDto) - for insert', () async {
          // UpdateDto can also be used for inserts when all required fields are provided
          const dto = UserUpdateDto(
            email: 'update-dto-insert@test.com',
            active: false,
          );

          final result = await userRepo.insert(dto);
          expect(result, isA<$User>());
          expect(result.email, 'update-dto-insert@test.com');
          expect(result.active, false);
        });

        test('raw Map<String, Object?>', () async {
          final map = <String, Object?>{
            'email': 'map-insert@test.com',
            'active': true,
          };

          final result = await userRepo.insert(map);
          expect(result, isA<$User>());
          expect(result.email, 'map-insert@test.com');
        });
      });

      group('insertMany() accepts:', () {
        test('list of tracked models', () async {
          final users = [
            $User(email: 'user1@test.com', active: true),
            $User(email: 'user2@test.com', active: false),
          ];

          final results = await userRepo.insertMany(users);
          expect(results, hasLength(2));
          expect(results[0].email, 'user1@test.com');
          expect(results[1].email, 'user2@test.com');
        });

        test('list of InsertDtos', () async {
          const dtos = [
            UserInsertDto(email: 'dto1@test.com', active: true),
            UserInsertDto(email: 'dto2@test.com', active: false),
          ];

          final results = await userRepo.insertMany(dtos);
          expect(results, hasLength(2));
          expect(results[0].email, 'dto1@test.com');
          expect(results[1].email, 'dto2@test.com');
        });

        test('list of raw maps', () async {
          final maps = [
            <String, Object?>{'email': 'map1@test.com', 'active': true},
            <String, Object?>{'email': 'map2@test.com', 'active': false},
          ];

          final results = await userRepo.insertMany(maps);
          expect(results, hasLength(2));
          expect(results[0].email, 'map1@test.com');
          expect(results[1].email, 'map2@test.com');
        });

        test('mixed list of different input types', () async {
          final inputs = <Object>[
            $User(email: 'tracked-mix@test.com', active: true),
            const UserInsertDto(email: 'dto-mix@test.com', active: false),
            <String, Object?>{'email': 'map-mix@test.com', 'active': true},
          ];

          final results = await userRepo.insertMany(inputs);
          expect(results, hasLength(3));
          expect(results[0].email, 'tracked-mix@test.com');
          expect(results[1].email, 'dto-mix@test.com');
          expect(results[2].email, 'map-mix@test.com');
        });
      });
    });

    group('Update Operations - Input Variations', () {
      group('update() data input variations:', () {
        test('tracked model - PK extracted automatically', () async {
          // First insert a user
          final inserted = await userRepo.insert(
            $User(email: 'update-tracked@test.com', active: true),
          );

          // Modify and update
          inserted.email = 'updated-tracked@test.com';
          final result = await userRepo.update(inserted);

          expect(result.email, 'updated-tracked@test.com');
          expect(result.id, inserted.id);
        });

        test('UpdateDto with Map where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'update-dto-map@test.com', active: true),
          );

          const dto = UserUpdateDto(email: 'updated-dto-map@test.com');
          final result = await userRepo.update(dto, where: {'id': inserted.id});

          expect(result.email, 'updated-dto-map@test.com');
        });

        test('UpdateDto with Partial where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'update-dto-partial@test.com', active: true),
          );

          const dto = UserUpdateDto(email: 'updated-dto-partial@test.com');
          final result = await userRepo.update(
            dto,
            where: UserPartial(id: inserted.id),
          );

          expect(result.email, 'updated-dto-partial@test.com');
        });

        test('UpdateDto with InsertDto where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'update-dto-insertdto@test.com', active: true),
          );

          const dto = UserUpdateDto(active: false);
          // InsertDto doesn't have id (auto-increment), so use email for matching
          final result = await userRepo.update(
            dto,
            where: UserInsertDto(email: inserted.email),
          );

          expect(result.active, false);
        });

        test('UpdateDto with UpdateDto where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'update-dto-updatedto@test.com', active: true),
          );

          const dto = UserUpdateDto(email: 'new-email-updatedto@test.com');
          final result = await userRepo.update(
            dto,
            where: UserUpdateDto(id: inserted.id),
          );

          expect(result.email, 'new-email-updatedto@test.com');
        });

        test('raw Map data with Map where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'update-map-map@test.com', active: true),
          );

          final data = <String, Object?>{'email': 'updated-map-map@test.com'};
          final result = await userRepo.update(
            data,
            where: {'id': inserted.id},
          );

          expect(result.email, 'updated-map-map@test.com');
        });

        test('raw Map data with Partial where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'update-map-partial@test.com', active: true),
          );

          final data = <String, Object?>{'active': false};
          final result = await userRepo.update(
            data,
            where: UserPartial(id: inserted.id),
          );

          expect(result.active, false);
        });
      });

      group('update() where clause variations:', () {
        test('Map<String, Object?> where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'where-map@test.com', active: true),
          );

          const dto = UserUpdateDto(email: 'where-map-updated@test.com');
          final result = await userRepo.update(dto, where: {'id': inserted.id});

          expect(result.email, 'where-map-updated@test.com');
        });

        test('UserPartial where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'where-partial@test.com', active: true),
          );

          const dto = UserUpdateDto(email: 'where-partial-updated@test.com');
          final result = await userRepo.update(
            dto,
            where: UserPartial(id: inserted.id),
          );

          expect(result.email, 'where-partial-updated@test.com');
        });

        test('UserInsertDto where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'where-insertdto@test.com', active: true),
          );

          const dto = UserUpdateDto(email: 'where-insertdto-updated@test.com');
          // InsertDto doesn't have id (auto-increment), so use email for matching
          final result = await userRepo.update(
            dto,
            where: UserInsertDto(email: inserted.email),
          );

          expect(result.email, 'where-insertdto-updated@test.com');
        });

        test('UserUpdateDto where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'where-updatedto@test.com', active: true),
          );

          const dto = UserUpdateDto(email: 'where-updatedto-updated@test.com');
          final result = await userRepo.update(
            dto,
            where: UserUpdateDto(id: inserted.id),
          );

          expect(result.email, 'where-updatedto-updated@test.com');
        });
      });

      group('updateMany() accepts:', () {
        test('list of tracked models', () async {
          final users = await userRepo.insertMany([
            $User(email: 'batch1@test.com', active: true),
            $User(email: 'batch2@test.com', active: true),
          ]);

          for (final user in users) {
            user.active = false;
          }

          final results = await userRepo.updateMany(users);
          expect(results, hasLength(2));
          expect(results.every((u) => u.active == false), isTrue);
        });

        test('list of UpdateDtos with where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'batch-dto@test.com', active: true),
          );

          const dtos = [UserUpdateDto(email: 'batch-dto-updated@test.com')];

          final results = await userRepo.updateMany(
            dtos,
            where: {'id': inserted.id},
          );

          expect(results, isNotEmpty);
          expect(results.first.email, 'batch-dto-updated@test.com');
        });

        test('list of raw maps with where clause', () async {
          final inserted = await userRepo.insert(
            $User(email: 'batch-map@test.com', active: true),
          );

          final maps = [
            <String, Object?>{'email': 'batch-map-updated@test.com'},
          ];

          final results = await userRepo.updateMany(
            maps,
            where: {'id': inserted.id},
          );

          expect(results, isNotEmpty);
          expect(results.first.email, 'batch-map-updated@test.com');
        });
      });
    });

    group('Upsert Operations - Input Variations', () {
      group('upsert() accepts:', () {
        test('tracked model - updates existing', () async {
          final inserted = await userRepo.insert(
            $User(email: 'upsert-existing@test.com', active: true),
          );

          final user = $User(
            id: inserted.id,
            email: 'upsert-updated@test.com',
            active: false,
          );

          final result = await userRepo.upsert(user);
          expect(result.email, 'upsert-updated@test.com');
          expect(result.active, false);
        });

        test('tracked model - inserts new', () async {
          final user = $User(email: 'upsert-new@test.com', active: true);

          final result = await userRepo.upsert(user);
          expect(result.email, 'upsert-new@test.com');
          expect(result.id, isNotNull);
        });

        test('InsertDto (UserInsertDto)', () async {
          // InsertDto doesn't have id (auto-increment), so test with new insert
          const dto = UserInsertDto(
            email: 'upsert-dto-new@test.com',
            active: false,
          );

          final result = await userRepo.upsert(dto);
          expect(result.email, 'upsert-dto-new@test.com');
          expect(result.id, isNotNull);
        });

        test('UpdateDto (UserUpdateDto)', () async {
          final inserted = await userRepo.insert(
            $User(email: 'upsert-updatedto@test.com', active: true),
          );

          final dto = UserUpdateDto(
            id: inserted.id,
            email: 'upsert-updatedto-updated@test.com',
            active: false,
          );

          final result = await userRepo.upsert(dto);
          expect(result.email, 'upsert-updatedto-updated@test.com');
        });

        test('raw Map<String, Object?>', () async {
          final inserted = await userRepo.insert(
            $User(email: 'upsert-map@test.com', active: true),
          );

          final map = <String, Object?>{
            'id': inserted.id,
            'email': 'upsert-map-updated@test.com',
            'active': false,
          };

          final result = await userRepo.upsert(map);
          expect(result.email, 'upsert-map-updated@test.com');
        });
      });

      group('upsertMany() accepts:', () {
        test('list of tracked models', () async {
          final inserted = await userRepo.insert(
            $User(email: 'upsert-many1@test.com', active: true),
          );

          final users = [
            $User(
              id: inserted.id,
              email: 'upsert-many1-updated@test.com',
              active: false,
            ),
            $User(email: 'upsert-many2-new@test.com', active: true),
          ];

          final results = await userRepo.upsertMany(users);
          expect(results, hasLength(2));
        });

        test('list of InsertDtos', () async {
          // InsertDto doesn't have id (auto-increment), so test with new inserts
          const dtos = [
            UserInsertDto(email: 'upsert-dto-many1@test.com', active: false),
            UserInsertDto(email: 'upsert-dto-many2@test.com', active: true),
          ];

          final results = await userRepo.upsertMany(dtos);
          expect(results, hasLength(2));
        });

        test('list of raw maps', () async {
          final inserted = await userRepo.insert(
            $User(email: 'upsert-map-many@test.com', active: true),
          );

          final maps = [
            <String, Object?>{
              'id': inserted.id,
              'email': 'upsert-map-many-updated@test.com',
              'active': false,
            },
            <String, Object?>{
              'email': 'upsert-map-many-new@test.com',
              'active': true,
            },
          ];

          final results = await userRepo.upsertMany(maps);
          expect(results, hasLength(2));
        });

        test('mixed list of different input types', () async {
          final inserted = await userRepo.insert(
            $User(email: 'upsert-mixed@test.com', active: true),
          );

          final inputs = <Object>[
            $User(
              id: inserted.id,
              email: 'upsert-mixed-tracked@test.com',
              active: false,
            ),
            const UserInsertDto(
              email: 'upsert-mixed-dto@test.com',
              active: true,
            ),
            <String, Object?>{
              'email': 'upsert-mixed-map@test.com',
              'active': true,
            },
          ];

          final results = await userRepo.upsertMany(inputs);
          expect(results, hasLength(3));
        });
      });
    });

    group('Edge Cases', () {
      group('InsertDto with optional fields omitted:', () {
        test('only required fields provided', () async {
          const dto = UserInsertDto(
            email: 'minimal@test.com',
            active: true,
            // name, age, createdAt, etc. omitted
          );

          final result = await userRepo.insert(dto);
          expect(result, isA<$User>());
          expect(result.email, 'minimal@test.com');
        });
      });

      group('UpdateDto with partial fields:', () {
        test('only updates specified fields', () async {
          final inserted = await userRepo.insert(
            $User(
              email: 'partial-update@test.com',
              active: true,
              name: 'Original',
            ),
          );

          const dto = UserUpdateDto(name: 'Updated Name');
          final result = await userRepo.update(dto, where: {'id': inserted.id});

          expect(result.name, 'Updated Name');
          expect(result.email, 'partial-update@test.com'); // Unchanged
          expect(result.active, true); // Unchanged
        });

        test('single field update', () async {
          final inserted = await userRepo.insert(
            $User(email: 'single-field@test.com', active: true),
          );

          const dto = UserUpdateDto(active: false);
          final result = await userRepo.update(dto, where: {'id': inserted.id});

          expect(result.active, false);
          expect(result.email, 'single-field@test.com'); // Unchanged
        });
      });

      group('Empty and null handling:', () {
        test('empty list returns empty results', () async {
          final results = await userRepo.insertMany([]);
          expect(results, isEmpty);
        });

        test('null where clause for tracked model update', () async {
          final inserted = await userRepo.insert(
            $User(email: 'null-where@test.com', active: true),
          );

          inserted.email = 'null-where-updated@test.com';

          // where is null, should use PK from tracked model
          final result = await userRepo.update(inserted, where: null);
          expect(result.email, 'null-where-updated@test.com');
        });
      });
    });

    group('Type Safety Tests', () {
      test('Partial implements PartialEntity<T>', () {
        const partial = UserPartial(id: 1, name: 'Test');
        expect(partial, isA<PartialEntity<$User>>());
      });

      test('InsertDto implements InsertDto<T>', () {
        const dto = UserInsertDto(email: 'test@test.com');
        expect(dto, isA<InsertDto<$User>>());
      });

      test('UpdateDto implements UpdateDto<T>', () {
        const dto = UserUpdateDto(name: 'Test');
        expect(dto, isA<UpdateDto<$User>>());
      });

      test('Partial.toMap() only includes set fields', () {
        const partial = UserPartial(id: 1, name: 'Test');
        final map = partial.toMap();

        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('name'), isTrue);
        expect(map.containsKey('email'), isFalse);
        expect(map.containsKey('active'), isFalse);
      });

      test('InsertDto.toMap() only includes set fields', () {
        const dto = UserInsertDto(email: 'test@test.com', name: 'Test');
        final map = dto.toMap();

        expect(map.containsKey('email'), isTrue);
        expect(map.containsKey('name'), isTrue);
        expect(map.containsKey('id'), isFalse);
        expect(map.containsKey('active'), isFalse);
      });

      test('UpdateDto.toMap() only includes set fields', () {
        const dto = UserUpdateDto(active: false);
        final map = dto.toMap();

        expect(map.containsKey('active'), isTrue);
        expect(map.containsKey('id'), isFalse);
        expect(map.containsKey('name'), isFalse);
        expect(map.containsKey('email'), isFalse);
      });
    });
  });
}
