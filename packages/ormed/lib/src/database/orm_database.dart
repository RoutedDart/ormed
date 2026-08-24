import 'dart:async';

import 'package:contextual/contextual.dart' as contextual;

import '../connection/orm_connection.dart';
import '../contracts.dart';
import '../data_source.dart';
import '../driver/driver.dart';
import '../../migrations.dart';
import '../model/model.dart';
import '../query/query.dart';
import '../repository/repository.dart';
import '../seeding/seeder_runner.dart';
import '../value_codec.dart';

/// A high-level database handle for codegen-optional applications.
///
/// [OrmDatabase] owns the lifecycle of a [DataSource] and exposes the common
/// operations needed by applications that do not use generated model code.
/// A [ModelRegistry] can still be supplied when typed models are desired.
///
/// ```dart
/// final db = await OrmDatabase.connect(
///   driver: myDriver,
/// );
///
/// await db.executeRaw('CREATE TABLE users (id INTEGER PRIMARY KEY)');
/// final rows = await db.queryRaw('SELECT * FROM users');
/// await db.close();
/// ```
class OrmDatabase {
  OrmDatabase(this.dataSource);

  /// Connects using a driver adapter without requiring generated code.
  static Future<OrmDatabase> connect({
    required DriverAdapter driver,
    ModelRegistry? registry,
    List<ModelDefinition<OrmEntity>> entities = const [],
    ScopeRegistry? scopeRegistry,
    String name = 'default',
    String? database,
    String tablePrefix = '',
    String? defaultSchema,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    List<DriverExtension> driverExtensions = const [],
    List<QueryInterceptor> interceptors = const [],
    bool logging = false,
    String? logFilePath,
    contextual.Logger? logger,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
  }) async {
    final dataSource = DataSource(
      DataSourceOptions(
        driver: driver,
        entities: entities,
        registry: registry ?? ModelRegistry(),
        scopeRegistry: scopeRegistry,
        name: name,
        database: database,
        tablePrefix: tablePrefix,
        defaultSchema: defaultSchema,
        codecs: codecs,
        driverExtensions: driverExtensions,
        interceptors: interceptors,
        logging: logging,
        logFilePath: logFilePath,
        logger: logger,
        carbonTimezone: carbonTimezone,
        carbonLocale: carbonLocale,
        enableNamedTimezones: enableNamedTimezones,
      ),
    );
    final databaseHandle = OrmDatabase(dataSource);
    await databaseHandle.open();
    return databaseHandle;
  }

  /// Opens an existing [DataSource] through the high-level facade.
  static Future<OrmDatabase> fromDataSource(DataSource dataSource) async {
    final database = OrmDatabase(dataSource);
    await database.open();
    return database;
  }

  /// The underlying data source for advanced Ormed APIs.
  final DataSource dataSource;

  /// Whether the underlying connection is open.
  bool get isOpen => dataSource.isInitialized;

  /// The logical connection name.
  String get name => dataSource.name;

  /// The initialized ORM connection.
  OrmConnection get connection => dataSource.connection;

  /// The underlying driver adapter.
  DriverAdapter get driver => connection.driver;

  /// The model registry, which may be empty when code generation is omitted.
  ModelRegistry get registry => dataSource.registry;

  /// The lower-level query context for advanced hooks and extensions.
  QueryContext get context => dataSource.context;

  /// The execution middleware pipeline for this database.
  QueryInterceptorPipeline get interceptorPipeline =>
      dataSource.interceptorPipeline;

  /// Opens the database. Calling this more than once is safe.
  Future<void> open() => dataSource.init();

  /// Returns a typed model query when a model registry is available.
  Query<T> query<T extends OrmEntity>() => dataSource.query<T>();

  /// Returns a typed repository when a model registry is available.
  Repository<T> repo<T extends OrmEntity>() => dataSource.repo<T>();

  /// Returns an ad-hoc query for a table without requiring model code.
  Query<AdHocRow> table(
    String table, {
    String? as,
    String? schema,
    List<String>? scopes,
    List<AdHocColumn> columns = const [],
  }) => dataSource.table(
    table,
    as: as,
    schema: schema,
    scopes: scopes,
    columns: columns,
  );

  /// Observes completed statements issued through the connection.
  ///
  /// The returned callback unregisters the listener. This includes queries
  /// built through [table] and [query]. Raw SQL is available through the
  /// interceptor pipeline configured for the connection.
  void Function() listen(void Function(QueryExecuted event) callback) {
    return dataSource.listen(callback);
  }

  /// Registers a callback before a query-builder statement is dispatched.
  ///
  /// This is useful for tracing, metrics, and request-local policy checks.
  /// The callback observes the statement; it cannot rewrite it. The returned
  /// callback unregisters the listener.
  void Function() beforeExecuting(ExecutingStatementCallback callback) {
    return dataSource.beforeExecuting(callback);
  }

  /// Observes query-builder query events, including failures.
  void onQuery(void Function(QueryEvent event) listener) {
    context.onQuery(listener);
  }

