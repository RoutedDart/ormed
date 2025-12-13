import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runDateTimeQueryTests() {
  ormedGroup('Date/Time Query Operations', (dataSource) {
    test('date range query - between dates', () async {
      await dataSource.repo<Post>().insertMany([
        Post(
          id: 1,
          authorId: 1,
          title: 'Post 1',
          publishedAt: DateTime(2024, 1, 10),
        ),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2024, 1, 15),
        ),
        Post(
          id: 3,
          authorId: 1,
          title: 'Post 3',
          publishedAt: DateTime(2024, 1, 20),
        ),
        Post(
          id: 4,
          authorId: 1,
          title: 'Post 4',
          publishedAt: DateTime(2024, 1, 25),
        ),
      ]);

      final posts = await dataSource.context
          .query<Post>()
          .whereBetween(
            'publishedAt',
            DateTime(2024, 1, 12),
            DateTime(2024, 1, 22),
          )
          .get();

      expect(posts, hasLength(2));
      expect(posts.map((p) => p.id), containsAll([2, 3]));
    });

    test('date comparison operators - greater than', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Past', publishedAt: yesterday),
        Post(id: 2, authorId: 1, title: 'Future', publishedAt: tomorrow),
      ]);

      final futurePosts = await dataSource.context
          .query<Post>()
          .where('publishedAt', now, PredicateOperator.greaterThan)
          .get();

      expect(futurePosts, hasLength(1));
      expect(futurePosts.first.id, 2);
    });

    test('date comparison operators - less than', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Past', publishedAt: yesterday),
        Post(id: 2, authorId: 1, title: 'Future', publishedAt: tomorrow),
      ]);

      final pastPosts = await dataSource.context
          .query<Post>()
          .where('publishedAt', now, PredicateOperator.lessThan)
          .get();

      expect(pastPosts, hasLength(1));
      expect(pastPosts.first.id, 1);
    });

    test('order by date', () async {
      await dataSource.repo<Post>().insertMany([
        Post(
          id: 1,
          authorId: 1,
          title: 'Post 1',
          publishedAt: DateTime(2024, 1, 20),
        ),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2024, 1, 10),
        ),
        Post(
          id: 3,
          authorId: 1,
          title: 'Post 3',
          publishedAt: DateTime(2024, 1, 15),
        ),
      ]);

      final posts = await dataSource.context
          .query<Post>()
          .orderBy('publishedAt')
          .get();

      expect(posts, hasLength(3));
      expect(posts[0].id, 2); // Jan 10
      expect(posts[1].id, 3); // Jan 15
      expect(posts[2].id, 1); // Jan 20
    });

    test('order by date descending', () async {
      await dataSource.repo<Post>().insertMany([
        Post(
          id: 1,
          authorId: 1,
          title: 'Post 1',
          publishedAt: DateTime(2024, 1, 10),
        ),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2024, 1, 20),
        ),
        Post(
          id: 3,
          authorId: 1,
          title: 'Post 3',
          publishedAt: DateTime(2024, 1, 15),
        ),
      ]);

      final posts = await dataSource.context
          .query<Post>()
          .orderBy('publishedAt', descending: true)
          .get();

      expect(posts, hasLength(3));
      expect(posts[0].id, 2); // Jan 20
      expect(posts[1].id, 3); // Jan 15
      expect(posts[2].id, 1); // Jan 10
    });

    test('date with WHERE and ORDER BY', () async {
      final cutoff = DateTime(2024, 1, 15);

      await dataSource.repo<Post>().insertMany([
        Post(
          id: 1,
          authorId: 1,
          title: 'Post 1',
          publishedAt: DateTime(2024, 1, 10),
        ),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2024, 1, 20),
        ),
        Post(
          id: 3,
          authorId: 1,
          title: 'Post 3',
          publishedAt: DateTime(2024, 1, 18),
        ),
        Post(
          id: 4,
          authorId: 1,
          title: 'Post 4',
          publishedAt: DateTime(2024, 1, 5),
        ),
      ]);

      final posts = await dataSource.context
          .query<Post>()
          .where('publishedAt', cutoff, PredicateOperator.greaterThanOrEqual)
          .orderBy('publishedAt')
          .get();

      expect(posts, hasLength(2));
      expect(posts[0].id, 3); // Jan 18
      expect(posts[1].id, 2); // Jan 20
    });

    test('date null checks', () async {
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime.now()),
        Post(id: 2, authorId: 1, title: 'Draft', publishedAt: DateTime.now()),
      ]);

      final published = await dataSource.context
          .query<Post>()
          .whereNotNull('publishedAt')
          .get();

      expect(published, hasLength(2));
    });

    test('multiple date filters', () async {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);

      await dataSource.repo<Post>().insertMany([
        Post(
          id: 1,
          authorId: 1,
          title: 'In 2024',
          publishedAt: DateTime(2024, 6, 15),
        ),
        Post(
          id: 2,
          authorId: 1,
          title: 'In 2023',
          publishedAt: DateTime(2023, 6, 15),
        ),
        Post(
          id: 3,
          authorId: 1,
          title: 'In 2025',
          publishedAt: DateTime(2025, 1, 1),
        ),
      ]);

      final posts = await dataSource.context
          .query<Post>()
          .where('publishedAt', start, PredicateOperator.greaterThanOrEqual)
          .where('publishedAt', end, PredicateOperator.lessThanOrEqual)
          .get();

      expect(posts, hasLength(1));
      expect(posts.first.id, 1);
    });
  });
}
