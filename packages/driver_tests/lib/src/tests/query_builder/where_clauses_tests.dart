import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runWhereClausesTests() {
  ormedGroup('Where Clauses tests', (dataSource) {
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
      final metadata = dataSource.options.driver.metadata;
      if (!metadata.supportsCapability(DriverCapability.rawSQL)) {
        return; // Skip test if raw SQL not supported
      }

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
    });

    test('whereColumn - column comparison', () async {
      await dataSource.repo<Article>().insertMany([
        Article(
          id: 1,
          title: 'same',
          body: 'same',
          status: 'draft',
          rating: 1.0,
          priority: 1,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 2,
          title: 'different',
          body: 'other',
          status: 'draft',
          rating: 2.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereColumn('title', 'body')
          .get();

      expect(articles, hasLength(1));
      expect(articles.first.id, 1);
    });

    test('whereLike - pattern matching', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'john@example.com', active: true),
        User(id: 2, email: 'jane@example.com', active: true),
        User(id: 3, email: 'bob@test.com', active: true),
      ]);

      final users = await dataSource.context
          .query<User>()
          .where('email', '%@example.com', PredicateOperator.like)
          .get();

      expect(users, hasLength(2));
      expect(users.map((u) => u.id), containsAll([1, 2]));
    });

    test('complex nested predicates', () async {
      await dataSource.repo<Article>().insertMany([
        Article(
          id: 1,
          title: 'Article 1',
          status: 'published',
          rating: 4.5,
          priority: 1,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 2,
          title: 'Article 2',
          status: 'draft',
          rating: 3.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 3,
          title: 'Article 3',
          status: 'published',
          rating: 2.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 2,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .where(
            (builder) => builder
                .where('status', 'published')
                .where('rating', 4.0, PredicateOperator.greaterThan),
          )
          .orWhere(
            (builder) =>
                builder.where('status', 'draft').where('categoryId', 1),
          )
          .get();

      expect(articles, hasLength(2));
      expect(articles.map((a) => a.id), containsAll([1, 2]));
    });

    test('multiple chained WHERE conditions', () async {
      await dataSource.repo<Article>().insertMany([
        Article(
          id: 1,
          title: 'Match All',
          status: 'published',
          rating: 4.5,
          priority: 1,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 2,
          title: 'Match Some',
          status: 'published',
          rating: 2.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 3,
          title: 'Match None',
          status: 'draft',
          rating: 1.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 2,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .whereEquals('status', 'published')
          .where('rating', 4.0, PredicateOperator.greaterThan)
          .whereEquals('categoryId', 1)
          .get();

      expect(articles, hasLength(1));
      expect(articles.first.id, 1);
    });

    test('whereIn with empty array', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'test1@example.com', active: true),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereIn('id', [])
          .get();

      expect(users, isEmpty);
    });

    test('whereNotIn with empty array', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'test1@example.com', active: true),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereNotIn('id', [])
          .get();

      expect(users, hasLength(1));
    });
  });
}
