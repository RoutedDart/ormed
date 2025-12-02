import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'shared.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

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

  test('tracks session metadata during transaction', () async {
    final sessions = <Map<String, Object?>>[];
    final remove = dataSource.context.beforeExecuting((statement) {
      final payload = statement.preview.payload as DocumentStatementPayload;
      final map = payload.metadata?['session'] as Map<String, Object?>?;
      if (map != null) {
        sessions.add(map);
      }
    });
    try {
      await dataSource.context.transaction(() async {
        await dataSource.context.query<Post>().whereEquals('id', 1).rows();
      });
      await dataSource.context.transaction(() async {
        await dataSource.context.query<Post>().whereEquals('id', 2).rows();
      });
    } finally {
      remove();
    }
    final sessionIds = sessions
        .map((session) => session['id'] as String?)
        .whereType<String>()
        .toSet();
    expect(sessionIds.length, equals(2));
    expect(sessionIds, hasLength(2));
    expect(sessions.every((session) => session['state'] == 'active'), isTrue);
  });

  test('preview metadata includes session id', () async {
    final sessions = <Map<String, Object?>>[];
    final remove = dataSource.context.beforeExecuting((statement) {
      final payload = statement.preview.payload as DocumentStatementPayload;
      final map = payload.metadata?['session'] as Map<String, Object?>?;
      if (map != null) {
        sessions.add(map);
      }
    });
    try {
      await dataSource.context.transaction(() async {
        await dataSource.context.query<Post>().rows();
      });
    } finally {
      remove();
    }
    final sessionIds = sessions
        .map((session) => session['id'] as String?)
        .whereType<String>()
        .toSet();
    expect(sessionIds, isNotEmpty);
    expect(sessionIds.length, equals(1));
    expect(sessions.first['state'], equals('active'));
  });
}
