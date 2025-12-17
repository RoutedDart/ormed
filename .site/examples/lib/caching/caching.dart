// Query caching examples for documentation
// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:ormed/ormed.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../models/post.dart';
import '../models/post.orm.dart';

// #region cache-remember
Future<void> rememberExample(DataSource dataSource) async {
  // Cache for 5 minutes
  final activeUsers = await dataSource
      .query<$User>()
      .whereEquals('active', true)
      .orderBy('name')
      .remember(Duration(minutes: 5))
      .get();

  // Cache for 1 hour
  final statistics = await dataSource
      .query<$User>()
      .remember(Duration(hours: 1))
      .get();

  // Cache for 1 day
  final users = await dataSource
      .query<$User>()
      .remember(Duration(days: 1))
      .get();
}
// #endregion cache-remember

// #region cache-forever
Future<void> rememberForeverExample(DataSource dataSource) async {
  // Good for reference data that rarely changes
  final users = await dataSource
      .query<$User>()
      .orderBy('name')
      .rememberForever()
      .get();

  final activeUsers = await dataSource
      .query<$User>()
      .whereEquals('active', true)
      .rememberForever()
      .get();
}
// #endregion cache-forever

// #region cache-dont-remember
Future<void> dontRememberExample(DataSource dataSource) async {
  final userId = 1;
  final user = await dataSource.query<$User>().find(userId);

  // Get fresh data, ignoring any cached results
  final freshUser = await dataSource
      .query<$User>()
      .whereEquals('id', userId)
      .dontRemember()
      .first();

  // Useful after updates
  if (user != null) {
    user.setAttribute('name', 'Updated');
    await dataSource.repo<$User>().update(user);

    final updated = await dataSource
        .query<$User>()
        .whereEquals('id', user.id)
        .dontRemember()
        .first();
  }
}
// #endregion cache-dont-remember

// #region cache-chaining
Future<void> cacheChainingExample(DataSource dataSource) async {
  // Complex query with caching
  final premiumUsers = await dataSource
      .query<$User>()
      .whereEquals('active', true)
      .orderBy('name')
      .limit(100)
      .remember(Duration(minutes: 10))
      .get();

  // With eager loading
  final postsWithAuthors = await dataSource
      .query<$Post>()
      .with_(['author'])
      .whereEquals('published', true)
      .remember(Duration(minutes: 15))
      .get();
}
// #endregion cache-chaining

// #region cache-flush
Future<void> flushCacheExample(DataSource dataSource) async {
  dataSource.context.flushQueryCache();

  // Typically done after schema changes or deployment
  // await runMigrations();
  dataSource.context.flushQueryCache();
}
// #endregion cache-flush

// #region cache-vacuum
Future<void> vacuumCacheExample(DataSource dataSource) async {
  dataSource.context.vacuumQueryCache();

  // Periodic vacuum
  Timer.periodic(Duration(hours: 1), (_) {
    dataSource.context.vacuumQueryCache();
  });
}
// #endregion cache-vacuum

// #region cache-stats
Future<void> cacheStatsExample(DataSource dataSource) async {
  final stats = dataSource.context.queryCacheStats;

  print('Cache size: ${stats.size} entries');
  print('Cache hits: ${stats.hits}');
  print('Cache misses: ${stats.misses}');
  print('Hit ratio: ${stats.hitRatio.toStringAsFixed(2)}%');

  if (stats.hitRatio < 0.5) {
    print('Warning: Low cache hit ratio: ${stats.hitRatio}');
  }
}
// #endregion cache-stats

// #region cache-events-listening
void cacheEventsListeningExample(DataSource dataSource) {
  final subscription = dataSource.context.queryCache.listen((event) {
    print('${event.eventName}: ${event.sql}');

    if (event is CacheHitEvent) {
      print('✅ Cache hit!');
    } else if (event is CacheMissEvent) {
      print('❌ Cache miss');
    } else if (event is CacheStoreEvent) {
      print('💾 Stored ${event.rowCount} rows');
    }
  });

  // Remove listener
  dataSource.context.queryCache.unlisten(subscription);
}
// #endregion cache-events-listening

// #region cache-monitor
class CacheMonitor {
  int hits = 0;
  int misses = 0;

