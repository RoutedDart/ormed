import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'models/models.dart';

void runWhereClausesTests(DataSource dataSource) {
  final metadata = dataSource.connection.driver.metadata;

  group('Where Clauses tests', () {
    test('whereEquals', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereEquals('active', true)
          .get();
      expect(users, hasLength(1));
      expect(users.first.id, 1);
    });

    test('whereNotEquals', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereNotEquals('active', true)
          .get();
      expect(users, hasLength(1));
      expect(users.first.id, 2);
    });

    test('whereIn', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
        User(id: 3, email: 'test3@example.com', active: true),
      ]);

      final users = await dataSource.context.query<User>().whereIn('id', [
        1,
        3,
      ]).get();
      expect(users, hasLength(2));
      expect(users.map((u) => u.id), containsAll([1, 3]));
    });

    test('whereNotIn', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
        User(id: 3, email: 'test3@example.com', active: true),
      ]);

      final users = await dataSource.context.query<User>().whereNotIn('id', [
        1,
        3,
      ]).get();
      expect(users, hasLength(1));
      expect(users.first.id, 2);
    });

    test('whereGreaterThan', () async {
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
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereGreaterThan('rating', 2.0)
          .get();
      expect(articles, hasLength(1));
      expect(articles.first.id, 2);
    });

    test('whereGreaterThanOrEqual', () async {
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
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereGreaterThanOrEqual('rating', 1.0)
          .get();
      expect(articles, hasLength(2));
    });

    test('whereLessThan', () async {
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
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereLessThan('rating', 2.0)
          .get();
      expect(articles, hasLength(1));
      expect(articles.first.id, 1);
    });

    test('whereLessThanOrEqual', () async {
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
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereLessThanOrEqual('rating', 3.0)
          .get();
      expect(articles, hasLength(2));
    });

    test('whereBetween', () async {
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
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 3,
          title: 'c',
          status: 'draft',
          rating: 5.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereBetween('rating', 2.0, 4.0)
          .get();

      expect(articles, hasLength(1));
      expect(articles.first.id, 2);
    });

    test('whereNotBetween', () async {
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
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 3,
          title: 'c',
          status: 'draft',
          rating: 5.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereNotBetween('rating', 2.0, 4.0)
          .get();

      expect(articles, hasLength(2));
      expect(articles.map((a) => a.id), containsAll([1, 3]));
    });

    test('whereNull', () async {
      await dataSource.repo<Article>().insertMany([
        Article(
          id: 1,
          title: 'a',
          body: null,
          status: 'draft',
          rating: 1.0,
          priority: 1,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 2,
          title: 'b',
          body: 'not null',
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereNull('body')
          .get();
      expect(articles, hasLength(1));
      expect(articles.first.id, 1);
    });

    test('whereNotNull', () async {
      await dataSource.repo<Article>().insertMany([
        Article(
          id: 1,
          title: 'a',
          body: null,
          status: 'draft',
          rating: 1.0,
          priority: 1,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 2,
          title: 'b',
          body: 'not null',
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereNotNull('body')
          .get();
      expect(articles, hasLength(1));
      expect(articles.first.id, 2);
    });

    test('orWhere', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
        User(id: 3, email: 'test3@example.com', active: false),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereEquals('active', true)
          .orWhere('id', 2)
          .get();

      expect(users, hasLength(2));
      expect(users.map((u) => u.id), containsAll([1, 2]));
    });

    test('whereRaw', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
      ]);

      final users = await dataSource.context.query<User>().whereRaw(
        'active = ?',
        [true],
      ).get();
      expect(users, hasLength(1));
      expect(users.first.id, 1);
    }, skip: !metadata.supportsCapability(DriverCapability.rawSQL));
  });
}
