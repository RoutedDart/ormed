import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';
import 'package:test/test.dart';

class _FakeTransport implements D1Transport {
  final List<(String, List<Object?>)> executed = [];
  final List<(String, List<Object?>)> queried = [];

  @override
  Future<void> close() async {}

  @override
  Future<D1StatementResult> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    executed.add((sql, List<Object?>.from(parameters)));
    return const D1StatementResult(meta: <String, Object?>{'changes': 1});
  }

  @override
  Future<D1StatementResult> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    queried.add((sql, List<Object?>.from(parameters)));
    return const D1StatementResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'ok': 1},
      ],
    );
  }
}

class _FakeBatchTransport extends _FakeTransport implements D1BatchTransport {
  final List<List<D1Statement>> batches = [];

  @override
  Future<List<D1StatementResult>> batch(
    Iterable<D1Statement> statements,
  ) async {
    final batch = List<D1Statement>.from(statements);
    batches.add(batch);
    var mutationNumber = 0;
    return [
      for (final statement in batch)
        if (statement.sql.trimLeft().toUpperCase().startsWith('SELECT'))
          const D1StatementResult(
            rows: [
              <String, Object?>{
                'id': 1,
                'email': 'ada@example.test',
                'active': 1,
              },
            ],
          )
        else
          D1StatementResult(
            meta: <String, Object?>{
              'changes': 1,
              'last_row_id': 100 + ++mutationNumber,
            },
          ),
    ];
  }
}

final class _FailingBatchTransport extends _FakeBatchTransport {
  @override
  Future<List<D1StatementResult>> batch(
    Iterable<D1Statement> statements,
  ) async {
    final batch = List<D1Statement>.from(statements);
    batches.add(batch);
    return [
      const D1StatementResult(meta: <String, Object?>{'changes': 1}),
      const D1StatementResult(success: false, error: 'constraint failed'),
    ];
  }
}

final class _StaleIdBatchTransport extends _FakeBatchTransport {
  @override
  Future<List<D1StatementResult>> batch(
    Iterable<D1Statement> statements,
  ) async {
    final batch = List<D1Statement>.from(statements);
    batches.add(batch);
    return [
      for (var index = 0; index < batch.length; index++)
        D1StatementResult(
          meta: <String, Object?>{
            'changes': index == 0 ? 0 : 1,
            'last_row_id': 999,
          },
        ),
    ];
  }
}

