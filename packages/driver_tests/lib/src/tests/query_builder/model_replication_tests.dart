import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runModelReplicationTests() {
  ormedGroup('Model Replication & Comparison (Laravel-inspired)', (dataSource) {
    group('replicate()', () {
      test('clones model without primary key', () async {
        // Create and save original
        final original = User(
          id: 100,
          email: 'original@example.com',
          name: 'Original User',
          active: true,
        );
        await dataSource.repo<User>().insert(original);

        // Fetch tracked model from database
        final tracked = await dataSource.context
            .query<User>()
            .where('id', 100)
            .first();

        // Replicate the tracked model
        final replica = tracked!.replicate();

        // Replica should have default id (0) since id is required and codec provides default
        expect(replica.id, 0);
        expect(replica.email, 'original@example.com');
        expect(replica.name, 'Original User');
        expect(replica.active, true);
      });

      test('clones model with custom exclusions', () async {
        final original = User(
          id: 101,
          email: 'test@example.com',
          name: 'Test User',
          active: true,
        );
        await dataSource.repo<User>().insert(original);

        // Fetch tracked model
        final tracked = await dataSource.context
            .query<User>()
            .where('id', 101)
            .first();

        // Replicate but exclude name (a nullable field)
        final replica = tracked!.replicate(except: ['name']);
        expect(replica.id, 0); // Default value from codec
        expect(replica.email, 'test@example.com'); // Included
        expect(replica.name, isNull); // Excluded
        expect(replica.active, true);
      });

      test('replicated model can be saved independently', () async {
        final original = User(
          id: 102,
          email: 'original@example.com',
          name: 'Original',
          active: true,
        );
        await dataSource.repo<User>().insert(original);

        // Fetch tracked model
        final tracked = await dataSource.context
            .query<User>()
            .where('id', 102)
            .first();

        // Replicate and modify
        final replica = tracked!.replicate();
        replica.setAttribute('email', 'replica@example.com');
        replica.setAttribute('name', 'Replica');

        // Save replica
        await dataSource.repo<User>().insert(replica);

        // Both should exist in database
        final allUsers = await dataSource.context.query<User>().get();
        expect(allUsers.length, greaterThanOrEqualTo(2));

        final originalFromDb = await dataSource.context
            .query<User>()
            .where('email', 'original@example.com')
            .first();
        expect(originalFromDb?.name, 'Original');

        final replicaFromDb = await dataSource.context
            .query<User>()
            .where('email', 'replica@example.com')
            .first();
        expect(replicaFromDb?.name, 'Replica');
      });

      test('excludes timestamp fields by default', () async {
        final original = User(
          id: 103,
          email: 'timestamp@example.com',
          name: 'Timestamp Test',
          active: true,
        );
        await dataSource.repo<User>().insert(original);

        // Fetch tracked model
        final tracked = await dataSource.context
            .query<User>()
            .where('id', 103)
            .first();

        final replica = tracked!.replicate();

        // Timestamps should be excluded
        expect(replica.createdAt, isNull);
        // When saved, new timestamps will be generated
      });
    });

    group('isSameAs()', () {
      test('returns true for same database record', () async {
        final user1 = User(id: 200, email: 'same@example.com', active: true);
        await dataSource.repo<User>().insert(user1);

        // Fetch same user twice
        final fetched1 = await dataSource.context.query<User>().find(200);
        final fetched2 = await dataSource.context.query<User>().find(200);

        expect(fetched1, isNotNull);
        expect(fetched2, isNotNull);
        expect(fetched1!.isSameAs(fetched2), true);
      });

      test('returns false for different records', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 201, email: 'user1@example.com', active: true),
          User(id: 202, email: 'user2@example.com', active: true),
        ]);

        final user1 = await dataSource.context.query<User>().find(201);
        final user2 = await dataSource.context.query<User>().find(202);

        expect(user1, isNotNull);
        expect(user2, isNotNull);
        expect(user1!.isSameAs(user2), false);
      });

      test('returns false when other is null', () async {
        final user = User(id: 203, email: 'null@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Fetch tracked model
        final tracked = await dataSource.context.query<User>().find(203);

        expect(tracked!.isSameAs(null), false);
      });

      test('returns false for different model types', () async {
        final user = User(id: 204, email: 'user@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final post = Post(
          id: 204,
          authorId: 1,
          title: 'Test Post',
          publishedAt: DateTime.now(),
        );
        await dataSource.repo<Post>().insert(post);

        // Fetch tracked models
        final trackedUser = await dataSource.context.query<User>().find(204);
        final trackedPost = await dataSource.context.query<Post>().find(204);

        // Same ID but different tables
        expect(trackedUser!.isSameAs(trackedPost as Model), false);
      });
    });

    group('isDifferentFrom()', () {
      test('returns false for same record', () async {
        final user = User(id: 300, email: 'same@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final fetched1 = await dataSource.context.query<User>().find(300);
        final fetched2 = await dataSource.context.query<User>().find(300);

        expect(fetched1, isNotNull);
        expect(fetched2, isNotNull);
        expect(fetched1!.isDifferentFrom(fetched2), false);
      });

      test('returns true for different records', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 301, email: 'user1@example.com', active: true),
          User(id: 302, email: 'user2@example.com', active: true),
        ]);

        final user1 = await dataSource.context.query<User>().find(301);
        final user2 = await dataSource.context.query<User>().find(302);

        expect(user1, isNotNull);
        expect(user2, isNotNull);
        expect(user1!.isDifferentFrom(user2), true);
      });
    });

    group('Integration tests', () {
      test('replicate and compare workflow', () async {
        // Create original
        final original = User(
          id: 400,
          email: 'workflow@example.com',
          name: 'Original',
          active: true,
        );
        await dataSource.repo<User>().insert(original);

        // Fetch tracked model from database
        final trackedOriginal = await dataSource.context
            .query<User>()
            .where('id', 400)
            .first();

        // Replicate
        final replica = trackedOriginal!.replicate();
        replica.setAttribute('email', 'replica@example.com');

        // Original and replica are different before save
        expect(trackedOriginal.isDifferentFrom(replica), true);

        // Save replica
        await dataSource.repo<User>().insert(replica);

        // Fetch both from database
        final originalFromDb = await dataSource.context
            .query<User>()
            .where('email', 'workflow@example.com')
            .first();

        final replicaFromDb = await dataSource.context
            .query<User>()
            .where('email', 'replica@example.com')
            .first();

        // Should be different records
        expect(originalFromDb!.isDifferentFrom(replicaFromDb), true);

        // Original from DB should match the tracked original
        expect(originalFromDb.isSameAs(trackedOriginal), true);

        // Replica from DB should have different id than original
        expect(replicaFromDb, isNotNull);
        expect(replicaFromDb!.id, isNot(trackedOriginal.id));
        expect(replicaFromDb.email, 'replica@example.com');
      });
    });
  });
}
