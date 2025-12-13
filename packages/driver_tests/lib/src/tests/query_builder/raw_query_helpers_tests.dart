import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runRawQueryHelperTests() {
  ormedGroup('Raw Query Helpers', (dataSource) {
    group('havingRaw', () {
      test('adds raw HAVING clause with aggregates', () async {
        await dataSource.repo<Author>().insertMany([
          Author(id: 1, name: 'Author 1'),
          Author(id: 2, name: 'Author 2'),
          Author(id: 3, name: 'Author 3'),
        ]);

        final posts = List.generate(
          30,
          (i) => Post(
            id: i + 1,
            authorId: (i % 3) + 1,
            title: 'Post ${i + 1}',
            publishedAt: DateTime.now(),
          ),
        );
        await dataSource.repo<Post>().insertMany(posts);

        // Find authors with more than 8 posts
        final results = await dataSource.context
            .query<Post>()
            .select(['authorId'])
            .selectRaw('COUNT(*) as postCount')
            .groupBy(['authorId'])
            .havingRaw('COUNT(*) > ?', [8])
            .get();

        // All authors have 10 posts (30 / 3)
        expect(results, hasLength(3));
      });

      test('works with simple HAVING conditions', () async {
        await dataSource.repo<Author>().insertMany([
          Author(id: 1, name: 'Popular Author'),
          Author(id: 2, name: 'Quiet Author'),
        ]);

        final posts = [
          ...List.generate(
            15,
            (i) => Post(
              id: i + 1,
              authorId: 1,
              title: 'Popular Post ${i + 1}',
              publishedAt: DateTime.now(),
            ),
          ),
          ...List.generate(
            2,
            (i) => Post(
              id: 20 + i,
              authorId: 2,
              title: 'Quiet Post ${i + 1}',
              publishedAt: DateTime.now(),
            ),
          ),
        ];
        await dataSource.repo<Post>().insertMany(posts);

        // Count posts per author and filter
        final authorCounts = await dataSource.context
            .query<Post>()
            .select(['authorId'])
            .selectRaw('COUNT(*) as postCount')
            .groupBy(['authorId'])
            .havingRaw('COUNT(*) >= ?', [10])
            .get();

        expect(authorCounts, hasLength(1));
      });

      test('havingRaw with complex aggregation', () async {
        await dataSource.repo<Author>().insertMany([
          Author(id: 1, name: 'Author A'),
          Author(id: 2, name: 'Author B'),
          Author(id: 3, name: 'Author C'),
        ]);

        final posts = [
          ...List.generate(
            25,
            (i) => Post(
              id: i + 1,
              authorId: (i % 3) + 1,
              title: 'Post ${i + 1}',
              publishedAt: DateTime.now(),
            ),
          ),
        ];
        await dataSource.repo<Post>().insertMany(posts);

        final results = await dataSource.context
            .query<Post>()
            .select(['authorId'])
            .selectRaw('COUNT(*) as postCount')
            .groupBy(['authorId'])
            .havingRaw('COUNT(*) >= ?', [8])
            .get();

        expect(results, hasLength(3));
        // All authors have 8+ posts (25 / 3 = ~8 each)
      });

      test('orHavingRaw combines conditions with OR', () async {
        await dataSource.repo<Author>().insertMany([
          Author(id: 1, name: 'Author 1'),
          Author(id: 2, name: 'Author 2'),
          Author(id: 3, name: 'Author 3'),
        ]);

        final posts = [
          ...List.generate(
            20,
            (i) => Post(
              id: i + 1,
              authorId: 1,
              title: 'Post ${i + 1}',
              publishedAt: DateTime.now(),
            ),
          ),
          ...List.generate(
            5,
            (i) => Post(
              id: 21 + i,
              authorId: 2,
              title: 'Post ${21 + i}',
              publishedAt: DateTime.now(),
            ),
          ),
          Post(
            id: 50,
            authorId: 3,
            title: 'Post 50',
            publishedAt: DateTime.now(),
          ),
        ];
        await dataSource.repo<Post>().insertMany(posts);

        // Authors with many posts OR few posts (not in between)
        final results = await dataSource.context
            .query<Post>()
            .select(['authorId'])
            .selectRaw('COUNT(*) as postCount')
            .groupBy(['authorId'])
            .havingRaw('COUNT(*) > ?', [15])
            .orHavingRaw('COUNT(*) < ?', [3])
            .get();

        // Should have 2 results: author 1 (20) and author 3 (1)
        expect(results, hasLength(2));
      });

      test('multiple havingRaw calls combine correctly', () async {
        await dataSource.repo<Author>().insertMany([
          Author(id: 1, name: 'Author 1'),
          Author(id: 2, name: 'Author 2'),
        ]);

        final posts = [
          ...List.generate(
            15,
            (i) => Post(
              id: i + 1,
              authorId: 1,
              title: 'Post ${i + 1}',
              publishedAt: DateTime.now(),
            ),
          ),
          ...List.generate(
            5,
            (i) => Post(
              id: 20 + i,
              authorId: 2,
              title: 'Post ${20 + i}',
              publishedAt: DateTime.now(),
            ),
          ),
        ];
        await dataSource.repo<Post>().insertMany(posts);

        final stats = await dataSource.context
            .query<Post>()
            .select(['authorId'])
            .selectRaw('COUNT(*) as total')
            .groupBy(['authorId'])
            .havingRaw('COUNT(*) > ?', [3])
            .get();

        expect(stats, hasLength(2));
      });
    });
  });
}
