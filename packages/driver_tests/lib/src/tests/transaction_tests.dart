import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';
import '../config.dart';
import '../support/driver_schema.dart';

void runDriverTransactionTests({
  required DataSource dataSource,
  required DriverTestConfig config,
}) {
  if (!config.supportsCapability(DriverCapability.transactions)) {
    return;
  }

  group('${config.driverName} transactions', () {
    late TestDatabaseManager manager;

    setUpAll(() async {
      await dataSource.init();
      manager = TestDatabaseManager(
        baseDataSource: dataSource,
        migrationDescriptors: driverTestMigrationEntries
            .map((e) => MigrationDescriptor.fromMigration(
                  id: e.id,
                  migration: e.migration,
                ))
            .toList(),
        strategy: DatabaseIsolationStrategy.truncate,
      );
      await manager.initialize();
    });

    setUp(() async {
      await manager.beginTest('transaction_tests', dataSource);
    });

    tearDown(() async => manager.endTest('transaction_tests', dataSource));

    tearDownAll(() async {
      // Schema cleanup is handled by outer test file
    });

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
