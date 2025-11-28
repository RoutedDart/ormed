import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';

import 'support/mariadb_harness.dart';

void main() {
  const mariaDbCapabilities = {
    DriverCapability.joins,
    DriverCapability.insertUsing,
    DriverCapability.queryDeletes,
    DriverCapability.schemaIntrospection,
    DriverCapability.threadCount,
    DriverCapability.transactions,
    DriverCapability.adHocQueryUpdates,
  };
  const config = DriverTestConfig(
    driverName: 'MariaDbDriverAdapter',
    supportsReturning: false,
    supportsCaseInsensitiveLike: false,
    identifierQuote: '`',
    supportsQueryDeletes: true,
    supportsThreadCount: true,
    supportsAdvancedQueryBuilders: true,
    supportsSqlPreviews: true,
    supportsWhereRaw: true,
    supportsSelectRaw: true,
    capabilities: mariaDbCapabilities,
  );

  runDriverQueryTests(
    createHarness: MariaDbTestHarness.connect,
    config: config,
  );

  runDriverJoinTests(createHarness: MariaDbTestHarness.connect, config: config);

  runDriverAdvancedQueryTests(
    createHarness: MariaDbTestHarness.connect,
    config: config,
  );

  runDriverMutationTests(
    createHarness: MariaDbTestHarness.connect,
    config: config,
  );

  runDriverTransactionTests(
    createHarness: MariaDbTestHarness.connect,
    config: config,
  );

  runDriverOverrideTests(
    createHarness: MariaDbTestHarness.connect,
    config: config,
  );

  runDriverQueryBuilderTests(
    createHarness: MariaDbTestHarness.connect,
    config: config,
  );
}
