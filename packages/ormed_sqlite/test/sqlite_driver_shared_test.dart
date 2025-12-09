import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

Future<void> main() async {
  registerDriverTestFactories();
  
  // Build and register models with type aliases
  final registry = buildOrmRegistry();

  // Register SQLite codecs
  SqliteDriverAdapter.registerCodecs();

  // Register custom test codecs
  ValueCodecRegistry.instance.registerCodec(
    key: 'PostgresPayloadCodec',
    codec: const PostgresPayloadCodec(),
  );
  ValueCodecRegistry.instance.registerCodec(
    key: 'SqlitePayloadCodec',
    codec: const SqlitePayloadCodec(),
  );
  ValueCodecRegistry.instance.registerCodec(
    key: 'JsonMapCodec',
    codec: const JsonMapCodec(),
  );

  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
  };

  // Create adapter
  final driverAdapter = SqliteDriverAdapter.inMemory();

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'default',
      driver: driverAdapter,
      entities: registry.allDefinitions,
      registry: registry,
      codecs: customCodecs,
      enableNamedTimezones: true, // Enable for timezone conversion tests
    ),
  );

  await dataSource.init();

  // Enable query logging
  dataSource.connection.enableQueryLog(includeParameters: true);

  // Add query logging callback for real-time output
  dataSource.connection.onQueryLogged((entry) {
    print('SQL: ${entry.sql}');
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  runAllDriverTests(dataSource: dataSource);
}
