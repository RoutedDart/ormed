import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:ormed_mongo/src/mongo_query_plan_metadata.dart';
import 'package:test/test.dart';

void main() {
  test('Mongo preview metadata lists relation order info', () {
    final author = AdHocModelDefinition(
      tableName: 'authors',
      columns: const [AdHocColumn(name: 'id', isPrimaryKey: true)],
    );
    final post = AdHocModelDefinition(
      tableName: 'posts',
      columns: const [AdHocColumn(name: 'id', isPrimaryKey: true)],
    );
    final relation = RelationDefinition(
      name: 'posts',
      kind: RelationKind.hasMany,
      targetModel: post.modelName,
      foreignKey: 'author_id',
      localKey: 'id',
    );
    final segment = RelationSegment(
      name: relation.name,
      relation: relation,
      parentDefinition: author,
      targetDefinition: post,
      parentKey: 'id',
      childKey: 'author_id',
    );
    final order = RelationOrder(
      path: RelationPath(segments: [segment]),
      aggregateType: RelationAggregateType.count,
      descending: true,
    );
    final aggregate = RelationAggregate(
      type: RelationAggregateType.count,
      alias: 'posts_count',
      path: order.path,
    );
    final plan = QueryPlan(
      definition: author,
      relationAggregates: [aggregate],
      relationOrders: [order],
    );
    trackMongoQueryPlan(
      plan,
      relationLoads: plan.relations,
      relationAggregates: plan.relationAggregates,
      relationOrders: plan.relationOrders,
    );
    final preview = const MongoPlanCompiler().compileSelect(plan);
    final payload = preview.payload as DocumentStatementPayload;
    final metadata = payload.metadata?['mongo_plan'] as Map<String, Object?>?;
    expect(metadata, isNotNull);
    final orders = metadata!['relation_orders'] as List<Object?>?;
    expect(orders, isNotNull);
    final orderEntry = orders!.cast<Map<String, Object?>>().first;
    expect(orderEntry['path'], equals('posts'));
    expect(orderEntry['aggregate'], equals('count'));
    expect(orderEntry['direction'], equals('desc'));
  });
}
