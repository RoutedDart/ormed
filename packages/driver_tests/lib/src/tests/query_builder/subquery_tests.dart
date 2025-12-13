import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runSubqueryTests() {
  ormedGroup('Subquery Operations', (dataSource) {
    group('whereInSubquery', () {
      test(
        'filters records where column value exists in subquery results',
        () async {
          // Create users and posts
          await dataSource.repo<User>().insertMany([
            User(id: 1, email: 'alice@example.com', active: true),
            User(id: 2, email: 'bob@example.com', active: true),
            User(id: 3, email: 'charlie@example.com', active: true),
          ]);

          await dataSource.repo<Post>().insertMany([
            Post(
              id: 1,
              authorId: 1,
              title: 'Post 1',
              publishedAt: DateTime.now(),
            ),
            Post(
              id: 2,
              authorId: 1,
              title: 'Post 2',
              publishedAt: DateTime.now(),
            ),
            Post(
              id: 3,
              authorId: 2,
              title: 'Post 3',
              publishedAt: DateTime.now(),
            ),
          ]);

          // Find users who have posts
          final users = await dataSource.context
              .query<User>()
              .whereInSubquery(
                'id',
                dataSource.context.query<Post>().select(['authorId']),
              )
              .get();

          expect(users, hasLength(2));
          expect(users.map((u) => u.id), containsAll([1, 2]));
        },
      );

      test('works with WHERE conditions in subquery', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: true),
          User(id: 3, email: 'charlie@example.com', active: true),
        ]);

        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Published',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 2,
            authorId: 2,
            title: 'Draft',
            publishedAt: DateTime(2000, 1, 1),
          ),
          Post(
            id: 3,
            authorId: 3,
            title: 'Old',
            publishedAt: DateTime(2000, 1, 1),
          ),
        ]);

        // Find users who have published posts (recent posts)
        final recentDate = DateTime.now().subtract(Duration(days: 1));
        final users = await dataSource.context
            .query<User>()
            .whereInSubquery(
              'id',
              dataSource.context
                  .query<Post>()
                  .select(['authorId'])
                  .where(
                    'publishedAt',
                    recentDate,
                    PredicateOperator.greaterThan,
                  ),
            )
            .get();

        expect(users, hasLength(1));
        expect(users.first.id, 1);
      });

      test('returns empty when no matches', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
        ]);

        final users = await dataSource.context
            .query<User>()
            .whereInSubquery(
              'id',
              dataSource.context.query<Post>().select(['authorId']),
            )
            .get();

        expect(users, isEmpty);
      });
    });

    group('whereNotInSubquery', () {
      test(
        'filters records where column value does NOT exist in subquery',
        () async {
          await dataSource.repo<User>().insertMany([
            User(id: 1, email: 'alice@example.com', active: true),
            User(id: 2, email: 'bob@example.com', active: true),
            User(id: 3, email: 'charlie@example.com', active: true),
          ]);

          await dataSource.repo<Post>().insertMany([
            Post(
              id: 1,
              authorId: 1,
              title: 'Post 1',
              publishedAt: DateTime.now(),
            ),
          ]);

          // Find users who have NO posts
          final users = await dataSource.context
              .query<User>()
              .whereNotInSubquery(
                'id',
                dataSource.context.query<Post>().select(['authorId']),
              )
              .get();

          expect(users, hasLength(2));
          expect(users.map((u) => u.id), containsAll([2, 3]));
        },
      );

      test('whereNotInSubquery excludes matching ids', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: true),
        ]);

        final users = await dataSource.context
            .query<User>()
            .whereNotInSubquery(
              'id',
              dataSource.context.query<Post>().select(['authorId']),
            )
            .get();

        expect(users, hasLength(2));
      });
    });

    group('whereExists', () {
      test('whereExists returns rows when subquery matches', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: true),
          User(id: 3, email: 'charlie@example.com', active: true),
        ]);

        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 2,
            authorId: 1,
            title: 'Post 2',
            publishedAt: DateTime.now(),
          ),
        ]);

        // Find users who have at least one post
        final users = await dataSource.context
            .query<User>()
            .whereExists(
              dataSource.context.query<Post>().whereColumn(
                'authorId',
                'users.id',
              ),
            )
            .get();

        expect(users, hasLength(1));
        expect(users.first.id, 1);
      });

      test('whereExists supports additional predicates', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: true),
        ]);

        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Published',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 2,
            authorId: 2,
            title: 'Old',
            publishedAt: DateTime(2000, 1, 1),
          ),
        ]);

        // Find users with recent posts
        final recentDate = DateTime.now().subtract(Duration(days: 1));
        final users = await dataSource.context
            .query<User>()
            .whereExists(
              dataSource.context
                  .query<Post>()
                  .whereColumn('authorId', 'users.id')
                  .where(
                    'publishedAt',
                    recentDate,
                    PredicateOperator.greaterThan,
                  ),
            )
            .get();

        expect(users, hasLength(1));
        expect(users.first.id, 1);
      });

      test('whereExists returns empty when subquery has no rows', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
        ]);

        final users = await dataSource.context
            .query<User>()
            .whereExists(
              dataSource.context.query<Post>().whereColumn(
                'authorId',
                'users.id',
              ),
            )
            .get();

        expect(users, isEmpty);
      });
    });

    group('whereNotExists', () {
      test(
        'filters records where correlated subquery returns NO results',
        () async {
          await dataSource.repo<User>().insertMany([
            User(id: 1, email: 'alice@example.com', active: true),
            User(id: 2, email: 'bob@example.com', active: true),
            User(id: 3, email: 'charlie@example.com', active: true),
          ]);

          await dataSource.repo<Post>().insertMany([
            Post(
              id: 1,
              authorId: 1,
              title: 'Post 1',
              publishedAt: DateTime.now(),
            ),
          ]);

          // Find users who have NO posts
          final users = await dataSource.context
              .query<User>()
              .whereNotExists(
                dataSource.context.query<Post>().whereColumn(
                  'authorId',
                  'users.id',
                ),
              )
              .get();

          expect(users, hasLength(2));
          expect(users.map((u) => u.id), containsAll([2, 3]));
        },
      );

      test('whereNotExists returns all when subquery empty', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: true),
        ]);

        final users = await dataSource.context
            .query<User>()
            .whereNotExists(
              dataSource.context.query<Post>().whereColumn(
                'authorId',
                'users.id',
              ),
            )
            .get();

        expect(users, hasLength(2));
      });
    });

    group('OR variants', () {
      test('orWhereInSubquery combines with OR logic', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: false),
          User(id: 3, email: 'charlie@example.com', active: false),
        ]);

        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 3,
            title: 'Post 1',
            publishedAt: DateTime.now(),
          ),
        ]);

        // Find users who are active OR have posts
        final users = await dataSource.context
            .query<User>()
            .where('active', true)
            .orWhereInSubquery(
              'id',
              dataSource.context.query<Post>().select(['authorId']),
            )
            .get();

        expect(users, hasLength(2));
        expect(users.map((u) => u.id), containsAll([1, 3]));
      });

      test('orWhereExists combines with OR logic', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: false),
          User(id: 3, email: 'charlie@example.com', active: false),
        ]);

        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 2,
            title: 'Post 1',
            publishedAt: DateTime.now(),
          ),
        ]);

        // Find users who are active OR have posts
        final users = await dataSource.context
            .query<User>()
            .where('active', true)
            .orWhereExists(
              dataSource.context.query<Post>().whereColumn(
                'authorId',
                'users.id',
              ),
            )
            .get();

        expect(users, hasLength(2));
        expect(users.map((u) => u.id), containsAll([1, 2]));
      });
    });

    group('Complex subquery scenarios', () {
      test('chaining multiple subquery conditions', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: true),
          User(id: 3, email: 'charlie@example.com', active: true),
        ]);

        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 2,
            authorId: 2,
            title: 'Post 2',
            publishedAt: DateTime.now(),
          ),
        ]);

        // Find users who have posts AND are active
        final users = await dataSource.context
            .query<User>()
            .where('active', true)
            .whereExists(
              dataSource.context.query<Post>().whereColumn(
                'authorId',
                'users.id',
              ),
            )
            .get();

        expect(users, hasLength(2));
      });

      test('combining whereIn and whereExists', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'alice@example.com', active: true),
          User(id: 2, email: 'bob@example.com', active: true),
        ]);

        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime.now(),
          ),
        ]);

        final users = await dataSource.context
            .query<User>()
            .whereInSubquery(
              'id',
              dataSource.context.query<Post>().select(['authorId']),
            )
            .whereExists(
              dataSource.context.query<Post>().whereColumn(
                'authorId',
                'users.id',
              ),
            )
            .get();

        expect(users, hasLength(1));
        expect(users.first.id, 1);
      });
    });
  });
}
