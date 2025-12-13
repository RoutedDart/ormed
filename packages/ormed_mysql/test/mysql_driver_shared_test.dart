import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'support/mysql_test_harness.dart';

Future<void> main() async {
  final harness = await createMySqlTestHarness();

  tearDownAll(() async {
    await harness.dispose();
  });

  // All driver tests are run using ormedTest/ormedGroup which
  // automatically gets isolated databases via the setUpOrmed configuration
  runAllDriverTests();
}
