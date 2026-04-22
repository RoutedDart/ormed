import 'package:ormed_sqlite_web/ormed_sqlite_web.dart';

final class FakeSqliteWebTransport implements SqliteWebTransport {
  FakeSqliteWebTransport({
    List<SqliteWebStatementResult>? executeResults,
    List<SqliteWebStatementResult>? queryResults,
  }) : _executeResults = List<SqliteWebStatementResult>.from(
         executeResults ?? const <SqliteWebStatementResult>[],
       ),
       _queryResults = List<SqliteWebStatementResult>.from(
         queryResults ?? const <SqliteWebStatementResult>[],
       );

  final List<SqliteWebStatementResult> _executeResults;
  final List<SqliteWebStatementResult> _queryResults;

  final List<String> executedSql = <String>[];
  final List<Object?> tokenHistory = <Object?>[];
  int lockRequests = 0;

  int get distinctNonNullTokens =>
      tokenHistory.whereType<Object>().toSet().length;

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
    tokenHistory.add(token);
    if (_executeResults.isEmpty) {
      return const SqliteWebStatementResult(affectedRows: 1);
    }
    return _executeResults.removeAt(0);
  }

  @override
  Future<SqliteWebStatementResult> query(
    String sql, [
    List<Object?> parameters = const [],
    SqliteWebLockToken? token,
    bool checkInTransaction = false,
  ]) async {
    tokenHistory.add(token);
    if (_queryResults.isEmpty) {
      return const SqliteWebStatementResult();
    }
    return _queryResults.removeAt(0);
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
