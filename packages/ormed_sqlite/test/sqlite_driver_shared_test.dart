import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';

import 'support/database_utils.dart';

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

  runDriverQueryTests(
    createHarness: SqliteTestHarness.inMemory,
    config: config,
  );

  runDriverJoinTests(createHarness: SqliteTestHarness.inMemory, config: config);

  runDriverAdvancedQueryTests(
    createHarness: SqliteTestHarness.inMemory,
    config: config,
  );

  runDriverMutationTests(
    createHarness: SqliteTestHarness.inMemory,
    config: config,
  );

  runDriverTransactionTests(
    createHarness: SqliteTestHarness.inMemory,
    config: config,
  );

  runDriverOverrideTests(
    createHarness: SqliteTestHarness.inMemory,
    config: config,
  );

  runDriverFactoryInheritanceTests(
    createHarness: SqliteTestHarness.inMemory,
    config: config,
  );

  runDriverQueryBuilderTests(
    createHarness: SqliteTestHarness.inMemory,
    config: config,
  );
}
