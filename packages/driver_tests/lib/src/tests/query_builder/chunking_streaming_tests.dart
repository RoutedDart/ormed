import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runChunkingStreamingTests() {
  ormedGroup('Chunking & Streaming Operations', (dataSource) {
    test('chunk - processes records in batches', () async {
      // Insert 250 users
      final users = List.generate(
        250,
        (i) => User(id: i + 1, email: 'user${i + 1}@test.com', active: true),
      );
      await dataSource.repo<User>().insertMany(users);

      var processedCount = 0;
      var chunkCount = 0;

      await dataSource.context.query<User>().chunk(100, (chunk) async {
        chunkCount++;
        processedCount += chunk.length;
        expect(chunk.length, lessThanOrEqualTo(100));
        return true; // Continue processing
      });

      expect(chunkCount, 3); // 100, 100, 50
      expect(processedCount, 250);
    });

    test('chunk - can stop early by returning false', () async {
      final users = List.generate(
        100,
        (i) => User(id: i + 1, email: 'user${i + 1}@test.com', active: true),
      );
      await dataSource.repo<User>().insertMany(users);

      var chunkCount = 0;

      await dataSource.context.query<User>().chunk(30, (chunk) async {
        chunkCount++;
        return chunkCount < 2; // Stop after 2 chunks
      });

      expect(chunkCount, 2);
    });

    test('chunk - works with WHERE clauses', () async {
      final users = List.generate(
        150,
        (i) => User(
          id: i + 1,
          email: 'user${i + 1}@test.com',
          active: i % 2 == 0, // Half active, half inactive
        ),
      );
      await dataSource.repo<User>().insertMany(users);

      var processedCount = 0;

      await dataSource.context.query<User>().whereEquals('active', true).chunk(
        50,
        (chunk) async {
          processedCount += chunk.length;
          return true;
        },
      );

      expect(processedCount, 75); // Half of 150
    });

    test('stream - iterates over all records', () async {
      final users = List.generate(
        50,
        (i) => User(id: i + 1, email: 'user${i + 1}@test.com', active: true),
      );
      await dataSource.repo<User>().insertMany(users);

      var count = 0;
      await for (final user in dataSource.context.query<User>().stream()) {
        count++;
        expect(user.id, greaterThan(0));
      }

      expect(count, 50);
    });

    test('stream - works with WHERE clauses', () async {
      final users = List.generate(
        100,
        (i) => User(
          id: i + 1,
          email: 'user${i + 1}@test.com',
          active: i < 30, // First 30 are active
        ),
      );
      await dataSource.repo<User>().insertMany(users);

      var count = 0;
      await for (final user
          in dataSource.context
              .query<User>()
              .whereEquals('active', true)
              .stream()) {
        count++;
        expect(user.active, isTrue);
      }

      expect(count, 30);
    });

    test('stream - can break early', () async {
      final users = List.generate(
        100,
        (i) => User(id: i + 1, email: 'user${i + 1}@test.com', active: true),
      );
      await dataSource.repo<User>().insertMany(users);

      var count = 0;
      await for (final _ in dataSource.context.query<User>().stream()) {
        count++;
        if (count >= 25) break;
      }

      expect(count, 25);
    });

    test('each - iterates with callback', () async {
      final users = List.generate(
        30,
        (i) => User(id: i + 1, email: 'user${i + 1}@test.com', active: true),
      );
      await dataSource.repo<User>().insertMany(users);

      var count = 0;
      await dataSource.context.query<User>().each((user) async {
        count++;
        expect(user.id, greaterThan(0));
      });

      expect(count, 30);
    });

    test('chunk with complex query - with filtering', () async {
      await dataSource.repo<Author>().insertMany([
        Author(id: 1, name: 'Author 1'),
        Author(id: 2, name: 'Author 2'),
      ]);

      final posts = List.generate(
        100,
        (i) => Post(
          id: i + 1,
          authorId: (i % 2) + 1,
          title: 'Post ${i + 1}',
          publishedAt: DateTime.now(),
        ),
      );
      await dataSource.repo<Post>().insertMany(posts);

      var chunkCount = 0;
      await dataSource.context.query<Post>().whereEquals('authorId', 1).chunk(
        25,
        (chunk) async {
          chunkCount++;
          for (final row in chunk) {
            expect(row.model.authorId, 1);
          }
          return true;
        },
      );

      expect(chunkCount, 2); // 50 posts for author 1 in chunks of 25
    });

    test('chunk with empty result set', () async {
      var chunkCount = 0;

      await dataSource.context
          .query<User>()
          .whereEquals('id', 99999) // Non-existent
          .chunk(100, (chunk) async {
            chunkCount++;
            return true;
          });

      expect(chunkCount, 0);
    });

    test('stream with empty result set', () async {
      var count = 0;

      await for (final _
          in dataSource.context
              .query<User>()
              .whereEquals('id', 99999)
              .stream()) {
        count++;
      }

      expect(count, 0);
    });
  });
}
