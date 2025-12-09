import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runCacheTests(DataSource dataSource) {
  group('Query Caching', () {
    setUp(() {
      // Clear cache before each test
      dataSource.context.flushQueryCache();
    });

    group('remember()', () {
      test('caches query results for specified duration', () async {
        // Insert test data
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // First query - cache miss
        final result1 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        expect(result1, hasLength(1));
        expect(result1.first.email, 'test@example.com');

        // Second identical query - cache hit (doesn't re-query)
        final result2 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        expect(result2, hasLength(1));
        expect(result2.first.email, 'test@example.com');
      });

      test('different queries produce different cache entries', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'user1@example.com', active: true),
          User(id: 2, email: 'user2@example.com', active: false),
        ]);

        // Query 1
        final activeUsers = await dataSource.context
            .query<User>()
            .where('active', true)
            .remember(Duration(minutes: 5))
            .get();

        // Query 2 - different WHERE clause
        final inactiveUsers = await dataSource.context
            .query<User>()
            .where('active', false)
            .remember(Duration(minutes: 5))
            .get();

        expect(activeUsers, hasLength(1));
        expect(inactiveUsers, hasLength(1));
        expect(activeUsers.first.email, 'user1@example.com');
        expect(inactiveUsers.first.email, 'user2@example.com');
      });

      test('cache respects query parameters', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'user1@example.com', active: true),
          User(id: 2, email: 'user2@example.com', active: true),
        ]);

        // Query with parameter 1
        final user1 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        // Query with parameter 2 - different cache key
        final user2 = await dataSource.context
            .query<User>()
            .where('id', 2)
            .remember(Duration(minutes: 5))
            .get();

        expect(user1.first.email, 'user1@example.com');
        expect(user2.first.email, 'user2@example.com');
      });

      test('cache works with complex queries', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            views: 100,
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 2,
            authorId: 1,
            title: 'Post 2',
            views: 200,
            publishedAt: DateTime.now(),
          ),
          Post(
            id: 3,
            authorId: 2,
            title: 'Post 3',
            views: 50,
            publishedAt: DateTime.now(),
          ),
        ]);

        final posts = await dataSource.context
            .query<Post>()
            .where('authorId', 1)
            .where('views', 150, PredicateOperator.greaterThan)
            .orderBy('views', descending: true)
            .remember(Duration(minutes: 5))
            .get();

        expect(posts, hasLength(1));
        expect(posts.first.title, 'Post 2');

        // Second call should hit cache
        final cachedPosts = await dataSource.context
            .query<Post>()
            .where('authorId', 1)
            .where('views', 150, PredicateOperator.greaterThan)
            .orderBy('views', descending: true)
            .remember(Duration(minutes: 5))
            .get();

        expect(cachedPosts, hasLength(1));
        expect(cachedPosts.first.title, 'Post 2');
      });
    });

    group('rememberForever()', () {
      test('caches query results indefinitely', () async {
        final user = User(id: 1, email: 'forever@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final result = await dataSource.context
            .query<User>()
            .where('id', 1)
            .rememberForever()
            .get();

        expect(result, hasLength(1));
        expect(result.first.email, 'forever@example.com');

        // Cache should persist
        final cached = await dataSource.context
            .query<User>()
            .where('id', 1)
            .rememberForever()
            .get();

        expect(cached, hasLength(1));
      });
    });

    group('dontRemember()', () {
      test('disables caching for specific query', () async {
        final user = User(id: 1, email: 'nocache@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Query without caching
        final result1 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .dontRemember()
            .get();

        expect(result1, hasLength(1));

        // Second query - should not use cache
        final result2 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .dontRemember()
            .get();

        expect(result2, hasLength(1));
      });
    });

    group('Cache management', () {
      test('flushQueryCache clears all cache entries', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'user1@example.com', active: true),
          User(id: 2, email: 'user2@example.com', active: true),
        ]);

        // Cache two queries
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        await dataSource.context
            .query<User>()
            .where('id', 2)
            .remember(Duration(minutes: 5))
            .get();

        // Verify cache has entries
        final statsBefore = dataSource.context.queryCacheStats;
        expect(statsBefore.totalEntries, greaterThan(0));

        // Flush cache
        dataSource.context.flushQueryCache();

        // Verify cache is empty
        final statsAfter = dataSource.context.queryCacheStats;
        expect(statsAfter.totalEntries, 0);
      });

      test('cache statistics are accurate', () async {
        final user = User(id: 1, email: 'stats@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Initially empty
        var stats = dataSource.context.queryCacheStats;
        expect(stats.totalEntries, 0);

        // Add cache entry
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(seconds: 1))
            .get();

        stats = dataSource.context.queryCacheStats;
        expect(stats.totalEntries, greaterThan(0));
        expect(stats.activeEntries, greaterThan(0));
      });
    });

    group('Cache with different query methods', () {
      test('caching works with first()', () async {
        final user = User(id: 1, email: 'first@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final result1 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .first();

        expect(result1?.email, 'first@example.com');

        // Second call should hit cache
        final result2 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .first();

        expect(result2?.email, 'first@example.com');
      });

      test('caching works with count()', () async {
        await dataSource.repo<User>().insertMany([
          User(id: 1, email: 'user1@example.com', active: true),
          User(id: 2, email: 'user2@example.com', active: true),
          User(id: 3, email: 'user3@example.com', active: false),
        ]);

        final count1 = await dataSource.context
            .query<User>()
            .where('active', true)
            .remember(Duration(minutes: 5))
            .count();

        expect(count1, 2);

        // Should hit cache
        final count2 = await dataSource.context
            .query<User>()
            .where('active', true)
            .remember(Duration(minutes: 5))
            .count();

        expect(count2, 2);
      });
    });

    group('Cache invalidation scenarios', () {
      test('mutations do not auto-invalidate cache', () async {
        final user = User(id: 1, email: 'original@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Cache the query
        final result1 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .first();

        expect(result1?.email, 'original@example.com');

        // Update the user
        await dataSource.context.query<User>().where('id', 1).update({
          'email': 'updated@example.com',
        });

        // Cache still returns old value (Laravel behavior)
        final result2 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .first();

        expect(result2?.email, 'original@example.com');

        // After flushing cache, get fresh data
        dataSource.context.flushQueryCache();

        final result3 = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .first();

        expect(result3?.email, 'updated@example.com');
      });

      test('manual cache flush enables fresh data retrieval', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Cache result
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        // Clear cache
        dataSource.context.flushQueryCache();

        // New query should fetch from database
        final fresh = await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        expect(fresh, hasLength(1));
      });
    });

    group('Cache Events', () {
      test('emits CacheHitEvent on cache hit', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final events = <CacheEvent>[];
        dataSource.context.queryCache.listen((event) {
          events.add(event);
        });

        // First query - cache miss
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        // Second query - cache hit
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        // Should have: CacheMissEvent, CacheStoreEvent, CacheHitEvent
        final hitEvents = events.whereType<CacheHitEvent>().toList();
        expect(hitEvents, isNotEmpty);
      });

      test('emits CacheMissEvent on cache miss', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final events = <CacheEvent>[];
        dataSource.context.queryCache.listen((event) {
          events.add(event);
        });

        // Query - cache miss
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        final missEvents = events.whereType<CacheMissEvent>().toList();
        expect(missEvents, isNotEmpty);
      });

      test('emits CacheStoreEvent when storing result', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final events = <CacheEvent>[];
        dataSource.context.queryCache.listen((event) {
          events.add(event);
        });

        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        final storeEvents = events.whereType<CacheStoreEvent>().toList();
        expect(storeEvents, isNotEmpty);
        expect(storeEvents.first.entryCount, greaterThan(0));
      });

      test('emits CacheForgetEvent on cache forget', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Cache result
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        final events = <CacheEvent>[];
        dataSource.context.queryCache.listen((event) {
          events.add(event);
        });

        // Forget cache entry
        dataSource.context.flushQueryCache();

        final forgetEvents = events.whereType<CacheFlushEvent>().toList();
        expect(forgetEvents, isNotEmpty);
      });

      test('emits CacheFlushEvent when flushing cache', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Cache multiple queries
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        final events = <CacheEvent>[];
        dataSource.context.queryCache.listen((event) {
          events.add(event);
        });

        dataSource.context.flushQueryCache();

        final flushEvents = events.whereType<CacheFlushEvent>().toList();
        expect(flushEvents, isNotEmpty);
      });

      test('emits CacheVacuumEvent when vacuuming cache', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        // Cache query
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        final events = <CacheEvent>[];
        dataSource.context.queryCache.listen((event) {
          events.add(event);
        });

        dataSource.context.vacuumQueryCache();

        final vacuumEvents = events.whereType<CacheVacuumEvent>().toList();
        expect(vacuumEvents, isNotEmpty);
      });

      test('event listeners can be removed', () async {
        final user = User(id: 1, email: 'test@example.com', active: true);
        await dataSource.repo<User>().insert(user);

        final events = <CacheEvent>[];
        void listener(CacheEvent event) {
          events.add(event);
        }

        dataSource.context.queryCache.listen(listener);

        // First query generates events
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        final initialCount = events.length;
        expect(initialCount, greaterThan(0));

        // Remove listener
        dataSource.context.queryCache.unlisten(listener);

        // Second query should not add events
        await dataSource.context
            .query<User>()
            .where('id', 1)
            .remember(Duration(minutes: 5))
            .get();

        // Events count should remain the same
        expect(events.length, initialCount);
      });
    });
  });
}
