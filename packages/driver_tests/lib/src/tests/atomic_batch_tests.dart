import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';

/// Verifies the shared atomic-batch contract for every transactional driver
/// and every driver that advertises a native atomic batch implementation.
void runDriverAtomicBatchTests() {
  ormedGroup('atomic batches', (dataSource) {
    final metadata = dataSource.options.driver.metadata;
    final supportsAtomicBatches = metadata.supportsCapability(
      DriverCapability.atomicBatches,
    );

    test('executes staged mutations and queries in order', () async {
      final id = _testId();
      final email = 'atomic_order_$id@example.com';
      final repo = dataSource.repo<User>();
      await repo.insert(User(id: id, email: email));

      final results = await dataSource.context.atomicBatch([
        dataSource.context.query<User>().where('id', id).batchUpdate({
          'active': true,
        }),
        dataSource.context.query<User>().where('id', id).batchSelect(),
      ]);

      expect(results, hasLength(2));
      expect(results.first.affectedRows, 1);
      expect(results.last.rows, hasLength(1));
      expect(results.last.rows.single['id'], id);
      expect(results.last.rows.single['active'], isTrue);
    }, skip: !supportsAtomicBatches);

    test('rolls back earlier mutations when a later operation fails', () async {
      final id = _testId();
      final email = 'atomic_rollback_$id@example.com';
      final repo = dataSource.repo<User>();
      await repo.insert(User(id: id, email: email, name: 'before'));

      await expectLater(
        dataSource.context.atomicBatch([
          dataSource.context.query<User>().where('id', id).batchUpdate({
            'name': 'after',
          }),
          dataSource.context.query<User>().batchInsert([
            User(id: id, email: 'conflict_$id@example.com'),
          ]),
        ]),
        throwsA(anything),
      );

      final user = await dataSource.context
          .query<User>()
          .where('id', id)
          .first();
      expect(user?.name, 'before');
    }, skip: !supportsAtomicBatches);
  });
}

int _testId() => 900000 + (DateTime.now().microsecondsSinceEpoch % 90000);
