import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';


void runAggregationTests(DataSource dataSource) {
  group('Aggregation tests', () {
    setUp(() async {});

    // A test for 'count' for aggregation functionality
    test('count', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
      ]);

      final count = await dataSource.context.query<User>().count();
      expect(count, 2);
    });

    // A test for 'sum' for aggregation functionality
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

    // A test for 'avg' for aggregation functionality
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

    // A test for 'min' for aggregation functionality
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

    // A test for 'max' for aggregation functionality
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

    // A test for 'groupBy' for aggregation functionality
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
          .rows(); // Use rows() instead of get() to get QueryRow

      expect(results, hasLength(2));
      final draft = results.firstWhere((r) => r.row['status'] == 'draft');
      expect(draft.row['count'], 2);
    });

    // A test for 'having' for aggregation functionality
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
          .countAggregate(alias: 'count')
          .groupBy(['status'])
          .having('count', PredicateOperator.greaterThan, 1)
          .rows(); // Use rows() instead of get() to get QueryRow

      expect(results, hasLength(1));
      expect(results.first.row['status'], 'draft');
    });
  });
}
