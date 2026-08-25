import 'package:drift/drift.dart' as drift;
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';

import 'drift_postgres_profile_stub.dart'
    if (dart.library.io) 'drift_postgres_profile.dart';

/// A no-op Drift database user for applications whose schema is owned by
/// Ormed migrations.
class OrmedDriftExecutorUser implements drift.QueryExecutorUser {
  /// Creates an executor user with no Drift-owned schema migrations.
  const OrmedDriftExecutorUser({this.version = 1});

  /// The version reported to Drift while it opens the executor.
  final int version;

  @override
  Future<void> beforeOpen(
    drift.QueryExecutor executor,
    drift.OpeningDetails details,
  ) async {}

  @override
  int get schemaVersion => version;
}

/// Ormed driver backed by a Drift [drift.QueryExecutor].
///
/// The adapter can also be passed back to Drift as its executor:
///
/// ```dart
/// final driver = DriftDriverAdapter(NativeDatabase.memory());
/// final driftConnection = drift.DatabaseConnection(driver.driftExecutor);
/// final ormed = await OrmDatabase.connect(driver: driver);
/// ```
///
/// Sharing the adapter means writes made through either Ormed or Drift are
/// published to the same [QueryChangeBus]. Ormed watchers can therefore react
/// to direct Drift writes without requiring Drift-generated model classes.
class DriftDriverAdapter extends SqliteRemoteAdapterBase
    implements DriverChangeFeed, DriverLifecycle {
  static final _sqliteProfile = SqlRemoteAdapterProfile.sqlite();

  /// Creates an adapter around an existing Drift executor.
  DriftDriverAdapter(
    this._delegate, {
    super.changeBus,
    this.closeDelegate = false,
    drift.QueryExecutorUser? executorUser,
    this.synchronize,
    super.options = const {},
  }) : _profile = _profileFor(_delegate),
       executorUser = executorUser ?? const OrmedDriftExecutorUser(),
       super(
         driverName: _driverNameFor(_delegate),
         profile: _profileFor(_delegate),
       );

  /// Creates an adapter around Drift's PostgreSQL executor.
  ///
  /// The same Ormed API is used for SQLite and PostgreSQL. The PostgreSQL
  /// profile is conditionally unavailable on browser/worker builds because
  /// Drift's PostgreSQL transport depends on native server-side Dart.
  DriftDriverAdapter.postgres(
    this._delegate, {
    super.changeBus,
    this.closeDelegate = false,
    drift.QueryExecutorUser? executorUser,
    this.synchronize,
    super.options = const {},
  }) : _profile = createDriftPostgresProfile(),
       executorUser = executorUser ?? const OrmedDriftExecutorUser(),
       super(driverName: 'postgres', profile: createDriftPostgresProfile());

  final drift.QueryExecutor _delegate;
  final SqlRemoteAdapterProfile _profile;

  static SqlRemoteAdapterProfile _profileFor(drift.QueryExecutor executor) {
    return switch (executor.dialect) {
      drift.SqlDialect.sqlite => _sqliteProfile,
      drift.SqlDialect.postgres => createDriftPostgresProfile(),
      final dialect => throw UnsupportedError(
        'No Ormed Drift profile is available for the ${dialect.name} dialect.',
      ),
    };
  }

  static String _driverNameFor(drift.QueryExecutor executor) =>
      executor.dialect == drift.SqlDialect.postgres ? 'postgres' : 'drift';

  /// Drift executor facade that shares this driver's database and change bus.
  late final drift.QueryExecutor driftExecutor = _DriftExecutorProxy(
    _delegate,
    this,
  );

  /// Whether closing this adapter also closes the supplied Drift executor.
  final bool closeDelegate;

  /// User passed to Drift when the wrapped executor is opened.
  final drift.QueryExecutorUser executorUser;

  /// Backend-specific synchronization callback, when supported.
  final Future<void> Function()? synchronize;
  Future<void>? _openFuture;

  final List<drift.QueryExecutor> _activeExecutors = [];
  final List<_PendingChangeScope> _transactionScopes = [];

  @override
  bool get recordsRawChanges => false;

  /// Whether this adapter has a synchronization callback.
  bool get canSynchronize => synchronize != null;

  /// Opens the wrapped Drift executor for Ormed operations.
  @override
  Future<void> open() => _openFuture ??= _openDelegate();

  Future<void> _openDelegate() async {
    await _delegate.ensureOpen(executorUser);
  }

  /// Synchronizes an external backend and invalidates all Ormed watchers.
  ///
  /// Backends such as LibSQL can receive remote changes without invoking the
  /// wrapped executor's `runInsert`/`runUpdate` methods. The callback should
  /// perform that backend-specific synchronization. Since it cannot report a
  /// precise table set, successful synchronization conservatively invalidates
  /// every watcher.
  Future<void> sync() async {
    final callback = synchronize;
    if (callback == null) {
      throw UnsupportedError(
        'This DriftDriverAdapter has no synchronization callback.',
      );
    }
    await callback();
    changeBus.publish(DatabaseChange.all());
  }

  drift.QueryExecutor get _activeExecutor =>
      _activeExecutors.isEmpty ? _delegate : _activeExecutors.last;

  @override
  Future<void> closeBackend() async {
    if (closeDelegate) {
      await _delegate.close();
    }
  }

  @override
  Future<int> executeStatement(String sql, List<Object?> parameters) async {
    final executor = _activeExecutor;
    final operation = _leadingSqlVerb(sql);
    final preparedSql = _profile.prepareSql(sql);
    switch (operation) {
      case 'INSERT':
      case 'REPLACE':
        if (_profile.insertUsesUpdate) {
          return _recordAffectedWrite(
            preparedSql,
            parameters,
            executor.runUpdate,
          );
        }
        await executor.runInsert(preparedSql, parameters);
        _recordSqlChange(sql);
        return _sqliteChanges(executor);
      case 'UPDATE':
      case 'DELETE':
        final affected = await executor.runUpdate(preparedSql, parameters);
        _recordSqlChange(sql);
        return affected;
      default:
        await executor.runCustom(preparedSql, parameters);
        _recordSqlChange(sql);
        return 0;
    }
  }

  @override
  Future<List<Map<String, Object?>>> queryStatement(
    String sql,
    List<Object?> parameters,
  ) => _activeExecutor.runSelect(_profile.prepareSql(sql), parameters);

  Future<int> _recordAffectedWrite(
    String sql,
    List<Object?> parameters,
    Future<int> Function(String, List<Object?>) execute,
  ) async {
    final affected = await execute(sql, parameters);
    _recordSqlChange(sql);
    return affected;
  }

  Future<int> _sqliteChanges(drift.QueryExecutor executor) async {
    final rows = await executor.runSelect(
      'SELECT changes() AS changes',
      const [],
    );
    final value = rows.isEmpty ? null : rows.first['changes'];
    return value is num ? value.toInt() : 0;
  }

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    final transaction = _activeExecutor.beginTransaction();
    final scope = _PendingChangeScope();
    _activeExecutors.add(transaction);
    _transactionScopes.add(scope);
    try {
      final result = await action();
      await transaction.send();
      _activeExecutors.removeLast();
      _transactionScopes.removeLast();
      _finishScope(scope);
      return result;
    } catch (_) {
      try {
        await transaction.rollback();
      } finally {
        _activeExecutors.removeLast();
        _transactionScopes.removeLast();
      }
      rethrow;
    }
  }

  Future<void> runBatched(drift.BatchedStatements statements) async {
    await _activeExecutor.runBatched(_prepareBatch(statements));
    for (final statement in statements.statements) {
      _recordSqlChange(statement);
    }
  }

  Future<void> runCustom(String statement, [List<Object?>? args]) async {
    await _activeExecutor.runCustom(
      _profile.prepareSql(statement),
      args ?? const [],
    );
    _recordSqlChange(statement);
  }

  Future<int> runInsert(String statement, List<Object?> args) async {
    final result = _profile.insertUsesUpdate
        ? await _activeExecutor.runUpdate(_profile.prepareSql(statement), args)
        : await _activeExecutor.runInsert(_profile.prepareSql(statement), args);
    _recordSqlChange(statement);
    return result;
  }

  Future<int> runUpdate(String statement, List<Object?> args) async {
    final result = await _activeExecutor.runUpdate(
      _profile.prepareSql(statement),
      args,
    );
    _recordSqlChange(statement);
    return result;
  }

  Future<int> runDelete(String statement, List<Object?> args) async {
    final result = await _activeExecutor.runDelete(
      _profile.prepareSql(statement),
      args,
    );
    _recordSqlChange(statement);
    return result;
  }

  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) => _activeExecutor.runSelect(_profile.prepareSql(statement), args);

  drift.BatchedStatements _prepareBatch(drift.BatchedStatements statements) =>
      drift.BatchedStatements(
        statements.statements.map(_profile.prepareSql).toList(growable: false),
        statements.arguments,
      );

  void _recordSqlChange(String sql, {_PendingChangeScope? scope}) {
    final change = _changeForSql(sql);
    if (change == null) return;

    final target =
        scope ?? (_transactionScopes.isEmpty ? null : _transactionScopes.last);
    if (target != null) {
      target.absorb(change);
    } else {
      changeBus.publish(change);
    }
  }

  void _finishScope(_PendingChangeScope scope, {_PendingChangeScope? parent}) {
    if (parent != null) {
      parent.absorb(scope.change);
      return;
    }
    final change = scope.change;
    if (change.allTables || change.tables.isNotEmpty) {
      changeBus.publish(change);
    }
  }

  DatabaseChange? _changeForSql(String sql) => _profile.changeForSql(sql);

  String _leadingSqlVerb(String sql) {
    final match = RegExp(r'^\s*([A-Za-z]+)').firstMatch(sql);
    return match?.group(1)?.toUpperCase() ?? '';
  }
}

