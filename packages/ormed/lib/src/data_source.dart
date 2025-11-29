import 'dart:async';

import 'connection/connection.dart';
import 'connection/connection_manager.dart';
import 'connection/orm_connection.dart';
import 'driver/driver.dart';
import 'model.dart';
import 'model_definition.dart';
import 'model_registry.dart';
import 'query/query.dart';
import 'repository/repository.dart';
import 'value_codec.dart';

/// Configuration options for initializing a [DataSource].
///
/// Provides a declarative way to configure the ORM with all required
/// components in a single object.
///
/// ```dart
/// final options = DataSourceOptions(
///   driver: SqliteDriverAdapter.file('app.sqlite'),
///   entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
/// );
/// ```
class DataSourceOptions {
  const DataSourceOptions({
    required this.driver,
    required this.entities,
    this.name = 'default',
    this.database,
    this.tablePrefix = '',
    this.defaultSchema,
    this.codecs = const {},
    this.synchronize = false,
    this.logging = false,
  });

  /// The database driver adapter to use for connections.
  final DriverAdapter driver;

  /// List of model definitions (entities) to register with this data source.
  final List<ModelDefinition<dynamic>> entities;

  /// Logical name for this connection. Defaults to 'default'.
  final String name;

  /// Optional database/catalog identifier for observability.
  final String? database;

  /// Table prefix automatically applied by some schemas.
  final String tablePrefix;

  /// Default schema applied to ad-hoc tables when not specified.
  final String? defaultSchema;

  /// Additional value codecs to register beyond the standard set.
  final Map<String, ValueCodec<dynamic>> codecs;

  /// Whether to automatically synchronize the database schema.
  /// WARNING: Not recommended for production use.
  final bool synchronize;

  /// Whether to enable query logging.
  final bool logging;

  DataSourceOptions copyWith({
    DriverAdapter? driver,
    List<ModelDefinition<dynamic>>? entities,
    String? name,
    String? database,
    String? tablePrefix,
    String? defaultSchema,
    Map<String, ValueCodec<dynamic>>? codecs,
    bool? synchronize,
    bool? logging,
  }) => DataSourceOptions(
    driver: driver ?? this.driver,
    entities: entities ?? this.entities,
    name: name ?? this.name,
    database: database ?? this.database,
    tablePrefix: tablePrefix ?? this.tablePrefix,
    defaultSchema: defaultSchema ?? this.defaultSchema,
    codecs: codecs ?? this.codecs,
    synchronize: synchronize ?? this.synchronize,
    logging: logging ?? this.logging,
  );
}

/// A unified entry point for ORM operations that manages connections,
/// model registration, and provides ergonomic access to queries and repositories.
///
/// ## Single Data Source Example
///
/// ```dart
/// final ds = DataSource(DataSourceOptions(
///   driver: SqliteDriverAdapter.file('app.sqlite'),
///   entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
/// ));
///
/// await ds.init();
///
/// // Query data
/// final users = await ds.query<User>().whereEquals('active', true).get();
///
/// // Use repository
/// final userRepo = ds.repo<User>();
/// await userRepo.insert(newUser);
///
/// // Transaction
/// await ds.transaction(() async {
///   await ds.repo<User>().insert(user);
///   await ds.repo<Post>().insert(post);
/// });
///
/// await ds.dispose();
/// ```
///
/// ## Multi-Tenant Example
///
/// ```dart
/// final mainDs = DataSource(DataSourceOptions(
///   name: 'main',
///   driver: SqliteDriverAdapter.file('main.sqlite'),
///   entities: entities,
/// ));
///
/// final analyticsDs = DataSource(DataSourceOptions(
///   name: 'analytics',
///   driver: SqliteDriverAdapter.file('analytics.sqlite'),
///   entities: entities,
/// ));
///
/// await mainDs.init();
/// await analyticsDs.init();
///
/// // Query specific data sources
/// final mainUsers = await mainDs.query<User>().get();
/// final analyticsUsers = await analyticsDs.query<User>().get();
/// ```
class DataSource {
  /// Creates a new data source with the given configuration options.
  DataSource(this.options)
    : _registry = ModelRegistry(),
      _codecRegistry = ValueCodecRegistry() {
    // Register custom codecs
    for (final entry in options.codecs.entries) {
      _codecRegistry.registerCodec(key: entry.key, codec: entry.value);
    }
  }

  /// The configuration options for this data source.
  final DataSourceOptions options;

  final ModelRegistry _registry;
  final ValueCodecRegistry _codecRegistry;
  OrmConnection? _connection;
  bool _initialized = false;

  /// Whether this data source has been initialized.
  bool get isInitialized => _initialized;

  /// The logical name of this data source connection.
  String get name => options.name;

