/// Events emitted during query caching lifecycle.
abstract class CacheEvent {
  const CacheEvent();

  String get eventName;
}

/// Emitted when a query result is retrieved from cache.
class CacheHitEvent extends CacheEvent {
  const CacheHitEvent({
    required this.sql,
    required this.parameters,
    required this.ttl,
  });

  final String sql;
  final List<Object?> parameters;
  final Duration ttl;

  @override
  String get eventName => 'cache.hit';

  @override
  String toString() => 'CacheHit(sql: $sql, ttl: $ttl)';
}

/// Emitted when a query result is not in cache.
class CacheMissEvent extends CacheEvent {
  const CacheMissEvent({
    required this.sql,
    required this.parameters,
    required this.ttl,
  });

  final String sql;
  final List<Object?> parameters;
  final Duration ttl;

  @override
  String get eventName => 'cache.miss';

  @override
  String toString() => 'CacheMiss(sql: $sql, ttl: $ttl)';
}

/// Emitted when a query result is stored in cache.
class CacheStoreEvent extends CacheEvent {
  const CacheStoreEvent({
    required this.sql,
    required this.parameters,
    required this.ttl,
    required this.entryCount,
  });

  final String sql;
  final List<Object?> parameters;
  final Duration ttl;
  final int entryCount; // Number of rows cached

  @override
  String get eventName => 'cache.store';

  @override
  String toString() => 'CacheStore(sql: $sql, rows: $entryCount, ttl: $ttl)';
}

/// Emitted when a cache entry is manually removed.
class CacheForgetEvent extends CacheEvent {
  const CacheForgetEvent({
    required this.sql,
    required this.parameters,
  });

  final String sql;
  final List<Object?> parameters;

  @override
  String get eventName => 'cache.forget';

  @override
  String toString() => 'CacheForget(sql: $sql)';
}

/// Emitted when cache is flushed.
class CacheFlushEvent extends CacheEvent {
  const CacheFlushEvent({required this.entriesCleared});

  final int entriesCleared;

  @override
  String get eventName => 'cache.flush';

  @override
  String toString() => 'CacheFlush(cleared: $entriesCleared)';
}

/// Emitted when cache is vacuumed (expired entries removed).
class CacheVacuumEvent extends CacheEvent {
  const CacheVacuumEvent({
    required this.entriesRemoved,
    required this.totalBefore,
    required this.totalAfter,
  });

  final int entriesRemoved;
  final int totalBefore;
  final int totalAfter;

  @override
  String get eventName => 'cache.vacuum';

  @override
  String toString() => 'CacheVacuum(removed: $entriesRemoved, before: $totalBefore, after: $totalAfter)';
}

