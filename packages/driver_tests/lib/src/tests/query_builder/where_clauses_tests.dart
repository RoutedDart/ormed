import 'package:test/test.dart';

import '../../models/models.dart';
import '../../harness/driver_test_harness.dart';
import '../../config.dart';

void runWhereClausesTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  group('Where Clauses tests', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();
    });

    tearDown(() async => harness.dispose());

    test('whereEquals', () async {
      await harness.seedUsers([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
      ]);

      final users = await harness.context
          .query<User>()
          .whereEquals('active', true)
          .get();
      expect(users, hasLength(1));
      expect(users.first.id, 1);
    });

    test('whereNotEquals', () async {
      await harness.seedUsers([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
      ]);

      final users = await harness.context
          .query<User>()
          .whereNotEquals('active', true)
          .get();
      expect(users, hasLength(1));
      expect(users.first.id, 2);
    });

    test('whereIn', () async {
      await harness.seedUsers([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
        User(id: 3, email: 'test3@example.com', active: true),
      ]);

      final users = await harness.context.query<User>().whereIn('id', [
        1,
        3,
      ]).get();
      expect(users, hasLength(2));
      expect(users.map((u) => u.id), containsAll([1, 3]));
    });

    test('whereNotIn', () async {
      await harness.seedUsers([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
        User(id: 3, email: 'test3@example.com', active: true),
      ]);

      final users = await harness.context.query<User>().whereNotIn('id', [
        1,
        3,
      ]).get();
      expect(users, hasLength(1));
      expect(users.first.id, 2);
    });

    test('whereGreaterThan', () async {
      await harness.seedArticles([
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

      final articles = await harness.context
          .query<Article>()
          .whereGreaterThan('rating', 2.0)
          .get();
      expect(articles, hasLength(1));
      expect(articles.first.id, 2);
    });

    test('whereGreaterThanOrEqual', () async {
      await harness.seedArticles([
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

      final articles = await harness.context
          .query<Article>()
          .whereGreaterThanOrEqual('rating', 1.0)
          .get();
      expect(articles, hasLength(2));
    });

    test('whereLessThan', () async {
      await harness.seedArticles([
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

      final articles = await harness.context
          .query<Article>()
          .whereLessThan('rating', 2.0)
          .get();
      expect(articles, hasLength(1));
      expect(articles.first.id, 1);
    });

    test('whereLessThanOrEqual', () async {
      await harness.seedArticles([
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

      final articles = await harness.context
          .query<Article>()
          .whereLessThanOrEqual('rating', 3.0)
          .get();
      expect(articles, hasLength(2));
    });

    test('whereBetween', () async {
      await harness.seedArticles([
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

      final articles = await harness.context
          .query<Article>()
          .whereBetween('rating', 2.0, 4.0)
          .get();

      expect(articles, hasLength(1));
      expect(articles.first.id, 2);
    });

    test('whereNotBetween', () async {
      await harness.seedArticles([
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

      final articles = await harness.context
          .query<Article>()
          .whereNotBetween('rating', 2.0, 4.0)
          .get();

      expect(articles, hasLength(2));
      expect(articles.map((a) => a.id), containsAll([1, 3]));
    });

    test('whereNull', () async {
      await harness.seedArticles([
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

      final articles = await harness.context
          .query<Article>()
          .whereNull('body')
          .get();
      expect(articles, hasLength(1));
      expect(articles.first.id, 1);
    });

    test('whereNotNull', () async {
      await harness.seedArticles([
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

      final articles = await harness.context
          .query<Article>()
          .whereNotNull('body')
          .get();
      expect(articles, hasLength(1));
      expect(articles.first.id, 2);
    });

    test('orWhere', () async {
      await harness.seedUsers([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
        User(id: 3, email: 'test3@example.com', active: false),
      ]);

      final users = await harness.context
          .query<User>()
          .whereEquals('active', true)
          .orWhere('id', 2)
          .get();

      expect(users, hasLength(2));
      expect(users.map((u) => u.id), containsAll([1, 2]));
    });

    test('whereRaw', () async {
      if (!config.supportsWhereRaw) {
        return;
      }

      await harness.seedUsers([
        User(id: 1, email: 'test1@example.com', active: true),
        User(id: 2, email: 'test2@example.com', active: false),
      ]);

      final users = await harness.context.query<User>().whereRaw('active = ?', [
        true,
      ]).get();
      expect(users, hasLength(1));
      expect(users.first.id, 1);
    });
  });
}
