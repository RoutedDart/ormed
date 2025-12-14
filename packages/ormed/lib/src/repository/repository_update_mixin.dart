part of 'repository.dart';

/// Mixin that provides update operations for repositories.
///
/// This mixin supports updating data using:
/// - Tracked models (`$Model`)
/// - Update DTOs (`$ModelUpdateDto`)
/// - Raw maps (`Map<String, Object?>`)
mixin RepositoryUpdateMixin<T extends OrmEntity>
    on
        RepositoryBase<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInputHandlerMixin<T> {
  /// Updates a single [model] in the database and returns the updated record.
  ///
  /// Accepts tracked models, update DTOs, or raw maps.
  ///
  /// When using a DTO or map, a [where] clause must be provided to identify
  /// which row(s) to update. When using a tracked model, the primary key is
  /// extracted automatically.
  ///
  /// The [where] parameter accepts:
  /// - `Map<String, Object?>` - Raw column/value pairs
  /// - `$ModelPartial` - Partial entity with the fields to match
  /// - `$ModelUpdateDto` or `$ModelInsertDto` - DTO with fields to match
  /// - Tracked model (`$Model`) - Uses all column values for matching
  ///
  /// Example with tracked model:
  /// ```dart
  /// final user = await repository.find(1);
  /// user.name = 'John Smith';
  /// final updated = await repository.update(user);
  /// ```
  ///
  /// Example with update DTO:
  /// ```dart
  /// final dto = $UserUpdateDto(name: 'John Smith');
  /// final updated = await repository.update(dto, where: {'id': 1});
  /// ```
  ///
  /// Example with partial as where clause:
  /// ```dart
  /// final dto = $UserUpdateDto(name: 'John Smith');
  /// final updated = await repository.update(dto, where: $UserPartial(id: 1));
  /// ```
  ///
  /// Example with raw map:
  /// ```dart
  /// final data = {'name': 'John Smith'};
  /// final updated = await repository.update(data, where: {'id': 1});
  /// ```
  Future<T> update(
    Object model, {
    Object? where,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    final updated = await updateMany(
      [model],
      where: where,
      jsonUpdates: jsonUpdates,
    );
    return updated.first;
  }

  /// Updates multiple items in the database and returns the updated records.
  ///
  /// Accepts a list of tracked models, update DTOs, or raw maps.
  ///
  /// When using DTOs or maps, a [where] clause must be provided to identify
  /// which row(s) to update. When using tracked models, the primary key is
  /// extracted automatically from each model.
  ///
  /// The [where] parameter accepts various input types (see [update] for details).
  ///
  /// An optional [jsonUpdates] builder can be provided to update JSON fields.
  ///
  /// Example:
  /// ```dart
  /// final users = await repository.findMany([1, 2]);
  /// for (final user in users) {
  ///   user.active = true;
  /// }
  /// final updatedUsers = await repository.updateMany(users);
  /// ```
  Future<List<T>> updateMany(
    List<Object> inputs, {
    Object? where,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const [];

    final query = _requireQuery('updateMany');
    return query.updateInputs(inputs, where: where, jsonUpdates: jsonUpdates);
  }

  /// Updates multiple items in the database and returns the raw result.
  ///
  /// Use this when you only need the affected row count, not the updated data.
  Future<MutationResult> updateManyRaw(
    List<Object> inputs, {
    Object? where,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const MutationResult(affectedRows: 0);

    final query = _requireQuery('updateManyRaw');
    return query.updateInputsRaw(
      inputs,
      where: where,
      jsonUpdates: jsonUpdates,
    );
  }
}
