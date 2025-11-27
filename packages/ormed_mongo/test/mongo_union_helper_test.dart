import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mongo/src/mongo_query_plan_metadata.dart';
import 'package:ormed_mongo/src/mongo_union_helper.dart';
import 'package:test/test.dart';

void main() {
  group('MongoUnionExecutor', () {
    final helper = const MongoUnionExecutor();
    const pipelineStage = {
      '\$match': {
        'value': {'\$gt': 0},
      },
    };

    QueryPlan planWithUnion({
      required bool unionAll,
      required QueryPlan unionPlan,
    }) => QueryPlan(
      definition: AuthorOrmDefinition.definition,
      unions: [QueryUnion(plan: unionPlan, all: unionAll)],
    );

    Future<List<Map<String, Object?>>> execute(
      QueryPlan plan,
      QueryPlan basePlan,
      QueryPlan unionPlan,
      List<Map<String, Object?>> baseRows,
      List<Map<String, Object?>> unionRows,
    ) => helper.execute(plan, (subPlan) {
      if (identical(subPlan, basePlan)) {
        return Future.value(baseRows);
      }
      if (identical(subPlan, unionPlan)) {
        return Future.value(unionRows);
      }
      return Future.value(const <Map<String, Object?>>[]);
    });

    test('deduplicates rows when UNION is used', () async {
      final unionPlan = QueryPlan(definition: AuthorOrmDefinition.definition);
      final plan = planWithUnion(unionAll: false, unionPlan: unionPlan);

      final result = await execute(
        plan,
        plan,
        unionPlan,
        const [
          {'id': 1},
          {'id': 2},
        ],
        const [
          {'id': 2},
          {'id': 3},
        ],
      );

      expect(result.map((row) => row['id']), equals([1, 2, 3]));
    });

    test('retains duplicates when UNION ALL is used', () async {
      final unionPlan = QueryPlan(definition: AuthorOrmDefinition.definition);
      final plan = planWithUnion(unionAll: true, unionPlan: unionPlan);

      final result = await execute(
        plan,
        plan,
        unionPlan,
        const [
          {'id': 1},
          {'id': 2},
        ],
        const [
          {'id': 2},
          {'id': 3},
        ],
      );

      expect(result.map((row) => row['id']), equals([1, 2, 2, 3]));
    });

    test('mergeMetadata aggregates tracked descriptors', () {
      consumeTrackedMongoPlans();
      final unionPlan = QueryPlan(definition: PostOrmDefinition.definition);
      final plan = QueryPlan(
        definition: PostOrmDefinition.definition,
        unions: [QueryUnion(plan: unionPlan, all: false)],
      );
      final authorRelation = PostOrmDefinition.definition.relations.firstWhere(
        (relation) => relation.name == 'author',
      );
      final tagsRelation = PostOrmDefinition.definition.relations.firstWhere(
        (relation) => relation.name == 'tags',
      );

      trackMongoQueryPlan(
        plan,
        relationLoads: [RelationLoad(relation: authorRelation)],
        pipelineStages: [pipelineStage],
      );
      trackMongoQueryPlan(
        unionPlan,
        relationLoads: [RelationLoad(relation: tagsRelation)],
        pipelineStages: [pipelineStage],
      );

      final merged = helper.mergeMetadata(plan);

      expect(merged, isNotNull);
      expect(
        merged!.relationLoads.map((load) => load.relation.name),
        containsAll(<String>['author', 'tags']),
      );
      expect(merged.pipelineStages, contains(pipelineStage));
      consumeTrackedMongoPlans();
    });
  });
}