class _PendingChangeScope {
  final Set<String> tables = <String>{};
  bool allTables = false;

  DatabaseChange get change =>
      DatabaseChange(tables: tables, allTables: allTables);

  void absorb(DatabaseChange change) {
    tables.addAll(change.tables);
    allTables = allTables || change.allTables;
  }
}

class _DriftTransactionExecutor implements drift.TransactionExecutor {
  _DriftTransactionExecutor(this._inner, this._owner, {this._parentScope})
    : _scope = _PendingChangeScope();

  final drift.TransactionExecutor _inner;
  final DriftDriverAdapter _owner;
  final _PendingChangeScope? _parentScope;
  final _PendingChangeScope _scope;

  @override
  bool get supportsNestedTransactions => _inner.supportsNestedTransactions;

  @override
  drift.TransactionExecutor beginTransaction() => _DriftTransactionExecutor(
    _inner.beginTransaction(),
    _owner,
    parentScope: _scope,
  );

  @override
  drift.QueryExecutor beginExclusive() =>
      _DriftExecutorProxy(_inner.beginExclusive(), _owner);

  @override
  drift.SqlDialect get dialect => _inner.dialect;

  @override
  Future<bool> ensureOpen(drift.QueryExecutorUser user) =>
      _inner.ensureOpen(user);

