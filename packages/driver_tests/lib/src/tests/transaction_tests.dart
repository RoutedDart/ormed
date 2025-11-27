import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';
import '../config.dart';
import '../harness/driver_test_harness.dart';

void runDriverTransactionTests({
  required DriverHarnessBuilder<DriverTestHarness> createHarness,
  required DriverTestConfig config,
}) {
  if (!config.supportsCapability(DriverCapability.transactions)) {
    return;
  }

  group('${config.driverName} transactions', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();
    });

    tearDown(() async => harness.dispose());

    test('rolls back when transaction throws', () async {
      final repo = harness.context.repository<User>();
      await expectLater(
        () => harness.adapter.transaction(() async {
          await repo.insert(
            const User(id: 1, email: 'dave@example.com', active: true),
          );
          throw StateError('boom');
        }),
        throwsStateError,
      );

      final users = await harness.context.query<User>().get();
      expect(users, isEmpty);
    });

    test('commits when transaction completes', () async {
      final repo = harness.context.repository<User>();
      await harness.adapter.transaction(() async {
        await repo.insert(
          const User(id: 2, email: 'eve@example.com', active: true),
        );
      });

      final users = await harness.context.query<User>().get();
      expect(users.single.email, 'eve@example.com');
    });
  });
}
