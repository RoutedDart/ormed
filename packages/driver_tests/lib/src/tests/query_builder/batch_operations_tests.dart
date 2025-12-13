import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runBatchOperationsTests() {
  ormedGroup('Batch Operations', (dataSource) {
    group('insertGetIds', () {
      test('inserts multiple records sequentially', () async {
        final users = [
          User(id: 1, email: 'user1@example.com', active: true),
          User(id: 2, email: 'user2@example.com', active: true),
          User(id: 3, email: 'user3@example.com', active: false),
        ];

        // Note: insertGetIds is a placeholder - for now we'll test basic insert
        await dataSource.repo<User>().insertMany(users);

        final allUsers = await dataSource.context.query<User>().get();
        expect(allUsers, hasLength(3));
      });

      test('insertMany works with multiple records', () async {
        final users = [
          User(id: 10, email: 'alice@example.com', name: 'Alice', active: true),
          User(id: 11, email: 'bob@example.com', name: 'Bob', active: true),
          User(
            id: 12,
            email: 'charlie@example.com',
            name: 'Charlie',
            active: true,
          ),
        ];

        await dataSource.repo<User>().insertMany(users);

        // Verify insertion
        final alice = await dataSource.context
            .query<User>()
            .where('email', 'alice@example.com')
            .first();
        expect(alice?.name, 'Alice');
      });
    });

    group('updateBatch', () {
      test('updates multiple rows in one batch', () async {
        // Insert test users
        final users = [
          User(id: 100, email: 'user100@example.com', active: true),
          User(id: 101, email: 'user101@example.com', active: true),
          User(id: 102, email: 'user102@example.com', active: false),
        ];
        await dataSource.repo<User>().insertMany(users);

        // Update using updateBatch
        final updatedCount = await dataSource.context.query<User>().updateBatch(
          [
            {'id': 100, 'active': false, 'name': 'Updated 1'},
            {'id': 101, 'active': false, 'name': 'Updated 2'},
            {'id': 102, 'active': true, 'name': 'Updated 3'},
          ],
          uniqueBy: 'id',
        );

        expect(updatedCount, greaterThanOrEqualTo(3));

        // Verify updates
        final updated1 = await dataSource.context
            .query<User>()
            .where('id', 100)
            .first();
        expect(updated1?.active, isFalse);
        expect(updated1?.name, 'Updated 1');
      });

      test('updateBatch with empty updates returns 0', () async {
        final updatedCount = await dataSource.context.query<User>().updateBatch(
          [],
          uniqueBy: 'id',
        );

        expect(updatedCount, 0);
      });

      test('updateBatch updates only specified columns', () async {
        // Insert user
        final user = User(
          id: 200,
          email: 'user200@example.com',
          name: 'Original Name',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        // Update only name and active
        await dataSource.context.query<User>().updateBatch([
          {'id': 200, 'name': 'Updated Name', 'active': false},
        ], uniqueBy: 'id');

        // Verify only specified columns changed
        final updated = await dataSource.context
            .query<User>()
            .where('id', 200)
            .first();
        expect(updated?.name, 'Updated Name');
        expect(updated?.active, isFalse);
        expect(updated?.email, 'user200@example.com'); // Should not change
      });

      test('updates different columns per row', () async {
        // Insert posts
        final posts = [
          Post(
            id: 300,
            authorId: 1,
            title: 'Post 300',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 301,
            authorId: 1,
            title: 'Post 301',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 302,
            authorId: 2,
            title: 'Post 302',
            publishedAt: DateTime.now(),
          ),
        ];
        await dataSource.repo<Post>().insertMany(posts);

        // Update different columns for different rows
        await dataSource.context.query<Post>().updateBatch([
          {'id': 300, 'title': 'Updated 300'},
          {'id': 301, 'title': 'Updated 301'},
          {'id': 302, 'title': 'Updated 302', 'authorId': 3},
        ], uniqueBy: 'id');

        // Verify each update
        final post300 = await dataSource.context
            .query<Post>()
            .where('id', 300)
            .first();
        expect(post300?.title, 'Updated 300');
        expect(post300?.authorId, 1); // Unchanged

        final post302 = await dataSource.context
            .query<Post>()
            .where('id', 302)
            .first();
        expect(post302?.title, 'Updated 302');
        expect(post302?.authorId, 3); // Changed
      });

      test('updateBatch with null values', () async {
        // Insert user
        final user = User(
          id: 400,
          email: 'user400@example.com',
          name: 'Test User',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        // Update with null values
        await dataSource.context.query<User>().updateBatch([
          {'id': 400, 'name': null, 'active': false},
        ], uniqueBy: 'id');

        // Verify null update
        final updated = await dataSource.context
            .query<User>()
            .where('id', 400)
            .first();
        expect(updated?.name, isNull);
        expect(updated?.active, isFalse);
      });
    });

    group('Batch Operations Combined', () {
      test('insert then update batch', () async {
        // Insert users
        final users = [
          User(
            id: 500,
            email: 'batch1@example.com',
            name: 'Batch 1',
            active: true,
          ),
          User(
            id: 501,
            email: 'batch2@example.com',
            name: 'Batch 2',
            active: true,
          ),
        ];
        await dataSource.repo<User>().insertMany(users);

        // Update the batch
        await dataSource.context.query<User>().updateBatch([
          {'id': 500, 'active': false},
          {'id': 501, 'active': false},
        ], uniqueBy: 'id');

        // Verify both operations
        final all = await dataSource.context
            .query<User>()
            .where('email', 'batch1@example.com')
            .orWhere('email', 'batch2@example.com')
            .get();

        expect(all, hasLength(2));
        expect(all.every((u) => !u.active), isTrue);
      });

      test('batch operations with related records', () async {
        // Insert authors
        final authors = [
          Author(id: 600, name: 'Author A'),
          Author(id: 601, name: 'Author B'),
          Author(id: 602, name: 'Author C'),
        ];
        await dataSource.repo<Author>().insertMany(authors);

        // Insert posts
        final posts = [
          Post(
            id: 600,
            authorId: 600,
            title: 'A1',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 601,
            authorId: 600,
            title: 'A2',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 602,
            authorId: 601,
            title: 'B1',
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 603,
            authorId: 602,
            title: 'C1',
            publishedAt: DateTime.now(),
          ),
        ];
        await dataSource.repo<Post>().insertMany(posts);

        // Update posts in batch
        await dataSource.context.query<Post>().updateBatch([
          {'id': 600, 'title': 'Updated A1'},
          {'id': 601, 'title': 'Updated A2'},
          {'id': 602, 'title': 'Updated B1'},
          {'id': 603, 'title': 'Updated C1'},
        ], uniqueBy: 'id');

        // Verify all updated
        final allPosts = await dataSource.context.query<Post>().get();
        expect(allPosts.where((p) => p.id >= 600 && p.id <= 603), hasLength(4));
      });
    });
  });
}
