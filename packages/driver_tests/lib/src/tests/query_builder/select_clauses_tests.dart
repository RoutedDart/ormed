import 'package:test/test.dart';

import '../../models/models.dart';
import '../../harness/driver_test_harness.dart';
import '../../config.dart';

void runSelectClausesTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  group('Select Clauses tests', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();
    });

    tearDown(() async => harness.dispose());

    test('select', () async {
      await harness.seedUsers([
        User(id: 1, email: 'a@example.com', active: true),
      ]);

      final users = await harness.context.query<User>().select([
        'email',
      ]).rows();
      expect(users, hasLength(1));
      expect(users.first.row.containsKey('email'), isTrue);
    });

    test('addSelect', () async {
      await harness.seedUsers([
        User(id: 1, email: 'a@example.com', active: true),
      ]);

      final users = await harness.context
          .query<User>()
          .select(['id'])
          .addSelect('email')
          .rows();

      expect(users, hasLength(1));
      expect(users.first.row.containsKey('id'), isTrue);
      expect(users.first.row.containsKey('email'), isTrue);
    });

    test('selectRaw', () async {
      if (!config.supportsSelectRaw) {
        return;
      }
      await harness.seedUsers([
        User(id: 1, email: 'a@example.com', active: true),
      ]);

      final users = await harness.context
          .query<User>()
          .selectRaw('email as user_email')
          .rows();

      expect(users, hasLength(1));
      expect(users.first.row.containsKey('user_email'), isTrue);
      expect(users.first.row['user_email'], 'a@example.com');
    });

    test('distinct', () async {
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

      final articles = await harness.context.query<Article>().distinct([
        'status',
      ]).get();

      if (config.supportsDistinctOn) {
        expect(articles, hasLength(2));
        final statuses = articles.map((a) => a.status).toSet();
        expect(statuses, hasLength(2));
        expect(statuses, containsAll(['draft', 'published']));
      } else {
        expect(articles, hasLength(3));
      }
    });

    test('distinct multiple columns', () async {
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

      final articles = await harness.context.query<Article>().distinct([
        'status',
        'priority',
      ]).get();

      if (config.supportsDistinctOn) {
        expect(articles, hasLength(2));
        final statuses = articles.map((a) => a.status).toSet();
        expect(statuses, containsAll(['draft', 'published']));
      } else {
        expect(articles, hasLength(3));
      }
    });

    test('distinct with orderBy', () async {
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
          rating: 2.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);

      final articles = await harness.context
          .query<Article>()
          .distinct(['status'])
          .orderBy('status')
          .orderBy('id')
          .get();

      if (config.supportsDistinctOn) {
        expect(articles, hasLength(1));
      } else {
        expect(articles, hasLength(2));
      }
    });
  });
}
