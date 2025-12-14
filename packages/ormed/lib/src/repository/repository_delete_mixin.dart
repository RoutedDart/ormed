part of 'repository.dart';

/// Mixin that provides delete operations for repositories.
mixin RepositoryDeleteMixin<T extends OrmEntity>
    on
        RepositoryBase<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInputHandlerMixin<T> {
  /// Deletes records that match the provided [where] clause.
  ///
  /// Accepts the same flexible inputs as [RepositoryUpdateMixin.where]:
  /// - `Map<String, Object?>`
  /// - `PartialEntity<$T>`
  /// - `InsertDto<$T>` / `UpdateDto<$T>`
  /// - tracked model `$T`
  ///
  /// Returns the number of affected rows.
  Future<int> delete(Object where) => deleteMany([where]);

  /// Deletes multiple records using a list of [wheres].
  ///
  /// Each entry can be any supported where input (Map, Partial, DTO, tracked model).
  /// Returns the number of affected rows.
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
