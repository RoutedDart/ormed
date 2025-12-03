import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

import 'shared.dart';

Future<void> main() async {
  late DataSource dataSource;
  late MongoDriverAdapter driverAdapter;

  await waitForMongoReady();

  // Create custom codecs map
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
  };

  final codecRegistry = ValueCodecRegistry.standard();
  for (final entry in customCodecs.entries) {
    codecRegistry.registerCodec(key: entry.key, codec: entry.value);
  }

  driverAdapter = createAdapter();

  dataSource = DataSource(
    DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
      codecs: customCodecs,
      logging: true,
    ),
  );
  await dataSource.init();

  // Reset schema
  await clearDatabase();

  // Register test factories if needed, though Mongo is schema-less
  // registerDriverTestFactories();

  tearDownAll(() async {
    await dataSource.dispose();
  });

  // Run all tests
  runAllDriverTests(dataSource: dataSource);
}