  /// The underlying model registry.
  ModelRegistry get registry => _registry;

  /// The underlying value codec registry.
  ValueCodecRegistry get codecRegistry => _codecRegistry;

  /// The underlying ORM connection.
  ///
  /// Throws [StateError] if the data source has not been initialized.
  OrmConnection get connection {
    _ensureInitialized();
    return _connection!;
  }

  /// The underlying query context.
  ///
  /// Throws [StateError] if the data source has not been initialized.
  QueryContext get context {
    _ensureInitialized();
    return _connection!.context;
  }

  /// Initializes the data source by registering all entities and
  /// establishing the database connection.
  ///
  /// Automatically registers this DataSource with ConnectionManager.
  /// If this is the first DataSource registered, it becomes the default.
  ///
  /// Must be called before using [query], [repo], or other database operations.
  ///
  /// ```dart
  /// final ds = DataSource(options);
  /// await ds.init(); // Auto-registers and sets as default if first
  /// 
  /// // Static helpers now work
  /// final users = await User.query().get();
  /// ```
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    // Register all model definitions
    _registry.registerAll(options.entities);

    // Create the connection configuration
    final config = ConnectionConfig(
      name: options.name,
      database: options.database,
      tablePrefix: options.tablePrefix,
      defaultSchema: options.defaultSchema,
    );

    // Create the ORM connection
    _connection = OrmConnection(
      config: config,
      driver: options.driver,
      registry: _registry,
      codecRegistry: _codecRegistry,
    );

    // Enable logging if requested
    if (options.logging) {
      _connection!.enableQueryLog();
    }

    // Mark as initialized BEFORE registering (registration may access connection)
    _initialized = true;
    
    // Auto-register with ConnectionManager
    ConnectionManager.instance.registerDataSource(this);
    
