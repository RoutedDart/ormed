part of 'repository.dart';

/// Mixin that provides delete operations for repositories.
mixin RepositoryDeleteMixin<T extends OrmEntity>
    on
        RepositoryBase<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInputHandlerMixin<T> {
  /// Deletes records that match the provided [where] clause.
  ///
  /// The [where] parameter accepts:
  /// - `Map<String, Object?>` - Raw column/value pairs
  /// - `PartialEntity<$T>` - Partial entity with fields to match
  /// - `InsertDto<$T>` / `UpdateDto<$T>` - DTO with fields to match
  /// - Tracked model (`$T`) - Uses primary key for matching
  /// - `Query<T>` - A pre-built query with where conditions
  /// - `Query<T> Function(Query<T>)` - A callback that builds a query
  ///
  /// **Important**: When using a callback function, you must explicitly type
  /// the parameter (e.g., `(Query<$User> q) => ...`) because Dart extension
  /// methods are not accessible on dynamically-typed parameters.
  ///
  /// Returns the number of affected rows.
  ///
  /// Example with primary key:
  /// ```dart
  /// final affected = await repository.delete(userId);
  /// ```
  ///
  /// Example with tracked model:
  /// ```dart
  /// final affected = await repository.delete(user);
  /// ```
  ///
  /// Example with Query callback:
  /// ```dart
  /// final affected = await repository.delete(
  ///   (Query<$User> q) => q.whereEquals('email', 'john@example.com'),
  /// );
  /// ```
  Future<int> delete(Object where) => deleteMany([where]);

  /// Deletes multiple records using a list of [wheres].
  ///
  /// Each entry can be any supported where input:
  /// - `Map<String, Object?>` - Raw column/value pairs
  /// - `PartialEntity<$T>` - Partial entity with fields to match
  /// - `InsertDto<$T>` / `UpdateDto<$T>` - DTO with fields to match
  /// - Tracked model (`$T`) - Uses primary key for matching
  /// - Primary key value (int, String, etc.)
  /// - `Query<T>` - A pre-built query with where conditions
  /// - `Query<T> Function(Query<T>)` - A callback that builds a query
  ///
  /// Returns the number of affected rows.
  ///
  /// Example with mixed inputs:
  /// ```dart
  /// final affected = await repository.deleteMany([
  ///   (Query<$User> q) => q.whereEquals('role', 'guest'),
  ///   {'id': 42},
  ///   someTrackedUser,
  /// ]);
  /// ```
  Future<int> deleteMany(List<Object> wheres) async {
    if (wheres.isEmpty) return 0;

    final query = _requireQuery('deleteMany');
    return query.deleteWhereMany(wheres);
  }

  /// Deletes a single record by primary key [id].
  ///
  /// Returns the number of affected rows (0 or 1).
  Future<int> deleteById(Object id) => deleteByIds([id]);

  /// Deletes multiple records by their primary key [ids].
  ///
  /// Returns the number of affected rows.
  Future<int> deleteByIds(List<Object> ids) async {
    if (ids.isEmpty) return 0;

    final query = _requireQuery('deleteByIds');
    return query.deleteWhereMany(ids);
  }

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

    final query = _requireQuery('deleteByKeys');
    return query.deleteWhereMany(keys);
  }
}
