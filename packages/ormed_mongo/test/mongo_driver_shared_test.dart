import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';

import 'support/mongo_harness.dart';

Future<MongoTestHarness> _createHarness() => MongoTestHarness.create();

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
  runDriverQueryTests(createHarness: _createHarness, config: config);

  runDriverMutationTests(createHarness: _createHarness, config: config);

  runDriverAdvancedQueryTests(createHarness: _createHarness, config: config);

  runDriverTransactionTests(createHarness: _createHarness, config: config);

  runDriverOverrideTests(createHarness: _createHarness, config: config);

  runDriverQueryBuilderTests(createHarness: _createHarness, config: config);
}
