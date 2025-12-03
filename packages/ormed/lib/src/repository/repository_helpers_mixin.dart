part of 'repository.dart';

/// Mixin that provides internal helper methods for repository operations.
mixin RepositoryHelpersMixin<T> on RepositoryBase<T> {
  MutationRow mutationRowFromModel(
    T model, {
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final values = definition.toMap(model, registry: codecs);
    final keyColumn = definition.primaryKeyField?.columnName;
    if (keyColumn == null) {
      throw StateError(
        'Primary key required for mutations on ${definition.modelName}.',
      );
    }
    final keyValue = values[keyColumn];
    if (keyValue == null) {
      throw StateError('Primary key column $keyColumn cannot be null.');
    }
    final jsonClauses = jsonUpdatesFor(model, jsonUpdates);
    return MutationRow(
      values: values,
      keys: {keyColumn: keyValue},
      jsonUpdates: jsonClauses,
    );
  }

  List<T> mapResult(List<T> original, MutationResult result, bool returning) {
    // If driver returned data (e.g., lastInsertID), merge it even if returning wasn't explicitly requested
    if (result.returnedRows == null || result.returnedRows!.isEmpty) {
      return original;
    }

    // Merge returned data with original models
    // Some drivers (like MySQL) only return PKs via lastInsertID, not full rows
    final returned = <T>[];
    for (int i = 0; i < result.returnedRows!.length; i++) {
      final returnedRow = result.returnedRows![i];
      final originalModel = i < original.length ? original[i] : null;

      final Map<String, Object?> mergedData;
      if (originalModel != null) {
        // Merge returned data (e.g., auto-generated PK) with original model data
        final originalData = definition.toMap(originalModel, registry: codecs);
        mergedData = {...originalData, ...returnedRow};
      } else {
        mergedData = returnedRow;
      }

      final model = definition.fromMap(mergedData, registry: codecs);
      attachRuntimeMetadata(model);
      returned.add(model);
    }
    return returned;
  }

  MutationPlan buildInsertPlan(
    List<T> models, {
    required bool returning,
    bool ignoreConflicts = false,
  }) {
    final rows = models
        .map((model) {
          final map = definition.toMap(model, registry: codecs);

          // Filter out auto-increment primary keys with default/zero values
          // to allow the database to generate them
          final filtered = Map<String, Object?>.from(map);
          for (final field in definition.fields) {
            if (field.isPrimaryKey && field.autoIncrement) {
              final value = map[field.columnName];
              // Remove if null, 0, or empty string (common sentinel values)
              if (value == null || value == 0 || value == '') {
                filtered.remove(field.columnName);
              }
            }
          }
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

  MutationPlan buildUpdatePlan(
    List<T> models, {
    required bool returning,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final rows = models
        .map((model) => mutationRowFromModel(model, jsonUpdates: jsonUpdates))
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
      final pending = model.takeJsonAttributeUpdates();
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
}
