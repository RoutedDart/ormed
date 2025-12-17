part of 'repository.dart';

/// Mixin that provides internal helper methods for repository operations.
mixin RepositoryHelpersMixin<T extends OrmEntity> on RepositoryBase<T> {
  Query<T>? get _queryOrNull =>
      queryContext?.queryFromDefinition<T>(definition);

  Query<T> applyWhere(
    Query<T> query,
    Object? where, {
    String feature = 'where',
  }) {
    if (where == null) return query;

    if (where is Query<T>) {
      if (!identical(where.context, query.context)) {
        throw StateError(
          '$feature requires the provided Query to use the same QueryContext as the repository.',
        );
      }
      return where;
    }

    if (where is Query<T> Function(Query<T>)) {
      return where(query);
    }

    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: query.context.codecRegistry,
    );
    final map = helper.whereInputToMap(where);
    if (map == null || map.isEmpty) {
      throw StateError(
        'Unsupported where input for ${definition.modelName}: ${where.runtimeType}',
      );
    }

    var q = query;
    map.forEach((key, value) {
      q = q.where(key, value);
    });
    return q;
  }

  Query<T> _requireQuery(String method) {
    final q = _queryOrNull;
    if (q != null) return q;
    throw StateError(
      '$method requires a QueryContext; construct Repository via QueryContext.repository() or Model.repository() with a registered connection.',
    );
  }

  MutationRow mutationRowFromModel(
    T model, {
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final allValues = definition.toMap(model, registry: codecs);
    final keyColumn = definition.primaryKeyField?.columnName;
    if (keyColumn == null) {
      throw StateError(
        'Primary key required for mutations on ${definition.modelName}.',
      );
    }
    final keyValue = allValues[keyColumn];
    if (keyValue == null) {
      throw StateError('Primary key column $keyColumn cannot be null.');
    }

    // Filter out non-updatable fields (like primary keys)
    final values = <String, Object?>{};
    for (final field in definition.fields) {
      if (field.isUpdatable && allValues.containsKey(field.columnName)) {
        values[field.columnName] = allValues[field.columnName];
      }
    }

    final jsonClauses = jsonUpdatesFor(model, jsonUpdates);
    return MutationRow(
      values: values,
      keys: {keyColumn: keyValue},
      jsonUpdates: jsonClauses,
    );
  }

  List<T> mapResult(List<T> original, MutationResult result, bool returning) {
    // Delegate to the new method with empty inputMaps for backward compatibility
    return mapResultWithInputs(original, const [], result, returning);
  }

  /// Maps mutation results back to model instances.
  ///
  /// This method handles merging returned data (e.g., auto-generated PKs) with
  /// the original input data. It supports:
  /// - Tracked models in [original] list
  /// - Input maps from DTOs/Maps in [inputMaps] list
  ///
  /// The merge priority is: returned data > original model data > input map data
  ///
  /// [canCreateFromInputs] indicates whether [inputMaps] contain complete data
  /// that can be used to create model instances when no returned data is available.
  /// This should be `true` for inserts/upserts (complete row data) and `false`
  /// for updates (partial data).
  List<T> mapResultWithInputs(
    List<T> original,
    List<Map<String, Object?>> inputMaps,
    MutationResult result,
    bool returning, {
    bool canCreateFromInputs = true,
  }) {
    // If driver returned data (e.g., lastInsertID), merge it with inputs
    if (result.returnedRows != null && result.returnedRows!.isNotEmpty) {
      // Merge returned data with original models
      // Some drivers (like MySQL) only return PKs via lastInsertID, not full rows
      final returned = <T>[];
      for (int i = 0; i < result.returnedRows!.length; i++) {
        final returnedRow = result.returnedRows![i];
        final originalModel = i < original.length ? original[i] : null;
        final inputMap = i < inputMaps.length ? inputMaps[i] : null;

        final Map<String, Object?> mergedData;
        if (originalModel != null) {
          // Merge returned data (e.g., auto-generated PK) with original model data
          final originalData = definition.toMap(
            originalModel,
            registry: codecs,
          );
          mergedData = {...originalData, ...returnedRow};
        } else if (inputMap != null) {
          // For DTOs/Maps, merge returned data with the input map
          // This ensures required fields from the input are preserved
          mergedData = {...inputMap, ...returnedRow};
        } else {
          mergedData = returnedRow;
        }

        final model = definition.fromMap(mergedData, registry: codecs);
        attachRuntimeMetadata(model);

        // Sync original state for change tracking
        if (model is ModelAttributes) {
          final attrs = model as ModelAttributes;
          attrs.syncOriginal();
        }

        returned.add(model);
      }
      return returned;
    }

    // No returned rows from driver
    // If we have original models, return those
    if (original.isNotEmpty) {
      return original;
    }

    // For DTOs/Maps with no returned data, create models from input maps
    // only if the inputs contain complete data (inserts/upserts)
    // For updates, inputMaps only have partial data and can't create valid models
    if (canCreateFromInputs && inputMaps.isNotEmpty) {
      return inputMaps.map((map) {
        final model = definition.fromMap(map, registry: codecs);
        attachRuntimeMetadata(model);
        if (model is ModelAttributes) {
          (model as ModelAttributes).syncOriginal();
        }
        return model;
      }).toList();
    }

    return const [];
  }

  void requireModels(List<T> models, String method) {
    if (models.isEmpty) {
      throw ArgumentError.value(models, 'models', '$method requires models');
    }
  }

  void requireKeys(List<Map<String, Object?>> keys) {
    if (keys.isEmpty) {
      throw ArgumentError.value(keys, 'keys', 'At least one key required');
    }
    for (final entry in keys) {
      if (entry.isEmpty) {
        throw ArgumentError.value(entry, 'key', 'Key map cannot be empty');
      }
    }
  }

  List<String>? resolveColumnNames(List<String>? fields) {
    if (fields == null) return null;
    if (fields.isEmpty) {
      throw ArgumentError.value(fields, 'fields', 'At least one column name.');
    }
    return fields
        .map((name) => fieldFor(name).columnName)
        .toList(growable: false);
  }

  FieldDefinition fieldFor(String name) {
    final match = definition.fields.firstWhere(
      (field) => field.name == name || field.columnName == name,
      orElse: () => throw ArgumentError.value(
        name,
        'field',
        'Unknown field on ${definition.modelName}.',
      ),
    );
    return match;
  }

  List<JsonUpdateClause> jsonUpdatesFor(
    T model,
    JsonUpdateBuilder<T>? builder,
  ) {
    final support = JsonUpdateSupport<T>(definition);
    return support.buildJsonUpdates(model, builder);
  }

  String resolveColumnName(String input) {
    for (final field in definition.fields) {
      if (field.name == input || field.columnName == input) {
        return field.columnName;
      }
    }
    return input;
  }
}
