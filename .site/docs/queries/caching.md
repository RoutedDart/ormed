---
sidebar_position: 5
---

# Query Caching

Query caching stores expensive database query results in memory, reducing database load and improving performance.

## Basic Usage

### remember(Duration)

Cache query results for a specified duration:

```dart
// Cache for 5 minutes
final activeUsers = await dataSource.query<$User>()
    .whereEquals('active', true)
    .orderBy('name')
    .remember(Duration(minutes: 5))
    .get();

// Cache for 1 hour
final statistics = await dataSource.query<$DashboardStats>()
    .remember(Duration(hours: 1))
    .get();

// Cache for 1 day
final countries = await dataSource.query<$Country>()
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
// Good for reference data that rarely changes
final currencies = await dataSource.query<$Currency>()
    .orderBy('code')
    .rememberForever()
    .get();

final categories = await dataSource.query<$Category>()
    .whereEquals('active', true)
    .rememberForever()
    .get();
```

:::warning
Use `rememberForever()` carefully! Cached data won't update automatically. Clear the cache manually when data changes.
:::

### dontRemember()

Bypass the cache for a specific query:

```dart
// Get fresh data, ignoring any cached results
final freshUsers = await dataSource.query<$User>()
    .whereEquals('id', userId)
    .dontRemember()
    .first();

// Useful after updates
await user.save();
final updated = await dataSource.query<$User>()
    .whereEquals('id', user.id)
    .dontRemember()
    .first();
```

### Chaining with Other Methods

```dart
// Complex query with caching
final premiumUsers = await dataSource.query<$User>()
    .whereEquals('subscription_type', 'premium')
    .whereEquals('active', true)
    .orderBy('name')
    .limit(100)
    .remember(Duration(minutes: 10))
    .get();

// With eager loading
final postsWithAuthors = await dataSource.query<$Post>()
    .with_(['author'])
    .whereEquals('published', true)
    .remember(Duration(minutes: 15))
    .get();
```

## Cache Management

### Flushing the Cache

Clear all cached queries:

```dart
dataSource.context.flushQueryCache();

// Typically done after schema changes or deployment
await runMigrations();
dataSource.context.flushQueryCache();
```

### Vacuum Expired Entries

Remove expired cache entries to free memory:

```dart
dataSource.context.vacuumQueryCache();

// Periodic vacuum
Timer.periodic(Duration(hours: 1), (_) {
  dataSource.context.vacuumQueryCache();
});
```

### Cache Statistics

```dart
final stats = dataSource.context.queryCacheStats;

print('Cache size: ${stats.size} entries');
print('Cache hits: ${stats.hits}');
print('Cache misses: ${stats.misses}');
print('Hit ratio: ${stats.hitRatio.toStringAsFixed(2)}%');

if (stats.hitRatio < 0.5) {
  logger.warning('Low cache hit ratio: ${stats.hitRatio}');
}
```

## Cache Events

Real-time notifications about cache operations:

| Event | Trigger | Properties |
|-------|---------|-----------|
| `CacheHitEvent` | Result found in cache | sql, parameters, timestamp |
| `CacheMissEvent` | Result not in cache | sql, parameters, timestamp |
| `CacheStoreEvent` | Result stored in cache | sql, parameters, ttl, rowCount |
| `CacheForgetEvent` | Entry removed | sql, parameters, timestamp |
| `CacheFlushEvent` | All cache cleared | timestamp, entriesCleared |
| `CacheVacuumEvent` | Expired entries cleaned | timestamp, entriesRemoved |

### Listening to Events

```dart
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
```

### Monitoring Cache Performance

```dart
class CacheMonitor {
  int hits = 0;
  int misses = 0;
  
  void startMonitoring(QueryContext context) {
    context.queryCache.listen((event) {
      if (event is CacheHitEvent) hits++;
      else if (event is CacheMissEvent) misses++;
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
```

### Integration with Metrics

```dart
dataSource.context.queryCache.listen((event) {
  if (event is CacheHitEvent) {
    metrics.increment('cache.hits');
  } else if (event is CacheMissEvent) {
    metrics.increment('cache.misses');
  } else if (event is CacheStoreEvent) {
    metrics.histogram('cache.stored_rows', event.rowCount);
  }
});
```

## When to Use Caching

### ✅ Good Candidates

- Dashboard statistics and reports
- Reference data (countries, categories)
- User permissions and roles
- Popular content (trending posts)
- Aggregated data

### ❌ Poor Candidates

- Real-time data requiring immediate consistency
- User-specific personalized content
- Rapidly changing data (live scores, stock prices)
- Write-heavy operations

## Best Practices

### Use Appropriate TTLs

```dart
// Short TTL for frequently changing data
final recentPosts = await dataSource.query<$Post>()
    .orderBy('created_at', descending: true)
    .limit(10)
    .remember(Duration(minutes: 1))
    .get();

// Longer TTL for stable data
final categories = await dataSource.query<$Category>()
    .remember(Duration(hours: 24))
    .get();
```

### Cache Expensive Queries

```dart
// Complex aggregations
final stats = await dataSource.query<$Order>()
    .selectRaw("DATE(created_at) as date, SUM(total) as revenue")
    .groupBy('date')
    .remember(Duration(hours: 1))
    .get();
```

### Clear Cache on Schema Changes

```dart
await runMigrations();
dataSource.context.flushQueryCache();
```

### Don't Cache User-Specific Data Globally

```dart
// BAD - caches for all users!
final userOrders = await dataSource.query<$Order>()
    .whereEquals('user_id', currentUserId)
    .remember(Duration(minutes: 5))
    .get();

// BETTER - don't cache user-specific data
final userOrders = await dataSource.query<$Order>()
    .whereEquals('user_id', currentUserId)
    .get();
```

### Monitor Cache Performance

```dart
dataSource.context.queryCache.listen((event) {
  if (event is CacheMissEvent) {
    logger.info('Cache miss for: ${event.sql}');
  }
});
```

## Cache Invalidation Strategies

### Time-based (TTL)

```dart
final data = await dataSource.query<$Model>()
    .remember(Duration(minutes: 5))
    .get();
```

### Manual Invalidation

```dart
await user.save();
dataSource.context.flushQueryCache();
```

### Event-driven

```dart
dataSource.context.onMutation((event) {
  if (event.affectedModels.contains('User')) {
    dataSource.context.flushQueryCache();
  }
});
```

## Performance Benefits

Query caching can provide:
- **10-100x faster** query response times
- **Reduced database load** - Fewer connections and queries
- **Better scalability** - Handle more concurrent users
- **Lower costs** - Reduced database resource usage
