library;

import 'dart:async';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';

import 'sqlite_web_transport.dart';

class SqliteWebDriverAdapter extends SqliteRemoteAdapterBase
    implements SchemaStateProvider {
  SqliteWebDriverAdapter.custom({
    required DatabaseConfig config,
    SqliteWebTransport? transport,
    super.extensions = const [],
  }) : _transportLoader = transport != null
           ? (() => Future<SqliteWebTransport>.value(transport))
           : (() => sqliteWebTransportFromOptions(config.options)),
       super(
         driverName: 'sqlite_web',
         options: config.options,
         supportsQueryDeletes: true,
         requiresPrimaryKeyForQueryUpdate: false,
         queryUpdateRowIdentifier: QueryRowIdentifier(
           column: 'rowid',
           expression: 'rowid',
         ),
         capabilities: {
           DriverCapability.joins,
           DriverCapability.insertUsing,
           DriverCapability.queryDeletes,
           DriverCapability.schemaIntrospection,
           DriverCapability.transactions,
           DriverCapability.adHocQueryUpdates,
           DriverCapability.rawSQL,
           DriverCapability.increment,
           DriverCapability.relationAggregates,
           DriverCapability.caseInsensitiveLike,
           DriverCapability.foreignKeyConstraintControl,
         },
       );

  final Future<SqliteWebTransport> Function() _transportLoader;
  SqliteWebLockToken? _activeLock;
  Future<void>? _lockLease;
  Completer<void>? _releaseLock;
  int _transactionDepth = 0;
  late final Future<SqliteWebTransport> _transport = _transportLoader();

  static void registerCodecs() {
    registerSqliteLikeDriverCodecs('sqlite_web');
  }

  @override
  Future<void> closeBackend() async {
    if (_transactionDepth > 0 && _activeLock != null) {
      try {
        final transport = await _transport;
        await transport.execute('ROLLBACK', const [], _activeLock, true);
      } catch (_) {
        // Best effort rollback during close.
      } finally {
        _transactionDepth = 0;
        await _releaseExclusiveLock();
      }
    }

    final transport = await _transport;
    await transport.close();
  }

  @override
  Future<int> executeStatement(String sql, List<Object?> parameters) async {
    final transport = await _transport;
    final result = await transport.execute(
      sql,
      parameters,
      _activeLock,
      _transactionDepth > 0,
    );
    return result.affectedRows;
  }

  @override
  Future<List<Map<String, Object?>>> queryStatement(
    String sql,
    List<Object?> parameters,
  ) async {
    final transport = await _transport;
    final result = await transport.query(
      sql,
      parameters,
      _activeLock,
      _transactionDepth > 0,
    );
    return result.rows;
  }

  @override
  SchemaState? createSchemaState({
    required OrmConnection connection,
    required String ledgerTable,
  }) => null;

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    await beginTransaction();
    try {
      final result = await action();
      await commitTransaction();
      return result;
    } catch (_) {
      await rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<void> beginTransaction() async {
    if (_transactionDepth == 0) {
      await _acquireExclusiveLock();
      try {
        final transport = await _transport;
        await transport.execute('BEGIN', const [], _activeLock, false);
        _transactionDepth = 1;
      } catch (_) {
        await _releaseExclusiveLock();
        rethrow;
      }
      return;
    }

    _transactionDepth++;
    final transport = await _transport;
    await transport.execute(
      'SAVEPOINT sp_$_transactionDepth',
      const [],
      _activeLock,
      true,
    );
  }

  @override
  Future<void> commitTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to commit');
    }

    final transport = await _transport;
    if (_transactionDepth == 1) {
      try {
        await transport.execute('COMMIT', const [], _activeLock, true);
      } finally {
        _transactionDepth = 0;
        await _releaseExclusiveLock();
      }
      return;
    }

    await transport.execute(
      'RELEASE SAVEPOINT sp_$_transactionDepth',
      const [],
      _activeLock,
      true,
    );
    _transactionDepth--;
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to rollback');
    }

    final transport = await _transport;
    if (_transactionDepth == 1) {
      try {
        await transport.execute('ROLLBACK', const [], _activeLock, true);
      } finally {
        _transactionDepth = 0;
        await _releaseExclusiveLock();
      }
      return;
    }

    await transport.execute(
      'ROLLBACK TO SAVEPOINT sp_$_transactionDepth',
      const [],
      _activeLock,
      true,
    );
    _transactionDepth--;
  }

  Future<void> _acquireExclusiveLock() async {
    if (_activeLock != null) return;

    final transport = await _transport;
    final ready = Completer<void>();
    final release = Completer<void>();
    _releaseLock = release;
    _lockLease = transport.requestLock((token) async {
      _activeLock = token;
      if (!ready.isCompleted) {
        ready.complete();
      }
      await release.future;
    });

    await ready.future;
  }

  Future<void> _releaseExclusiveLock() async {
    final release = _releaseLock;
    final lease = _lockLease;
    _releaseLock = null;
    _lockLease = null;

    if (release != null && !release.isCompleted) {
      release.complete();
    }
    if (lease != null) {
      await lease;
    }

    _activeLock = null;
  }
}
