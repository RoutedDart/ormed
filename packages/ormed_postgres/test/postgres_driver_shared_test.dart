import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';

import 'support/postgres_harness.dart';

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

  runDriverQueryTests(
    createHarness: PostgresTestHarness.connect,
    config: sharedConfig,
  );

  runDriverJoinTests(
    createHarness: PostgresTestHarness.connect,
    config: sharedConfig,
  );

  runDriverAdvancedQueryTests(
    createHarness: PostgresTestHarness.connect,
    config: sharedConfig,
  );

  runDriverMutationTests(
    createHarness: PostgresTestHarness.connect,
    config: sharedConfig,
  );

  runDriverTransactionTests(
    createHarness: PostgresTestHarness.connect,
    config: sharedConfig,
  );

  runDriverOverrideTests(
    createHarness: PostgresTestHarness.connect,
    config: sharedConfig,
  );

  runDriverQueryBuilderTests(
    createHarness: PostgresTestHarness.connect,
    config: sharedConfig,
  );
}
