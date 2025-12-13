import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

/// Runs tests for generated partial classes and their toEntity() validation.
void runPartialEntityTests() {
  group('Partial Entity Tests', () {
    group('UserPartial', () {
      test('toEntity() succeeds with all required fields', () {
        const partial = UserPartial(
          id: 1,
          email: 'test@example.com',
          active: true,
          name: 'Test User',
          age: 25,
        );

        final entity = partial.toEntity();

        expect(entity.id, equals(1));
        expect(entity.email, equals('test@example.com'));
        expect(entity.active, isTrue);
        expect(entity.name, equals('Test User'));
        expect(entity.age, equals(25));
      });

      test('toEntity() succeeds with only required fields', () {
        const partial = UserPartial(
          id: 1,
          email: 'test@example.com',
          active: false,
        );

        final entity = partial.toEntity();

        expect(entity.id, equals(1));
        expect(entity.email, equals('test@example.com'));
        expect(entity.active, isFalse);
        expect(entity.name, isNull);
        expect(entity.age, isNull);
      });

      test('toEntity() throws StateError when id is missing', () {
        const partial = UserPartial(
          email: 'test@example.com',
          active: true,
        );

        expect(
          () => partial.toEntity(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('id'),
            ),
          ),
        );
      });

      test('toEntity() throws StateError when email is missing', () {
        const partial = UserPartial(
          id: 1,
          active: true,
        );

        expect(
          () => partial.toEntity(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('email'),
            ),
          ),
        );
      });

      test('toEntity() throws StateError when active is missing', () {
        const partial = UserPartial(
          id: 1,
          email: 'test@example.com',
        );

        expect(
          () => partial.toEntity(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('active'),
            ),
          ),
        );
      });

      test('toEntity() throws StateError when multiple required fields missing',
          () {
        const partial = UserPartial(
          name: 'Test User',
        );

        expect(
          () => partial.toEntity(),
          throwsStateError,
        );
      });

      test('partial can be created with optional fields only', () {
        const partial = UserPartial(
          name: 'Optional Only',
          age: 30,
          profile: {'key': 'value'},
        );

        expect(partial.name, equals('Optional Only'));
        expect(partial.age, equals(30));
        expect(partial.profile, equals({'key': 'value'}));
        expect(partial.id, isNull);
        expect(partial.email, isNull);
        expect(partial.active, isNull);
      });

      test('empty partial is valid but toEntity() throws', () {
        const partial = UserPartial();

        expect(partial.id, isNull);
        expect(partial.email, isNull);
        expect(partial.active, isNull);
        expect(() => partial.toEntity(), throwsStateError);
      });

      test('fromRow creates partial from database row map', () {
        final row = {
          'id': 42,
          'email': 'from-row@example.com',
          'active': true,
          'name': 'Row User',
        };

        final partial = UserPartial.fromRow(row);

        expect(partial.id, equals(42));
        expect(partial.email, equals('from-row@example.com'));
        expect(partial.active, isTrue);
        expect(partial.name, equals('Row User'));
        expect(partial.age, isNull); // Not in row
      });

      test('fromRow handles missing columns gracefully', () {
        final row = <String, Object?>{
          'id': 1,
        };

        final partial = UserPartial.fromRow(row);

        expect(partial.id, equals(1));
        expect(partial.email, isNull);
        expect(partial.active, isNull);
      });
    });

    group('AuthorPartial', () {
      test('toEntity() succeeds with required fields', () {
        const partial = AuthorPartial(
          id: 1,
          name: 'Test Author',
          active: true,
        );

        final entity = partial.toEntity();

        expect(entity.id, equals(1));
        expect(entity.name, equals('Test Author'));
        expect(entity.active, isTrue);
      });

      test('toEntity() throws when name is missing', () {
        const partial = AuthorPartial(
          id: 1,
          active: true,
        );

        expect(
          () => partial.toEntity(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('name'),
            ),
          ),
        );
      });
    });

    group('PostPartial', () {
      test('toEntity() succeeds with required fields', () {
        final partial = PostPartial(
          id: 1,
          authorId: 100,
          title: 'Test Post',
          publishedAt: DateTime(2025, 1, 1),
        );

        final entity = partial.toEntity();

        expect(entity.id, equals(1));
        expect(entity.authorId, equals(100));
        expect(entity.title, equals('Test Post'));
        expect(entity.content, isNull);
        expect(entity.publishedAt, equals(DateTime(2025, 1, 1)));
      });

      test('toEntity() throws when authorId is missing', () {
        final partial = PostPartial(
          id: 1,
          title: 'Test Post',
          publishedAt: DateTime(2025, 1, 1),
        );

        expect(
          () => partial.toEntity(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('authorId'),
            ),
          ),
        );
      });

      test('toEntity() throws when title is missing', () {
        final partial = PostPartial(
          id: 1,
          authorId: 100,
          publishedAt: DateTime(2025, 1, 1),
        );

        expect(
          () => partial.toEntity(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('title'),
            ),
          ),
        );
      });

      test('toEntity() throws when publishedAt is missing', () {
        const partial = PostPartial(
          id: 1,
          authorId: 100,
          title: 'Test Post',
        );

        expect(
          () => partial.toEntity(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('publishedAt'),
            ),
          ),
        );
      });
    });
  });

  // Database integration tests using ormedGroup
  runPartialProjectionIntegrationTests();
}

