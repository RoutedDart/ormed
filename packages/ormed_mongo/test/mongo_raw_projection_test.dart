import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
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

  test('executeRaw throws UnsupportedError for SQL', () async {
    expect(
      () => driverAdapter.executeRaw('SHOW TABLES'),
      throwsUnsupportedError,
    );
    expect(
      () => driverAdapter.executeRaw('DESCRIBE authors'),
      throwsUnsupportedError,
    );
  });

  test('select projection only returns requested fields', () async {
    final plan = dataSource.context.query<Author>().select(['id']).debugPlan();
    final rows = await dataSource.context.runSelect(plan);
    for (final row in rows) {
      expect(row.containsKey('id'), isTrue);
      final extra = row.keys.toSet().difference({'id', '_id'});
      expect(
        extra,
        isEmpty,
        reason: 'Projection should not include unexpected fields',
      );
    }
  });
}
