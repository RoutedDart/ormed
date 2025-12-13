
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';

import 'support/postgres_test_harness.dart';

Future<void> main() async {
  final harness = await createPostgresTestHarness();

  tearDownAll(() async {
    await harness.dispose();
  });


  runAllDriverTests();
}
