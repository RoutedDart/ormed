import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'shared.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

void main() {
  late DataSource dataSource;
  late MongoDriverAdapter driverAdapter;
  late QueryContext loggingContext;
  late OrmConnection connection;
  final logEntries = <QueryLogEntry>[];

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
    loggingContext = QueryContext(
      registry: dataSource.registry,
      driver: driverAdapter,
      codecRegistry: driverAdapter.codecs,
      queryLogHook: (entry) => logEntries.add(entry),
    );
    connection = OrmConnection(
      config: ConnectionConfig(name: 'mongo-log'),
      driver: driverAdapter,
      registry: dataSource.registry,
      context: loggingContext,
    );
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  test('logged previews include relation aggregate metadata', () async {
    logEntries.clear();
    await loggingContext.query<Author>().withCount('posts').rows();
    final entry = logEntries.last;
    final payload = entry.preview.payload as DocumentStatementPayload;
    final metadata = payload.metadata?['mongo_plan'] as Map<String, Object?>?;
    expect(metadata, isNotNull);
    final aggregates = metadata!['relation_aggregates'] as List<Object?>?;
    expect(aggregates, isNotNull);
  });

  test('pretend output includes relation metadata', () async {
    final _ = await connection.pretend(() async {
      await loggingContext.query<Author>().withCount('posts').rows();
    });
    final entry = logEntries.last;
    final payload = entry.preview.payload as DocumentStatementPayload;
    final metadata = payload.metadata?['mongo_plan'] as Map<String, Object?>?;
    expect(metadata, isNotNull);
    final aggregates = metadata!['relation_aggregates'] as List<Object?>?;
    expect(aggregates, isNotNull);
    final formatted = const JsonEncoder.withIndent(
      '  ',
    ).convert(payload.toJson());
    expect(formatted, contains('relation_aggregates'));
  });
}
