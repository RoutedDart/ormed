part of 'repository.dart';

/// Mixin that provides upsert operations for repositories.
mixin RepositoryUpsertMixin<T> on RepositoryBase<T>, RepositoryHelpersMixin<T> {
  /// Upserts multiple [models] in the database.
  ///
  /// If a model with the same unique key already exists, it is updated.
  /// Otherwise, a new model is inserted.
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
  /// final users = [User(id: 1, name: 'John Doe'), User(name: 'Jane Doe')];
  /// final upsertedUsers = await repository.upsertMany(users, returning: true);
  /// print(upsertedUsers.map((u) => u.id).toList());
  /// ```
  Future<List<T>> upsertMany(
    List<T> models, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (models.isEmpty) return const [];
    final plan = buildUpsertPlan(
      models,
      returning: returning,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
    final result = await runMutation(plan);

    return mapResult(models, result, returning);
  }
}
