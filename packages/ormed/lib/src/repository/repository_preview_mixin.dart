part of 'repository.dart';

/// Mixin that provides preview methods for repository operations.
///
/// This mixin supports previewing operations with:
/// - Tracked models (`$Model`)
/// - Insert/Update DTOs
/// - Raw maps (`Map<String, Object?>`)
mixin RepositoryPreviewMixin<T extends OrmEntity>
    on
        RepositoryBase<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInputHandlerMixin<T>,
        RepositoryInsertMixin<T>,
        RepositoryUpdateMixin<T>,
        RepositoryUpsertMixin<T>,
        RepositoryDeleteMixin<T> {
  /// Returns the statement preview for inserting a single item.
  ///
  /// Accepts tracked models, insert DTOs, or raw maps.
  ///
  /// Example:
  /// ```dart
  /// final user = $User(name: 'John Doe', email: 'john@example.com');
  /// final preview = repository.previewInsert(user);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// ```
  StatementPreview previewInsert(Object model) => previewInsertMany([model]);

  /// Returns the statement preview for inserting multiple items.
  ///
  /// Accepts a list of tracked models, insert DTOs, or raw maps.
  ///
  /// Example:
  /// ```dart
  /// final users = [
  ///   $UserInsertDto(name: 'John', email: 'john@example.com'),
  ///   {'name': 'Jane', 'email': 'jane@example.com'},
  /// ];
  /// final preview = repository.previewInsertMany(users);
  /// ```
  StatementPreview previewInsertMany(List<Object> inputs) {
    if (inputs.isEmpty) {
      throw ArgumentError.value(
        inputs,
        'inputs',
        'previewInsertMany requires inputs',
      );
    }
    final hasTrackedModels = inputs.any((input) => isTrackedModel(input));
    final plan = buildInsertPlanFromInputs(
      inputs,
      applySentinelFiltering: hasTrackedModels,
    );
    return describeMutation(plan);
  }

  /// Returns the statement preview for inserting items while ignoring conflicts.
  ///
  /// Accepts a list of tracked models, insert DTOs, or raw maps.
  StatementPreview previewInsertOrIgnoreMany(List<Object> inputs) {
    if (inputs.isEmpty) {
      throw ArgumentError.value(
        inputs,
        'inputs',
        'previewInsertOrIgnoreMany requires inputs',
      );
    }
    final hasTrackedModels = inputs.any((input) => isTrackedModel(input));
    final plan = buildInsertPlanFromInputs(
      inputs,
      ignoreConflicts: true,
      applySentinelFiltering: hasTrackedModels,
    );
    return describeMutation(plan);
  }

  /// Returns the statement preview for updating items.
  ///
  /// Accepts a list of tracked models, update DTOs, or raw maps.
  ///
  /// Example:
  /// ```dart
  /// final dto = $UserUpdateDto(id: 1, email: 'newemail@example.com');
  /// final preview = repository.previewUpdateMany([dto]);
  /// ```
  StatementPreview previewUpdateMany(
    List<Object> inputs, {
    Map<String, Object?>? where,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    if (inputs.isEmpty) {
      throw ArgumentError.value(
        inputs,
        'inputs',
        'previewUpdateMany requires inputs',
      );
    }
    final plan = buildUpdatePlanFromInputs(
      inputs,
      where: where,
      jsonUpdates: jsonUpdates,
    );
    return describeMutation(plan);
  }

  /// Returns the statement preview for upserting items.
  ///
  /// Accepts a list of tracked models, insert DTOs, or raw maps.
  ///
  /// Example:
  /// ```dart
  /// final users = [
  ///   $User(id: 1, name: 'John Doe', email: 'john@example.com'),
  ///   {'name': 'Jane Doe', 'email': 'jane@example.com'},
  /// ];
  /// final preview = repository.previewUpsertMany(users, uniqueBy: ['email']);
  /// ```
  StatementPreview previewUpsertMany(
    List<Object> inputs, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    if (inputs.isEmpty) {
      throw ArgumentError.value(
        inputs,
        'inputs',
        'previewUpsertMany requires inputs',
      );
    }
    final plan = buildUpsertPlanFromInputs(
      inputs,
      returning: false,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
    return describeMutation(plan);
  }

  /// Returns the statement preview for deleting records by [keys].
  ///
  /// Example:
  /// ```dart
  /// final preview = repository.previewDeleteByKeys([{'id': 1}, {'id': 2}]);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewDeleteByKeys(List<Map<String, Object?>> keys) {
    requireKeys(keys);
    final plan = buildDeletePlan(keys);
    return describeMutation(plan);
  }

  /// Returns the statement preview for deleting the row described by [key].
  ///
  /// Example:
  /// ```dart
  /// final preview = repository.previewDelete({'id': 1});
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewDelete(Map<String, Object?> key) =>
      previewDeleteByKeys([key]);

  /// Returns the statement preview for deleting using flexible where inputs.
  ///
  /// Accepts the same inputs as [RepositoryDeleteMixin.delete].
  StatementPreview previewDeleteMany(List<Object> wheres) {
    if (wheres.isEmpty) {
      throw ArgumentError.value(
        wheres,
        'wheres',
        'previewDeleteMany requires inputs',
      );
    }
    final plan = buildDeletePlanFromWhereInputs(wheres);
    return describeMutation(plan);
  }

  /// Returns the statement preview for deleting a single where clause.
  StatementPreview previewDeleteWhere(Object where) =>
      previewDeleteMany([where]);
}
