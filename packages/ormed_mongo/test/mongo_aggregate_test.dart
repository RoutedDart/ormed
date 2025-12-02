import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

import 'shared.dart';

void main() {
  late DataSource dataSource;
  late MongoDriverAdapter driverAdapter;

  setUpAll(() async {
    await waitForMongoReady();
    await clearDatabase();
    driverAdapter = createAdapter();
    registerDriverTestFactories();
    dataSource = DataSource(DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
    ));
    await dataSource.init();
    await seedGraph(dataSource);
  });

  tearDownAll(() async => await dataSource.dispose());

  test('aggregates counts by author with a raw pipeline stage', () async {
    final query = dataSource.context
        .query<Post>()
        .select(['authorId'])
        .countAggregate(alias: 'post_count')
        .groupBy(['authorId'])
        .withMongoPipelineStage({
          '\$match': {
            'post_count': {'\$gt': 0},
          },
        })
        .orderBy('authorId');
    final plan = query.debugPlan();
    final rows = await dataSource.context.runSelect(plan);
    expect(rows, isNotEmpty);
  });

  test('preview exposes pipeline metadata for aggregates', () {
    final preview = dataSource.context
        .query<Post>()
        .countAggregate(alias: 'total_posts')
        .groupBy(['authorId'])
        .toSql();

    final payload = preview.payload as DocumentStatementPayload;
    expect(payload.command, equals('aggregate'));
    final pipeline = payload.arguments['pipeline'] as List<Object?>?;
    expect(pipeline, isNotNull);
    expect(
      pipeline!.any((stage) => stage is Map && stage.containsKey('\$group')),
      isTrue,
    );
  });

  test('aggregate pipeline respects HAVING predicates', () {
    final query = dataSource.context
        .query<Post>()
        .countAggregate(alias: 'total_posts')
        .groupBy(['authorId'])
        .having('total_posts', PredicateOperator.greaterThan, 1)
        .orderBy('authorId');
    final pipeline = const MongoAggregatePipelineBuilder().build(
      query.debugPlan(),
    );
    final havingStage = pipeline.firstWhere(
      (stage) => stage.containsKey('\$match'),
      orElse: () => const <String, Object?>{},
    );
    expect(havingStage['\$match'], containsPair('total_posts', {'\$gt': 1}));
  });
}
