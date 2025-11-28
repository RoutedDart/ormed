import 'package:ormed/ormed.dart';

import 'mongo_query_plan_metadata.dart';

class MongoRelationHelper {
  MongoRelationHelper(this.context);

  final QueryContext context;

  Future<void> attach<T>(
    ModelDefinition<T> parentDefinition,
    QueryPlan plan,
    List<QueryRow<T>> parents,
    List<RelationLoad> relations,
  ) async {
    final metadata = metadataForPlan(plan);
    final loads = metadata?.relationLoads ?? relations;
    if (loads.isNotEmpty) {
      final joinMap = {
        for (final join in plan.relationJoins) join.pathKey: join,
      };
      await RelationLoader(
        context,
      ).attach(parentDefinition, parents, loads, joinMap: joinMap);
    }

    // Relation aggregates are now handled by the MongoDB aggregation pipeline
    // in MongoPlanCompiler.

    final orders = metadata?.relationOrders ?? plan.relationOrders;
    await _applyRelationOrders(plan, parents, orders);
  }

  Future<void> _applyRelationOrders<T>(
    QueryPlan plan,
    List<QueryRow<T>> parents,
    List<RelationOrder> orders,
  ) async {
    if (orders.isEmpty || parents.isEmpty) return;
    final driverName = context.driver.metadata.name;
    for (final order in orders) {
      final alias = relationOrderAlias(order);
      final aggregate = RelationAggregate(
        type: order.aggregateType,
        alias: alias,
        path: order.path,
        where: order.where,
        distinct: order.distinct,
      );
      // TODO: Move relation order sorting to the aggregation pipeline
      await _applyAggregate(plan, parents, aggregate, driverName);
      parents.sort((a, b) {
        final left = _orderComparable(a.row[alias]);
        final right = _orderComparable(b.row[alias]);
        final result = left.compareTo(right);
        return order.descending ? -result : result;
      });
      for (final row in parents) {
        row.row.remove(alias);
      }
    }
  }

  Future<void> _applyAggregate<T>(
    QueryPlan plan,
    List<QueryRow<T>> parents,
    RelationAggregate aggregate,
    String driverName,
  ) async {
    if (parents.isEmpty) return;
    final segments = aggregate.path.segments;
    if (segments.isEmpty) return;
    Map<Object?, Set<int>> currentIndices = {};
    final firstSegment = segments.first;
    for (var index = 0; index < parents.length; index++) {
      final parentValue = parents[index].row[firstSegment.parentKey];
      if (parentValue == null) continue;
      currentIndices.putIfAbsent(parentValue, () => <int>{}).add(index);
    }
    if (currentIndices.isEmpty) {
      for (final row in parents) {
        row.row[aggregate.alias] = _defaultAggregateValue(aggregate.type);
      }
      return;
    }
    final totals = <int, int>{};
    final distinctValues = <int, Set<Object?>>{};
    final aggregateValues = <int, List<num>>{}; // For sum, avg, min, max

    for (
      var segmentIndex = 0;
      segmentIndex < segments.length && currentIndices.isNotEmpty;
      segmentIndex++
    ) {
      final segment = segments[segmentIndex];
      final targetPk = segment.targetDefinition.primaryKeyField?.columnName;
      if (targetPk == null) {
        currentIndices = {};
        break;
      }
      final parentKeys = currentIndices.keys.toList();

      // Determine column to aggregate for sum, avg, min, max
      final aggregateColumn = _getAggregateColumn(
        aggregate,
        segment,
        segmentIndex,
        segments.length,
      );

      final childPlan = QueryPlan(
        definition: segment.targetDefinition,
        driverName: driverName,
        filters: [
          FilterClause(
            field: segment.childKey,
            operator: FilterOperator.inValues,
            value: parentKeys,
          ),
        ],
        predicate: segmentIndex == segments.length - 1 ? aggregate.where : null,
      );
      final childRows = await context.driver.execute(childPlan);
      final nextIndices = <Object?, Set<int>>{};
      for (final childRow in childRows) {
        final joinValue = childRow[segment.childKey];
        final childPrimary = childRow[targetPk];
        if (joinValue == null || childPrimary == null) continue;
        final indices = currentIndices[joinValue];
        if (indices == null) continue;
        for (final index in indices) {
          nextIndices.putIfAbsent(childPrimary, () => <int>{}).add(index);
          if (segmentIndex == segments.length - 1) {
            // Handle different aggregate types
            if (aggregate.type == RelationAggregateType.count ||
                aggregate.type == RelationAggregateType.exists) {
              if (aggregate.distinct) {
                distinctValues
                    .putIfAbsent(index, () => <Object?>{})
                    .add(childPrimary);
              } else {
                totals[index] = (totals[index] ?? 0) + 1;
              }
            } else {
              // sum, avg, min, max
              final value = aggregateColumn != null
                  ? childRow[aggregateColumn]
                  : null;
              if (value != null) {
                final numValue = _toNum(value);
                if (numValue != null) {
                  aggregateValues.putIfAbsent(index, () => []).add(numValue);
                }
              }
            }
          }
        }
      }
      currentIndices = nextIndices;
    }
    for (var index = 0; index < parents.length; index++) {
      final row = parents[index];
      final value = _computeAggregateValue(
        aggregate,
        index,
        totals,
        distinctValues,
        aggregateValues,
      );
      row.row[aggregate.alias] = value;
    }
  }

