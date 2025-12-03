import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:ormed_mongo/src/mongo_query_plan_metadata.dart';
import 'package:ormed_mongo/src/mongo_transaction_context.dart';
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
    // Create custom codecs map
    final customCodecs = <String, ValueCodec<dynamic>>{
      'PostgresPayloadCodec': const PostgresPayloadCodec(),
      'SqlitePayloadCodec': const SqlitePayloadCodec(),
      'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
      'JsonMapCodec': const JsonMapCodec(),
    };

    dataSource = DataSource(DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
      codecs: customCodecs,
    ));
    await dataSource.init();
    await seedGraph(dataSource);
  });

  tearDownAll(() async => await dataSource.dispose());

  const stage = {
    '\$match': {
      'post_count': {'\$gt': 0},
    },
  };

  test('Mongo aggregate builder appends recorded stages', () async {
    final plan = dataSource.context
        .query<Post>()
        .countAggregate(alias: 'post_count')
        .groupBy(['authorId'])
        .debugPlan();

    trackMongoQueryPlan(
      plan,
      pipelineStages: [stage],
      sessionState: MongoTransactionState.idle,
    );

    final pipeline = const MongoAggregatePipelineBuilder().build(plan);

    final projectIndex = pipeline.indexWhere(
      (element) => element.containsKey('\$project'),
    );
    expect(projectIndex, isNonNegative);
    expect(projectIndex + 1, lessThan(pipeline.length));
    expect(pipeline[projectIndex + 1], equals(stage));
  });

  test('Statement preview includes recorded stages after aggregation', () {
    final plan = dataSource.context
        .query<Post>()
        .countAggregate(alias: 'post_count')
        .groupBy(['authorId'])
        .debugPlan();

    trackMongoQueryPlan(
      plan,
      pipelineStages: [stage],
      sessionState: MongoTransactionState.idle,
    );

    final preview = dataSource.context.describeQuery(plan);
    final payload = preview.payload as DocumentStatementPayload;
    final pipeline = payload.arguments['pipeline'] as List<Object?>?;

    expect(pipeline, isNotNull);
    final projectIndex = pipeline!.indexWhere(
      (element) => element is Map && element.containsKey('\$project'),
    );
    expect(projectIndex, isNonNegative);
    expect(projectIndex + 1, lessThan(pipeline.length));
    expect(pipeline[projectIndex + 1], equals(stage));
  });

  test('Mongo hook records pipeline stages automatically', () async {
    final query = dataSource.context
        .query<Post>()
        .countAggregate(alias: 'post_count')
        .groupBy(['authorId'])
        .withMongoPipelineStage(stage);
    final plan = query.debugPlan();

    await dataSource.context.runSelect(plan);

    final metadata = metadataForPlan(plan);
    expect(metadata, isNotNull);
    expect(metadata!.pipelineStages, contains(stage));
  });
}
