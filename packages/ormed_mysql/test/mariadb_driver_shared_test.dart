import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

Future<void> main() async {
  late DataSource dataSource;
  late MariaDbDriverAdapter driverAdapter;

  registerDriverTestFactories();
  
  // Build and register models with type aliases
  final registry = buildOrmRegistry();

  // Configure the MariaDB driver
  final url =
      Platform.environment['MARIADB_URL'] ??
      'mariadb://root:secret@localhost:6604/orm_test';

  // Register MySQL/MariaDB codecs
  MySqlDriverAdapter.registerCodecs();

  // Register custom test codecs
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
    'json': const JsonMapCodec(), // For @OrmField(cast: 'json')
    'bool': const MySqlBoolCodec(),
    'bool?': const MySqlBoolCodec(),
  };

  for (final entry in customCodecs.entries) {
    ValueCodecRegistry.instance.registerCodec(key: entry.key, codec: entry.value);
  }

  driverAdapter = MariaDbDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mariadb', options: {'url': url}),
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

  setUpAll(() async {
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
      print('[MUTATION SQL] ${event.preview.normalized.command}');
      if (event.preview.normalized.parameters.isNotEmpty) {
        print('[PARAMS] ${event.preview.normalized.parameters}');
      }
      if (event.error != null) {
        print('[MUTATION ERROR] ${event.error}');
      }
    });

    registerDriverTestFactories();
    await resetDriverTestSchema(driverAdapter, schema: null);
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  runAllDriverTests(dataSource: dataSource);
}
