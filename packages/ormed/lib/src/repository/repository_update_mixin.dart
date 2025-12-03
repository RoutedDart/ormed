part of 'repository.dart';

/// Mixin that provides update operations for repositories.
mixin RepositoryUpdateMixin<T> on RepositoryBase<T>, RepositoryHelpersMixin<T> {
  /// Updates multiple [models] in the database.
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
  /// final user = await repository.find(1);
  /// user.name = 'John Smith';
  /// final updatedUsers = await repository.updateMany([user], returning: true);
  /// print(updatedUsers.first.name); // 'John Smith'
  /// ```
  Future<List<T>> updateMany(
    List<T> models, {
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (models.isEmpty) return const [];
    final plan = buildUpdatePlan(
      models,
      returning: returning,
      jsonUpdates: jsonUpdates,
    );
    final result = await runMutation(plan);

    return mapResult(models, result, returning);
  }

  /// Updates multiple [models] in the database and returns the raw result.
  Future<MutationResult> updateManyRaw(
    List<T> models, {
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (models.isEmpty) return const MutationResult(affectedRows: 0);
    final plan = buildUpdatePlan(
      models,
      returning: returning,
      jsonUpdates: jsonUpdates,
    );
    return runMutation(plan);
  }
}
