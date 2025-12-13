part of 'repository.dart';

/// Mixin that provides upsert operations for repositories.
///
/// This mixin supports upserting data using:
/// - Tracked models (`$Model`)
/// - Insert DTOs (`$ModelInsertDto`)
/// - Raw maps (`Map<String, Object?>`)
mixin RepositoryUpsertMixin<T extends OrmEntity>
    on RepositoryBase<T>, RepositoryHelpersMixin<T>, RepositoryInputHandlerMixin<T> {
  /// Upserts a single item in the database.
  ///
  /// Accepts tracked models, insert DTOs, or raw maps.
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
  /// final upserted = await repository.upsert(user, returning: true);
  /// ```
  ///
  /// Example with insert DTO:
  /// ```dart
  /// final dto = $UserInsertDto(name: 'John Doe', email: 'john@example.com');
  /// final upserted = await repository.upsert(dto, uniqueBy: ['email'], returning: true);
  /// ```
  Future<T> upsert(
    Object model, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    final upserted = await upsertMany(
      [model],
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      returning: returning,
      jsonUpdates: jsonUpdates,
    );
    return upserted.first;
  }

  /// Upserts multiple items in the database.
  ///
  /// Accepts a list of tracked models, insert DTOs, or raw maps.
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
  /// By default, the returned future completes with the same model instances
  /// that were passed in. If [returning] is `true`, the returned future
  /// completes with new model instances that contain the values that were
  /// actually upserted in the database.
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
  ///   returning: true,
  /// );
  /// ```
  Future<List<T>> upsertMany(
    List<Object> inputs, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const [];

    final plan = buildUpsertPlanFromInputs(
      inputs,
      returning: returning,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
    final result = await runMutation(plan);

    final originalModels = inputs.whereType<T>().toList();

    // Extract the input maps from the plan for merging with returned data
    final inputMaps = plan.rows.map((r) => r.values).toList();
    return mapResultWithInputs(originalModels, inputMaps, result, returning);
  }

  /// Builds an upsert plan from various input types.
  MutationPlan buildUpsertPlanFromInputs(
    List<Object> inputs, {
    required bool returning,
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final rows = inputs.map((input) {
      // For upserts, we need both insert and update values
      final Map<String, Object?> values;
      final Map<String, Object?> keys;

      if (input is T) {
        // For tracked models, use the full serialization
        final allValues = definition.toMap(input, registry: codecs);

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
        keys = {pkField.columnName: pkValue};

        // For upserts, include ALL insertable fields in values (not just updatable)
        // The INSERT part needs all fields, and the adapter will determine
        // which columns to use for the ON CONFLICT DO UPDATE clause
        values = <String, Object?>{};
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
      } else {
        // For DTOs/maps, convert to map and extract PK if available
        values = insertInputToMap(input, applySentinelFiltering: false);

        final pk = extractPrimaryKey(input);
        final pkField = definition.primaryKeyField;
        if (pkField != null && pk != null) {
          keys = {pkField.columnName: pk};
        } else {
          keys = const {};
        }
      }

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
}
