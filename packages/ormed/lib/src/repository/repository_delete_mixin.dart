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

    final plan = buildDeletePlanFromWhereInputs(wheres);
    final result = await runMutation(plan);
    return result.affectedRows;
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

    final pk = definition.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'deleteByIds requires ${definition.modelName} to declare a primary key.',
      );
    }

    final keys = ids
        .map((id) => <String, Object?>{pk.columnName: id})
        .toList(growable: false);
    return deleteByKeys(keys);
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
    final plan = buildDeletePlan(keys);
    final result = await runMutation(plan);

    return result.affectedRows;
  }

  /// Builds a delete plan from flexible where inputs.
  MutationPlan buildDeletePlanFromWhereInputs(List<Object> wheres) {
    final keys = wheres.map(_whereInputToKey).toList(growable: false);
    return buildDeletePlan(keys);
  }

  Map<String, Object?> _whereInputToKey(Object input) {
    final pkField = definition.primaryKeyField;

    // For tracked models, prefer deleting by primary key to avoid null column matches
    if (input is T) {
      if (pkField == null) {
        throw StateError(
          'delete requires ${definition.modelName} to declare a primary key.',
        );
      }
      final map = definition.toMap(input, registry: codecs);
      final pkValue = map[pkField.columnName];
      if (pkValue == null) {
        throw StateError('Primary key cannot be null for delete().');
      }
      return {pkField.columnName: pkValue};
    }

    // Try the flexible where conversion first
    try {
      final map = whereInputToMap(input);
      if (map != null && map.isNotEmpty) {
        return map;
      }
    } on ArgumentError {
      // fall through to PK fallback
    }

    // Fallback: treat input as a primary key value (any type) if PK exists
    if (pkField != null) {
      return {pkField.columnName: input};
    }

    throw ArgumentError.value(
      input,
      'where',
      'Delete requires at least one condition.',
    );
  }
}
