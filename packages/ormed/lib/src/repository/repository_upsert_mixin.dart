part of 'repository.dart';

/// Mixin that provides upsert operations for repositories.
///
/// This mixin supports upserting data using:
/// - Tracked models (`$Model`)
/// - Insert DTOs (`$ModelInsertDto`)
/// - Update DTOs (`$ModelUpdateDto`)
/// - Raw maps (`Map<String, Object?>`)
mixin RepositoryUpsertMixin<T extends OrmEntity>
    on RepositoryBase<T>, RepositoryHelpersMixin<T>, RepositoryInputHandlerMixin<T> {
  /// Upserts a single item in the database and returns the result.
  ///
  /// Accepts tracked models, insert DTOs, update DTOs, or raw maps.
  ///
  /// If an item with the same unique key already exists, it is updated.
  /// Otherwise, a new item is inserted.
  ///
  /// The [uniqueBy] parameter specifies the fields that make up the unique key.
  /// If not provided, the primary key is used.
  ///
  /// The [updateColumns] parameter specifies which columns to update if a
  /// conflict occurs. If not provided, all columns are updated.
  ///
  /// Example with tracked model:
  /// ```dart
  /// final user = $User(id: 1, name: 'John Doe', email: 'john@example.com');
  /// final upserted = await repository.upsert(user);
  /// ```
  ///
  /// Example with insert DTO:
  /// ```dart
  /// final dto = $UserInsertDto(name: 'John Doe', email: 'john@example.com');
  /// final upserted = await repository.upsert(dto, uniqueBy: ['email']);
  /// ```
  Future<T> upsert(
    Object model, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    final upserted = await upsertMany(
      [model],
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
    return upserted.first;
  }

  /// Upserts multiple items in the database and returns the results.
  ///
  /// Accepts a list of tracked models, insert DTOs, update DTOs, or raw maps.
  ///
  /// If an item with the same unique key already exists, it is updated.
  /// Otherwise, a new item is inserted.
  ///
  /// The [uniqueBy] parameter specifies the fields that make up the unique key.
  /// If not provided, the primary key is used.
  ///
  /// The [updateColumns] parameter specifies which columns to update if a
  /// conflict occurs. If not provided, all columns are updated.
  ///
  /// An optional [jsonUpdates] builder can be provided to update JSON fields.
  ///
  /// Example:
  /// ```dart
  /// final users = [
  ///   $UserInsertDto(name: 'John', email: 'john@example.com'),
  ///   $UserInsertDto(name: 'Jane', email: 'jane@example.com'),
  /// ];
  /// final upsertedUsers = await repository.upsertMany(
  ///   users,
  ///   uniqueBy: ['email'],
  /// );
  /// ```
  Future<List<T>> upsertMany(
    List<Object> inputs, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const [];

    final plan = buildUpsertPlanFromInputs(
      inputs,
      returning: true,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
    final result = await runMutation(plan);

    final originalModels = inputs.whereType<T>().toList();

    // Extract the input maps from the plan for merging with returned data
    final inputMaps = plan.rows.map((r) => r.values).toList();
    return mapResultWithInputs(originalModels, inputMaps, result, true);
  }

  /// Builds an upsert plan from various input types.
  ///
  /// Supports the following input types:
  /// - `T` (tracked model like `$User`) - Uses full definition encoding
  /// - `InsertDto<T>` (like `UserInsertDto`) - Uses the DTO's `toMap()` directly
  /// - `UpdateDto<T>` (like `UserUpdateDto`) - Uses the DTO's `toMap()` directly
  /// - `Map<String, Object?>` - Uses as-is with column name normalization
  MutationPlan buildUpsertPlanFromInputs(
    List<Object> inputs, {
    required bool returning,
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final rows = inputs.map((input) {
      // For upserts, we need both insert and update values
      final (Map<String, Object?> values, Map<String, Object?> keys) = switch (input) {
        // Tracked model ($User) - use full definition encoding
        T model => _upsertValuesFromModel(model),
        // InsertDto (UserInsertDto) - use the DTO's toMap() directly
        InsertDto<T> dto => _upsertValuesFromDto(dto),
        // UpdateDto (UserUpdateDto) - also supported for flexibility
        UpdateDto<T> dto => _upsertValuesFromUpdateDto(dto),
        // Raw Map - use as-is with column name normalization
        Map<String, Object?> m => _upsertValuesFromMap(m),
        // Fallback - throw for unsupported types
        _ => throw ArgumentError.value(
          input,
          'input',
          'Expected $T, InsertDto<$T>, UpdateDto<$T>, or Map<String, Object?>, got ${input.runtimeType}',
        ),
      };

      final jsonClauses = input is T ? jsonUpdatesFor(input, jsonUpdates) : <JsonUpdateClause>[];

      return MutationRow(
        values: values,
        keys: keys,
        jsonUpdates: jsonClauses,
      );
    }).toList(growable: false);

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

  /// Extracts upsert values and keys from a tracked model.
  (Map<String, Object?>, Map<String, Object?>) _upsertValuesFromModel(T model) {
    final allValues = definition.toMap(model, registry: codecs);

    // Extract primary key for the keys map
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError(
        'Primary key required for upserts on ${definition.modelName}.',
      );
    }
    final pkValue = allValues[pkField.columnName];
    if (pkValue == null) {
      throw StateError('Primary key cannot be null for upsert.');
    }
    final keys = {pkField.columnName: pkValue};

    // For upserts, include ALL insertable fields in values (not just updatable)
    // The INSERT part needs all fields, and the adapter will determine
    // which columns to use for the ON CONFLICT DO UPDATE clause
    final values = <String, Object?>{};
    for (final field in definition.fields) {
      if (field.isInsertable && allValues.containsKey(field.columnName)) {
        values[field.columnName] = allValues[field.columnName];
      }
    }
    // Also include the primary key if it's specified and not auto-increment
    // (or even if it's auto-increment, if the user provided a value)
    if (allValues.containsKey(pkField.columnName)) {
      values[pkField.columnName] = allValues[pkField.columnName];
    }

    return (values, keys);
  }

  /// Extracts upsert values and keys from an InsertDto.
  (Map<String, Object?>, Map<String, Object?>) _upsertValuesFromDto(InsertDto<T> dto) {
    final values = _normalizeColumnNames(dto.toMap());
    final pk = extractPrimaryKey(dto);
    final pkField = definition.primaryKeyField;
    final keys = (pkField != null && pk != null)
        ? {pkField.columnName: pk}
        : const <String, Object?>{};
    return (values, keys);
  }

  /// Extracts upsert values and keys from an UpdateDto.
  (Map<String, Object?>, Map<String, Object?>) _upsertValuesFromUpdateDto(UpdateDto<T> dto) {
    final values = _normalizeColumnNames(dto.toMap());
    final pk = extractPrimaryKey(dto);
    final pkField = definition.primaryKeyField;
    final keys = (pkField != null && pk != null)
        ? {pkField.columnName: pk}
        : const <String, Object?>{};
    return (values, keys);
  }

  /// Extracts upsert values and keys from a raw Map.
  (Map<String, Object?>, Map<String, Object?>) _upsertValuesFromMap(Map<String, Object?> data) {
    final values = _normalizeColumnNames(data);
    final pk = extractPrimaryKey(data);
    final pkField = definition.primaryKeyField;
    final keys = (pkField != null && pk != null)
        ? {pkField.columnName: pk}
        : const <String, Object?>{};
    return (values, keys);
  }

  /// Normalizes field names to column names if needed.
  @override
  Map<String, Object?> _normalizeColumnNames(Map<String, Object?> input) {
    final result = <String, Object?>{};
    for (final entry in input.entries) {
      final columnName = _fieldToColumnName(entry.key);
      result[columnName] = entry.value;
    }
    return result;
  }

  /// Converts a field name to its corresponding column name.
  @override
  String _fieldToColumnName(String fieldOrColumn) {
    for (final field in definition.fields) {
      if (field.columnName == fieldOrColumn) {
        return fieldOrColumn;
      }
    }
    for (final field in definition.fields) {
      if (field.name == fieldOrColumn) {
        return field.columnName;
      }
    }
    return fieldOrColumn;
  }
}
