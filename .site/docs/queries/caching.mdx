---
sidebar_position: 5
---

# Query Caching

Query caching stores expensive database query results in memory, reducing database load and improving performance.

## Basic Usage

### remember(Duration)

Cache query results for a specified duration:

```dart file=../../examples/lib/caching/caching.dart#cache-remember
```

**How it works:**
1. First query executes against the database
2. Results are stored in cache with the specified TTL
3. Subsequent identical queries retrieve from cache
4. Cache entry expires after the duration

### rememberForever()

Cache results indefinitely (until manually cleared):

```dart file=../../examples/lib/caching/caching.dart#cache-forever
```

:::warning
Use `rememberForever()` carefully! Cached data won't update automatically. Clear the cache manually when data changes.
:::

### dontRemember()

Bypass the cache for a specific query:

```dart file=../../examples/lib/caching/caching.dart#cache-dont-remember
```

### Chaining with Other Methods

```dart file=../../examples/lib/caching/caching.dart#cache-chaining
```

## Cache Management

### Flushing the Cache

Clear all cached queries:

```dart file=../../examples/lib/caching/caching.dart#cache-flush
```

### Vacuum Expired Entries

Remove expired cache entries to free memory:

```dart file=../../examples/lib/caching/caching.dart#cache-vacuum
```

### Cache Statistics

```dart file=../../examples/lib/caching/caching.dart#cache-stats
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

```dart file=../../examples/lib/caching/caching.dart#cache-events-listening

```

### Monitoring Cache Performance

```dart file=../../examples/lib/caching/caching.dart#cache-monitor

```

### Integration with Metrics

```dart file=../../examples/lib/caching/caching.dart#cache-metrics-integration

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

```dart file=../../examples/lib/caching/caching.dart#cache-best-practices-ttl

```

### Cache Expensive Queries

```dart file=../../examples/lib/caching/caching.dart#cache-expensive-queries

```

### Clear Cache on Schema Changes

```dart file=../../examples/lib/caching/caching.dart#cache-clear-on-schema

```

### Don't Cache User-Specific Data Globally

```dart file=../../examples/lib/caching/caching.dart#cache-user-specific-bad

```

```dart file=../../examples/lib/caching/caching.dart#cache-user-specific-good

```

### Monitor Cache Performance

```dart file=../../examples/lib/caching/caching.dart#cache-performance-monitor

```

## Cache Invalidation Strategies

### Time-based (TTL)

```dart file=../../examples/lib/caching/caching.dart#cache-ttl-invalidation

```

### Manual Invalidation

```dart file=../../examples/lib/caching/caching.dart#cache-manual-invalidation

```

### Event-driven

```dart file=../../examples/lib/caching/caching.dart#cache-event-driven-invalidation

```

## Performance Benefits

Query caching can provide:
- **10-100x faster** query response times
- **Reduced database load** - Fewer connections and queries
- **Better scalability** - Handle more concurrent users
- **Lower costs** - Reduced database resource usage
