part of 'repository.dart';

/// Mixin that provides delete operations for repositories.
mixin RepositoryDeleteMixin<T> on RepositoryBase<T>, RepositoryHelpersMixin<T> {
  /// Deletes records from the database by their [keys].
  ///
  /// Each key is a map of column names to values.
  ///
  /// Returns the number of affected rows.
  ///
  /// Example:
  /// ```dart
  /// final affectedRows = await repository.deleteByKeys([{'id': 1}, {'id': 2}]);
  /// print(affectedRows); // The number of deleted rows.
  /// ```
  Future<int> deleteByKeys(List<Map<String, Object?>> keys) async {
    if (keys.isEmpty) return 0;
    requireKeys(keys);
    final plan = buildDeletePlan(keys);
    final result = await runMutation(plan);

    return result.affectedRows;
  }
}