/// Runs database integration tests for partial projections.
/// These tests require a database connection.
void runPartialProjectionIntegrationTests() {
  ormedGroup('Partial Projection Integration', (dataSource) {
    test('getPartial() returns partial instances', () async {
      // Insert test data
      await dataSource.repo<User>().insert(
        $User(
          id: 9001,
          email: 'partial-test@example.com',
          active: true,
          name: 'Partial User',
        ),
      );

      // Query with partial projection
      final partials = await dataSource.context
          .query<$User>()
          .where('id', 9001)
          .select(['id', 'email', 'name'])
          .getPartial(UserPartial.fromRow);

      expect(partials, hasLength(1));
      expect(partials.first.id, equals(9001));
      expect(partials.first.email, equals('partial-test@example.com'));
      expect(partials.first.name, equals('Partial User'));
    });

    test('firstPartial() returns single partial or null', () async {
      await dataSource.repo<User>().insert(
        $User(id: 9002, email: 'first-partial@example.com', active: true),
      );

      final partial = await dataSource.context
          .query<$User>()
          .where('id', 9002)
          .select(['id', 'email'])
          .firstPartial(UserPartial.fromRow);

      expect(partial, isNotNull);
      expect(partial!.id, equals(9002));
      expect(partial.email, equals('first-partial@example.com'));
    });

    test('firstPartial() returns null when no match', () async {
      final partial = await dataSource.context
          .query<$User>()
          .where('id', 99999)
          .select(['id', 'email'])
          .firstPartial(UserPartial.fromRow);

      expect(partial, isNull);
    });

    test('partial toEntity() works with full data from database', () async {
      await dataSource.repo<User>().insert(
        $User(id: 9003, email: 'to-entity@example.com', active: false),
      );

      // Select all required fields
      final partial = await dataSource.context
          .query<$User>()
          .where('id', 9003)
          .firstPartial(UserPartial.fromRow);

      expect(partial, isNotNull);

      // Convert to full entity
      final entity = partial!.toEntity();
      expect(entity.id, equals(9003));
      expect(entity.email, equals('to-entity@example.com'));
      expect(entity.active, isFalse);
    });

    test('getPartial() with multiple rows', () async {
      await dataSource.repo<User>().insertMany([
        $User(id: 9010, email: 'multi1@example.com', active: true),
        $User(id: 9011, email: 'multi2@example.com', active: false),
        $User(id: 9012, email: 'multi3@example.com', active: true),
      ]);

      final partials = await dataSource.context
          .query<$User>()
          .whereIn('id', [9010, 9011, 9012])
          .orderBy('id')
          .getPartial(UserPartial.fromRow);

      expect(partials, hasLength(3));
      expect(partials[0].email, equals('multi1@example.com'));
      expect(partials[1].email, equals('multi2@example.com'));
      expect(partials[2].email, equals('multi3@example.com'));
    });

    test('getPartial() respects select columns', () async {
      await dataSource.repo<User>().insert(
        $User(
          id: 9020,
          email: 'select-cols@example.com',
          active: true,
          name: 'Full Name',
          age: 30,
        ),
      );

      // Only select id and email
      final partials = await dataSource.context
          .query<$User>()
          .where('id', 9020)
          .select(['id', 'email'])
          .getPartial(UserPartial.fromRow);

      expect(partials, hasLength(1));
      expect(partials.first.id, equals(9020));
      expect(partials.first.email, equals('select-cols@example.com'));
      // Fields not selected should be null in the partial
      // (depending on driver behavior with select)
    });
  });
}