  @override
  Future<void> runBatched(drift.BatchedStatements statements) async {
    await _inner.runBatched(_owner._prepareBatch(statements));
    for (final statement in statements.statements) {
      _owner._recordSqlChange(statement, scope: _scope);
    }
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {
    await _inner.runCustom(
      _owner._profile.prepareSql(statement),
      args ?? const [],
    );
    _owner._recordSqlChange(statement, scope: _scope);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final result = _owner._profile.insertUsesUpdate
        ? await _inner.runUpdate(_owner._profile.prepareSql(statement), args)
        : await _inner.runInsert(_owner._profile.prepareSql(statement), args);
    _owner._recordSqlChange(statement, scope: _scope);
    return result;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    final result = await _inner.runUpdate(
      _owner._profile.prepareSql(statement),
      args,
    );
    _owner._recordSqlChange(statement, scope: _scope);
    return result;
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) async {
    final result = await _inner.runDelete(
      _owner._profile.prepareSql(statement),
      args,
    );
    _owner._recordSqlChange(statement, scope: _scope);
    return result;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) => _inner.runSelect(_owner._profile.prepareSql(statement), args);

  @override
  Future<void> send() async {
    await _inner.send();
    _owner._finishScope(_scope, parent: _parentScope);
  }

  @override
  Future<void> rollback() => _inner.rollback();

  @override
  Future<void> close() => _inner.close();
}

class _DriftExecutorProxy implements drift.QueryExecutor {
  _DriftExecutorProxy(this._inner, this._owner);

  final drift.QueryExecutor _inner;
  final DriftDriverAdapter _owner;

  @override
  drift.SqlDialect get dialect => _inner.dialect;

  @override
  Future<bool> ensureOpen(drift.QueryExecutorUser user) =>
      _inner.ensureOpen(user);

  @override
  drift.QueryExecutor beginExclusive() =>
      _DriftExecutorProxy(_inner.beginExclusive(), _owner);

  @override
  drift.TransactionExecutor beginTransaction() =>
      _DriftTransactionExecutor(_inner.beginTransaction(), _owner);

  @override
  Future<void> runBatched(drift.BatchedStatements statements) async {
    await _inner.runBatched(_owner._prepareBatch(statements));
    for (final statement in statements.statements) {
      _owner._recordSqlChange(statement);
    }
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {
    await _inner.runCustom(
      _owner._profile.prepareSql(statement),
      args ?? const [],
    );
    _owner._recordSqlChange(statement);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final result = _owner._profile.insertUsesUpdate
        ? await _inner.runUpdate(_owner._profile.prepareSql(statement), args)
        : await _inner.runInsert(_owner._profile.prepareSql(statement), args);
    _owner._recordSqlChange(statement);
    return result;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    final result = await _inner.runUpdate(
      _owner._profile.prepareSql(statement),
      args,
    );
    _owner._recordSqlChange(statement);
    return result;
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) async {
    final result = await _inner.runDelete(
      _owner._profile.prepareSql(statement),
      args,
    );
    _owner._recordSqlChange(statement);
    return result;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) => _inner.runSelect(_owner._profile.prepareSql(statement), args);

  @override
  Future<void> close() => _inner.close();
}
