part of '../query_builder.dart';

/// Reactive query helpers.
extension ReactiveQueryExtension<T extends OrmEntity> on Query<T> {
  /// Watches this query and emits the complete result whenever a relevant
  /// committed database change occurs.
  ///
  /// This is distinct from [streamModels], which is a finite row stream used
  /// for processing large result sets. A watcher always emits an initial
  /// snapshot and then emits a new snapshot after invalidation.
  Stream<List<T>> watch() => watchRows().map(
    (rows) => rows.map((row) => row.model).toList(growable: false),
  );

  /// Watches this query and emits hydrated rows whenever it is invalidated.
  Stream<List<QueryRow<T>>> watchRows() {
    final plan = _buildPlan();
    return context.watchSelect(plan).asyncMap((rows) async {
      final result = rows
          .map((row) => _hydrateRow(row, plan))
          .toList(growable: false);
      await _applyRelationHookBatch(plan, result);
      return result;
    });
  }
}
