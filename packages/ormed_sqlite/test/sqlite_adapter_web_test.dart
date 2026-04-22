import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/src/sqlite_adapter_web.dart' as web_adapter;
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('Sqlite web adapter source', () {
    setUp(() {
      ValueCodecRegistry.instance.clearAll();
    });

    tearDown(() {
      ValueCodecRegistry.instance.clearAll();
    });

    test(
      'rejects missing worker and wasm options without custom transport',
      () {
        expect(
          () => web_adapter.SqliteDriverAdapter.file('app.sqlite'),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('workerUri'),
            ),
          ),
        );
      },
    );

    test('allows custom transport without worker and wasm options', () {
      final adapter = web_adapter.SqliteDriverAdapter.file(
        'app.sqlite',
        transport: _FakeSqliteWebTransport(),
      );

      expect(adapter.driverName, equals('sqlite'));
    });

    test('registers SQLite DateTime codecs for the sqlite driver', () {
      web_adapter.SqliteDriverAdapter.file(
        'app.sqlite',
        transport: _FakeSqliteWebTransport(),
      );

      final registry = ValueCodecRegistry.instance.forDriver('sqlite');
      final dateField = FieldDefinition(
        name: 'created_at',
        columnName: 'created_at',
        dartType: 'DateTime',
        resolvedType: 'DateTime',
        isPrimaryKey: false,
        isNullable: false,
      );

      final encoded = registry.encodeField(dateField, DateTime.utc(2024, 1, 1));
      expect(encoded, equals('2024-01-01T00:00:00.000Z'));
      expect(
        () => registry.decodeByKey<DateTime>('DateTime', 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'applies session pragmas and init statements before queries',
      () async {
        final transport = _FakeSqliteWebTransport();
        final adapter = web_adapter.SqliteDriverAdapter.custom(
          config: const DatabaseConfig(
            driver: 'sqlite',
            options: {
              'database': 'app.sqlite',
              'session': {'foreign_keys': true},
              'sessionAllowlist': ['foreign_keys'],
              'init': ['PRAGMA busy_timeout = 5000'],
            },
          ),
          transport: transport,
        );

        await adapter.queryRaw('SELECT 1 AS ok');
        await adapter.queryRaw('SELECT 2 AS ok');

        expect(
          transport.executedSql,
          equals(<String>[
            'PRAGMA foreign_keys = ON',
            'PRAGMA busy_timeout = 5000',
          ]),
        );
        expect(
          transport.queriedSql,
          equals(<String>['SELECT 1 AS ok', 'SELECT 2 AS ok']),
        );
        expect(transport.lockRequests, equals(1));
      },
    );
  });
}

final class _FakeSqliteWebTransport implements SqliteWebTransport {
  final List<String> executedSql = <String>[];
  final List<String> queriedSql = <String>[];
  int lockRequests = 0;

  @override
  Future<void> close() async {}

  @override
  Future<SqliteWebStatementResult> execute(
    String sql, [
    List<Object?> parameters = const [],
    SqliteWebLockToken? token,
    bool checkInTransaction = false,
  ]) async {
    executedSql.add(sql);
    return const SqliteWebStatementResult(affectedRows: 1);
  }

  @override
  Future<SqliteWebStatementResult> query(
    String sql, [
    List<Object?> parameters = const [],
    SqliteWebLockToken? token,
    bool checkInTransaction = false,
  ]) async {
    queriedSql.add(sql);
    return const SqliteWebStatementResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'ok': 1},
      ],
    );
  }

  @override
  Future<T> requestLock<T>(
    Future<T> Function(SqliteWebLockToken token) body, {
    Future<void>? abortTrigger,
  }) async {
    lockRequests++;
    return body(_FakeSqliteWebLockToken(lockRequests));
  }
}

final class _FakeSqliteWebLockToken implements SqliteWebLockToken {
  const _FakeSqliteWebLockToken(this.id);

  final int id;
}
