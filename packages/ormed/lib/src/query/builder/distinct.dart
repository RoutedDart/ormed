part of '../query_builder.dart';

/// Extension providing DISTINCT clause methods for query results.
extension DistinctExtension<T> on Query<T> {
  /// Applies DISTINCT (and optional DISTINCT ON) semantics to the select.
  ///
  /// [columns] are optional columns to apply `DISTINCT ON` to (PostgreSQL specific).
  /// If no columns are provided, a simple `SELECT DISTINCT` is used.
  ///
  /// Examples:
  /// ```dart
  /// // Select distinct user names
  /// final distinctNames = await context.query<User>()
  ///   .distinct()
  ///   .select(['name'])
  ///   .pluck<String>('name');
  ///
  /// // Select distinct on specific columns (PostgreSQL)
  /// final distinctUsers = await context.query<User>()
  ///   .distinct(['firstName', 'lastName'])
  ///   .get();
  /// ```
  Query<T> distinct([Iterable<String> columns = const []]) {
    final normalized = _normalizeDistinctColumns(columns);
    return _copyWith(distinct: true, distinctOn: normalized);
  }

  /// Removes any previously applied DISTINCT state.
  ///
  /// Example:
  /// ```dart
  /// final allUsers = await context.query<User>()
  ///   .distinct()
  ///   .withoutDistinct()
  ///   .get();
  /// ```
  Query<T> withoutDistinct() =>
      _copyWith(distinct: false, distinctOn: const <DistinctOnClause>[]);
}
