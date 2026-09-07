import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

final class _TransactionalDriver extends InMemoryQueryExecutor {
  var transactionCalls = 0;

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    transactionCalls++;
    return action();
  }
}

final class _NonAtomicDriver extends InMemoryQueryExecutor {
  @override
  DriverMetadata get metadata =>
      const DriverMetadata(name: 'non_atomic', supportsTransactions: false);
}

void main() {
  test('transactional drivers execute staged operations in order', () async {
    final registry = bootstrapOrm();
    final driver = _TransactionalDriver()
      ..register(UserOrmDefinition.definition, const [
        User(id: 1, email: 'ada@example.test', active: false),
      ]);
    final context = QueryContext(registry: registry, driver: driver);

    final results = await context.atomicBatch([
      context.query<User>().where('id', 1).batchUpdate({'active': true}),
      context.query<User>().where('id', 1).batchSelect(),
    ]);

    expect(driver.transactionCalls, 1);
    expect(results, hasLength(2));
    expect(results.first.affectedRows, 1);
    expect(results.last.rows.single['active'], isTrue);
  });

  test('rejects an operation built for another driver', () async {
    final registry = bootstrapOrm();
    final context = QueryContext(
      registry: registry,
      driver: _TransactionalDriver(),
    );
    final plan = QueryPlan(
      definition: UserOrmDefinition.definition,
      driverName: 'another_driver',
    );

    expect(
      () => context.atomicBatch([AtomicBatchOperation.query(plan)]),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects drivers without transactions or native batches', () async {
    final registry = bootstrapOrm();
    final context = QueryContext(
      registry: registry,
      driver: _NonAtomicDriver(),
    );

    expect(
      () => context.atomicBatch([context.query<User>().batchSelect()]),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
