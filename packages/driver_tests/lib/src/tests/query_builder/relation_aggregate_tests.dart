import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import '../../../driver_tests.dart';

/// Tests for relation aggregate loading methods like loadSum, loadAvg, loadMax, loadMin
/// Note: MongoDB supports these via client-side aggregation, while SQL drivers use database-level aggregation.
void runRelationAggregateTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  group('${config.driverName} relation aggregates', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();

      // Bind connection resolver for Model.load() to work
      Model.bindConnectionResolver(
        resolveConnection: (name) => harness.context,
      );

      // Seed test data
      await harness.seedAuthors([
        const Author(id: 1, name: 'Alice'),
        const Author(id: 2, name: 'Bob'),
      ]);
      await harness.seedPosts([
        Post(
          id: 1,
          authorId: 1,
          title: 'Post 1',
          publishedAt: DateTime(2024),
          views: 100,
        ),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2024, 2),
          views: 250,
        ),
        Post(
          id: 3,
          authorId: 1,
          title: 'Post 3',
          publishedAt: DateTime(2024, 3),
          views: 150,
        ),
        Post(
          id: 4,
          authorId: 2,
          title: 'Post 4',
          publishedAt: DateTime(2024, 4),
          views: 500,
        ),
      ]);
    });

    tearDown(() async {
      Model.unbindConnectionResolver();
      await harness.dispose();
    });

    test('loadSum calculates sum of relation column', () async {
      final rows = await harness.context.query<Author>().where('id', 1).get();
      final author = rows.first;

      // Load sum of views
      await author.loadSum('posts', 'views', alias: 'total_views');

      final totalViews = author.getAttribute<num>('total_views');
      expect(totalViews, equals(500)); // 100 + 250 + 150
    }, skip: !config.supportsCapability(DriverCapability.relationAggregates));

    test('loadSum returns 0 for empty relations', () async {
      // Create author with no posts
      await harness.seedAuthors([const Author(id: 99, name: 'Lonely')]);
      final rows =
          await harness.context.query<Author>().where('id', 99).get();
      final author = rows.first;

      await author.loadSum('posts', 'views', alias: 'total_views');

      final totalViews = author.getAttribute<num>('total_views');
      expect(totalViews, equals(0));
    }, skip: !config.supportsCapability(DriverCapability.relationAggregates));

    test('query builder withSum works', () async {
      final authors = await harness.context
          .query<Author>()
          .withSum('posts', 'views', alias: 'total_views')
          .orderBy('id')
          .get();

      expect(authors.length, equals(2));
      expect(authors[0].getAttribute<num>('total_views'), equals(500));
      expect(authors[1].getAttribute<num>('total_views'), equals(500));
    }, skip: !config.supportsCapability(DriverCapability.relationAggregates));

    test('withSum default alias naming', () async {
      final authors = await harness.context
          .query<Author>()
          .withSum('posts', 'views')
          .where('id', 1)
          .get();

      final author = authors.first;
      // Default alias should be: posts_sum_views
      expect(author.getAttribute<num>('posts_sum_views'), equals(500));
    }, skip: !config.supportsCapability(DriverCapability.relationAggregates));

    test('withSum with constraints', () async {
      // Add a low-view post
      await harness.seedPosts([
        Post(
          id: 5,
          authorId: 1,
          title: 'Low views',
          publishedAt: DateTime(2024, 5),
          views: 10,
        ),
      ]);

      final authors = await harness.context
          .query<Author>()
          .withSum(
            'posts',
            'views',
            alias: 'high_views',
            constraint: (q) => q.where('views', 50, PredicateOperator.greaterThan),
          )
          .where('id', 1)
          .get();

      final author = authors.first;
      // Should only sum posts with views > 50 (100 + 250 + 150 = 500, excluding 10)
      expect(author.getAttribute<num>('high_views'), equals(500));
    }, skip: !config.supportsCapability(DriverCapability.relationAggregates));
  }, skip: !config.supportsCapability(DriverCapability.relationAggregates));
}
