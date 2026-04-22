import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart';
import 'package:test/test.dart';

import 'test_support.dart';

void main() {
  group('SqliteWebDriverAdapter', () {
    test('nested transactions reuse a single exclusive lock', () async {
      final transport = FakeSqliteWebTransport();
      final adapter = SqliteWebDriverAdapter.custom(
        config: const DatabaseConfig(
          driver: 'sqlite_web',
          options: {'database': 'app.sqlite'},
        ),
        transport: transport,
      );

      await adapter.beginTransaction();
      await adapter.beginTransaction();
      await adapter.commitTransaction();
      await adapter.commitTransaction();

      expect(transport.lockRequests, equals(1));
      expect(
        transport.executedSql,
        equals(['BEGIN', 'SAVEPOINT sp_2', 'RELEASE SAVEPOINT sp_2', 'COMMIT']),
      );
      expect(transport.distinctNonNullTokens, equals(1));
    });

    test('transaction rolls back on error', () async {
      final transport = FakeSqliteWebTransport();
      final adapter = SqliteWebDriverAdapter.custom(
        config: const DatabaseConfig(
          driver: 'sqlite_web',
          options: {'database': 'app.sqlite'},
        ),
        transport: transport,
      );

      await expectLater(
        () => adapter.transaction(() async {
          await adapter.executeRaw('UPDATE users SET active = 0');
          throw StateError('boom');
        }),
        throwsStateError,
      );

      expect(transport.lockRequests, equals(1));
      expect(
        transport.executedSql,
        equals(['BEGIN', 'UPDATE users SET active = 0', 'ROLLBACK']),
      );
    });

    test('execute and query delegate through transport', () async {
      final transport = FakeSqliteWebTransport(
        executeResults: [const SqliteWebStatementResult(affectedRows: 3)],
        queryResults: [
          const SqliteWebStatementResult(
            rows: [
              {'id': 1, 'email': 'a@example.com'},
            ],
          ),
        ],
      );
      final adapter = SqliteWebDriverAdapter.custom(
        config: const DatabaseConfig(
          driver: 'sqlite_web',
          options: {'database': 'app.sqlite'},
        ),
        transport: transport,
      );

      final affected = await adapter.executeStatement(
        'DELETE FROM users',
        const [],
      );
      final rows = await adapter.queryStatement(
        'SELECT id, email FROM users',
        const [],
      );

      expect(affected, equals(3));
      expect(rows, hasLength(1));
      expect(rows.first['email'], equals('a@example.com'));
    });
  });
}
