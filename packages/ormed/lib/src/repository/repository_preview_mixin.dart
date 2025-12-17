part of 'repository.dart';

/// Mixin that provides preview methods for repository operations.
///
/// Preview methods accept the same inputs as the corresponding write methods.
///
/// {@macro ormed.query.insert_inputs}
/// {@macro ormed.query.update_inputs}
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
  /// {@macro ormed.query.insert_inputs}
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
  /// {@macro ormed.query.insert_inputs}
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
    final query = _requireQuery('previewInsertMany');
    final plan = query.previewInsertPlan(inputs);
    return describeMutation(plan);
  }

  /// Returns the statement preview for inserting items while ignoring conflicts.
  ///
  /// {@macro ormed.query.insert_inputs}
  StatementPreview previewInsertOrIgnoreMany(List<Object> inputs) {
    if (inputs.isEmpty) {
      throw ArgumentError.value(
        inputs,
        'inputs',
        'previewInsertOrIgnoreMany requires inputs',
      );
    }
    final query = _requireQuery('previewInsertOrIgnoreMany');
    final plan = query.previewInsertPlan(inputs, ignoreConflicts: true);
    return describeMutation(plan);
  }

  /// Returns the statement preview for updating items.
  ///
  /// {@macro ormed.query.update_inputs}
  /// {@macro ormed.mutation.json_updates}
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
    final query = _requireQuery('previewUpdateMany');
    final plan = query.previewUpdatePlan(
      inputs,
      where: where,
      jsonUpdates: jsonUpdates,
    );
    return describeMutation(plan);
  }

  /// Returns the statement preview for upserting items.
  ///
  /// {@macro ormed.query.insert_inputs}
  /// {@macro ormed.query.upsert_options}
  /// {@macro ormed.mutation.json_updates}
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
    final query = _requireQuery('previewUpsertMany');
    final plan = query.previewUpsertPlan(
      inputs,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
      returning: false,
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
    final query = _requireQuery('previewDeleteByKeys');
    final plan = query.previewDeleteWherePlan(keys);
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
  /// {@macro ormed.query.where_input}
  StatementPreview previewDeleteMany(List<Object> wheres) {
    if (wheres.isEmpty) {
      throw ArgumentError.value(
        wheres,
        'wheres',
        'previewDeleteMany requires inputs',
      );
    }
    final query = _requireQuery('previewDeleteMany');
    final plan = query.previewDeleteWherePlan(wheres);
    return describeMutation(plan);
  }

  /// Returns the statement preview for deleting a single where clause.
  StatementPreview previewDeleteWhere(Object where) =>
      previewDeleteMany([where]);
}
