import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runJsonQueryTests() {
  ormedGroup('JSON Query Operations', (dataSource) {
    test('whereJsonContains - simple value in array', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 1,
          email: 'user1@test.com',
          active: true,
          metadata: {
            'skills': ['Dart', 'Flutter'],
          },
        ),
        User(
          id: 2,
          email: 'user2@test.com',
          active: true,
          metadata: {
            'skills': ['Python', 'Django'],
          },
        ),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereJsonContains('metadata', 'Dart', path: r'$.skills')
          .get();

      expect(users, hasLength(1));
      expect(users.first.id, 1);
    });

    test('whereJsonLength - array length exact match', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 1,
          email: 'user1@test.com',
          active: true,
          metadata: {
            'tags': ['a', 'b', 'c'],
          },
        ),
        User(
          id: 2,
          email: 'user2@test.com',
          active: true,
          metadata: {
            'tags': ['x'],
          },
        ),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereJsonLength('metadata->tags', 3)
          .get();

      expect(users.length, greaterThanOrEqualTo(1));
    });

    test('whereJsonContainsKey - key existence', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 1,
          email: 'user1@test.com',
          active: true,
          metadata: {
            'address': {'city': 'NYC'},
          },
        ),
        User(
          id: 2,
          email: 'user2@test.com',
          active: true,
          metadata: {'name': 'John'},
        ),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereJsonContainsKey('metadata')
          .get();

      expect(users, hasLength(2));
    });

    test('whereJsonOverlaps - array intersection', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 1,
          email: 'user1@test.com',
          active: true,
          metadata: {
            'skills': ['Dart', 'Flutter', 'Go'],
          },
        ),
        User(
          id: 2,
          email: 'user2@test.com',
          active: true,
          metadata: {
            'skills': ['Python', 'Django'],
          },
        ),
      ]);

      final users = await dataSource.context.query<User>().whereJsonOverlaps(
        'metadata->skills',
        ['Dart', 'Python'],
      ).get();

      expect(users.length, greaterThanOrEqualTo(2));
    });

    test('whereLike - pattern matching', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'john@example.com', active: true),
        User(id: 2, email: 'jane@example.com', active: true),
        User(id: 3, email: 'bob@test.com', active: true),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereLike('email', '%@example.com')
          .get();

      expect(users.length, greaterThanOrEqualTo(2));
    });
  });
}
