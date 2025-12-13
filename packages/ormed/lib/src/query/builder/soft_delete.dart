part of '../query_builder.dart';

/// Extension providing soft delete functionality for models.
extension SoftDeleteExtension<T extends OrmEntity> on Query<T> {
  /// Includes soft-deleted models in the query results.
  ///
  /// This method effectively disables the soft-delete global scope if it's applied.
  ///
  /// Example:
  /// ```dart
  /// final allUsers = await context.query<User>()
  ///   .withTrashed()
  ///   .get();
  /// ```
  Query<T> withTrashed() {
    if (_softDeleteField == null) {
      return this;
    }
    return withoutGlobalScope(Query._softDeleteScope);
  }

  /// Retrieves only soft-deleted models.
  ///
  /// This method applies a condition to only select models where the soft-delete
  /// field is not null.
  ///
  /// Example:
  /// ```dart
  /// final deletedUsers = await context.query<User>()
  ///   .onlyTrashed()
  ///   .get();
  /// ```
  Query<T> onlyTrashed() {
    final field = _softDeleteField;
    if (field == null) {
      return this;
    }
    return withTrashed().whereNotNull(field.columnName);
  }

  /// Restores soft-deleted models that match the current query constraints.
  ///
  /// This sets the soft-delete field back to null.
  /// Throws [StateError] if the model does not support soft deletes.
  ///
  /// Example:
  /// ```dart
  /// final restoredCount = await context.query<User>()
  ///   .where('id', 1)
  ///   .restore();
  /// print('Restored $restoredCount users.');
  /// ```
  Future<int> restore() async {
    final field = _requireSoftDeleteSupport('restore');
    final keys = await _collectPrimaryKeyConditions(onlyTrashed());
    if (keys.isEmpty) {
      return 0;
    }
    final rows = keys
        .map((key) => MutationRow(values: {field.columnName: null}, keys: key))
        .toList(growable: false);
    final plan = MutationPlan.update(
      definition: definition,
      rows: rows,
      driverName: context.driver.metadata.name,
    );
    final result = await context.runMutation(plan);
    return result.affectedRows;
  }

  /// Permanently deletes models that match the current query constraints,
  /// bypassing soft deletes.
  ///
  /// Throws [StateError] if the model does not define a primary key or
  /// the driver does not expose a row identifier for query updates.
  ///
  /// Example:
  /// ```dart
  /// final deletedCount = await context.query<User>()
  ///   .where('status', 'inactive')
  ///   .forceDelete();
  /// print('Force deleted $deletedCount inactive users.');
  /// ```
  Future<int> forceDelete() async {
    if (_supportsQueryDeletes) {
      final target = withTrashed();
      final driverMetadata = context.driver.metadata;
      final pk = definition.primaryKeyField;
      final fallbackIdentifier = driverMetadata.queryUpdateRowIdentifier;
      final identifier = pk?.columnName ?? fallbackIdentifier?.column;
      if (identifier == null) {
        throw StateError(
          'forceDelete requires ${definition.modelName} to declare a primary key or expose a driver row identifier.',
        );
      }
      final selection = pk != null ? target.select([pk.name]) : target;
      final plan = MutationPlan.queryDelete(
        definition: definition,
        plan: selection._buildPlan(),
        primaryKey: identifier,
        driverName: driverMetadata.name,
      );
      final result = await context.runMutation(plan);
      return result.affectedRows;
    }
    return _forceDeleteByKeys();
  }
}
