part of 'repository.dart';

/// Mixin that provides update operations for repositories.
///
/// This mixin supports updating data using:
/// - Tracked models (`$Model`)
/// - Update DTOs (`$ModelUpdateDto`)
/// - Raw maps (`Map<String, Object?>`)
mixin RepositoryUpdateMixin<T extends OrmEntity>
    on RepositoryBase<T>, RepositoryHelpersMixin<T>, RepositoryInputHandlerMixin<T> {
  /// Updates a single [model] in the database.
  ///
  /// Accepts tracked models, update DTOs, or raw maps.
  ///
  /// When using a DTO or map, a [where] clause must be provided to identify
  /// which row(s) to update. When using a tracked model, the primary key is
  /// extracted automatically.
  ///
  /// By default, the returned future completes with the same model instance
  /// that was passed in. If [returning] is `true`, the returned future
  /// completes with a new model instance that contains the values that were
  /// actually updated in the database.
  ///
  /// Example with tracked model:
  /// ```dart
  /// final user = await repository.find(1);
  /// user.name = 'John Smith';
  /// final updated = await repository.update(user, returning: true);
  /// ```
  ///
  /// Example with update DTO:
  /// ```dart
  /// final dto = $UserUpdateDto(name: 'John Smith');
  /// final updated = await repository.update(dto, where: {'id': 1}, returning: true);
  /// ```
  ///
  /// Example with raw map:
  /// ```dart
  /// final data = {'name': 'John Smith'};
  /// final updated = await repository.update(data, where: {'id': 1}, returning: true);
  /// ```
  Future<T> update(
    Object model, {
    Map<String, Object?>? where,
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    final updated = await updateMany(
      [model],
      where: where,
      returning: returning,
      jsonUpdates: jsonUpdates,
    );
    return updated.first;
  }

  /// Updates multiple items in the database.
  ///
  /// Accepts a list of tracked models, update DTOs, or raw maps.
  ///
  /// When using DTOs or maps, a [where] clause must be provided to identify
  /// which row(s) to update. When using tracked models, the primary key is
  /// extracted automatically from each model.
  ///
  /// By default, the returned future completes with the same model instances
  /// that were passed in. If [returning] is `true`, the returned future
  /// completes with new model instances that contain the values that were
  /// actually updated in the database.
  ///
  /// An optional [jsonUpdates] builder can be provided to update JSON fields.
  ///
  /// Example:
  /// ```dart
  /// final users = await repository.findMany([1, 2]);
  /// for (final user in users) {
  ///   user.active = true;
  /// }
  /// final updatedUsers = await repository.updateMany(users, returning: true);
  /// ```
  Future<List<T>> updateMany(
    List<Object> inputs, {
    Map<String, Object?>? where,
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const [];

    final plan = buildUpdatePlanFromInputs(
      inputs,
      where: where,
      returning: returning,
      jsonUpdates: jsonUpdates,
    );
    final result = await runMutation(plan);

    final originalModels = inputs.whereType<T>().toList();

    // Extract the input maps from the plan for merging with returned data
    // For updates, include both values and keys to have complete data
    final inputMaps = plan.rows.map((r) => {...r.values, ...r.keys}).toList();

    return mapResultWithInputs(
      originalModels,
      inputMaps,
      result,
      returning,
      canCreateFromInputs: false,
    );
  }

  /// Updates multiple items in the database and returns the raw result.
  Future<MutationResult> updateManyRaw(
    List<Object> inputs, {
    Map<String, Object?>? where,
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const MutationResult(affectedRows: 0);

    final plan = buildUpdatePlanFromInputs(
      inputs,
      where: where,
      returning: returning,
      jsonUpdates: jsonUpdates,
    );
    return runMutation(plan);
  }

  /// Builds an update plan from various input types.
  MutationPlan buildUpdatePlanFromInputs(
    List<Object> inputs, {
    Map<String, Object?>? where,
    required bool returning,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final rows = inputs.map((input) {
      // Apply timestamps to tracked models before serialization
      if (input is T) {
        _applyUpdateTimestampsToModel(input);
      }

      final values = updateInputToMap(input);

      // For non-tracked models, ensure updated_at in the map
      if (input is! ModelAttributes) {
        _ensureTimestampsInMap(values, isInsert: false);
      }

      // Determine keys for the update
      final Map<String, Object?> keys;
      if (input is T) {
        // For tracked models, extract PK from the model
        final pkField = definition.primaryKeyField;
        if (pkField == null) {
          throw StateError(
            'Primary key required for updates on ${definition.modelName}.',
          );
        }
        final allValues = definition.toMap(input, registry: codecs);
        final pkValue = allValues[pkField.columnName];
        if (pkValue == null) {
          throw StateError('Primary key cannot be null for update.');
        }
        keys = {pkField.columnName: pkValue};
      } else if (where != null) {
        // For DTOs/maps, use the provided where clause
        keys = _normalizeColumnNames(where);
      } else {
        // Try to extract PK from the input
        final pk = extractPrimaryKey(input);
        if (pk == null) {
          throw ArgumentError(
            'Update with DTO or Map requires a "where" clause or PK in the data.',
          );
        }
        final pkField = definition.primaryKeyField!;
        keys = {pkField.columnName: pk};
      }

      final jsonClauses = input is T ? jsonUpdatesFor(input, jsonUpdates) : <JsonUpdateClause>[];

      return MutationRow(
        values: values,
        keys: keys,
        jsonUpdates: jsonClauses,
      );
    }).toList(growable: false);

    return MutationPlan.update(
      definition: definition,
      rows: rows,
      driverName: driverName,
      returning: returning,
    );
  }
}
