/// Browser-backed SQLite implementation for the unified ormed_sqlite package.
library;

import 'dart:async';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart'
    show SqliteWebLockToken, SqliteWebTransport, sqliteWebTransportFromOptions;

import 'sqlite_connection_settings.dart';

class SqliteDriverAdapter extends SqliteRemoteAdapterBase
    implements SchemaStateProvider {
  static void registerCodecs() {
    registerSqliteLikeDriverCodecs('sqlite');
    registerSqliteCodecs();
  }

  SqliteDriverAdapter.inMemory({
    List<DriverExtension> extensions = const [],
    Map<String, Object?> options = const {},
    SqliteWebTransport? transport,
  }) : this.custom(
         config: DatabaseConfig(
           driver: 'sqlite',
           options: _normalizeOptions({...options, 'memory': true}),
         ),
         extensions: extensions,
         transport: transport,
       );

  SqliteDriverAdapter.file(
    String path, {
    List<DriverExtension> extensions = const [],
    Map<String, Object?> options = const {},
    SqliteWebTransport? transport,
  }) : this.custom(
         config: DatabaseConfig(
           driver: 'sqlite',
           options: _normalizeOptions({
             ...options,
             'database': options['database'] ?? path,
             'path': path,
           }),
           name: path,
         ),
         extensions: extensions,
         transport: transport,
       );

  SqliteDriverAdapter.custom({
    required DatabaseConfig config,
    ConnectionFactory? connections,
    List<DriverExtension> extensions = const [],
    SqliteWebTransport? transport,
  }) : this._(
         options: _normalizeOptions(config.options),
         extensions: extensions,
         transport: transport,
       );

  SqliteDriverAdapter._({
    required super.options,
    super.extensions = const [],
    SqliteWebTransport? transport,
  }) : _transportLoader = _createTransportLoader(options, transport),
       super(
         driverName: 'sqlite',
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
       ) {
    registerSqliteCodecs();
  }

  final Future<SqliteWebTransport> Function() _transportLoader;
  SqliteWebLockToken? _activeLock;
  Future<void>? _lockLease;
  Completer<void>? _releaseLock;
  int _transactionDepth = 0;
  late final Future<SqliteWebTransport> _transport = _transportLoader();
  late final Future<void> _initialized = _initializeConnection();

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
    await _initialized;
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
    await _initialized;
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
    } catch (error, stackTrace) {
      if (_transactionDepth > 0) {
        try {
          await rollbackTransaction();
        } catch (_) {}
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> beginTransaction() async {
    await _initialized;
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

    final nextDepth = _transactionDepth + 1;
    final transport = await _transport;
    await transport.execute(
      'SAVEPOINT sp_$nextDepth',
      const [],
      _activeLock,
      true,
    );
    _transactionDepth = nextDepth;
  }

  @override
  Future<void> commitTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to commit');
    }

    final transport = await _transport;
    if (_transactionDepth == 1) {
      await transport.execute('COMMIT', const [], _activeLock, true);
      _transactionDepth = 0;
      await _releaseExclusiveLock();
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

  Future<void> _initializeConnection() async {
    final sessionOptions = sqliteSessionOptions(options);
    final initStatements = sqliteInitStatements(options);
    if (sessionOptions.isEmpty && initStatements.isEmpty) return;

    final sessionAllowlist = sqliteSessionAllowlist(options);
    final transport = await _transport;
    await transport.requestLock((token) async {
      for (final entry in sessionOptions.entries) {
        final key = entry.key.toString().trim();
        if (key.isEmpty) {
          throw ArgumentError.value(
            key,
            'session',
            'SQLite session option keys cannot be empty.',
          );
        }
        validateSqliteSessionKey(key, sessionAllowlist, driverName: 'sqlite');
        await transport.execute(
          'PRAGMA $key = ${sqlitePragmaValue(entry.value)}',
          const [],
          token,
          false,
        );
      }

      for (final statement in initStatements) {
        if (statement.trim().isEmpty) continue;
        await transport.execute(statement, const [], token, false);
      }
    });
  }
}

Map<String, Object?> _normalizeOptions(Map<String, Object?> options) {
  final normalized = <String, Object?>{...options};
  final memory = normalized['memory'] == true;

  if (memory) {
    normalized['database'] ??= ':memory:';
    normalized['implementation'] ??= 'in_memory_local';
  }

  if (!memory) {
    final path = normalized['path']?.toString().trim();
    if (path != null && path.isNotEmpty) {
      normalized['database'] ??= path;
    }
  }

  return normalized;
}

Future<SqliteWebTransport> Function() _createTransportLoader(
  Map<String, Object?> options,
  SqliteWebTransport? transport,
) {
  if (transport != null) {
    return () => Future<SqliteWebTransport>.value(transport);
  }

  _requireWebBootstrapOption(
    options,
    keys: const ['workerUri', 'worker_uri'],
    label: 'workerUri',
  );
  _requireWebBootstrapOption(
    options,
    keys: const ['wasmUri', 'wasm_uri', 'wasmModule', 'wasm_module'],
    label: 'wasmUri',
  );
  return () => sqliteWebTransportFromOptions(options);
}

void _requireWebBootstrapOption(
  Map<String, Object?> options, {
  required List<String> keys,
  required String label,
}) {
  for (final key in keys) {
    final value = options[key];
    if (value == null) continue;
    if (value.toString().trim().isNotEmpty) return;
  }

  throw ArgumentError(
    'sqlite web support requires `$label` unless a custom transport is provided.',
  );
}
