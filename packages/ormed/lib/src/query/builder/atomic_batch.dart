part of '../query_builder.dart';

/// Stages query-builder operations for [QueryContext.atomicBatch].
extension AtomicBatchOperationsExtension<T extends OrmEntity> on Query<T> {
  /// Stages this query and returns decoded row maps when the batch completes.
  ///
  /// Eager relation loading and model hydration are not performed because an
  /// atomic batch returns statement results only after every operation runs.
  AtomicBatchOperation batchSelect() {
    return AtomicBatchOperation.query(_buildPlan());
  }

  /// Stages an update of rows matching this query.
  AtomicBatchOperation batchUpdate(
    Map<String, Object?> values, {
    bool returning = false,
  }) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'Must not be empty.');
    }
    final valuesWithTimestamp = _addUpdateTimestamp(values);
    final payload = _normalizeUpdateValues(valuesWithTimestamp);
    if (payload.isEmpty) {
      throw ArgumentError.value(
        values,
        'values',
        'Must contain at least one persisted field.',
      );
    }
    return AtomicBatchOperation.mutation(
      _buildQueryUpdateMutation(
        values: payload.values,
        jsonUpdates: payload.jsonUpdates,
        feature: 'batchUpdate',
        returning: returning,
      ),
    );
  }

  /// Stages deletion of rows matching this query.
  ///
  /// Model lifecycle events are not emitted because staging cannot first load
  /// models and then vary the fixed operation list. Soft-delete models are
  /// updated using their configured deleted-at field.
  AtomicBatchOperation batchDelete({bool returning = false}) {
    final softDeleteField = _softDeleteField;
    if (softDeleteField != null) {
      final value = Carbon.now().toUtc().toDateTime();
      return AtomicBatchOperation.mutation(
        _buildQueryUpdateMutation(
          values: {
            softDeleteField.columnName: context.codecRegistry.encodeField(
              softDeleteField,
              value,
            ),
          },
          feature: 'batchDelete',
          returning: returning,
        ),
      );
    }

    if (!_supportsQueryDeletes) {
      throw UnsupportedError(
        '${context.driver.metadata.name} cannot stage query-driven deletes.',
      );
    }
    final metadata = context.driver.metadata;
    final primaryKey =
        definition.primaryKeyField?.columnName ??
        metadata.queryUpdateRowIdentifier?.column;
    if (primaryKey == null) {
      throw StateError(
        'batchDelete requires ${definition.modelName} to declare a primary '
        'key or the ${metadata.name} driver to provide a row identifier.',
      );
    }
    return AtomicBatchOperation.mutation(
      MutationPlan.queryDelete(
        definition: definition,
        plan: _buildPlan(),
        primaryKey: primaryKey,
        driverName: metadata.name,
        returning: returning,
      ),
    );
  }

  /// Stages inserts built from model, DTO, or map inputs.
  AtomicBatchOperation batchInsert(
    List<Object> inputs, {
    bool ignoreConflicts = false,
    bool returning = false,
  }) {
    return AtomicBatchOperation.mutation(
      previewInsertPlan(
        inputs,
        ignoreConflicts: ignoreConflicts,
        returning: returning,
      ),
    );
  }

  /// Stages upserts built from model, DTO, or map inputs.
  AtomicBatchOperation batchUpsert(
    List<Object> inputs, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
    bool returning = false,
  }) {
    return AtomicBatchOperation.mutation(
      previewUpsertPlan(
        inputs,
        uniqueBy: uniqueBy,
        updateColumns: updateColumns,
        jsonUpdates: jsonUpdates,
        returning: returning,
      ),
    );
  }
}
