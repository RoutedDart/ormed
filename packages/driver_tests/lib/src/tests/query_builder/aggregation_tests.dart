import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';
import '../../harness/driver_test_harness.dart';
import '../../config.dart';

void runAggregationTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  group('Aggregation tests', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();
    });

    tearDown(() async => harness.dispose());

    // A test for 'count' using the provided harness and config
    test('count', () async {
      await harness.seedUsers([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
      ]);

      final count = await harness.context.query<User>().count();
      expect(count, 2);
    });

    // A test for 'sum' using the provided harness and config
    test('sum', () async {
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

      final sum = await harness.context.query<Article>().sumValue('priority');
      expect(sum, 3);
    });

    // A test for 'avg' using the provided harness and config
    test('avg', () async {
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

      final avg = await harness.context.query<Article>().avgValue('rating');
      expect(avg, 2.0);
    });

    // A test for 'min' using the provided harness and config
    test('min', () async {
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

      final min = await harness.context.query<Article>().minValue('rating');
      expect(min, 1.0);
    });

    // A test for 'max' using the provided harness and config
    test('max', () async {
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

      final max = await harness.context.query<Article>().maxValue('rating');
      expect(max, 3.0);
    });

    // A test for 'groupBy' using the provided harness and config
    test('groupBy', () async {
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

      final results = await harness.context
          .query<Article>()
          .select(['status'])
          .countAggregate(alias: 'count')
          .groupBy(['status'])
          .rows(); // Use rows() instead of get() to get QueryRow

      expect(results, hasLength(2));
      final draft = results.firstWhere((r) => r.row['status'] == 'draft');
      expect(draft.row['count'], 2);
    });

    // A test for 'having' using the provided harness and config
    test('having', () async {
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

      final results = await harness.context
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
