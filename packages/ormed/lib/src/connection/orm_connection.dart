import 'dart:async';

import '../driver/driver.dart';
import '../contracts.dart';
import '../model_definition.dart';
import '../model_registry.dart';
import '../query/query.dart';
import '../query/query_plan.dart';
import '../repository/repository.dart';
import '../value_codec.dart';
import '../migrations/sql_migration_ledger.dart';
import '../migrations/migration_runner.dart';
import '../migrations/migration_status.dart';
import 'connection.dart';
import 'connection_manager.dart';
import 'connection_resolver.dart';

/// Represents a fully materialized ORM connection that exposes helpers,
/// metadata, and instrumentation hooks.
class OrmConnection implements ConnectionResolver {
  OrmConnection({
    required this.config,
    required DriverAdapter driver,
    required ModelRegistry registry,
    ValueCodecRegistry? codecRegistry,
    ScopeRegistry? scopeRegistry,
    QueryContext? context,
  }) : _driver = driver,
       _registry = registry,
       _codecRegistry = codecRegistry ?? driver.codecs {
    _context =
        context ??
        QueryContext(
          registry: registry,
          driver: driver,
          scopeRegistry: scopeRegistry,
          connectionName: config.name,
          connectionDatabase: config.database,
          connectionTablePrefix: config.tablePrefix,
          beforeQueryHook: _dispatchBeforeQuery,
          beforeMutationHook: _dispatchBeforeMutation,
          beforeTransactionHook: _dispatchBeforeTransaction,
          afterTransactionHook: _dispatchAfterTransaction,
          queryLogHook: _recordQueryLog,
          pretendResolver: () => _pretending,
        );
  }

  /// Configuration describing the logical connection.
  final ConnectionConfig config;

  final DriverAdapter _driver;
  final ModelRegistry _registry;
  final ValueCodecRegistry _codecRegistry;
  late final QueryContext _context;
  int _tableAliasCounter = 0;

  bool _pretending = false;
  bool _loggingQueries = false;
  bool _includeLogParameters = true;

  final List<QueryHook> _beforeQuery = [];
  final List<MutationHook> _beforeMutation = [];
  final List<TransactionHook> _beforeTransaction = [];
  final List<TransactionHook> _afterTransaction = [];
  final List<QueryLogHook> _queryLogHooks = [];
  final List<QueryLogEntry> _queryLog = [];

  /// Underlying QueryContext for advanced operations.
  QueryContext get context => _context;

  /// Current pretend-mode flag.
  bool get pretending => _pretending;

  /// Whether query logging is enabled.
  bool get loggingQueries => _loggingQueries;

  /// Immutable view of recorded query log entries.
  List<QueryLogEntry> get queryLog => List.unmodifiable(_queryLog);

  /// Connection name convenience accessor.
  String get name => config.name;

  /// Optional database/catalog identifier.
  String? get database => config.database;

  /// Table prefix metadata.
  String get tablePrefix => config.tablePrefix;

  ConnectionRole get role => config.role;

  Map<String, Object?> get options => config.options;

  /// Runs [action] with pretend mode enabled and returns the captured SQL.
  Future<List<QueryLogEntry>> pretend(FutureOr<void> Function() action) async {
    final previousPretending = _pretending;
    final previousLogging = _loggingQueries;
    final previousInclude = _includeLogParameters;
    final previousLog = List<QueryLogEntry>.from(_queryLog);
    _pretending = true;
    enableQueryLog(includeParameters: true, clear: true);
    try {
      await Future.sync(action);
    } finally {
      _pretending = previousPretending;
    }
    final captured = List<QueryLogEntry>.from(_queryLog);
    _queryLog
      ..clear()
      ..addAll(previousLog);
    _loggingQueries = previousLogging;
    _includeLogParameters = previousInclude;
    return captured;
  }

  /// Enables query logging for this connection.
  void enableQueryLog({bool includeParameters = true, bool clear = true}) {
    _loggingQueries = true;
    _includeLogParameters = includeParameters;
    if (clear) {
      _queryLog.clear();
    }
  }

  /// Disables query logging and optionally clears existing entries.
  void disableQueryLog({bool clear = false}) {
    _loggingQueries = false;
    if (clear) {
      _queryLog.clear();
    }
  }

  /// Resets accumulated query log entries.
  void clearQueryLog() => _queryLog.clear();

  /// Registers a callback to run before each query executes.
  void onBeforeQuery(QueryHook callback) => _beforeQuery.add(callback);

  /// Registers a callback to run before each mutation executes.
  void onBeforeMutation(MutationHook callback) => _beforeMutation.add(callback);

  /// Registers a callback before each transaction boundary.
  void onBeforeTransaction(TransactionHook callback) =>
      _beforeTransaction.add(callback);

