import 'package:sqlite3/common.dart';
import 'package:sqlite3_web/sqlite3_web.dart';

import 'sqlite_web_transport.dart';

final class Sqlite3WebTransport implements SqliteWebTransport {
  Sqlite3WebTransport._({required Database database}) : _database = database;

  final Database _database;

  static Future<Sqlite3WebTransport> fromOptions(
    Map<String, Object?> options,
  ) async {
    final workerUri = _requiredString(
      options,
      keys: const ['workerUri', 'worker_uri'],
      label: 'workerUri',
    );
    final wasmUri = _requiredString(
      options,
      keys: const ['wasmUri', 'wasm_uri', 'wasmModule', 'wasm_module'],
      label: 'wasmUri',
    );
    final databaseName =
        _firstString(options, const [
          'database',
          'databaseName',
          'dbName',
          'name',
        ]) ??
        'app.sqlite';
    final onlyOpenVfs = _readBool(
      options,
      keys: const ['onlyOpenVfs', 'only_open_vfs'],
      fallback: false,
    );

    final sqlite = WebSqlite.open(
      workers: WorkerConnector.defaultWorkers(Uri.parse(workerUri)),
      wasmModule: Uri.parse(wasmUri),
    );

    final implementationName = _firstString(options, const [
      'implementation',
      'mode',
    ]);

    final database = switch (implementationName?.toLowerCase()) {
      null || '' || 'recommended' => (await sqlite.connectToRecommended(
        databaseName,
        onlyOpenVfs: onlyOpenVfs,
      )).database,
      final name => await sqlite.connect(
        databaseName,
        _parseImplementation(name),
        onlyOpenVfs: onlyOpenVfs,
      ),
    };

    return Sqlite3WebTransport._(database: database);
  }

  @override
  Future<void> close() => _database.dispose();

  @override
  Future<SqliteWebStatementResult> execute(
    String sql, [
    List<Object?> parameters = const [],
    SqliteWebLockToken? token,
    bool checkInTransaction = false,
  ]) async {
    final response = await _database.execute(
      sql,
      parameters: parameters,
      token: _unwrapToken(token),
      checkInTransaction: checkInTransaction,
    );
    final changes = await _readChanges(
      token: token,
      checkInTransaction: checkInTransaction,
    );
    return SqliteWebStatementResult(
      affectedRows: changes,
      lastInsertRowid: response.lastInsertRowid,
      autocommit: response.autocommit,
    );
  }

  @override
  Future<SqliteWebStatementResult> query(
    String sql, [
    List<Object?> parameters = const [],
    SqliteWebLockToken? token,
    bool checkInTransaction = false,
  ]) async {
    final response = await _database.select(
      sql,
      parameters: parameters,
      token: _unwrapToken(token),
      checkInTransaction: checkInTransaction,
    );
    final rows = <Map<String, Object?>>[
      for (final row in response.result)
        _rowToMap(row, response.result.columnNames),
    ];
    return SqliteWebStatementResult(
      rows: rows,
      lastInsertRowid: response.lastInsertRowid,
      autocommit: response.autocommit,
    );
  }

  @override
  Future<T> requestLock<T>(
    Future<T> Function(SqliteWebLockToken token) body, {
    Future<void>? abortTrigger,
  }) {
    return _database.requestLock(
      (token) => body(_Sqlite3WebLockToken(token)),
      abortTrigger: abortTrigger,
    );
  }

  Future<int> _readChanges({
    SqliteWebLockToken? token,
    required bool checkInTransaction,
  }) async {
    final response = await _database.select(
      'SELECT changes() AS changes',
      token: _unwrapToken(token),
      checkInTransaction: checkInTransaction,
    );
    final row = response.result.isEmpty
        ? const <String, Object?>{}
        : _rowToMap(response.result.first, response.result.columnNames);
    final value = row['changes'];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

final class _Sqlite3WebLockToken implements SqliteWebLockToken {
  const _Sqlite3WebLockToken(this.token);

  final LockToken token;
}

LockToken? _unwrapToken(SqliteWebLockToken? token) {
  if (token == null) return null;
  if (token is _Sqlite3WebLockToken) return token.token;
  throw ArgumentError.value(
    token,
    'token',
    'Unexpected lock token implementation.',
  );
}

Future<SqliteWebTransport> sqliteWebTransportFromOptions(
  Map<String, Object?> options,
) => Sqlite3WebTransport.fromOptions(options);

DatabaseImplementation _parseImplementation(String value) {
  return switch (value) {
    'inmemorylocal' ||
    'in_memory_local' ||
    'in-memory-local' => DatabaseImplementation.inMemoryLocal,
    'inmemoryshared' ||
    'in_memory_shared' ||
    'in-memory-shared' => DatabaseImplementation.inMemoryShared,
    'indexeddbunsafelocal' ||
    'indexed_db_unsafe_local' ||
    'indexeddb-unsafe-local' => DatabaseImplementation.indexedDbUnsafeLocal,
    'indexeddbunsafeworker' ||
    'indexed_db_unsafe_worker' ||
    'indexeddb-unsafe-worker' => DatabaseImplementation.indexedDbUnsafeWorker,
    'indexeddbshared' ||
    'indexed_db_shared' ||
    'indexeddb-shared' => DatabaseImplementation.indexedDbShared,
    'opfswithexternallocks' ||
    'opfs_with_external_locks' ||
    'opfs-with-external-locks' => DatabaseImplementation.opfsWithExternalLocks,
    'opfsatomics' ||
    'opfs_atomics' ||
    'opfs-atomics' => DatabaseImplementation.opfsAtomics,
    'opfsshared' ||
    'opfs_shared' ||
    'opfs-shared' => DatabaseImplementation.opfsShared,
    _ => throw ArgumentError.value(
      value,
      'implementation',
      'Unsupported sqlite3_web database implementation.',
    ),
  };
}

String _requiredString(
  Map<String, Object?> options, {
  required List<String> keys,
  required String label,
}) {
  final value = _firstString(options, keys);
  if (value == null) {
    throw ArgumentError('sqlite_web option "$label" is required.');
  }
  return value;
}

String? _firstString(Map<String, Object?> options, List<String> keys) {
  for (final key in keys) {
    final value = options[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

bool _readBool(
  Map<String, Object?> options, {
  required List<String> keys,
  required bool fallback,
}) {
  for (final key in keys) {
    final value = options[key];
    if (value == null) continue;
    if (value is bool) return value;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) continue;
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

Map<String, Object?> _rowToMap(Row row, List<String> columnNames) {
  final map = <String, Object?>{};
  for (var i = 0; i < columnNames.length; i++) {
    map[columnNames[i]] = row.columnAt(i);
  }
  return map;
}
