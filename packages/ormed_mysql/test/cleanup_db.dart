import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'support/mysql_test_harness.dart';

Future<void> main() async {
  final harness = await createMySqlTestHarness();

  tearDownAll(() async {
    await harness.dispose();
  });

  final manager = createDriverTestSchemaManager(harness.adapter);

  test('cleanup test database', () async {
    print('Purging all tables...');
    await manager.purge();

    await harness.dataSource.dispose();
    print('Done!');
  });
}