void main() {
  test(
    'queryRaw/executeRaw delegates to transport with normalized params',
    () async {
      final transport = _FakeTransport();
      final adapter = D1DriverAdapter.custom(
        config: const DatabaseConfig(driver: 'd1'),
        transport: transport,
      );

      final rows = await adapter.queryRaw('select ?', <Object?>[
        true,
        DateTime.utc(2026, 1, 1),
        BigInt.from(7),
      ]);
      await adapter.executeRaw('pragma foreign_keys = on', <Object?>[false]);

      expect(rows, hasLength(1));
      expect(rows.first['ok'], 1);

      expect(transport.queried, hasLength(1));
      expect(transport.queried.first.$2[0], 1);
      expect(transport.queried.first.$2[1], isA<String>());
      expect(transport.queried.first.$2[2], 7);

      expect(transport.executed, hasLength(1));
      expect(transport.executed.first.$2[0], 0);
    },
  );

  test('throws after close', () async {
    final adapter = D1DriverAdapter.custom(
      config: const DatabaseConfig(driver: 'd1'),
      transport: _FakeTransport(),
    );

    await adapter.close();

    expect(() => adapter.queryRaw('select 1'), throwsA(isA<StateError>()));
    expect(
      () => adapter.batch(const [D1Statement(sql: 'SELECT 1')]),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      adapter.runAtomicBatch(const []),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects transaction API because D1 cannot provide atomicity', () async {
    final adapter = D1DriverAdapter.custom(
      config: const DatabaseConfig(driver: 'd1'),
      transport: _FakeTransport(),
    );

    expect(
      () => adapter.transaction(() async => 1),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('does not support atomic'),
        ),
      ),
    );
  });

  test('does not advertise transactions when the API cannot provide them', () {
    final adapter = D1DriverAdapter.custom(
      config: const DatabaseConfig(driver: 'd1'),
      transport: _FakeTransport(),
    );

    expect(adapter.metadata.supportsTransactions, isFalse);
    expect(
      adapter.metadata.supportsCapability(DriverCapability.transactions),
      isFalse,
    );
  });

  test('executes query-builder operations through one native batch', () async {
    final transport = _FakeBatchTransport();
    final adapter = D1DriverAdapter.custom(
      config: const DatabaseConfig(driver: 'd1'),
      transport: transport,
    );
    final registry = bootstrapOrm();
    final context = QueryContext(registry: registry, driver: adapter);

    final results = await context.atomicBatch([
      context.query<User>().where('id', 1).batchUpdate({'active': true}),
      context.query<User>().where('id', 1).batchSelect(),
    ]);

    expect(
      adapter.metadata.supportsCapability(DriverCapability.atomicBatches),
      isTrue,
    );
    expect(transport.batches, hasLength(1));
    expect(transport.batches.single, hasLength(2));
    expect(transport.batches.single.first.parameters, contains(1));
    expect(transport.executed, isEmpty);
    expect(transport.queried, isEmpty);
    expect(results.first.affectedRows, 1);
    expect(results.last.rows.single['active'], isTrue);
    expect(results.first.statementMetadata.single['changes'], 1);
  });

  test('expands multi-row inserts and exposes generated IDs', () async {
    final transport = _FakeBatchTransport();
    final adapter = D1DriverAdapter.custom(
      config: const DatabaseConfig(driver: 'd1'),
      transport: transport,
    );
    final registry = bootstrapOrm();
    final context = QueryContext(registry: registry, driver: adapter);

    final results = await context.atomicBatch([
      context.query<User>().batchInsert([
        <String, Object?>{'email': 'ada@example.test', 'active': true},
        <String, Object?>{'email': 'grace@example.test', 'active': false},
      ]),
    ]);

    expect(transport.batches.single, hasLength(2));
    expect(transport.batches.single.first.parameters, contains(1));
    expect(transport.batches.single.last.parameters, contains(0));
    expect(results.single.affectedRows, 2);
    expect(results.single.generatedIds, [101, 102]);
    expect(results.single.statementMetadata, hasLength(2));
  });

  test('does not report stale IDs for skipped inserts or upserts', () async {
    final transport = _StaleIdBatchTransport();
    final adapter = D1DriverAdapter.custom(
      config: const DatabaseConfig(driver: 'd1'),
      transport: transport,
    );
    final registry = bootstrapOrm();
    final context = QueryContext(registry: registry, driver: adapter);

    final results = await context.atomicBatch([
      context.query<User>().batchInsert([
        <String, Object?>{'email': 'duplicate@example.test'},
      ], ignoreConflicts: true),
      context.query<User>().batchUpsert(
        [
          <String, Object?>{'email': 'existing@example.test', 'active': true},
        ],
        uniqueBy: const ['email'],
      ),
    ]);

    expect(results[0].generatedIds, isEmpty);
    expect(results[1].generatedIds, isEmpty);
  });

  test('dispatches mutations that have no bound parameters', () async {
    final transport = _FakeBatchTransport();
    final adapter = D1DriverAdapter.custom(
      config: const DatabaseConfig(driver: 'd1'),
      transport: transport,
    );
    final registry = bootstrapOrm();
    final context = QueryContext(registry: registry, driver: adapter);

    final results = await context.atomicBatch([
      context.query<User>().batchDelete(),
    ]);

    expect(transport.batches.single, hasLength(1));
    expect(results.single.affectedRows, 1);
  });

  test(
    'surfaces a failed native batch statement without returning success',
    () async {
      final adapter = D1DriverAdapter.custom(
        config: const DatabaseConfig(driver: 'd1'),
        transport: _FailingBatchTransport(),
      );
      final registry = bootstrapOrm();
      final context = QueryContext(registry: registry, driver: adapter);

      await expectLater(
        context.atomicBatch([
          context.query<User>().where('id', 1).batchDelete(),
          context.query<User>().where('id', 2).batchDelete(),
        ]),
        throwsA(isA<D1RequestException>()),
      );
    },
  );

  test('http transport option validation', () {
    expect(
      () => D1HttpTransport.fromOptions(const <String, Object?>{}),
      throwsA(isA<ArgumentError>()),
    );

    expect(
      () => D1HttpTransport.fromOptions(const <String, Object?>{
        'accountId': 'acct',
        'databaseId': 'db',
        'apiToken': 'token',
      }),
      returnsNormally,
    );
  });
}
