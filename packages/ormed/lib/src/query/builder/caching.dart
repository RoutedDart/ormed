part of '../query_builder.dart';

/// Extension providing query result caching (Laravel-style remember).
extension QueryCachingExtension<T extends OrmEntity> on Query<T> {
  /// Cache query results for the specified duration.
  ///
  /// Results are stored in memory and reused for subsequent identical queries
  /// within the TTL window. Cache key is derived from SQL + bindings.
  ///
  /// Example:
  /// ```dart
  /// // Cache for 5 minutes
  /// final users = await context.query<User>()
  ///   .where('active', true)
  ///   .remember(Duration(minutes: 5))
  ///   .get();
  ///
  /// // Second call within 5 minutes returns cached result
  /// final sameUsers = await context.query<User>()
  ///   .where('active', true)
  ///   .remember(Duration(minutes: 5))
  ///   .get(); // ← Hits cache
  /// ```
  Query<T> remember(Duration ttl) {
    return _copyWith(cacheTtl: ttl);
  }

  /// Cache query results indefinitely (until manually cleared).
  ///
  /// Useful for reference data that rarely changes.
  ///
  /// Example:
  /// ```dart
  /// final countries = await context.query<Country>()
  ///   .rememberForever()
  ///   .get();
  ///
  /// // Clear when data updates
  /// context.flushQueryCache();
  /// ```
  Query<T> rememberForever() {
    // Use 100 years as "forever"
    return remember(const Duration(days: 36500));
  }

  /// Disable caching for this query (even if parent had caching).
  ///
  /// Example:
  /// ```dart
  /// final fresh = await context.query<User>()
  ///   .dontRemember()
  ///   .get(); // Never cached
  /// ```
  Query<T> dontRemember() {
    return _copyWith(cacheTtl: null, disableCache: true);
  }
}
