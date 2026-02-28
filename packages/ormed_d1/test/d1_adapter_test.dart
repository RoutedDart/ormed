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
  });

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
