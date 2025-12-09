import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

Future<void> main() async {
  late DataSource dataSource;
  late PostgresDriverAdapter driverAdapter;

  registerDriverTestFactories();
  
  // Build and register models with type aliases
  final registry = buildOrmRegistry();

  // Configure the Postgres driver
  final url =
      Platform.environment['POSTGRES_URL'] ??
      'postgres://postgres:postgres@localhost:6543/orm_test';

  // Register PostgreSQL codecs
  PostgresDriverAdapter.registerCodecs();

  // Register custom test codecs
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
    'Map<String, Object?>': const JsonMapCodec(),
    'Map<String, Object?>?': const JsonMapCodec(),
  };

  for (final entry in customCodecs.entries) {
    ValueCodecRegistry.instance.registerCodec(key: entry.key, codec: entry.value);
  }

  driverAdapter = PostgresDriverAdapter.custom(
    config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
  );

  // Create the DataSource
  dataSource = DataSource(
    DataSourceOptions(
      name: 'default',
      driver: driverAdapter,
      entities: registry.allDefinitions,
      registry: registry,
      codecs: customCodecs,
      logging: true,
      enableNamedTimezones: true,
    ),
  );

  // Initialize and setup schema
  await dataSource.init();
  dataSource.enableQueryLog();

  // Enable SQL query logging
  dataSource.connection.onBeforeQuery((plan) {
    final preview = dataSource.connection.driver.describeQuery(plan);
    print('[QUERY SQL] ${preview.normalized.command}');
    if (preview.normalized.parameters.isNotEmpty) {
      print('[PARAMS] ${preview.normalized.parameters}');
    }
  });

  // Enable mutation logging
  dataSource.context.onMutation((event) {
    if (Platform.environment['ORMED_TEST_LOG_MUTATIONS'] == 'true') {
      print('[MUTATION SQL] ${event.preview.normalized.command}');
      if (event.preview.normalized.parameters.isNotEmpty) {
        print('[PARAMS] ${event.preview.normalized.parameters}');
      }
    }
    if (event.error != null) {
      print('[MUTATION ERROR] ${event.error}');
    }
  });

  registerDriverTestFactories();

  tearDownAll(() async {
    await dataSource.dispose();
  });

  runAllDriverTests(dataSource: dataSource);
}
