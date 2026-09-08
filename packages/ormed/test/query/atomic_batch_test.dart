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

final class _FailingNativeBatchDriver extends InMemoryQueryExecutor
    implements AtomicBatchDriver {
  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'native_batch',
    supportsTransactions: false,
    capabilities: {DriverCapability.atomicBatches},
  );

  @override
  Future<List<AtomicBatchResult>> runAtomicBatch(
    List<AtomicBatchOperation> operations,
  ) async {
    throw StateError('native batch failed');
  }
}

final class _RecordingNativeBatchDriver extends InMemoryQueryExecutor
    implements AtomicBatchDriver {
  var batchCalls = 0;

  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'native_batch',
    supportsTransactions: false,
    capabilities: {DriverCapability.atomicBatches},
  );

  @override
  Future<List<AtomicBatchResult>> runAtomicBatch(
    List<AtomicBatchOperation> operations,
  ) async {
    batchCalls++;
    return [
      for (final operation in operations)
        AtomicBatchResult(operation: operation),
    ];
  }
}

final class _NoGeneratedIdsDriver extends InMemoryQueryExecutor {
  @override
  Future<MutationResult> runMutation(MutationPlan plan) {
    if (plan.operation == MutationOperation.insert) {
      return Future.value(MutationResult(affectedRows: plan.rows.length));
    }
    return super.runMutation(plan);
  }
}

final class _QueryDeletePlanningDriver extends InMemoryQueryExecutor {
  @override
  DriverMetadata get metadata =>
      const DriverMetadata(name: 'query_delete', supportsQueryDeletes: true);
}

final class _RejectUpdateInterceptor extends QueryInterceptor {
  @override
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  ) {
    if (context.mutationPlan?.operation == MutationOperation.update ||
        context.mutationPlan?.operation == MutationOperation.queryUpdate) {
      throw StateError('updates are not allowed in this batch');
    }
    return next();
  }
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
    expect(
      () => context.repository<User>().batchUpdate({'active': false}),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => context.repository<User>().batchDelete(),
      throwsA(isA<ArgumentError>()),
    );
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

  test('rejects an operation built by another query context', () async {
    final registry = bootstrapOrm();
    final first = _TransactionalDriver()
      ..register(UserOrmDefinition.definition, const [
        User(id: 1, email: 'ada@example.test', active: false),
      ]);
    final second = _TransactionalDriver();
    final firstContext = QueryContext(registry: registry, driver: first);
    final secondContext = QueryContext(registry: registry, driver: second);

    expect(
      secondContext.atomicBatch([
        firstContext.query<User>().where('id', 1).batchSelect(),
      ]),
      throwsA(isA<StateError>()),
    );
  });

  test('repository operations can be staged for an atomic batch', () async {
    final registry = bootstrapOrm();
    final driver = _TransactionalDriver()
      ..register(UserOrmDefinition.definition, const [
        User(id: 1, email: 'ada@example.test', active: false),
      ]);
    final context = QueryContext(registry: registry, driver: driver);

    final results = await context.atomicBatch([
      context.repository<User>().batchUpdate(
        {'active': true},
        where: {'id': 1},
      ),
      context.repository<User>().batchSelect(where: {'id': 1}),
    ]);

    expect(results.first.affectedRows, 1);
    expect(results.last.rows.single['active'], isTrue);
  });

  test('insertGetIds returns IDs from returned mutation rows', () async {
    final registry = bootstrapOrm();
    final driver = _TransactionalDriver();
    final context = QueryContext(registry: registry, driver: driver);

    final ids = await context.query<User>().insertGetIds(const [
      User(id: 10, email: 'ada@example.test'),
      User(id: 11, email: 'grace@example.test'),
    ]);

    expect(ids, [10, 11]);
    expect(driver.transactionCalls, 1);
  });

  test('updateBatch rejects rows missing their unique key', () async {
    final registry = bootstrapOrm();
    final driver = _TransactionalDriver();
    final context = QueryContext(registry: registry, driver: driver);

    await expectLater(
      context.query<User>().updateBatch([
        {'active': true},
      ], uniqueBy: 'id'),
      throwsA(isA<ArgumentError>()),
    );
    expect(driver.transactionCalls, 0);
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

  test('preflights native operations with their individual plans', () async {
    final registry = bootstrapOrm();
    final driver = _RecordingNativeBatchDriver();
    final context = QueryContext(
      registry: registry,
      driver: driver,
      interceptorPipeline: QueryInterceptorPipeline(
        driverName: 'native_batch',
        interceptors: [_RejectUpdateInterceptor()],
      ),
    );

    await expectLater(
      context.atomicBatch([
        context.query<User>().batchSelect(),
        context.query<User>().batchUpdate({'active': true}),
      ]),
      throwsA(isA<StateError>()),
    );
    expect(driver.batchCalls, 0);
  });

  test('hard-delete plans retain the primary key for projected queries', () {
    final registry = bootstrapOrm();
    final context = QueryContext(
      registry: registry,
      driver: _QueryDeletePlanningDriver(),
    );

    final operation = context
        .query<User>()
        .select(['email'])
        .withoutAutoHydration()
        .batchDelete();
    final plan = (operation as AtomicBatchMutationOperation).plan;

    expect(plan.queryPlan!.selects, ['id']);
    expect(plan.queryPlan!.rawSelects, isEmpty);
    expect(plan.queryPlan!.customSelects, isEmpty);
  });

  test(
    'insertGetIds rejects auto-increment sentinels without driver IDs',
    () async {
      final registry = bootstrapOrm();
      final context = QueryContext(
        registry: registry,
        driver: _NoGeneratedIdsDriver(),
      );

      await expectLater(
        context.query<User>().insertGetIds(const [
          User(id: 0, email: 'ada@example.test'),
          User(id: -1, email: 'grace@example.test'),
        ]),
        throwsA(isA<UnsupportedError>()),
      );
    },
  );

  test('logs every operation when a native batch fails', () async {
    final registry = bootstrapOrm();
    final connection = OrmConnection(
      config: ConnectionConfig(name: 'native-batch-test'),
      driver: _FailingNativeBatchDriver(),
      registry: registry,
    );
    final events = <QueryExecuted>[];
    connection.listen(events.add);
    connection.enableQueryLog();

    await expectLater(
      connection.atomicBatch([
        connection.query<User>().batchSelect(),
        connection.query<User>().where('id', 1).batchUpdate({'active': true}),
      ]),
      throwsA(isA<StateError>()),
    );

    expect(connection.queryLog, hasLength(2));
    expect(connection.queryLog.map((entry) => entry.type), [
      'query',
      'mutation',
    ]);
    expect(connection.queryLog.every((entry) => !entry.success), isTrue);
    expect(events, hasLength(2));
    expect(events.every((event) => event.error is StateError), isTrue);
  });
}
