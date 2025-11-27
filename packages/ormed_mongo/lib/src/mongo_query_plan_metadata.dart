import 'package:ormed/ormed.dart';

import 'mongo_transaction_context.dart';

class MongoQueryPlanMetadata {
  MongoQueryPlanMetadata({
    required this.hasUnions,
    required List<RelationLoad> relationLoads,
    required List<RelationAggregate> relationAggregates,
    required List<RelationOrder> relationOrders,
    required List<Map<String, Object?>> pipelineStages,
    required this.sessionId,
    required this.sessionState,
    required this.sessionStartedAt,
    required this.sessionEndedAt,
  }) : relationLoads = List.unmodifiable(relationLoads),
       relationAggregates = List.unmodifiable(relationAggregates),
       relationOrders = List.unmodifiable(relationOrders),
       pipelineStages = List.unmodifiable(pipelineStages);

  final bool hasUnions;
  final List<RelationLoad> relationLoads;
  final List<RelationAggregate> relationAggregates;
  final List<RelationOrder> relationOrders;
  final List<Map<String, Object?>> pipelineStages;
  final String? sessionId;
  final MongoTransactionState sessionState;
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndedAt;

  Map<String, Object?> toJson() {
    final data = <String, Object?>{'has_unions': hasUnions};
    if (relationLoads.isNotEmpty) {
      data['relations'] = relationLoads
          .map((load) => load.relation.name)
          .toList(growable: false);
    }
    if (relationAggregates.isNotEmpty) {
      data['relation_aggregates'] = relationAggregates
          .map(_aggregateDescriptor)
          .toList(growable: false);
    }
    if (relationOrders.isNotEmpty) {
      data['relation_orders'] = relationOrders
          .map(
            (order) => {
              'path': order.path.segments
                  .map((segment) => segment.name)
                  .join('.'),
              'alias': relationOrderAlias(order),
              'aggregate': order.aggregateType.name,
              'direction': order.descending ? 'desc' : 'asc',
              'distinct': order.distinct,
            },
          )
          .toList(growable: false);
    }
    if (pipelineStages.isNotEmpty) {
      data['pipeline_stages'] = pipelineStages;
    }
    if (sessionId != null) {
      data['session_id'] = sessionId;
      data['session_state'] = sessionState.name;
      if (sessionStartedAt != null) {
        data['session_started_at'] = sessionStartedAt!.toIso8601String();
      }
      if (sessionEndedAt != null) {
        data['session_ended_at'] = sessionEndedAt!.toIso8601String();
      }
    }
    return data;
  }

  static Map<String, Object?> _aggregateDescriptor(
    RelationAggregate aggregate,
  ) => relationAggregateDescriptor(aggregate);
}

final _planMetadata = Expando<MongoQueryPlanMetadata>();
final List<QueryPlan> _trackedPlans = [];

void trackMongoQueryPlan(
  QueryPlan plan, {
  List<RelationLoad> relationLoads = const [],
  List<RelationAggregate> relationAggregates = const [],
  List<Map<String, Object?>> pipelineStages = const [],
  List<RelationOrder> relationOrders = const [],
  String? sessionId,
  MongoTransactionState sessionState = MongoTransactionState.idle,
  DateTime? sessionStartedAt,
  DateTime? sessionEndedAt,
}) {
  _planMetadata[plan] = MongoQueryPlanMetadata(
    hasUnions: plan.unions.isNotEmpty,
    relationLoads: relationLoads,
    relationAggregates: relationAggregates,
    relationOrders: relationOrders,
    pipelineStages: List.unmodifiable(pipelineStages),
    sessionId: sessionId,
    sessionState: sessionState,
    sessionStartedAt: sessionStartedAt,
    sessionEndedAt: sessionEndedAt,
  );
  _trackedPlans.add(plan);
}

MongoQueryPlanMetadata? metadataForPlan(QueryPlan plan) => _planMetadata[plan];

List<QueryPlan> consumeTrackedMongoPlans() {
  final plans = List<QueryPlan>.from(_trackedPlans);
  _trackedPlans.clear();
  return plans;
}

List<QueryPlan> trackedMongoPlans() => List.unmodifiable(_trackedPlans);

List<Map<String, Object?>> serializeRelationAggregates(
  List<RelationAggregate> aggregates,
) {
  if (aggregates.isEmpty) return const [];
  return aggregates.map(relationAggregateDescriptor).toList(growable: false);
}

Map<String, Object?> relationAggregateDescriptor(RelationAggregate aggregate) {
  final predicate = aggregate.where;
  return {
    'alias': aggregate.alias,
    'type': aggregate.type.name,
    'path': aggregate.path.segments.map((segment) => segment.name).join('.'),
    'distinct': aggregate.distinct,
    if (predicate != null) 'predicate': predicate.toString(),
  };
}

String relationOrderAlias(RelationOrder order) {
  final path = order.path.segments.map((segment) => segment.name).join('_');
  return '${path}_${order.aggregateType.name}';
}
