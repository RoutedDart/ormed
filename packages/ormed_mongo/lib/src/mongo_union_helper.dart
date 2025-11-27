import 'package:ormed/ormed.dart';

import 'mongo_query_plan_metadata.dart';
import 'mongo_transaction_context.dart';

/// Executes `QueryPlan` objects that include `UNION` clauses.
class MongoUnionExecutor {
  const MongoUnionExecutor({
    List<String> Function(QueryPlan)? primaryKeyResolver,
  }) : _primaryKeyResolver = primaryKeyResolver ?? _defaultPrimaryKeysForPlan;

  final List<String> Function(QueryPlan) _primaryKeyResolver;

  /// Runs [plan] together with any UNION clauses by delegating to [executePlan].
  ///
  /// [executePlan] is called for the base [plan] and each unioned plan in turn.
  Future<List<Map<String, Object?>>> execute(
    QueryPlan plan,
    Future<List<Map<String, Object?>>> Function(QueryPlan plan) executePlan,
  ) async {
    if (plan.unions.isEmpty) {
      return executePlan(plan);
    }

    final seenFingerprints = <String>{};
    final results = <Map<String, Object?>>[];

    void addDistinct(Map<String, Object?> row, List<String> keys) {
      final fingerprint = _rowFingerprint(row, keys);
      if (seenFingerprints.add(fingerprint)) {
        results.add(row);
      }
    }

    final baseKeys = _primaryKeyResolver(plan);
    final baseRows = await executePlan(plan);
    for (final row in baseRows) {
      addDistinct(row, baseKeys);
    }

    for (final union in plan.unions) {
      final unionRows = await executePlan(union.plan);
      if (union.all) {
        results.addAll(unionRows);
        continue;
      }
      final unionKeys = _primaryKeyResolver(union.plan);
      for (final row in unionRows) {
        addDistinct(row, unionKeys);
      }
    }

    return results;
  }

  static List<String> _defaultPrimaryKeysForPlan(QueryPlan plan) {
    final pk = plan.definition.primaryKeyField?.columnName;
    if (pk != null) {
      return [pk];
    }
    if (plan.definition.fields.isNotEmpty) {
      return [plan.definition.fields.first.columnName];
    }
    return [];
  }

  static String _rowFingerprint(Map<String, Object?> row, List<String> keys) {
    final buffer = StringBuffer();
    final keyList = keys.isNotEmpty
        ? List<String>.from(keys)
        : row.keys.toList();
    keyList.sort();
    for (final key in keyList) {
      buffer
        ..write(key)
        ..write(':')
        ..write(row[key])
        ..write('|');
    }
    return buffer.toString();
  }

  /// Combines the tracked metadata for the base plan and each union plan so
  /// tooling sees the merged pipeline/relation descriptors on the union.
  MongoQueryPlanMetadata? mergeMetadata(QueryPlan plan) {
    final entries = <MongoQueryPlanMetadata>[];
    final base = metadataForPlan(plan);
    if (base != null) {
      entries.add(base);
    }
    for (final union in plan.unions) {
      final meta = metadataForPlan(union.plan);
      if (meta != null) {
        entries.add(meta);
      }
    }
    if (entries.isEmpty) {
      return null;
    }
    final relationLoads = entries.expand((meta) => meta.relationLoads).toList();
    final relationAggregates = entries
        .expand((meta) => meta.relationAggregates)
        .toList();
    final relationOrders = entries
        .expand((meta) => meta.relationOrders)
        .toList();
    final pipelineStages = entries
        .expand((meta) => meta.pipelineStages)
        .toList();
    final sessionState =
        base?.sessionState ?? MongoTransactionContext.sessionState;
    return MongoQueryPlanMetadata(
      hasUnions: plan.unions.isNotEmpty,
      relationLoads: relationLoads,
      relationAggregates: relationAggregates,
      relationOrders: relationOrders,
      pipelineStages: pipelineStages,
      sessionId: base?.sessionId,
      sessionState: sessionState,
      sessionStartedAt: base?.sessionStartedAt,
      sessionEndedAt: base?.sessionEndedAt,
    );
  }
}
