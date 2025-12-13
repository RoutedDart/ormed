import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';

void runDriverTransactionTests() {
  ormedGroup('transactions', (dataSource) {
    final metadata = dataSource.options.driver.metadata;
    if (!metadata.supportsCapability(DriverCapability.transactions)) {
      return;
    }
    test('rolls back when transaction throws', () async {
      final repo = dataSource.context.repository<User>();
      final uniqueEmail = 'dave_${DateTime.now().millisecondsSinceEpoch}@example.com';
      await expectLater(
        () => dataSource.connection.driver.transaction(() async {
          await repo.insert(
            User(id: 0, email: uniqueEmail, active: true),
          );
          throw StateError('boom');
        }),
        throwsStateError,
      );

      final users = await dataSource.context.query<User>().get();
      expect(users, isEmpty);
    });

    test('commits when transaction completes', () async {
      dataSource.connection.onQueryLogged((l) {
        print(l.preview.sqlWithBindings);
      });
      final repo = dataSource.context.repository<User>();
      final uniqueEmail = 'eve_${DateTime.now().millisecondsSinceEpoch}@example.com';
      await dataSource.connection.driver.transaction(() async {
        await repo.insert(
          User(id: 0, email: uniqueEmail, active: true),
        );
      });

      final users = await dataSource.context.query<User>().get();
      expect(users.single.email, uniqueEmail);
    });
  });
}
