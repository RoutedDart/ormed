import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

Future<void> main() async {
  registerDriverTestFactories();

  // Create custom codecs map
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
  };

  // Create codec registry for the adapter
  final codecRegistry = ValueCodecRegistry.standard();
  for (final entry in customCodecs.entries) {
    codecRegistry.registerCodec(key: entry.key, codec: entry.value);
  }

  // Create adapter with the codec registry
  final driverAdapter = SqliteDriverAdapter.inMemory(
    codecRegistry: codecRegistry,
  );

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'default',
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
      codecs: customCodecs,
    ),
  );

  await dataSource.init();

  // Add query logging
  dataSource.connection.onQueryLogged((entry) {
    print('[SQL][${entry.type}] ${entry.sql}');
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  runAllDriverTests(dataSource: dataSource);
}
