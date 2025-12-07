import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'models/models.dart';

void runOrderByClausesTests(DataSource dataSource) {
  group('OrderBy Clauses tests', () {
    setUp(() async {});

    test('orderBy', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'b@example.com', active: true),
        User(id: 2, email: 'a@example.com', active: false),
      ]);

      final users = await dataSource.context
          .query<User>()
          .orderBy('email')
          .get();

      expect(users, hasLength(2));
      expect(users.first.id, 2);
      expect(users.last.id, 1);
    });

    test('orderBy descending', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
      ]);

      final users = await dataSource.context
          .query<User>()
          .orderBy('email', descending: true)
          .get();

      expect(users, hasLength(2));
      expect(users.first.id, 2);
      expect(users.last.id, 1);
    });

    test('multiple orderBy', () async {
      await dataSource.repo<Article>().insertMany([
        Article(
          id: 1,
          title: 'a',
          status: 'draft',
          rating: 1.0,
          priority: 1,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 2,
          title: 'b',
          status: 'published',
          rating: 2.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 3,
          title: 'c',
          status: 'draft',
          rating: 3.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .orderBy('status')
          .orderBy('id', descending: true)
          .get();

      expect(articles, hasLength(3));
      expect(articles.map((a) => a.id), equals([3, 1, 2]));
    });

    test('orderByRandom', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
        User(id: 3, email: 'c@example.com', active: true),
      ]);

      final seen = <List<int>>[];
      for (var i = 0; i < 5; i++) {
        final users = await dataSource.context
            .query<User>()
            .orderByRandom()
            .get();
        seen.add(users.map((u) => u.id).toList(growable: false));
      }

      final uniqueOrders = {for (final order in seen) order.join(',')};
      expect(uniqueOrders.length, greaterThan(1));
    });
  });
}