  /// Observes query-builder mutation events, including failures.
  void onMutation(void Function(MutationEvent event) listener) {
    context.onMutation(listener);
  }

  /// Publishes a committed change for the supplied tables to reactive queries.
  ///
  /// This is useful when a driver integration observes writes made outside
  /// Ormed, such as a reactive SQLite backend.
  void notifyTablesChanged(Iterable<String> tables) {
    context.notifyTablesChanged(tables);
  }

  /// Invalidates all reactive queries on this database.
  void notifyAllTablesChanged() {
    context.notifyAllTablesChanged();
  }

  /// Observes transaction and other connection lifecycle events.
  void Function() onEvent<T extends ConnectionEvent>(
    void Function(T event) callback,
  ) {
    return dataSource.onEvent<T>(callback);
  }

  /// Executes raw SQL that does not return rows.
  Future<void> executeRaw(String sql, [List<Object?> parameters = const []]) {
    return dataSource.executeRaw(sql, parameters);
  }

  /// Executes a raw SQL query and returns its rows.
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    return dataSource.queryRaw(sql, parameters);
  }

  /// Runs a callback inside a transaction.
  Future<R> transaction<R>(Future<R> Function() callback) {
    return dataSource.transaction(callback);
  }

  /// Begins a manually controlled transaction.
  ///
  /// Pair this with [commit] or [rollback]. Reactive watchers only refresh
  /// after the transaction commits.
  Future<void> beginTransaction() => dataSource.beginTransaction();

  /// Commits the active manually controlled transaction.
  Future<void> commit() => dataSource.commit();

  /// Rolls back the active manually controlled transaction.
  Future<void> rollback() => dataSource.rollback();

  /// Applies a schema plan built by [definition].
  ///
  /// This is the no-codegen equivalent of creating a one-off schema change.
  /// For durable changes, prefer [migrate] so the ledger can track them.
  Future<void> executeSchema(
    void Function(SchemaBuilder schema) definition, {
    String? description,
  }) async {
    final schemaDriver = _schemaDriver;
    final builder = SchemaBuilder(
      defaultSchema: dataSource.options.defaultSchema,
      tablePrefix: dataSource.options.tablePrefix,
    );
    definition(builder);
    if (!builder.isEmpty) {
      final plan = builder.build(description: description);
      if (!interceptorPipeline.isActive) {
        await schemaDriver.applySchemaPlan(plan);
        return;
      }
      final preview = schemaDriver.describeSchemaPlan(plan);
      await interceptorPipeline.run(
        QueryExecutionContext(
          driverName: interceptorPipeline.driverName,
          database: interceptorPipeline.database,
          sql: preview.statements.map((statement) => statement.sql).join('\n'),
          parameters: preview.statements
              .expand((statement) => statement.parameters)
              .toList(growable: false),
          operationName: 'SCHEMA',
          querySummary: 'SCHEMA PLAN',
        ),
        () => schemaDriver.applySchemaPlan(plan),
      );
    }
  }

  /// Applies manually registered migrations without generated registries.
  Future<MigrationReport> migrate(
    Iterable<MigrationEntry> entries, {
    String ledgerTable = 'orm_migrations',
    int? limit,
  }) {
    return migrateDescriptors(
      MigrationEntry.buildDescriptors(entries.toList()),
      ledgerTable: ledgerTable,
      limit: limit,
    );
  }

  /// Applies already-built migration descriptors, including generated ones.
  Future<MigrationReport> migrateDescriptors(
    Iterable<MigrationDescriptor> migrations, {
    String ledgerTable = 'orm_migrations',
    int? limit,
  }) async {
    final descriptors = List<MigrationDescriptor>.unmodifiable(migrations);
    if (descriptors.isEmpty) {
      return const MigrationReport([]);
    }

    final schemaDriver = _schemaDriver;
    final runner = MigrationRunner(
      schemaDriver: schemaDriver,
      ledger: SqlMigrationLedger(
        driver,
        tableName: ledgerTable,
        tablePrefix: dataSource.options.tablePrefix,
        interceptorPipeline: interceptorPipeline,
      ),
      migrations: descriptors,
      defaultSchema: dataSource.options.defaultSchema,
      interceptorPipeline: interceptorPipeline,
    );
    return runner.applyAll(limit: limit);
  }

  /// Runs registered seeders against this connection.
  Future<SeedingReport> seed(
    List<SeederRegistration> seeders, {
    List<String>? names,
    bool pretend = false,
  }) {
    return SeederRunner().run(
      connection: connection,
      seeders: seeders,
      names: names,
      pretend: pretend,
    );
  }

  /// Closes the underlying database connection.
  Future<void> close() => dataSource.dispose();

  /// Alias for [close].
  Future<void> dispose() => close();

  SchemaDriver get _schemaDriver {
    final currentDriver = driver;
    if (currentDriver is! SchemaDriver) {
      throw StateError(
        'The ${currentDriver.metadata.name} driver does not support schema operations.',
      );
    }
    return currentDriver as SchemaDriver;
  }
}
