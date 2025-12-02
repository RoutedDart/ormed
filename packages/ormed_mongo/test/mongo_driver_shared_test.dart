import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

import 'shared.dart';

const config = DriverTestConfig(
  driverName: 'MongoDriverAdapter',
  supportsJoins: false,
  supportsInsertUsing: false,
  supportsSchemaIntrospection: true,
  supportsQueryDeletes: true,
  supportsThreadCount: false,
  supportsAdHocQueryUpdates: true,
  supportsReturning: false,
  supportsWhereRaw: false,
  supportsSelectRaw: false,
  capabilities: {
    DriverCapability.schemaIntrospection,
    DriverCapability.queryDeletes,
    DriverCapability.adHocQueryUpdates,
    DriverCapability.relationAggregates,
  },
);

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
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  runDriverQueryTests(dataSource: dataSource, config: config);

  runDriverMutationTests(dataSource: dataSource, config: config);

  runDriverAdvancedQueryTests(dataSource: dataSource, config: config);

  runDriverTransactionTests(dataSource: dataSource, config: config);

  runDriverOverrideTests(dataSource: dataSource, config: config);

  runDriverQueryBuilderTests(dataSource: dataSource, config: config);
}