  void startMonitoring(QueryContext context) {
    context.queryCache.listen((event) {
      if (event is CacheHitEvent)
        hits++;
      else if (event is CacheMissEvent)
        misses++;
    });
  }

  double get hitRatio {
    final total = hits + misses;
    return total > 0 ? hits / total : 0.0;
  }

  void report() {
    print('Cache Performance:');
    print('  Hits: $hits');
    print('  Misses: $misses');
    print('  Hit Ratio: ${(hitRatio * 100).toStringAsFixed(2)}%');
  }
}
// #endregion cache-monitor

// #region cache-metrics-integration
void cacheMetricsIntegration(DataSource dataSource, Metrics metrics) {
  dataSource.context.queryCache.listen((event) {
    if (event is CacheHitEvent) {
      metrics.increment('cache.hits');
    } else if (event is CacheMissEvent) {
      metrics.increment('cache.misses');
    } else if (event is CacheStoreEvent) {
      metrics.histogram('cache.stored_rows', event.rowCount);
    }
  });
}

// Placeholder for metrics interface
abstract class Metrics {
  void increment(String name);
  void histogram(String name, int value);
}
// #endregion cache-metrics-integration

// #region cache-best-practices-ttl
Future<void> cacheBestPracticesTtl(DataSource dataSource) async {
  // Short TTL for frequently changing data
  final recentPosts = await dataSource
      .query<$Post>()
      .orderBy('createdAt', descending: true)
      .limit(10)
      .remember(Duration(minutes: 1))
      .get();

  // Longer TTL for stable data
  final users = await dataSource
      .query<$User>()
      .remember(Duration(hours: 24))
      .get();
}
// #endregion cache-best-practices-ttl

// #region cache-expensive-queries
Future<void> cacheExpensiveQueries(DataSource dataSource) async {
  // Complex aggregations
  final stats = await dataSource
      .query<$User>()
      .selectRaw("DATE(created_at) as date, COUNT(*) as count")
      .groupBy('date')
      .remember(Duration(hours: 1))
      .get();
}
// #endregion cache-expensive-queries

// #region cache-clear-on-schema
Future<void> cacheClearOnSchema(DataSource dataSource) async {
  // await runMigrations();
  dataSource.context.flushQueryCache();
}
// #endregion cache-clear-on-schema

// #region cache-user-specific-bad
Future<void> cacheUserSpecificBad(
  DataSource dataSource,
  int currentUserId,
) async {
  // BAD - caches for all users!
  final userPosts = await dataSource
      .query<$Post>()
      .whereEquals('user_id', currentUserId)
      .remember(Duration(minutes: 5))
      .get();
}
// #endregion cache-user-specific-bad

// #region cache-user-specific-good
Future<void> cacheUserSpecificGood(
  DataSource dataSource,
  int currentUserId,
) async {
  // BETTER - don't cache user-specific data
  final userPosts = await dataSource
      .query<$Post>()
      .whereEquals('user_id', currentUserId)
      .get();
}
// #endregion cache-user-specific-good

// #region cache-performance-monitor
void cachePerformanceMonitor(DataSource dataSource) {
  dataSource.context.queryCache.listen((event) {
    if (event is CacheMissEvent) {
      print('Cache miss for: ${event.sql}');
    }
  });
}
// #endregion cache-performance-monitor

// #region cache-ttl-invalidation
Future<void> cacheTtlInvalidation(DataSource dataSource) async {
  final data = await dataSource
      .query<$User>()
      .remember(Duration(minutes: 5))
      .get();
}
// #endregion cache-ttl-invalidation

// #region cache-manual-invalidation
Future<void> cacheManualInvalidation(DataSource dataSource, User user) async {
  await dataSource.repo<$User>().update(user);
  dataSource.context.flushQueryCache();
}
// #endregion cache-manual-invalidation

// #region cache-event-driven-invalidation
void cacheEventDrivenInvalidation(DataSource dataSource) {
  dataSource.context.onMutation((event) {
    if (event.affectedModels.contains('User')) {
      dataSource.context.flushQueryCache();
    }
  });
}

// #endregion cache-event-driven-invalidation
