library;

import 'dart:async';

import 'sqlite_web_transport_stub.dart'
    if (dart.library.js_interop) 'sqlite_web_transport_web.dart'
    as impl;

abstract interface class SqliteWebLockToken {
  const SqliteWebLockToken();
}

final class SqliteWebStatementResult {
  const SqliteWebStatementResult({
    this.rows = const <Map<String, Object?>>[],
    this.affectedRows = 0,
    this.lastInsertRowid,
    this.autocommit = true,
  });

  final List<Map<String, Object?>> rows;
  final int affectedRows;
  final int? lastInsertRowid;
  final bool autocommit;
}

abstract class SqliteWebTransport {
  Future<SqliteWebStatementResult> query(
    String sql, [
    List<Object?> parameters = const [],
    SqliteWebLockToken? token,
    bool checkInTransaction = false,
  ]);

  Future<SqliteWebStatementResult> execute(
    String sql, [
    List<Object?> parameters = const [],
    SqliteWebLockToken? token,
    bool checkInTransaction = false,
  ]);

  Future<T> requestLock<T>(
    Future<T> Function(SqliteWebLockToken token) body, {
    Future<void>? abortTrigger,
  });

  Future<void> close() async {}
}

Future<SqliteWebTransport> sqliteWebTransportFromOptions(
  Map<String, Object?> options,
) => impl.sqliteWebTransportFromOptions(options);
