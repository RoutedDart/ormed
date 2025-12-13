import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runAggregationTests() {
  ormedGroup('Aggregation tests', (dataSource) {
    setUp(() async {});

    test('count', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
      ]);

      final count = await dataSource.context.query<User>().count();
      expect(count, 2);
    });

    test('sum', () async {
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

      final sum = await dataSource.context.query<Article>().sumValue(
        'priority',
      );
      expect(sum, 3);
    });

    test('avg', () async {
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

      final avg = await dataSource.context.query<Article>().avgValue('rating');
      expect(avg, 2.0);
    });

    test('min', () async {
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

      final min = await dataSource.context.query<Article>().minValue('rating');
      expect(min, 1.0);
    });

    test('max', () async {
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

      final max = await dataSource.context.query<Article>().maxValue('rating');
      expect(max, 3.0);
    });

    test('groupBy', () async {
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
          categoryId: 2,
        ),
      ]);

      final results = await dataSource.context
          .query<Article>()
          .select(['status'])
          .countAggregate(alias: 'count')
          .groupBy(['status'])
          .rows();

      expect(results, hasLength(2));
      final draft = results.firstWhere((r) => r.row['status'] == 'draft');
      expect(draft.row['count'], 2);
    });

    test('having', () async {
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
          categoryId: 2,
        ),
      ]);

      final results = await dataSource.context
          .query<Article>()
          .select(['status'])
          .avg('rating', alias: 'avg_rating')
          .groupBy(['status'])
          .having('avg_rating', PredicateOperator.greaterThan, 1.5)
          .rows();

      expect(results, hasLength(2));
      final draft = results.firstWhere((r) => r.row['status'] == 'draft');
      expect(draft.row['avg_rating'], greaterThan(1.5));
    });

    test('multiple aggregates in single query', () async {
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

      final results = await dataSource.context
          .query<Article>()
          .select(['status'])
          .countAggregate(alias: 'count')
          .sum('priority', alias: 'sum_priority')
          .avg('rating', alias: 'avg_rating')
          .groupBy(['status'])
          .rows();

      final row = results.single;
      expect(row.row['count'], 2);
      expect(row.row['sum_priority'], 3);
      expect(row.row['avg_rating'], closeTo(1.5, 0.0001));
    });

    test('GROUP BY with multiple columns', () async {
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
          status: 'draft',
          rating: 2.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 2,
        ),
      ]);

      final results = await dataSource.context
          .query<Article>()
          .select(['status', 'rating'])
          .countAggregate(alias: 'count')
          .groupBy(['status', 'rating'])
          .rows();

      expect(results, hasLength(2));
      final draft2 = results.firstWhere(
        (r) => r.row['status'] == 'draft' && r.row['rating'] == 2.0,
      );
      expect(draft2.row['count'], 2);
    });

    test('HAVING with multiple conditions', () async {
      await dataSource.repo<$Article>().insertMany([
        $Article(
          title: 'a',
          status: 'draft',
          rating: 1.0,
          priority: 1,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        $Article(
          title: 'b',
          status: 'draft',
          rating: 2.0,
          priority: 2,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
        $Article(
          title: 'c',
          status: 'draft',
          rating: 3.0,
          priority: 3,
          publishedAt: DateTime.now(),
          categoryId: 1,
        ),
      ]);
      // dataSource.enableQueryLog();

      final results = await dataSource.context
          .query<Article>()
          .select(['status'])
          .countAggregate(alias: 'count')
          .sum('priority', alias: 'sum_priority')
          .groupBy(['status'])
          .havingRaw('COUNT(*) > ?', [1])
          .having('sum_priority', PredicateOperator.greaterThan, 3)
          .rows();

      expect(results, hasLength(1));
      expect(results.single.row['sum_priority'], greaterThan(3));
    });
  });
}
