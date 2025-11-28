import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';

import 'support/mysql_harness.dart';

void main() {
  const mysqlCapabilities = {
    DriverCapability.joins,
    DriverCapability.insertUsing,
    DriverCapability.queryDeletes,
    DriverCapability.schemaIntrospection,
    DriverCapability.threadCount,
    DriverCapability.transactions,
    DriverCapability.adHocQueryUpdates,
  };
  const config = DriverTestConfig(
    driverName: 'MySqlDriverAdapter',
    supportsReturning: false,
    supportsCaseInsensitiveLike: false,
    identifierQuote: '`',
    supportsQueryDeletes: true,
    supportsThreadCount: true,
    supportsAdvancedQueryBuilders: true,
    supportsSqlPreviews: true,
    supportsWhereRaw: true,
    supportsSelectRaw: true,
    supportsRightJoin: true,
    capabilities: mysqlCapabilities,
  );

  runDriverQueryTests(createHarness: MySqlTestHarness.connect, config: config);

  runDriverJoinTests(createHarness: MySqlTestHarness.connect, config: config);

  runDriverAdvancedQueryTests(
    createHarness: MySqlTestHarness.connect,
    config: config,
  );

  runDriverMutationTests(
    createHarness: MySqlTestHarness.connect,
    config: config,
  );

  runDriverTransactionTests(
    createHarness: MySqlTestHarness.connect,
    config: config,
  );

  runDriverOverrideTests(
    createHarness: MySqlTestHarness.connect,
    config: config,
  );

  runDriverQueryBuilderTests(
    createHarness: MySqlTestHarness.connect,
    config: config,
  );
}
