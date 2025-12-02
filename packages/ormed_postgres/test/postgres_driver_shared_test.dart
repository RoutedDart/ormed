import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

void main() {
  const postgresCapabilities = {
    DriverCapability.joins,
    DriverCapability.insertUsing,
    DriverCapability.queryDeletes,
    DriverCapability.schemaIntrospection,
    DriverCapability.threadCount,
    DriverCapability.transactions,
    DriverCapability.adHocQueryUpdates,
    DriverCapability.returning,
    DriverCapability.increment,
    DriverCapability.relationAggregates,
  };
  const sharedConfig = DriverTestConfig(
    driverName: 'PostgresDriverAdapter',
    supportsReturning: true,
    supportsCaseInsensitiveLike: true,
    supportsQueryDeletes: true,
    supportsThreadCount: true,
    supportsAdHocQueryUpdates: true,
    supportsSqlPreviews: true,
    supportsAdvancedQueryBuilders: true,
    supportsDistinctOn: true,
    capabilities: postgresCapabilities,
  );

  late DataSource dataSource;
  late PostgresDriverAdapter driverAdapter;

  // Configure the Postgres driver
  final url =
      Platform.environment['POSTGRES_URL'] ??
      'postgres://postgres:postgres@localhost:6543/orm_test';

  // Create custom codecs map
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
  };

  // Create codec registry for the adapter
  final codecRegistry = ValueCodecRegistry.standard();
  for (final entry in customCodecs.entries) {
    codecRegistry.registerCodec(key: entry.key, codec: entry.value);
  }

  driverAdapter = PostgresDriverAdapter.custom(
    config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
    codecRegistry: codecRegistry,
  );

  // Create the DataSource
  dataSource = DataSource(
    DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
      codecs: customCodecs,
      logging: true,
    ),
  );

  setUpAll(() async {
    // Initialize and setup schema
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

    registerDriverTestFactories();
    await resetDriverTestSchema(driverAdapter, schema: null);
  });

  tearDownAll(() async {
    await dropDriverTestSchema(driverAdapter, schema: null);
    await dataSource.dispose();
  });

  runDriverQueryTests(dataSource: dataSource, config: sharedConfig);

  runDriverJoinTests(dataSource: dataSource, config: sharedConfig);

  runDriverAdvancedQueryTests(dataSource: dataSource, config: sharedConfig);

  runDriverMutationTests(dataSource: dataSource, config: sharedConfig);

  runDriverTransactionTests(dataSource: dataSource, config: sharedConfig);

  runDriverOverrideTests(dataSource: dataSource, config: sharedConfig);

  runDriverQueryBuilderTests(dataSource: dataSource, config: sharedConfig);
}
