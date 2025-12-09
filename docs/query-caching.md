# Query Caching

Query caching allows you to cache expensive database queries, reducing database load and improving application performance. The caching system provides Laravel-style methods with an advanced event system for monitoring and debugging.

## Table of Contents

- [Overview](#overview)
- [Basic Usage](#basic-usage)
- [Cache Management](#cache-management)
- [Cache Events](#cache-events)
- [Advanced Topics](#advanced-topics)
- [Best Practices](#best-practices)
- [Comparison with Laravel](#comparison-with-laravel)

---

## Overview

### What is Query Caching?

Query caching stores the results of database queries in memory, allowing subsequent identical queries to retrieve results from the cache instead of hitting the database again. This can significantly improve performance for:

- **Expensive queries** - Complex joins, aggregations, or large datasets
- **Frequently accessed data** - Reference data, configuration, or popular content
- **High-traffic scenarios** - Reducing database load during traffic spikes

### When to Use Caching

✅ **Good candidates for caching:**
- Dashboard statistics and reports
- Reference data (countries, categories, etc.)
- User permissions and roles
- Popular content (trending posts, featured items)
- Aggregated data

❌ **Poor candidates for caching:**
- Real-time data requiring immediate consistency
- User-specific personalized content
- Rapidly changing data (live scores, stock prices)
- Write-heavy operations

### Performance Benefits

Query caching can provide:
- **10-100x faster** query response times
- **Reduced database load** - Fewer connections and queries
- **Better scalability** - Handle more concurrent users
- **Lower costs** - Reduced database resource usage

---

## Basic Usage

### remember(Duration)

Cache query results for a specified duration:

```dart
import 'package:ormed/ormed.dart';

// Cache for 5 minutes
final activeUsers = await User.query()
    .where('active', true)
    .orderBy('name')
    .remember(Duration(minutes: 5))
    .get();

// Cache for 1 hour
final statistics = await DashboardStats.query()
    .where('date', '>=', startOfMonth)
    .remember(Duration(hours: 1))
    .get();

// Cache for 1 day
final countries = await Country.query()
    .remember(Duration(days: 1))
    .get();
```

**How it works:**
1. First query executes against the database
2. Results are stored in cache with the specified TTL
3. Subsequent identical queries retrieve from cache
4. Cache entry expires after the duration

### rememberForever()

Cache results indefinitely (until manually cleared):

```dart
// Cache indefinitely - good for reference data
final currencies = await Currency.query()
    .orderBy('code')
    .rememberForever()
    .get();

// Categories that rarely change
final categories = await Category.query()
    .where('active', true)
    .rememberForever()
    .get();
```

⚠️ **Warning:** Use `rememberForever()` carefully! Cached data won't update automatically. Clear the cache manually when data changes.

### dontRemember()

Explicitly bypass the cache for a specific query:

```dart
// Get fresh data, ignoring any cached results
final freshUsers = await User.query()
    .where('id', userId)
    .dontRemember()
    .first();

// Useful after updates to ensure fresh data
await user.save();
final updated = await User.query()
    .where('id', user.id)
    .dontRemember()
    .first();
```

### Chaining with Other Query Methods

Caching works seamlessly with all query builder methods:

```dart
// Complex query with caching
final premiumUsers = await User.query()
    .where('subscription_type', 'premium')
    .where('active', true)
    .whereGreaterThan('last_login', thirtyDaysAgo)
    .orderBy('name')
    .limit(100)
    .remember(Duration(minutes: 10))
    .get();

// With eager loading
final postsWithAuthors = await Post.query()
    .with('author')
    .where('published', true)
    .remember(Duration(minutes: 15))
    .get();

// With aggregations
final totalSales = await Order.query()
    .where('status', 'completed')
    .sum('total')
    .remember(Duration(hours: 1));
```

---

## Cache Management

### Flushing the Cache

Clear all cached queries:

```dart
// Clear all cached queries
context.flushQueryCache();

// Typically done after schema changes or during deployment
await runMigrations();
context.flushQueryCache();
```

**When to flush:**
- After database migrations
- After bulk data imports
- During application deployment
- When cache becomes stale

### Vacuum Expired Entries

Remove expired cache entries to free memory:

```dart
// Manually vacuum expired entries
context.vacuumQueryCache();

// Good practice: vacuum periodically
Timer.periodic(Duration(hours: 1), (_) {
  context.vacuumQueryCache();
});
```

**Automatic cleanup** happens periodically, but manual vacuuming can help manage memory usage in long-running applications.

### Cache Statistics

Monitor cache performance:

```dart
final stats = context.queryCacheStats;

print('Cache size: ${stats.size} entries');
print('Cache hits: ${stats.hits}');
print('Cache misses: ${stats.misses}');
print('Hit ratio: ${stats.hitRatio.toStringAsFixed(2)}%');

// Use for monitoring
if (stats.hitRatio < 0.5) {
  logger.warning('Low cache hit ratio: ${stats.hitRatio}');
}
```

**Available statistics:**
- `size` - Current number of cached entries
- `hits` - Total cache hits
- `misses` - Total cache misses
- `hitRatio` - Percentage of hits vs total requests

---

## Cache Events

### Overview

The cache event system provides real-time notifications about cache operations. This is a **unique feature** not available in Laravel or most other ORMs!

### Event Types

| Event | Trigger | Properties |
|-------|---------|-----------|
| `CacheHitEvent` | Result found in cache | sql, parameters, timestamp |
| `CacheMissEvent` | Result not in cache | sql, parameters, timestamp |
| `CacheStoreEvent` | Result stored in cache | sql, parameters, ttl, rowCount |
| `CacheForgetEvent` | Entry removed from cache | sql, parameters, timestamp |
| `CacheFlushEvent` | All cache cleared | timestamp, entriesCleared |
| `CacheVacuumEvent` | Expired entries cleaned | timestamp, entriesRemoved |

### Listening to Cache Events

```dart
// Listen to all cache events
final subscription = context.queryCache.listen((event) {
  print('${event.eventName}: ${event.sql}');
  
  if (event is CacheHitEvent) {
    print('✅ Cache hit!');
  } else if (event is CacheMissEvent) {
    print('❌ Cache miss - querying database');
  } else if (event is CacheStoreEvent) {
    print('💾 Stored ${event.rowCount} rows with TTL ${event.ttl}');
  }
});

// Remove listener when done
context.queryCache.unlisten(subscription);
```

### Monitoring Cache Performance

Track cache hit ratios in real-time:

```dart
class CacheMonitor {
  int hits = 0;
  int misses = 0;
  
  void startMonitoring(QueryContext context) {
    context.queryCache.listen((event) {
      if (event is CacheHitEvent) {
        hits++;
      } else if (event is CacheMissEvent) {
        misses++;
      }
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

// Usage
final monitor = CacheMonitor();
monitor.startMonitoring(context);

// ... run queries ...

monitor.report();
```

### Debug Logging

Log all cache operations for debugging:

```dart
context.queryCache.listen((event) {
  logger.debug('Cache ${event.eventName}', {
    'sql': event.sql,
    'parameters': event.parameters,
    'timestamp': event.timestamp,
  });
});
```

### Integration with Metrics Systems

Send cache metrics to your monitoring service:

```dart
context.queryCache.listen((event) {
  if (event is CacheHitEvent) {
    metrics.increment('cache.hits');
  } else if (event is CacheMissEvent) {
    metrics.increment('cache.misses');
  } else if (event is CacheStoreEvent) {
    metrics.histogram('cache.stored_rows', event.rowCount);
  }
});
```

### Alerting on Low Hit Ratios

Set up alerts for poor cache performance:

```dart
class CacheAlert {
  int hits = 0;
  int misses = 0;
  final double threshold;
  
  CacheAlert({this.threshold = 0.5});
  
  void monitor(QueryContext context) {
    context.queryCache.listen((event) {
      if (event is CacheHitEvent) hits++;
      else if (event is CacheMissEvent) misses++;
      
      final total = hits + misses;
      if (total > 100) { // Check after 100 queries
        final ratio = hits / total;
        if (ratio < threshold) {
          logger.warning(
            'Low cache hit ratio: ${(ratio * 100).toFixed(2)}%',
          );
        }
      }
    });
  }
}
```

---

## Advanced Topics

### Cache Key Generation

Cache keys are generated automatically based on:
1. **SQL query** - The compiled SQL statement
2. **Parameters** - All query parameters/bindings
3. **Hash** - SHA-256 hash for efficiency

```dart
// These generate DIFFERENT cache keys:
User.query().where('active', true).remember(Duration(minutes: 5));
User.query().where('active', false).remember(Duration(minutes: 5));

// These generate the SAME cache key:
User.query().where('active', true).remember(Duration(minutes: 5));
User.query().where('active', true).remember(Duration(minutes: 10));
// Note: Different TTLs don't affect the cache key
```

### TTL Behavior

- **Expired entries** remain in cache until accessed or vacuumed
- **Access to expired entry** triggers cache miss and re-query
- **Vacuum** removes expired entries to free memory
- **Automatic vacuum** runs periodically (implementation-dependent)

### Memory Management

The cache uses an in-memory store with these characteristics:

- **LRU-style eviction** - Older entries removed when limit reached
- **Automatic cleanup** - Expired entries cleaned periodically
- **Manual control** - Use `flushQueryCache()` and `vacuumQueryCache()`
- **Statistics tracking** - Monitor with `queryCacheStats`

**Memory considerations:**
```dart
// Large result sets use more memory
final hugeDataset = await BigTable.query()
    .remember(Duration(hours: 24))
    .get(); // May use significant memory

// Consider limiting cached result sizes
final limitedData = await BigTable.query()
    .limit(1000) // Limit cached data
    .remember(Duration(hours: 1))
    .get();
```

### Cache Invalidation Strategies

#### 1. Time-based (TTL)
```dart
// Automatically expires after duration
final data = await Model.query()
    .remember(Duration(minutes: 5))
    .get();
```

#### 2. Manual Invalidation
```dart
// After updates, clear cache
await user.save();
context.flushQueryCache();
```

#### 3. Selective Invalidation
```dart
// Clear cache for specific operations
await importData();
context.flushQueryCache();
```

#### 4. Event-driven Invalidation
```dart
// Clear cache when data changes
context.onMutation((event) {
  if (event.affectedModels.contains('User')) {
    context.flushQueryCache();
  }
});
```

---

## Best Practices

### ✅ DO

**Use appropriate TTLs**
```dart
// Short TTL for frequently changing data
final recentPosts = await Post.query()
    .orderBy('created_at', descending: true)
    .limit(10)
    .remember(Duration(minutes: 1))
    .get();

// Longer TTL for stable data
final categories = await Category.query()
    .remember(Duration(hours: 24))
    .get();
```

**Cache expensive queries**
```dart
// Complex aggregations
final stats = await Order.query()
    .select(['DATE(created_at) as date', 'SUM(total) as revenue'])
    .groupBy('date')
    .remember(Duration(hours: 1))
    .get();
```

**Monitor cache performance**
```dart
context.queryCache.listen((event) {
  metrics.track(event);
});
```

**Clear cache on schema changes**
```dart
await runMigrations();
context.flushQueryCache();
```

### ❌ DON'T

**Don't cache user-specific data globally**
```dart
// BAD - caches for all users!
final userOrders = await Order.query()
    .where('user_id', currentUserId)
    .remember(Duration(minutes: 5))
    .get();

// BETTER - use user-specific cache key or don't cache
final userOrders = await Order.query()
    .where('user_id', currentUserId)
    .get();
```

**Don't use extremely long TTLs without invalidation**
```dart
// BAD - data might become very stale
final products = await Product.query()
    .remember(Duration(days: 365))
    .get();

// BETTER - reasonable TTL with manual invalidation
final products = await Product.query()
    .remember(Duration(hours: 1))
    .get();
```

**Don't cache rapidly changing data**
```dart
// BAD - live data shouldn't be cached
final liveScores = await Score.query()
    .where('game_active', true)
    .remember(Duration(minutes: 5))
    .get();
```

**Don't forget to monitor**
```dart
// BAD - no monitoring
final data = await Model.query().remember(Duration(minutes: 5)).get();

// GOOD - track performance
context.queryCache.listen((event) {
  if (event is CacheMissEvent) {
    logger.info('Cache miss for: ${event.sql}');
  }
});
```

---

## Comparison with Laravel

### Feature Comparison

| Feature | Laravel | This ORM | Notes |
|---------|---------|----------|-------|
| `remember()` | ✅ | ✅ | Identical API |
| `rememberForever()` | ✅ | ✅ | Identical API |
| Cache events | ❌ | ✅ | **Unique to this ORM!** |
| Hit/Miss events | ❌ | ✅ | **Not in Laravel** |
| Store events | ❌ | ✅ | **Not in Laravel** |
| Event listeners | ❌ | ✅ | **Not in Laravel** |
| Cache statistics | ❌ | ✅ | **Better than Laravel** |
| TTL expiration | ✅ | ✅ | Both support |
| Manual flush | ✅ | ✅ | Both support |

### What's Better in This ORM

🎉 **Cache Events System**
- Laravel doesn't provide cache hit/miss events for query results
- This ORM has a complete event system with 6 event types
- Real-time monitoring and debugging capabilities

🎉 **Cache Statistics**
- Built-in statistics tracking
- Hit ratio calculations
- Easy monitoring integration

🎉 **Type Safety**
- Full Dart type safety
- Compile-time checks
- Better IDE support

### Migration from Laravel

If you're coming from Laravel, the basic API is identical:

```php
// Laravel
$users = User::where('active', true)
    ->remember(5 * 60) // seconds
    ->get();
```

```dart
// This ORM
final users = await User.query()
    .where('active', true)
    .remember(Duration(minutes: 5))
    .get();
```

**Key differences:**
1. Use `Duration` objects instead of seconds
2. Cache events are available (Laravel doesn't have this)
3. `async/await` instead of synchronous calls

---

## See Also

- [Query Builder](query_builder.md) - Building database queries
- [Observability](observability.md) - Monitoring and logging
- [Best Practices](best_practices.md) - Recommended patterns
- [Testing](testing.md) - Testing cached queries

---

## Summary

Query caching provides:
- ✅ **Easy API** - `remember()`, `rememberForever()`, `dontRemember()`
- ✅ **TTL support** - Automatic expiration
- ✅ **Cache management** - Flush, vacuum, statistics
- ✅ **Event system** - Unique monitoring capabilities
- ✅ **Laravel compatibility** - Familiar API for Laravel developers
- ✅ **Better than Laravel** - Advanced event system not available in Laravel

Start caching your expensive queries today for better performance! 🚀

