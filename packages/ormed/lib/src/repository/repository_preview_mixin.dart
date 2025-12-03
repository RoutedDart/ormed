part of 'repository.dart';

/// Mixin that provides preview methods for repository operations.
mixin RepositoryPreviewMixin<T>
    on RepositoryBase<T>, RepositoryHelpersMixin<T> {
  /// Returns the statement preview for inserting [model].
  ///
  /// Example:
  /// ```dart
  /// final user = User(name: 'John Doe');
  /// final preview = repository.previewInsert(user);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewInsert(T model) => previewInsertMany([model]);

  /// Returns the statement preview for inserting [models].
  ///
  /// Example:
  /// ```dart
  /// final users = [User(name: 'John Doe'), User(name: 'Jane Doe')];
  /// final preview = repository.previewInsertMany(users);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewInsertMany(List<T> models) {
    requireModels(models, 'previewInsertMany');
    final plan = buildInsertPlan(models, returning: false);
    return describeMutation(plan);
  }

  /// Returns the statement preview for inserting [models] while ignoring conflicts.
  ///
  /// Example:
  /// ```dart
  /// final users = [User(id: 1, name: 'John Doe'), User(id: 2, name: 'Jane Doe')];
  /// final preview = repository.previewInsertOrIgnoreMany(users);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewInsertOrIgnoreMany(List<T> models) {
    requireModels(models, 'previewInsertOrIgnoreMany');
    final plan = buildInsertPlan(
      models,
      returning: false,
      ignoreConflicts: true,
    );
    return describeMutation(plan);
  }

  /// Returns the statement preview for updating [models].
  ///
  /// Example:
  /// ```dart
  /// final user = await repository.find(1);
  /// user.name = 'John Smith';
  /// final preview = repository.previewUpdateMany([user]);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewUpdateMany(
    List<T> models, {
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    requireModels(models, 'previewUpdateMany');
    final plan = buildUpdatePlan(
      models,
      returning: false,
      jsonUpdates: jsonUpdates,
    );
    return describeMutation(plan);
  }

  /// Returns the statement preview for upserting [models].
  ///
  /// Example:
  /// ```dart
  /// final users = [User(id: 1, name: 'John Doe'), User(name: 'Jane Doe')];
  /// final preview = repository.previewUpsertMany(users);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewUpsertMany(
    List<T> models, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    requireModels(models, 'previewUpsertMany');
    final plan = buildUpsertPlan(
      models,
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
}
