import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/scaffolding.dart';

import 'support/sqlite_test_harness.dart';

Future<void> main() async {
  final harness = await createSqliteTestHarness();

  tearDownAll(() async {
    await harness.dispose();
  });

  runAllDriverTests();
}
