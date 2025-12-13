import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runSelectClausesTests() {
  ormedGroup('Select Clauses tests', (dataSource) {
    setUp(() async {});

    test('select', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'a@example.com', active: true),
      ]);

      final users = await dataSource.context.query<User>().select([
        'id',
        'email',
        'active',
      ]).get();
      expect(users, hasLength(1));
      expect(users.first.email, 'a@example.com');
    });

    test('addSelect', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'a@example.com', active: true),
      ]);

      final users = await dataSource.context
          .query<User>()
          .select(['id', 'email', 'active'])
          .addSelect('email')
          .get();

      expect(users, hasLength(1));
      expect(users.first.id, 1);
      expect(users.first.email, 'a@example.com');
    });

    test('selectRaw', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'a@example.com', active: true),
      ]);

      final results = await dataSource.context
          .query<User>()
          .selectRaw('id, email as user_email, active')
          .rows();

      expect(results, hasLength(1));
      expect(results.first.row.containsKey('user_email'), isTrue);
      expect(results.first.row['user_email'], 'a@example.com');
    });

    test('distinct', () async {
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
          rating: 2.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 3,
          title: 'c',
          status: 'published',
          rating: 3.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context.query<Article>().distinct([
        'status',
      ]).get();

      if (dataSource.options.driver.metadata.supportsCapability(
        DriverCapability.distinctOn,
      )) {
        expect(articles, hasLength(2));
        final statuses = articles.map((a) => a.status).toSet();
        expect(statuses, hasLength(2));
        expect(statuses, containsAll(['draft', 'published']));
      } else {
        expect(articles, hasLength(3));
      }
    });

    test('distinct multiple columns', () async {
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
          rating: 1.0,
          priority: 1,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        Article(
          id: 3,
          title: 'c',
          status: 'published',
          rating: 3.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context.query<Article>().distinct([
        'status',
        'priority',
      ]).get();

      if (dataSource.options.driver.metadata.supportsCapability(
        DriverCapability.distinctOn,
      )) {
        expect(articles, hasLength(2));
        final statuses = articles.map((a) => a.status).toSet();
        expect(statuses, containsAll(['draft', 'published']));
      } else {
        expect(articles, hasLength(3));
      }
    });

    test('distinct with orderBy', () async {
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
          rating: 2.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await dataSource.context
          .query<Article>()
          .distinct(['status'])
          .orderBy('status')
          .orderBy('id')
          .get();

      if (dataSource.options.driver.metadata.supportsCapability(
        DriverCapability.distinctOn,
      )) {
        expect(articles, hasLength(1));
      } else {
        expect(articles, hasLength(2));
      }
    });
  });
}
