import 'package:driver_tests/models.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

/// Runs comprehensive upsert operation tests for the query builder.
///
/// These tests verify:
/// - Basic upsert operations (insert when not exists)
/// - Upsert updates (update when exists)
/// - Upsert with custom uniqueBy columns
/// - Upsert with selective updateColumns
/// - Batch upsert operations
/// - Edge cases and error handling
void runUpsertOperationsTests(DataSource dataSource) {
  final metadata = dataSource.connection.driver.metadata;

  group('Upsert Operations', () {
    test('upsert() inserts new record', () async {
      final user = await dataSource.query<User>().upsert({
        'id': 10000,
        'email': 'newuser@example.com',
        'active': true,
      });

      expect(user.id, 10000);
      expect(user.email, 'newuser@example.com');
      expect(user.active, isTrue);

      // Verify it was actually inserted
      final fetched = await dataSource
          .query<User>()
          .whereEquals('id', 10000)
          .first();
      expect(fetched, isNotNull);
      expect(fetched?.email, 'newuser@example.com');
    });

    test('upsert() updates existing record by primary key', () async {
      // Insert initial record
      await dataSource.query<User>().create({
        'id': 10001,
        'email': 'original@example.com',
        'active': true,
      });

      // Upsert with same ID should update
      final updated = await dataSource.query<User>().upsert({
        'id': 10001,
        'email': 'updated@example.com',
        'active': false,
      });

      expect(updated.id, 10001);
      expect(updated.email, 'updated@example.com');
      expect(updated.active, isFalse);

      // Verify only one record exists
      final all = await dataSource.query<User>().whereEquals('id', 10001).get();
      expect(all.length, 1);
    });

    test('upsert() with custom uniqueBy column', () async {
      // Insert with specific email
      await dataSource.query<User>().create({
        'id': 10002,
        'email': 'unique@example.com',
        'active': false,
      });

      // Upsert with same email should update (even with different ID)
      final updated = await dataSource.query<User>().upsert(
        {'id': 10003, 'email': 'unique@example.com', 'active': true},
        uniqueBy: ['email'],
      );

      expect(updated.email, 'unique@example.com');
      expect(updated.active, isTrue);

      // Verify only one record with this email exists
      final all = await dataSource
          .query<User>()
          .whereEquals('email', 'unique@example.com')
          .get();
      expect(all.length, 1);
    });

    test('upsert() with updateColumns restricts what is updated', () async {
      // Insert initial record
      await dataSource.query<User>().create({
        'id': 10004,
        'email': 'selective@example.com',
        'active': true,
      });

      // Upsert with selective update (only email)
      final updated = await dataSource.query<User>().upsert(
        {'id': 10004, 'email': 'newemail@example.com', 'active': false},
        updateColumns: ['email'],
      );

      expect(updated.email, 'newemail@example.com');
      // active should still be true since we didn't update it
      expect(updated.active, isTrue);
    });

    test('upsertMany() inserts multiple new records', () async {
      final users = await dataSource.query<User>().upsertMany([
        {'id': 10010, 'email': 'batch1@example.com', 'active': true},
        {'id': 10011, 'email': 'batch2@example.com', 'active': true},
        {'id': 10012, 'email': 'batch3@example.com', 'active': false},
      ]);

      expect(users.length, 3);
      expect(users[0].email, 'batch1@example.com');
      expect(users[1].email, 'batch2@example.com');
      expect(users[2].email, 'batch3@example.com');

      // Verify all were inserted
      final all = await dataSource.query<User>().whereIn('id', [
        10010,
        10011,
        10012,
      ]).get();
      expect(all.length, 3);
    });

    test('upsertMany() updates existing records', () async {
      // Insert initial records
      await dataSource.query<User>().createMany([
        {'id': 10020, 'email': 'update1@example.com', 'active': true},
        {'id': 10021, 'email': 'update2@example.com', 'active': true},
      ]);

      // Upsert with updates
      final updated = await dataSource.query<User>().upsertMany([
        {'id': 10020, 'email': 'updated1@example.com', 'active': false},
        {'id': 10021, 'email': 'updated2@example.com', 'active': false},
      ]);

      expect(updated.length, 2);
      expect(updated[0].email, 'updated1@example.com');
      expect(updated[0].active, isFalse);
      expect(updated[1].email, 'updated2@example.com');
      expect(updated[1].active, isFalse);
    });

    test('upsertMany() handles mix of inserts and updates', () async {
      // Insert one record
      await dataSource.query<User>().create({
        'id': 10030,
        'email': 'existing@example.com',
        'active': true,
      });

      // Upsert with one update and two inserts
      final results = await dataSource.query<User>().upsertMany([
        {
          'id': 10030,
          'email': 'updated@example.com',
          'active': false,
        }, // Update
        {'id': 10031, 'email': 'new1@example.com', 'active': true}, // Insert
        {'id': 10032, 'email': 'new2@example.com', 'active': true}, // Insert
      ]);

      expect(results.length, 3);
      expect(results[0].email, 'updated@example.com');
      expect(results[1].email, 'new1@example.com');
      expect(results[2].email, 'new2@example.com');
    });

    test('upsertMany() with custom uniqueBy', () async {
      // Insert initial records
      await dataSource.query<User>().createMany([
        {'id': 10040, 'email': 'email1@example.com', 'active': true},
        {'id': 10041, 'email': 'email2@example.com', 'active': true},
      ]);

      // Upsert using email as unique key
      final results = await dataSource.query<User>().upsertMany(
        [
          {
            'id': 10099,
            'email': 'email1@example.com',
            'active': false,
          }, // Should update 10040
          {
            'id': 10098,
            'email': 'email3@example.com',
            'active': true,
          }, // Should insert new
        ],
        uniqueBy: ['email'],
      );

      expect(results.length, 2);

      // Verify email1 was updated
      final user1 = await dataSource
          .query<User>()
          .whereEquals('email', 'email1@example.com')
          .first();
      expect(user1?.active, isFalse);

      // Verify email3 was inserted
      final user3 = await dataSource
          .query<User>()
          .whereEquals('email', 'email3@example.com')
          .first();
      expect(user3, isNotNull);
    });

    test('upsertMany() with updateColumns', () async {
      // Insert initial records
      await dataSource.query<User>().createMany([
        {'id': 10050, 'email': 'col1@example.com', 'active': true},
        {'id': 10051, 'email': 'col2@example.com', 'active': true},
      ]);

      // Upsert with selective updates (only active)
      final results = await dataSource.query<User>().upsertMany(
        [
          {'id': 10050, 'email': 'newemail1@example.com', 'active': false},
          {'id': 10051, 'email': 'newemail2@example.com', 'active': false},
        ],
        updateColumns: ['active'],
      );

      expect(results.length, 2);

      // Emails should not have changed
      expect(results[0].email, 'col1@example.com');
      expect(results[1].email, 'col2@example.com');

      // Active should have changed
      expect(results[0].active, isFalse);
      expect(results[1].active, isFalse);
    });

    test('upsertMany() with empty list returns empty', () async {
      final results = await dataSource.query<User>().upsertMany([]);
      expect(results, isEmpty);
    });

    test('upsert() throws on failure', () async {
      // This should fail for models without primary key
      // But User has primary key, so we test validation
      expect(() => dataSource.query<User>().upsert({}), throwsA(isA<Error>()));
    });

    test('upsert() works with Posts model', () async {
      // First create an author
      final author = await dataSource.query<Author>().create({
        'id': 20000,
        'name': 'Test Author',
        'active': true,
      });

      // Test upsert with Posts
      final post = await dataSource.query<Post>().upsert({
        'id': 30000,
        'title': 'Test Post',
        'content': 'Content',
        'authorId': author.id,
        'publishedAt': DateTime.now(),
      });

      expect(post.id, 30000);
      expect(post.title, 'Test Post');

      // Update the post
      final updated = await dataSource.query<Post>().upsert({
        'id': 30000,
        'title': 'Updated Post',
        'content': 'Updated Content',
        'authorId': author.id,
        'publishedAt': DateTime.now(),
      });

      expect(updated.title, 'Updated Post');
      expect(updated.content, 'Updated Content');
    });

    test('upsert() handles datetime fields correctly', () async {
      final author = await dataSource.query<Author>().create({
        'id': 20001,
        'name': 'Author with DateTime',
        'active': true,
      });

      // Posts have publishedAt
      final now = DateTime.now();
      final post = await dataSource.query<Post>().upsert({
        'id': 30001,
        'title': 'Timestamped Post',
        'content': 'Content',
        'authorId': author.id,
        'publishedAt': now.toIso8601String(),
      });

      expect(post.publishedAt, isNotNull);
    });

    test('upsertMany() handles large batches', () async {
      // Create author for posts
      final author = await dataSource.query<Author>().create({
        'id': 20002,
        'name': 'Batch Author',
        'active': true,
      });

      // Generate large batch
      final batch = List.generate(
        50,
        (i) => {
          'id': 30100 + i,
          'title': 'Post $i',
          'content': 'Content $i',
          'authorId': author.id,
          'publishedAt': DateTime.now(),
        },
      );

      final results = await dataSource.query<Post>().upsertMany(batch);
      expect(results.length, 50);

      // Verify all were inserted
      final all = await dataSource
          .query<Post>()
          .where('id', 30100, PredicateOperator.greaterThanOrEqual)
          .where('id', 30150, PredicateOperator.lessThan)
          .get();
      expect(all.length, 50);
    });

    test('upsert() with uniqueBy validates column exists', () async {
      // Should throw when specifying non-existent column
      expect(
        () => dataSource.query<User>().upsert(
          {'id': 10060, 'email': 'test@example.com', 'active': true},
          uniqueBy: ['nonexistent_column'],
        ),
        throwsA(isA<Error>()),
      );
    });

    test(
      'upsert() maintains data integrity across multiple operations',
      () async {
        final userId = 10070;

        // Initial insert
        final user1 = await dataSource.query<User>().upsert({
          'id': userId,
          'email': 'integrity@example.com',
          'active': true,
        });
        expect(user1.active, isTrue);

        // First update
        final user2 = await dataSource.query<User>().upsert({
          'id': userId,
          'email': 'integrity@example.com',
          'active': false,
        });
        expect(user2.active, isFalse);

        // Second update
        final user3 = await dataSource.query<User>().upsert({
          'id': userId,
          'email': 'integrity-updated@example.com',
          'active': true,
        });
        expect(user3.email, 'integrity-updated@example.com');
        expect(user3.active, isTrue);

        // Verify only one record exists
        final all = await dataSource
            .query<User>()
            .whereEquals('id', userId)
            .get();
        expect(all.length, 1);
        expect(all.first.email, 'integrity-updated@example.com');
      },
    );

    test('upsertMany() is atomic for batch operations', () async {
      // Create initial state
      await dataSource.query<User>().createMany([
        {'id': 10080, 'email': 'atomic1@example.com', 'active': true},
        {'id': 10081, 'email': 'atomic2@example.com', 'active': true},
      ]);

      // Batch upsert
      final results = await dataSource.query<User>().upsertMany([
        {'id': 10080, 'email': 'atomic1@example.com', 'active': false},
        {'id': 10081, 'email': 'atomic2@example.com', 'active': false},
        {'id': 10082, 'email': 'atomic3@example.com', 'active': true},
      ]);

      expect(results.length, 3);

      // Verify final state
      final all = await dataSource
          .query<User>()
          .whereIn('id', [10080, 10081, 10082])
          .orderBy('id')
          .get();

      expect(all.length, 3);
      expect(all[0].active, isFalse); // Updated
      expect(all[1].active, isFalse); // Updated
      expect(all[2].active, isTrue); // Inserted
    });

    test('upsert() respects driver capabilities', () async {
      // This test just verifies upsert executes successfully
      // The driver handles native vs emulated internally
      final user = await dataSource.query<User>().upsert({
        'id': 10090,
        'email': 'capabilities@example.com',
        'active': true,
      });

      expect(user.id, 10090);
      expect(user.email, 'capabilities@example.com');

      // Verify driver metadata if available
      print('Driver: ${metadata.name}');
      print('Supports returning: ${metadata.supportsReturning}');
    });
  });
}