  String? _getAggregateColumn(
    RelationAggregate aggregate,
    RelationSegment segment,
    int segmentIndex,
    int totalSegments,
  ) {
    // Only get column for the final segment and numeric aggregates
    if (segmentIndex != totalSegments - 1) return null;

    switch (aggregate.type) {
      case RelationAggregateType.sum:
      case RelationAggregateType.avg:
      case RelationAggregateType.min:
      case RelationAggregateType.max:
        // Use the column from the aggregate if specified
        return aggregate.column ?? segment.childKey;
      default:
        return null;
    }
  }

  num? _toNum(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Object _computeAggregateValue(
    RelationAggregate aggregate,
    int index,
    Map<int, int> totals,
    Map<int, Set<Object?>> distinctValues,
    Map<int, List<num>> aggregateValues,
  ) {
    switch (aggregate.type) {
      case RelationAggregateType.count:
        return aggregate.distinct
            ? distinctValues[index]?.length ?? 0
            : totals[index] ?? 0;
      case RelationAggregateType.exists:
        final total = aggregate.distinct
            ? distinctValues[index]?.length ?? 0
            : totals[index] ?? 0;
        return total > 0;
      case RelationAggregateType.sum:
        final values = aggregateValues[index];
        if (values == null || values.isEmpty) return 0;
        return values.reduce((a, b) => a + b);
      case RelationAggregateType.avg:
        final values = aggregateValues[index];
        if (values == null || values.isEmpty) return 0;
        final sum = values.reduce((a, b) => a + b);
        return sum / values.length;
      case RelationAggregateType.min:
        final values = aggregateValues[index];
        if (values == null || values.isEmpty) return 0;
        return values.reduce((a, b) => a < b ? a : b);
      case RelationAggregateType.max:
        final values = aggregateValues[index];
        if (values == null || values.isEmpty) return 0;
        return values.reduce((a, b) => a > b ? a : b);
    }
  }

  Object _defaultAggregateValue(RelationAggregateType type) {
    return type == RelationAggregateType.exists ? false : 0;
  }

  num _orderComparable(Object? value) {
    if (value is num) return value;
    if (value is bool) return value ? 1 : 0;
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }
}

class MongoRelationHook implements RelationHook {
  const MongoRelationHook();

  @override
  Future<void> handleRelations<T>(
    QueryContext context,
    QueryPlan plan,
    ModelDefinition<T> parentDefinition,
    List<QueryRow<T>> parents,
    List<RelationLoad> relations,
  ) {
    return MongoRelationHelper(
      context,
    ).attach(parentDefinition, plan, parents, relations);
  }
}
