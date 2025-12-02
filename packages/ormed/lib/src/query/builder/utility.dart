part of '../query_builder.dart';

/// Extension providing utility methods for query inspection and validation.
extension UtilityExtension<T> on Query<T> {
  /// Returns the SQL preview without executing the query.
  ///
  /// This method is useful for debugging and understanding the generated SQL.
  ///
  /// Example:
  /// ```dart
  /// final sql = context.query<User>()
  ///   .where('isActive', true)
  ///   .toSql();
  /// print(sql.sqlWithBindings);
  /// ```
  StatementPreview toSql() => context.describeQuery(_buildPlan());

  /// Returns the number of rows that match the current query.
  ///
  /// [expression] is the column or expression to count (defaults to '*').
  ///
  /// Example:
  /// ```dart
  /// final activeUserCount = await context.query<User>()
  ///   .where('isActive', true)
  ///   .count();
  /// print('Active users: $activeUserCount');
  /// ```
  Future<int> count({String expression = '*'}) async {
    final alias = _aggregateAlias('count');
    final aggregateQuery = _copyForAggregation().withAggregate(
      AggregateFunction.count,
      expression,
      alias: alias,
    );
    final plan = aggregateQuery._buildPlan();
    final rows = await context.runSelect(plan);
    if (rows.isEmpty) return 0;
    final value = rows.first[alias];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return rows.length;
    return 0;
  }

  /// Returns `true` if any rows match the current query.
  ///
  /// Example:
  /// ```dart
  /// final hasActiveUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .exists();
  /// print('Are there active users? $hasActiveUsers');
  /// ```
  Future<bool> exists() async {
    final rows = await limit(1).rows();
    return rows.isNotEmpty;
  }

  /// Returns `true` if no rows match the current query.
  ///
  /// Example:
  /// ```dart
  /// final noInactiveUsers = await context.query<User>()
  ///   .where('isActive', false)
  ///   .doesntExist();
  /// print('Are there no inactive users? $noInactiveUsers');
  /// ```
  Future<bool> doesntExist() async => !(await exists());
}
