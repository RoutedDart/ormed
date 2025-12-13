part of 'repository.dart';

/// Mixin that provides internal helper methods for repository operations.
mixin RepositoryHelpersMixin<T extends OrmEntity> on RepositoryBase<T> {
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
          final originalData = definition.toMap(originalModel, registry: codecs);
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

  /// Builds an insert plan from tracked models only.
  ///
  /// This is the legacy method that only accepts tracked models.
  /// For DTOs and Maps, use `buildInsertPlanFromInputs` from the insert mixin.
  MutationPlan buildInsertPlan(
    List<T> models, {
    required bool returning,
    bool ignoreConflicts = false,
  }) {
    final rows = models
        .map((model) {
          // Apply timestamps to tracked models BEFORE serialization
          _applyInsertTimestampsToModel(model);

          final map = definition.toMap(model, registry: codecs);

          // Filter out non-insertable fields and auto-increment fields with sentinel values
          final filtered = Map<String, Object?>.from(map);
          for (final field in definition.fields) {
            // Skip fields marked as non-insertable
            if (!field.isInsertable) {
              final value = map[field.columnName];
              // Only remove if value is a sentinel (null, -1, 0, empty string)
              // This allows explicitly set values to pass through
              if (_isSentinelValue(value, field)) {
                filtered.remove(field.columnName);
              }
            }
          }

          // For non-tracked models (const instances), add timestamps to the map
          _ensureTimestampsInMap(filtered, isInsert: true);

          return filtered;
        })
        .toList(growable: false);

    return MutationPlan.insert(
      definition: definition,
      rows: rows,
      driverName: driverName,
      returning: returning,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Checks if a value is a sentinel value indicating "not set".
  ///
  /// For auto-increment fields, sentinel values include:
  /// - `null`
  /// - `-1` (common sentinel for int IDs)
  /// - `0` (alternative sentinel)
  /// - Empty string (for non-int PKs)
  bool _isSentinelValue(Object? value, FieldDefinition field) {
    if (value == null) return true;
    if (field.autoIncrement) {
      if (value == 0 || value == -1) return true;
    }
    if (value == '') return true;
    // Check against configured default dart value
    if (field.defaultDartValue != null && value == field.defaultDartValue) {
      return true;
    }
    return false;
  }

  MutationPlan buildUpdatePlan(
    List<T> models, {
    required bool returning,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final rows = models
        .map((model) {
          // Apply timestamps to tracked models BEFORE serialization
          _applyUpdateTimestampsToModel(model);

          final row = mutationRowFromModel(model, jsonUpdates: jsonUpdates);

          // For non-tracked models, ensure updated_at in the map
          _ensureTimestampsInMap(row.values, isInsert: false);

          return row;
        })
        .toList(growable: false);
    return MutationPlan.update(
      definition: definition,
      rows: rows,
      driverName: driverName,
      returning: returning,
    );
  }

  MutationPlan buildUpsertPlan(
    List<T> models, {
    required bool returning,
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final rows = models
        .map((model) => mutationRowFromModel(model, jsonUpdates: jsonUpdates))
        .toList(growable: false);
    final uniqueColumns = resolveColumnNames(uniqueBy);
    final updateColumnNames = resolveColumnNames(updateColumns);
    return MutationPlan.upsert(
      definition: definition,
      rows: rows,
      driverName: driverName,
      returning: returning,
      uniqueBy: uniqueColumns,
      updateColumns: updateColumnNames,
    );
  }

  MutationPlan buildDeletePlan(List<Map<String, Object?>> keys) {
    final rows = keys
        .map((conditions) => MutationRow(values: const {}, keys: conditions))
        .toList(growable: false);
    return MutationPlan.delete(
      definition: definition,
      rows: rows,
      driverName: driverName,
    );
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
    final clauses = <JsonUpdateClause>[];
    if (builder != null) {
      final definitions = builder(model);
      for (final candidate in definitions) {
        clauses.add(toJsonUpdateClause(candidate));
      }
    }
    if (model is ModelAttributes) {
      final attrs = model as ModelAttributes;
      final pending = attrs.takeJsonAttributeUpdates();
      for (final update in pending) {
        clauses.add(
          JsonUpdateClause(
            column: resolveColumnName(update.fieldOrColumn),
            path: update.path,
            value: update.value,
            patch: update.patch,
          ),
        );
      }
    }
    return clauses;
  }

  JsonUpdateClause toJsonUpdateClause(JsonUpdateDefinition definition) =>
      JsonUpdateClause(
        column: resolveColumnName(definition.fieldOrColumn),
        path: definition.path,
        value: definition.value,
        patch: definition.patch,
      );

  String resolveColumnName(String input) {
    for (final field in definition.fields) {
      if (field.name == input || field.columnName == input) {
        return field.columnName;
      }
    }
    return input;
  }

  /// Applies timestamps for insert operations on tracked models.
  /// Sets created_at and updated_at attributes if the model supports it.
  /// ONLY manages snake_case timestamps to avoid interfering with user fields.
  void _applyInsertTimestampsToModel(T model) {
    if (model is! ModelAttributes) return;
    final attrs = model as ModelAttributes;

    final now = Carbon.now().toUtc().toDateTime();

    // Check if model has created_at field (snake_case only)
    try {
      final createdAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'created_at',
      );
      final columnName = createdAtField.columnName;

      // Only set if not already set
      if (attrs.getAttribute<dynamic>(columnName) == null) {
        attrs.setAttribute(columnName, now);
      }
    } catch (e) {
      // Field doesn't exist - this is expected for models without timestamps
    }

    // Check if model has updated_at field (snake_case only)
    try {
      final updatedAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'updated_at',
      );
      final columnName = updatedAtField.columnName;

      // Only set if not already set
      if (attrs.getAttribute<dynamic>(columnName) == null) {
        attrs.setAttribute(columnName, now);
      }
    } catch (e) {
      // Field doesn't exist - this is expected for models without timestamps
    }
  }

  /// Applies timestamps for update operations on tracked models.
  /// Sets updated_at attribute if the model supports it.
  /// ONLY manages snake_case timestamps to avoid interfering with user fields.
  void _applyUpdateTimestampsToModel(T model) {
    if (model is! ModelAttributes) return;
    final attrs = model as ModelAttributes;

    final now = Carbon.now().toUtc().toDateTime();

    // Check if model has updated_at field (snake_case only)
    try {
      final updatedAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'updated_at',
      );
      final columnName = updatedAtField.columnName;

      // Always update updated_at on updates
      attrs.setAttribute(columnName, now);
    } catch (_) {
      // Field doesn't exist
    }
  }

  /// Ensures timestamps are present in the values map for models that have timestamp fields.
  /// This handles both tracked models (where timestamps were already set) and const/untracked models.
  /// The values map is already encoded, so we need to encode timestamps the same way.
  ///
  /// ONLY manages timestamps with snake_case column names (created_at, updated_at) to avoid
  /// interfering with user-defined camelCase fields like createdAt.
  void _ensureTimestampsInMap(
    Map<String, Object?> values, {
    required bool isInsert,
  }) {
    if (isInsert) {
      // For inserts, set created_at if field exists and value is null
      // ONLY check for snake_case column name to avoid interfering with user fields
      try {
        final createdAtField = definition.fields.firstWhere(
          (f) => f.columnName == 'created_at',
        );
        final columnName = createdAtField.columnName;

        if (!values.containsKey(columnName) ||
            _isNullValue(values[columnName])) {
          // Encode using the field's codec with current timestamp
          final now = _createTimestampValue(createdAtField);
          values[columnName] = codecs.encodeField(createdAtField, now);
        }
      } catch (_) {
        // Field doesn't exist
      }
    }

    // For both inserts and updates, set updated_at if field exists
    // ONLY check for snake_case column name
    try {
      final updatedAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'updated_at',
      );
      final columnName = updatedAtField.columnName;

      if (isInsert) {
        // On insert, only set if not already present
        if (!values.containsKey(columnName) ||
            _isNullValue(values[columnName])) {
          // Encode using the field's codec with current timestamp
          final now = _createTimestampValue(updatedAtField);
          values[columnName] = codecs.encodeField(updatedAtField, now);
        }
      } else {
        // On update, always update (unless explicitly set in this operation)
        // Encode using the field's codec with current timestamp
        final now = _createTimestampValue(updatedAtField);
        values[columnName] = codecs.encodeField(updatedAtField, now);
      }
    } catch (_) {
      // Field doesn't exist
    }
  }

  /// Checks if a value is logically null, including driver-specific null wrappers.
  bool _isNullValue(Object? value) {
    if (value == null) return true;

    // Handle Postgres TypedValue with null
    if (value.runtimeType.toString().contains('TypedValue')) {
      // TypedValue has isSqlNull property or wraps null
      try {
        final dynamic typed = value;
        // Try to access value property
        if (typed.value == null) return true;
        // Try to check isSqlNull flag
        if (typed.isSqlNull == true) return true;
      } catch (_) {
        // Fallback: couldn't access properties
      }
    }

    return false;
  }

  /// Creates an appropriate timestamp value based on the field's Dart type.
  /// Returns DateTime since codecs expect DateTime, not Carbon.
  Object _createTimestampValue(FieldDefinition field) {
    return Carbon.now().toUtc().toDateTime();
  }
}
