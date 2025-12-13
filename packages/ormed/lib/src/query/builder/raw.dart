part of '../query_builder.dart';

/// Extension providing additional raw SQL query helpers for advanced use cases.
extension RawQueryExtension<T extends OrmEntity> on Query<T> {
  /// Adds a raw ORDER BY expression.
  ///
  /// This method allows you to add custom SQL to the ORDER BY clause
  /// for database-specific sorting logic.
  ///
  /// Note: [havingRaw], [havingBitwise], and [orHavingBitwise] are available
  /// via the GroupingExtension on Query.
  ///
  /// Example:
  /// ```dart
  /// // Random order (MySQL)
  /// final users = await context.query<User>()
  ///   .orderByRaw('RAND()')
  ///   .get();
  ///
  /// // Complex ordering with CASE
  /// final items = await context.query<Item>()
  ///   .orderByRaw('CASE WHEN status = ? THEN 0 ELSE 1 END', ['active'])
  ///   .get();
  ///
  /// // PostgreSQL specific: natural text sorting
  /// final products = await context.query<Product>()
  ///   .orderByRaw('name COLLATE "C"')
  ///   .get();
  /// ```
  Query<T> orderByRaw(String sql, [List<Object?> bindings = const []]) {
    // NOTE: Full implementation requires adding rawOrderings field to QueryPlan
    // For now, this is a placeholder that documents the API
    // Integration with SQL grammar still needed
    throw UnimplementedError(
      'orderByRaw() requires integration with QueryPlan and SQL grammar. '
      'Use whereRaw() or selectRaw() as workarounds for now.'
    );
  }

  /// Adds a raw GROUP BY expression.
  ///
  /// This method allows you to add custom SQL to the GROUP BY clause
  /// for database-specific grouping logic. Use this when `groupBy()` with
  /// simple column names isn't sufficient.
  ///
  /// Example:
  /// ```dart
  /// // Group by date truncation (PostgreSQL)
  /// final dailySales = await context.query<Sale>()
  ///   .select(['DATE_TRUNC(\'day\', created_at) as day', 'SUM(amount) as total'])
  ///   .groupByRaw('DATE_TRUNC(\'day\', created_at)')
  ///   .get();
  /// ```
  Query<T> groupByRaw(String sql, [List<Object?> bindings = const []]) {
    // NOTE: Full implementation requires adding rawGroupBys field to QueryPlan
    // For now, this is a placeholder that documents the API
    // Integration with SQL grammar still needed
    throw UnimplementedError(
      'groupByRaw() requires integration with QueryPlan and SQL grammar. '
      'Use whereRaw() or selectRaw() as workarounds for now.'
    );
  }
}

