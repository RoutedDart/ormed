import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() {
  const sqliteCapabilities = {
    DriverCapability.joins,
    DriverCapability.insertUsing,
    DriverCapability.queryDeletes,
    DriverCapability.schemaIntrospection,
    DriverCapability.threadCount,
    DriverCapability.transactions,
    DriverCapability.adHocQueryUpdates,
    DriverCapability.relationAggregates,
    DriverCapability.increment,
    DriverCapability.returning,
  };
  const config = DriverTestConfig(
    driverName: 'SqliteDriverAdapter',
    supportsQueryDeletes: true,
    supportsAdHocQueryUpdates: true,
    supportsSqlPreviews: true,
    supportsAdvancedQueryBuilders: true,
    supportsRightJoin: false,
    capabilities: sqliteCapabilities,
  );

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

  setUpAll(() async {
    await dataSource.init();

    // Add query logging
    dataSource.connection.onQueryLogged((entry) {
      print('[SQL][${entry.type}] ${entry.sql}');
    });

    // Setup test schema
    await resetDriverTestSchema(driverAdapter, schema: null);
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  runDriverQueryTests(dataSource: dataSource, config: config);

  runDriverJoinTests(dataSource: dataSource, config: config);

  runDriverAdvancedQueryTests(dataSource: dataSource, config: config);

  runDriverMutationTests(dataSource: dataSource, config: config);

  runDriverTransactionTests(dataSource: dataSource, config: config);

  runDriverOverrideTests(dataSource: dataSource, config: config);

  runDriverFactoryInheritanceTests(dataSource: dataSource, config: config);

  runDriverQueryBuilderTests(dataSource: dataSource, config: config);

  runDriverRepositoryTests(dataSource: dataSource, config: config);
}