  /// Registers a callback after each transaction boundary.
  void onAfterTransaction(TransactionHook callback) =>
      _afterTransaction.add(callback);

  /// Registers a callback that runs whenever a query log entry is recorded.
  void onQueryLogged(QueryLogHook callback) => _queryLogHooks.add(callback);

  /// Registers a callback invoked before any SQL is dispatched.
  void Function() beforeExecuting(ExecutingStatementCallback callback) =>
      _context.beforeExecuting(callback);

  /// Registers a handler for statements exceeding [threshold].
  void Function() whenQueryingForLongerThan(
    Duration threshold,
    LongRunningQueryCallback callback,
  ) => _context.whenQueryingForLongerThan(threshold, callback);

  /// Creates a typed query builder.
  Query<T> query<T extends OrmEntity>() => _context.query<T>();

  /// Ensures the migrations ledger table exists for this connection.
  Future<void> ensureLedgerInitialized({String? tableName}) async {
    final ledger = SqlMigrationLedger(
      _driver,
      tableName: tableName ?? 'orm_migrations',
    );
    await ledger.ensureInitialized();
  }

  /// Ensures pending migrations are applied using [runner].
  ///
  /// When [applyPendingMigrations] is `false`, this simply verifies the ledger
  /// exists and returns an empty report.
  Future<MigrationReport> ensureSchemaReady({
    required MigrationRunner runner,
    bool applyPendingMigrations = true,
  }) async {
    if (!applyPendingMigrations) {
      await runner.status();
      return const MigrationReport([]);
    }
    return runner.applyAll();
  }

  static OrmConnection fromManager(
    String name, {
    ConnectionRole role = ConnectionRole.primary,
    ConnectionManager? manager,
  }) => (manager ?? ConnectionManager.defaultManager).connection(
    name,
    role: role,
  );

  /// Queries using a specific model definition, optionally overriding table/schema.
  Query<T> queryFromDefinition<T extends OrmEntity>(
    ModelDefinition<T> definition, {
    String? table,
    String? schema,
    String? alias,
  }) => _context.queryFromDefinition(
    definition,
    table: table,
    schema: schema,
    alias: alias,
  );

  /// Returns a repository for [T].
  Repository<T> repository<T extends OrmEntity>() => _context.repository<T>();

  /// Executes [callback] within a transaction boundary.
  Future<R> transaction<R>(Future<R> Function() callback) =>
      _context.transaction(callback);

  /// Builds a query against an arbitrary table name.
  Query<AdHocRow> table(
    String table, {
    String? as,
    String? schema,
    List<String>? scopes,
    List<AdHocColumn> columns = const [],
  }) {
    final effectiveSchema = schema ?? config.defaultSchema;
    final alias = as ?? _generateAlias(table);
    return _context.table(
      table,
      as: alias,
      schema: effectiveSchema,
      scopes: scopes,
      columns: columns,
    );
  }

  /// Builds a query for [T] using an alternate table/schema/alias.
  Query<T> queryAs<T extends OrmEntity>({String? table, String? schema, String? alias}) =>
      queryFromDefinition(
        registry.expect<T>(),
        table: table,
        schema: schema,
        alias: alias,
      );

  @override
  DriverAdapter get driver => _driver;

  @override
  ModelRegistry get registry => _registry;

  @override
  ValueCodecRegistry get codecRegistry => _codecRegistry;

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryPlan plan) =>
      _context.runSelect(plan);

  @override
  Future<MutationResult> runMutation(MutationPlan plan) =>
      _context.runMutation(plan);

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _context.describeQuery(plan);

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      _context.describeMutation(plan);

  void _dispatchBeforeQuery(QueryPlan plan) {
    for (final hook in _beforeQuery) {
      hook(plan);
    }
  }

  void _dispatchBeforeMutation(MutationPlan plan) {
    for (final hook in _beforeMutation) {
      hook(plan);
    }
  }

  Future<void> _dispatchBeforeTransaction() async {
    for (final hook in _beforeTransaction) {
      await hook();
    }
  }

  Future<void> _dispatchAfterTransaction() async {
    for (final hook in _afterTransaction) {
      await hook();
    }
  }

  String? _generateAlias(String table) {
    switch (config.tableAliasStrategy) {
      case TableAliasStrategy.none:
        return null;
      case TableAliasStrategy.tableName:
        return table;
      case TableAliasStrategy.incremental:
        return 't${_tableAliasCounter++}';
    }
  }

  void _recordQueryLog(QueryLogEntry entry) {
    if (!_loggingQueries) {
      return;
    }
    final sanitized = _includeLogParameters ? entry : entry.withoutParameters();
    _queryLog.add(sanitized);
    for (final hook in _queryLogHooks) {
      hook(sanitized);
    }
  }
}
