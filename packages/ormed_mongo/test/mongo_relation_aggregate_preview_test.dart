import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

void main() {
  test('Mongo preview metadata lists relation aggregate aliases', () {
    final parent = AdHocModelDefinition(
      tableName: 'authors',
      columns: const [AdHocColumn(name: 'id', isPrimaryKey: true)],
    );
    final target = AdHocModelDefinition(
      tableName: 'posts',
      columns: const [AdHocColumn(name: 'id', isPrimaryKey: true)],
    );
    final relation = RelationDefinition(
      name: 'posts',
      kind: RelationKind.hasMany,
      targetModel: target.modelName,
      foreignKey: 'author_id',
      localKey: 'id',
    );
    final segment = RelationSegment(
      name: relation.name,
      relation: relation,
      parentDefinition: parent,
      targetDefinition: target,
      parentKey: 'id',
      childKey: 'author_id',
    );
    final aggregate = RelationAggregate(
      type: RelationAggregateType.count,
      alias: 'posts_count',
      path: RelationPath(segments: [segment]),
      distinct: false,
    );
    final plan = QueryPlan(definition: parent, relationAggregates: [aggregate]);

    final preview = const MongoPlanCompiler().compileSelect(plan);
    final payload = preview.payload as DocumentStatementPayload;
    final mongoMetadata =
        payload.metadata?['mongo_plan'] as Map<String, Object?>?;
    expect(mongoMetadata, isNotNull);
    final aggregates = mongoMetadata!['relation_aggregates'] as List<Object?>?;
    expect(aggregates, isNotNull);
    expect(aggregates!.first, containsPair('alias', 'posts_count'));
    expect(aggregates.first, containsPair('type', 'count'));
  });
}
