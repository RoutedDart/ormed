import 'package:ormed/ormed.dart';

import 'mongo_codecs.dart';
import 'mongo_driver.dart';
import 'mongo_query_plan_metadata.dart';
import 'mongo_query_pipeline_stage.dart';
import 'mongo_repository.dart';
import 'mongo_transaction_context.dart';

const _documentOperations = {
  SchemaMutationOperation.createCollection,
  SchemaMutationOperation.dropCollection,
  SchemaMutationOperation.createIndex,
  SchemaMutationOperation.dropIndex,
  SchemaMutationOperation.modifyValidator,
};
const _mongoDriverName = 'mongo';

class MongoQueryBuilderHook implements QueryBuilderHook {
  const MongoQueryBuilderHook();

  @override
  bool handles(ModelDefinition<dynamic> definition) => true;

  @override
  Query<T> build<T>(
    ModelDefinition<T> definition,
    QueryContext context,
    Query<T> defaultQuery,
  ) {
    context.beforeExecuting((statement) {
      final plan = statement.queryPlan;
      final mutation = statement.mutationPlan;

      if (mutation != null) {
        _convertMutationIds(mutation);
      }

      if (plan != null) {
        _convertQueryIds(plan);
      }

      if (plan == null || plan.definition != definition) {
        return;
      }
      final stages = consumeMongoPipelineStages(context);
      final sessionId = (context.driver is MongoDriverAdapter)
          ? (context.driver as MongoDriverAdapter).currentSessionId
          : null;
      final currentSessionState = MongoTransactionContext.sessionState;
      final sessionStartedAt = MongoTransactionContext.sessionStartedAt;
      final sessionEndedAt = MongoTransactionContext.sessionEndedAt;
      final shouldTrackPlan =
          plan.relations.isNotEmpty ||
          plan.relationAggregates.isNotEmpty ||
          plan.relationOrders.isNotEmpty ||
          plan.unions.isNotEmpty ||
          stages.isNotEmpty ||
          sessionId != null;
      if (!shouldTrackPlan) {
        return;
      }
      if (metadataForPlan(plan) == null) {
        trackMongoQueryPlan(
          plan,
          relationLoads: plan.relations,
          relationAggregates: plan.relationAggregates,
          relationOrders: plan.relationOrders,
          pipelineStages: stages,
          sessionId: sessionId,
          sessionState: currentSessionState,
          sessionStartedAt: sessionStartedAt,
          sessionEndedAt: sessionEndedAt,
        );
      }
      for (final union in plan.unions) {
        final unionPlan = union.plan;
        final shouldTrackUnion =
            unionPlan.relations.isNotEmpty ||
            unionPlan.relationAggregates.isNotEmpty ||
            unionPlan.relationOrders.isNotEmpty;
        if (!shouldTrackUnion) {
          continue;
        }
        if (metadataForPlan(unionPlan) != null) {
          continue;
        }
        trackMongoQueryPlan(
          unionPlan,
          relationLoads: unionPlan.relations,
          relationAggregates: unionPlan.relationAggregates,
          relationOrders: unionPlan.relationOrders,
          pipelineStages: const [],
          sessionId: sessionId,
          sessionState: currentSessionState,
          sessionStartedAt: sessionStartedAt,
          sessionEndedAt: sessionEndedAt,
        );
      }
    });
    return defaultQuery;
  }

  void _convertMutationIds(MutationPlan plan) {
    final codec = MongoObjectIdToIntCodec();
    for (final row in plan.rows) {
      if (row.values.containsKey('id')) {
        final value = row.values['id'];
        if (value is int) {
          row.values['id'] = codec.encode(value);
        }
      }
    }
  }

  void _convertQueryIds(QueryPlan plan) {
    // Note: We can't modify plan.filters as it's an unmodifiable list.
    // ID conversion will be handled in MongoPlanCompiler.buildFilter instead.
    // This method is kept for potential future use with mutable plans.
  }
}

class MongoRepositoryHook implements RepositoryHook {
  const MongoRepositoryHook();

  @override
  bool handles(ModelDefinition<dynamic> definition) =>
      _hasMongoAnnotation(definition);

  @override
  Repository<T> build<T>(
    ModelDefinition<T> definition,
    QueryContext context,
    Repository<T> _,
  ) => MongoRepository(
    definition: definition,
    driverName: context.driver.metadata.name,
    codecs: context.codecRegistry,
    runMutation: context.runMutation,
    describeMutation: context.describeMutation,
    attachRuntimeMetadata: context.attachRuntimeMetadata,
  );
}

class MongoSchemaHook implements SchemaMutationHook {
  const MongoSchemaHook();

  @override
  bool handles(SchemaMutation mutation) =>
      _documentOperations.contains(mutation.operation);

  @override
  List<SchemaStatement> handle(SchemaMutation mutation) {
    final operation = mutation.operation;
    final payload = DocumentStatementPayload(
      command: operation.name,
      arguments: mutation.documentPayload ?? const {},
    );
    return [SchemaStatement(operation.name, payload: payload)];
  }
}

bool _hasMongoAnnotation(ModelDefinition<dynamic> definition) =>
    definition.metadata.driverAnnotations.any(
      (annotation) =>
          annotation is DriverModel &&
          annotation.driverName.toLowerCase() == _mongoDriverName,
    );
