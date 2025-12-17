import 'package:ormed/src/contracts.dart';
import 'package:ormed/src/driver/json_update_clause.dart';
import 'package:ormed/src/driver/mutation/mutation_operation.dart';
import 'package:ormed/src/driver/mutation/mutation_row.dart';
import 'package:ormed/src/model/model.dart';
import 'package:ormed/src/query/query_plan.dart';

/// Description of a write operation to execute against a driver.
class MutationPlan {
  MutationPlan._({
    required this.operation,
    required this.definition,
    required this.rows,
    this.driverName,
    this.returning = false,
    List<String>? uniqueByColumns,
    List<String>? updateColumns,
    this.ignoreConflicts = false,
    this.queryPlan,
    this.queryPrimaryKey,
    Map<String, Object?>? queryUpdateValues,
    List<JsonUpdateClause>? queryJsonUpdates,
    Map<String, num>? queryIncrementValues,
    List<String>? insertColumns,
  }) : upsertUniqueColumns = List.unmodifiable(uniqueByColumns ?? const []),
       upsertUpdateColumns = List.unmodifiable(updateColumns ?? const []),
       queryUpdateValues = Map.unmodifiable(
         queryUpdateValues ?? const <String, Object?>{},
       ),
       queryJsonUpdates = List.unmodifiable(
         queryJsonUpdates ?? const <JsonUpdateClause>[],
       ),
       queryIncrementValues = Map.unmodifiable(
         queryIncrementValues ?? const <String, num>{},
       ),
       insertColumns = List.unmodifiable(insertColumns ?? const []);

  factory MutationPlan.insert({
    required ModelDefinition<OrmEntity> definition,
    required List<Map<String, Object?>> rows,
    String? driverName,
    bool returning = true,
    bool ignoreConflicts = false,
  }) => MutationPlan._(
    operation: MutationOperation.insert,
    definition: definition,
    rows: rows
        .map((values) => MutationRow(values: values, keys: const {}))
        .toList(growable: false),
    driverName: driverName,
    returning: returning,
    ignoreConflicts: ignoreConflicts,
  );

  factory MutationPlan.insertUsing({
    required ModelDefinition<OrmEntity> definition,
    required List<String> columns,
    required QueryPlan selectPlan,
    String? driverName,
    bool ignoreConflicts = false,
  }) => MutationPlan._(
    operation: MutationOperation.insertUsing,
    definition: definition,
    rows: const [],
    driverName: driverName,
    ignoreConflicts: ignoreConflicts,
    queryPlan: selectPlan,
    insertColumns: columns,
  );

  factory MutationPlan.update({
    required ModelDefinition<OrmEntity> definition,
    required List<MutationRow> rows,
    String? driverName,
    bool returning = true,
  }) => MutationPlan._(
    operation: MutationOperation.update,
    definition: definition,
    rows: rows,
    driverName: driverName,
    returning: returning,
  );

  factory MutationPlan.delete({
    required ModelDefinition<OrmEntity> definition,
    required List<MutationRow> rows,
    String? driverName,
    bool returning = false,
  }) => MutationPlan._(
    operation: MutationOperation.delete,
    definition: definition,
    rows: rows,
    driverName: driverName,
    returning: returning,
  );

  factory MutationPlan.queryDelete({
    required ModelDefinition<OrmEntity> definition,
    required QueryPlan plan,
    required String primaryKey,
    String? driverName,
    bool returning = false,
  }) => MutationPlan._(
    operation: MutationOperation.queryDelete,
    definition: definition,
    rows: const [],
    driverName: driverName,
    queryPlan: plan,
    queryPrimaryKey: primaryKey,
    returning: returning,
  );

  factory MutationPlan.queryUpdate({
    required ModelDefinition<OrmEntity> definition,
    required QueryPlan plan,
    required Map<String, Object?> values,
    List<JsonUpdateClause>? jsonUpdates,
    String? driverName,
    String? primaryKey,
    Map<String, num>? queryIncrementValues,
    bool returning = false,
  }) => MutationPlan._(
    operation: MutationOperation.queryUpdate,
    definition: definition,
    rows: const [],
    driverName: driverName,
    queryPlan: plan,
    queryUpdateValues: values,
    queryJsonUpdates: jsonUpdates,
    queryPrimaryKey: primaryKey,
    queryIncrementValues: queryIncrementValues,
    returning: returning,
  );

  factory MutationPlan.upsert({
    required ModelDefinition<OrmEntity> definition,
    required List<MutationRow> rows,
    String? driverName,
    bool returning = false,
    List<String>? uniqueBy,
    List<String>? updateColumns,
  }) => MutationPlan._(
    operation: MutationOperation.upsert,
    definition: definition,
    rows: rows,
    driverName: driverName,
    returning: returning,
    uniqueByColumns: uniqueBy,
    updateColumns: updateColumns,
  );

  final MutationOperation operation;
  final ModelDefinition<OrmEntity> definition;
  final List<MutationRow> rows;
  final String? driverName;
  final bool returning;
  final List<String> upsertUniqueColumns;
  final List<String> upsertUpdateColumns;
  final bool ignoreConflicts;
  final List<String> insertColumns;
  final QueryPlan? queryPlan;
  final String? queryPrimaryKey;
  final Map<String, Object?> queryUpdateValues;
  final List<JsonUpdateClause> queryJsonUpdates;
  final Map<String, num> queryIncrementValues;
}
