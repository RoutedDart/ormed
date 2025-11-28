import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'support/mongo_harness.dart';

void main() {
  late MongoTestHarness harness;

  setUpAll(() async {
    harness = await MongoTestHarness.create();
    await seedGraph(harness);
  });

  tearDownAll(() async => await harness.dispose());

  test('executeRaw throws UnsupportedError for SQL', () async {
    expect(
      () => harness.adapter.executeRaw('SHOW TABLES'),
      throwsUnsupportedError,
    );
    expect(
      () => harness.adapter.executeRaw('DESCRIBE authors'),
      throwsUnsupportedError,
    );
  });

  test('select projection only returns requested fields', () async {
    final plan = harness.context.query<Author>().select(['id']).debugPlan();
    final rows = await harness.context.runSelect(plan);
    for (final row in rows) {
      expect(row.containsKey('id'), isTrue);
      final extra = row.keys.toSet().difference({'id', '_id'});
      expect(
        extra,
        isEmpty,
        reason: 'Projection should not include unexpected fields',
      );
    }
  });
}
