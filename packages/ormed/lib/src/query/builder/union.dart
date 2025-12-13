part of '../query_builder.dart';

/// Extension providing UNION operations and insert-from-select functionality.
extension UnionExtension<T extends OrmEntity> on Query<T> {
  /// Adds a `UNION` clause combining the current query with [query].
  ///
  /// The `UNION` operator combines the result sets of two or more `SELECT` statements
  /// and removes duplicate rows.
  ///
  /// Example:
  /// ```dart
  /// final activeAndAdminUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .union(context.query<User>().where('role', 'admin'))
  ///   .get();
  /// ```
  Query<T> union(Query<dynamic> query) => _addUnion(query, all: false);

  /// Adds a `UNION ALL` clause combining the current query with [query].
  ///
  /// The `UNION ALL` operator combines the result sets of two or more `SELECT` statements
  /// and includes duplicate rows.
  ///
  /// Example:
  /// ```dart
  /// final allUsersIncludingDuplicates = await context.query<User>()
  ///   .where('isActive', true)
  ///   .unionAll(context.query<User>().where('role', 'admin'))
  ///   .get();
  /// ```
  Query<T> unionAll(Query<dynamic> query) => _addUnion(query, all: true);

  /// Inserts rows into this query's table using the results of [source]. The
  /// [columns] list must contain one entry per value selected by [source].
  ///
  /// This method allows for efficient bulk insertion of data from another query.
  ///
  /// [columns] are the target columns for insertion.
  /// [source] is the query whose results will be inserted.
  /// [ignoreConflicts] (defaults to `false`) whether to ignore duplicate key errors.
  ///
  /// Example:
  /// ```dart
  /// // Insert archived posts into a new 'old_posts' table
  /// final insertedCount = await context.query<OldPost>()
  ///   .insertUsing(
  ///     ['title', 'body'],
  ///     context.query<Post>().where('isArchived', true).select(['title', 'body']),
  ///   );
  /// print('Inserted $insertedCount old posts.');
  /// ```
  Future<int> insertUsing(
    Iterable<String> columns,
    Query<dynamic> source, {
    bool ignoreConflicts = false,
  }) async {
    _ensureSupportsCapability(
      DriverCapability.insertUsing,
      context.driver.metadata.name,
      'insertUsing',
    );
    final resolved = _normalizeInsertColumns(columns);
    if (resolved.isEmpty) {
      throw ArgumentError.value(columns, 'columns', 'At least one column');
    }
    _ensureSharedContext(source, 'insertUsing');
    final selectPlan = source._buildPlan().copyWith(disableAutoHydration: true);
    final mutation = MutationPlan.insertUsing(
      definition: definition,
      columns: resolved,
      selectPlan: selectPlan,
      ignoreConflicts: ignoreConflicts,
      driverName: context.driver.metadata.name,
    );
    final result = await context.runMutation(mutation);
    return result.affectedRows;
  }

  /// Inserts rows into this query's table using the results of [source],
  /// ignoring duplicate key errors.
  ///
  /// This is equivalent to calling [insertUsing] with `ignoreConflicts: true`.
  Future<int> insertOrIgnoreUsing(
    Iterable<String> columns,
    Query<dynamic> source,
  ) => insertUsing(columns, source, ignoreConflicts: true);
}