    // If this is the first DataSource, set it as default
    if (!ConnectionManager.instance.hasDefaultConnection) {
      setAsDefault();
    }
  }
  
  /// Sets this DataSource as the default connection for Model static helpers.
  ///
  /// This enables usage of static methods like `User.query()`, `Post.find()`, etc.
  /// without explicitly passing a connection.
  ///
  /// ```dart
  /// final ds = DataSource(options);
  /// await ds.init();
  /// ds.setAsDefault(); // Now User.query() works
  /// 
  /// final users = await User.query().get();
  /// ```
  void setAsDefault() {
    _ensureInitialized();
    // Register if not already registered
    if (!ConnectionManager.instance.isRegistered(options.name)) {
      ConnectionManager.instance.registerDataSource(this);
    }
    ConnectionManager.instance.setDefaultConnection(options.name);
    // Update Model's default connection name so static helpers work
    Model.bindConnectionResolver(
      defaultConnection: options.name,
      connectionManager: ConnectionManager.instance,
    );
    _defaultDataSource = this;
  }
  
  static DataSource? _defaultDataSource;
  
  /// Returns the current default DataSource, or null if none is set.
  ///
  /// ```dart
  /// final ds = DataSource.getDefault();
  /// if (ds != null) {
  ///   final users = await ds.query<User>().get();
  /// }
  /// ```
  static DataSource? getDefault() => _defaultDataSource;
  
  /// Clears the default DataSource. Useful for testing.
  static void clearDefault() {
    _defaultDataSource = null;
  }

  /// Creates a typed query builder for the specified model type.
  ///
  /// ```dart
  /// final users = await ds.query<User>()
  ///     .whereEquals('active', true)
  ///     .orderBy('createdAt', descending: true)
  ///     .limit(10)
  ///     .get();
  /// ```
  Query<T> query<T>() {
    _ensureInitialized();
    return _connection!.query<T>();
  }

  /// Returns a repository for performing CRUD operations on the specified model type.
  ///
  /// ```dart
  /// final userRepo = ds.repo<User>();
  /// await userRepo.insert(newUser);
  /// await userRepo.updateMany([updatedUser]);
  /// await userRepo.deleteByKeys([{'id': userId}]);
  /// ```
  Repository<T> repo<T>() {
    _ensureInitialized();
    return _connection!.repository<T>();
  }

  /// Executes the provided callback within a database transaction.
  ///
  /// If the callback completes successfully, the transaction is committed.
  /// If an exception is thrown, the transaction is rolled back.
  ///
  /// ```dart
  /// await ds.transaction(() async {
  ///   await ds.repo<User>().insert(user);
  ///   await ds.repo<Post>().insert(post);
  ///   // If either fails, both are rolled back
  /// });
  /// ```
  Future<R> transaction<R>(Future<R> Function() callback) {
    _ensureInitialized();
    return _connection!.transaction(callback);
  }

  /// Builds a query against an arbitrary table name.
  ///
  /// Useful for ad-hoc queries or tables without a model definition.
  ///
  /// ```dart
  /// final rows = await ds.table('audit_logs')
  ///     .whereEquals('action', 'login')
  ///     .orderBy('timestamp', descending: true)
  ///     .limit(100)
  ///     .get();
  /// ```
  Query<Map<String, Object?>> table(
    String table, {
    String? as,
    String? schema,
    List<String>? scopes,
    List<AdHocColumn> columns = const [],
  }) {
    _ensureInitialized();
    return _connection!.table(
      table,
      as: as,
      schema: schema,
      scopes: scopes,
      columns: columns,
    );
  }

  /// Runs [action] with pretend mode enabled and returns the captured SQL.
  ///
  /// No actual database operations are performed; this is useful for
  /// debugging and previewing generated queries.
  ///
  /// ```dart
  /// final statements = await ds.pretend(() async {
  ///   await ds.repo<User>().insert(user);
  /// });
  /// for (final entry in statements) {
  ///   print('SQL: ${entry.sql}');
  /// }
  /// ```
  Future<List<QueryLogEntry>> pretend(FutureOr<void> Function() action) {
    _ensureInitialized();
    return _connection!.pretend(action);
  }

  /// Registers a callback to run before each query executes.
  void onBeforeQuery(QueryHook callback) {
    _ensureInitialized();
    _connection!.onBeforeQuery(callback);
  }

  /// Registers a callback to run before each mutation executes.
  void onBeforeMutation(MutationHook callback) {
    _ensureInitialized();
    _connection!.onBeforeMutation(callback);
  }

  /// Registers a callback invoked before any SQL is dispatched.
  ///
  /// Returns a function that can be called to unregister the callback.
  void Function() beforeExecuting(ExecutingStatementCallback callback) {
    _ensureInitialized();
    return _connection!.beforeExecuting(callback);
  }

  /// Enables query logging for this data source.
  void enableQueryLog({bool includeParameters = true, bool clear = true}) {
    _ensureInitialized();
    _connection!.enableQueryLog(
      includeParameters: includeParameters,
      clear: clear,
    );
  }

  /// Disables query logging.
  void disableQueryLog({bool clear = false}) {
    _ensureInitialized();
    _connection!.disableQueryLog(clear: clear);
  }

  /// Returns the accumulated query log entries.
  List<QueryLogEntry> get queryLog {
    _ensureInitialized();
    return _connection!.queryLog;
  }

  /// Clears the accumulated query log entries.
  void clearQueryLog() {
    _ensureInitialized();
    _connection!.clearQueryLog();
  }

  /// Closes the data source connection and releases resources.
  ///
  /// After calling this method, the data source can no longer be used.
  /// Call [init] again to re-initialize if needed.
  Future<void> dispose() async {
    if (!_initialized || _connection == null) {
      return;
    }

    await _connection!.driver.close();
    _connection = null;
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'DataSource has not been initialized. Call init() first.',
      );
    }
  }
}

/// Extension to add data source registration to [ConnectionManager].
extension DataSourceManagerExtension on ConnectionManager {
  /// Registers a [DataSource] with this connection manager.
  ///
  /// This allows the data source's connection to be retrieved by name
  /// through the connection manager.
  void registerDataSource(DataSource dataSource) {
    if (!dataSource.isInitialized) {
      throw StateError(
        'DataSource must be initialized before registering with ConnectionManager.',
      );
    }

    register(
      dataSource.name,
      ConnectionConfig(
        name: dataSource.name,
        database: dataSource.options.database,
        tablePrefix: dataSource.options.tablePrefix,
        defaultSchema: dataSource.options.defaultSchema,
      ),
      (config) => dataSource.connection,
      singleton: true,
    );
  }

  /// Sets a default data source for convenience when using static Model helpers.
  ///
  /// This registers the data source under the 'default' connection name,
  /// which is used by Model static helpers like `User.all()`, `User.find()`, etc.
  ///
  /// ```dart
  /// final ds = DataSource(DataSourceOptions(
  ///   driver: SqliteDriverAdapter.file('app.sqlite'),
  ///   entities: [UserOrmDefinition.definition],
  /// ));
  /// await ds.init();
  ///
  /// // Register as default
  /// ConnectionManager.instance.setDefaultDataSource(ds);
  ///
  /// // Now you can use static helpers
  /// final users = await User.all();
  /// final user = await User.find(1);
  /// ```
  void setDefaultDataSource(DataSource dataSource) {
    if (dataSource.name != 'default') {
      throw ArgumentError(
        'DataSource must have name "default" to be set as default. '
        'Current name: "${dataSource.name}"',
      );
    }
    registerDataSource(dataSource);
  }
}
