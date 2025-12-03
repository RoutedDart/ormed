import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

Future<void> main() async {
  late DataSource dataSource;
  late MySqlDriverAdapter driverAdapter;

  // Configure the MySQL driver
  final url =
      Platform.environment['MYSQL_URL'] ??
      'mysql://root:secret@localhost:6605/orm_test';

  // Create custom codecs map and register in driver's codec registry
  // The driver will augment this with MySQL-specific codecs (e.g., MySqlBoolCodec)
  final codecRegistry = ValueCodecRegistry.standard();
  codecRegistry.registerCodec(
    key: 'PostgresPayloadCodec',
    codec: const PostgresPayloadCodec(),
  );
  codecRegistry.registerCodec(
    key: 'SqlitePayloadCodec',
    codec: const SqlitePayloadCodec(),
  );
  codecRegistry.registerCodec(
    key: 'MariaDbPayloadCodec',
    codec: const MariaDbPayloadCodec(),
  );
  codecRegistry.registerCodec(key: 'JsonMapCodec', codec: const JsonMapCodec());

  driverAdapter = MySqlDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mysql', options: {'url': url, 'ssl': true}),
    codecRegistry: codecRegistry,
  );

  // Create the DataSource - pass codecs again so DataSource has access to them
  // (DataSource creates its own registry, so we need to provide codecs here too)
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
    // Also add MySQL-specific codecs that the driver would add
    'bool': const MySqlBoolCodec(),
    'bool?': const MySqlBoolCodec(),
  };

  dataSource = DataSource(
    DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
      codecs: customCodecs,
      logging: true,
    ),
  );
  await dataSource.init();
  dataSource.enableQueryLog();

  // Enable SQL query logging
  dataSource.connection.onBeforeQuery((plan) {
    final preview = dataSource.connection.driver.describeQuery(plan);
    // print('[QUERY SQL] ${preview.normalized.command}');
    if (preview.normalized.parameters.isNotEmpty) {
      // print('[PARAMS] ${preview.normalized.parameters}');
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

  tearDownAll(() async {
    await dataSource.dispose();
  });

  runAllDriverTests(dataSource: dataSource);
}
