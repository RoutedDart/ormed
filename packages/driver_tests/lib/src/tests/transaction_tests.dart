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
      await expectLater(
        () => dataSource.connection.driver.transaction(() async {
          await repo.insert(
            const User(id: 1, email: 'dave@example.com', active: true),
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
      await dataSource.connection.driver.transaction(() async {
        await repo.insert(
          const User(id: 2, email: 'eve@example.com', active: true),
        );
      });

      final users = await dataSource.context.query<User>().get();
      expect(users.single.email, 'eve@example.com');
    });
  });
}
