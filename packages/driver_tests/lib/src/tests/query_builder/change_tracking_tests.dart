import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

/// Tests for model change tracking methods (isDirty, getOriginal, etc.)
void runChangeTrackingTests() {
  ormedGroup('Change Tracking', (dataSource) {
    group('syncOriginal()', () {
      test('marks current state as original', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Fetch from database (should auto-sync original)
        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(fetched, isNotNull);
        expect(fetched!.isDirty(), false);

        // Make changes
        fetched.setAttribute('name', 'Changed');
        expect(fetched.isDirty(), true);

        // Sync original
        fetched.syncOriginal();
        expect(fetched.isDirty(), false);
      });

      test('works with new unsaved models', () async {
        // Create and save a user to get a tracked model
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Fetch to get tracked model instance
        final tracked = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        // Tracked model from DB should not be dirty initially
        expect(tracked!.isDirty(), false);

        // Modify and sync
        tracked.setAttribute('name', 'Changed');
        expect(tracked.isDirty(), true);

        tracked.syncOriginal();
        expect(tracked.isDirty(), false);
      });
    });

    group('getOriginal()', () {
      test('returns original value for specific field', () async {
        final user = User(
          id: 1,
          email: 'original@example.com',
          name: 'Original Name',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        fetched!.setAttribute('name', 'Changed Name');
        fetched.setAttribute('email', 'changed@example.com');

        expect(fetched.getOriginal('name'), 'Original Name');
        expect(fetched.getOriginal('email'), 'original@example.com');
        expect(fetched.getAttribute('name'), 'Changed Name');
      });

      test('returns full original map when no key provided', () async {
        final user = User(
          id: 1,
          email: 'original@example.com',
          name: 'Original',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        fetched!.setAttribute('name', 'Changed');

        final original = fetched.getOriginal() as Map<String, Object?>;
        expect(original['name'], 'Original');
        expect(original['email'], 'original@example.com');
      });

      test('syncOriginal refreshes baseline for new attributes', () async {
        // Create and save to get tracked model
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final tracked = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        // Original should exist for fetched model
        expect(tracked!.getOriginal('email'), 'test@example.com');

        // For attributes we add after fetch, original is the db value (null for unset fields)
        tracked.setAttribute('name', 'Test');
        expect(tracked.getOriginal('name'), null);

        // After syncing original, changes can be tracked
        tracked.syncOriginal();
        tracked.setAttribute('name', 'Changed');
        expect(tracked.getOriginal('name'), 'Test');
      });
    });

    group('isDirty()', () {
      test('returns false for freshly fetched models', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(fetched!.isDirty(), false);
        expect(fetched.isDirty('email'), false);
        expect(fetched.isDirty('active'), false);
      });

      test('returns true after modifying attributes', () async {
        final user = User(
          id: 1,
          email: 'test@example.com',
          name: 'Original',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        fetched!.setAttribute('name', 'Changed');

        expect(fetched.isDirty(), true);
        expect(fetched.isDirty('name'), true);
        expect(fetched.isDirty('email'), false);
      });

      test('detects multiple dirty fields', () async {
        final user = User(
          id: 1,
          email: 'original@example.com',
          name: 'Original',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        fetched!.setAttribute('name', 'Changed');
        fetched.setAttribute('email', 'changed@example.com');
        fetched.setAttribute('active', false);

        expect(fetched.isDirty(), true);
        expect(fetched.isDirty('name'), true);
        expect(fetched.isDirty('email'), true);
        expect(fetched.isDirty('active'), true);
      });

      test('returns false for new models with no original', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);

        expect(user.isDirty(), false);
        expect(user.isDirty('email'), false);
      });
    });

    group('getDirty() / getChanges()', () {
      test('returns empty map when no changes', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(fetched!.getDirty(), isEmpty);
        expect(fetched.getChanges(), isEmpty);
      });

      test('returns changed attributes with new values', () async {
        final user = User(
          id: 1,
          email: 'original@example.com',
          name: 'Original',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        fetched!.setAttribute('name', 'Changed');
        fetched.setAttribute('email', 'changed@example.com');

        final dirty = fetched.getDirty();
        expect(dirty, hasLength(2));
        expect(dirty['name'], 'Changed');
        expect(dirty['email'], 'changed@example.com');

        // getChanges() is an alias
        expect(fetched.getChanges(), equals(dirty));
      });

      test('only includes changed fields', () async {
        final user = User(
          id: 1,
          email: 'test@example.com',
          name: 'Original',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        // Only change name
        fetched!.setAttribute('name', 'Changed');

        final dirty = fetched.getDirty();
        expect(dirty, hasLength(1));
        expect(dirty['name'], 'Changed');
        expect(dirty.containsKey('email'), false);
      });

      test('returns empty map for new models', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);

        expect(user.getDirty(), isEmpty);
        expect(user.getChanges(), isEmpty);
      });
    });

    group('Integration', () {
      test('change tracking works through full lifecycle', () async {
        // Create and insert
        final user = User(
          id: 1,
          email: 'test@example.com',
          name: 'Original',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        // Fetch (should auto-sync original)
        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        expect(fetched!.isDirty(), false);

        // Modify
        fetched.setAttribute('name', 'Modified');
        expect(fetched.isDirty(), true);
        expect(fetched.isDirty('name'), true);
        expect(fetched.getOriginal('name'), 'Original');
        expect(fetched.getAttribute('name'), 'Modified');

        // Sync original
        fetched.syncOriginal();
        expect(fetched.isDirty(), false);
        expect(fetched.getOriginal('name'), 'Modified'); // Now this is original
      });

      test('multiple changes tracked correctly', () async {
        final user = User(
          id: 1,
          email: 'original@example.com',
          name: 'Original Name',
          active: true,
        );
        await dataSource.repo<User>().insert(user);

        final fetched = await dataSource.context
            .query<User>()
            .where('id', 1)
            .first();

        // Make multiple changes
        fetched!.setAttribute('name', 'Name 1');
        expect(fetched.getDirty(), {'name': 'Name 1'});

        fetched.setAttribute('email', 'email1@example.com');
        expect(fetched.getDirty(), {
          'name': 'Name 1',
          'email': 'email1@example.com',
        });

        fetched.setAttribute('active', false);
        expect(fetched.getDirty(), {
          'name': 'Name 1',
          'email': 'email1@example.com',
          'active': false,
        });
      });
    });
  });
}
