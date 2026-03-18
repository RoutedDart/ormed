/// SQLite implementation of the routed ORM driver adapter.
library;

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'schema_state.dart';
import 'sqlite_codecs.dart';
import 'sqlite_connector.dart';

/// Adapter that executes [QueryPlan] objects against SQLite databases.
class SqliteDriverAdapter extends SqliteRemoteAdapterBase
    implements SchemaStateProvider {
  /// Registers SQLite-specific codecs and type mapper with the global registries.
  /// Call this once during application initialization before using SQLite.
  static void registerCodecs() {
    registerSqliteLikeDriverCodecs('sqlite');
    registerSqliteCodecs();
  }

  /// Opens an in-memory database connection using the shared connector.
  SqliteDriverAdapter.inMemory({List<DriverExtension> extensions = const []})
    : this.custom(
        config: const DatabaseConfig(
          driver: 'sqlite',
          options: {'memory': true},
        ),
        extensions: extensions,
      );

  /// Opens a database stored at [path].
  SqliteDriverAdapter.file(
    String path, {
    List<DriverExtension> extensions = const [],
  }) : this.custom(
         config: DatabaseConfig(
           driver: 'sqlite',
           options: {'path': path},
           name: path,
         ),
         extensions: extensions,
       );

  /// Creates an adapter for the provided [config] and [connections].
  SqliteDriverAdapter.custom({
    required DatabaseConfig config,
    ConnectionFactory? connections,
    List<DriverExtension> extensions = const [],
  }) : _connections =
           connections ??
           ConnectionFactory(connectors: {'sqlite': () => SqliteConnector()}),
       _config = config,
       super(
         driverName: 'sqlite',
         options: config.options,
         extensions: extensions,
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
           DriverCapability.threadCount,
           DriverCapability.transactions,
           DriverCapability.adHocQueryUpdates,
           DriverCapability.rawSQL,
           DriverCapability.increment,
           DriverCapability.relationAggregates,
           DriverCapability.caseInsensitiveLike,
           DriverCapability.databaseManagement,
           DriverCapability.foreignKeyConstraintControl,
         },
       ) {
    registerSqliteCodecs();
  }

  final ConnectionFactory _connections;
  final DatabaseConfig _config;
  ConnectionHandle<sqlite.Database>? _primaryHandle;
  bool _localClosed = false;
  int _transactionDepth = 0;
  String _currentSchema = 'main';

  @override
  Future<void> closeBackend() async {
    if (_primaryHandle != null) {
      await _primaryHandle!.close();
      _primaryHandle = null;
    }
    _localClosed = true;
  }

  @override
  Future<int> executeStatement(String sql, List<Object?> parameters) async {
    final database = await _database();
    final stmt = _prepareStatement(database, sql);
    try {
      stmt.execute(parameters);
      return database.updatedRows;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, Object?>>> queryStatement(
    String sql,
    List<Object?> parameters,
  ) async {
    final database = await _database();
    final stmt = _prepareStatement(database, sql);
    try {
      final result = stmt.select(parameters);
      final columnNames = result.columnNames;
      final rows = <Map<String, Object?>>[];
      for (final row in result) {
        rows.add(rowToMap(row, columnNames));
      }
      return rows;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int?> threadCount() async => 1;

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    final database = await _database();
    if (_transactionDepth == 0) {
      _transactionDepth++;
      database.execute('BEGIN');
      try {
        final result = await action();
        database.execute('COMMIT');
        return result;
      } catch (_) {
        database.execute('ROLLBACK');
        rethrow;
      } finally {
        _transactionDepth--;
      }
    } else {
      final savepoint = 'sp_${_transactionDepth + 1}';
      _transactionDepth++;
      database.execute('SAVEPOINT $savepoint');
      try {
        final result = await action();
        database.execute('RELEASE SAVEPOINT $savepoint');
        return result;
      } catch (_) {
        database.execute('ROLLBACK TO SAVEPOINT $savepoint');
        rethrow;
      } finally {
        _transactionDepth--;
      }
    }
  }

  @override
  Future<void> beginTransaction() async {
    final database = await _database();
    if (_transactionDepth == 0) {
      database.execute('BEGIN');
      _transactionDepth++;
    } else {
      final savepoint = 'sp_${_transactionDepth + 1}';
      database.execute('SAVEPOINT $savepoint');
      _transactionDepth++;
    }
  }

  @override
  Future<void> commitTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to commit');
    }

    final database = await _database();
    if (_transactionDepth == 1) {
      database.execute('COMMIT');
      _transactionDepth--;
    } else {
      final savepoint = 'sp_$_transactionDepth';
      database.execute('RELEASE SAVEPOINT $savepoint');
      _transactionDepth--;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to rollback');
    }

    final database = await _database();
    if (_transactionDepth == 1) {
      database.execute('ROLLBACK');
      _transactionDepth--;
    } else {
      final savepoint = 'sp_$_transactionDepth';
      database.execute('ROLLBACK TO SAVEPOINT $savepoint');
      _transactionDepth--;
    }
  }

  @override
  Future<void> truncateTable(String tableName) async {
    final database = await _database();
    database.execute('DELETE FROM $tableName');
    database.execute("DELETE FROM sqlite_sequence WHERE name = ?", [tableName]);
  }

  @override
  SchemaState? createSchemaState({
    required OrmConnection connection,
    required String ledgerTable,
  }) {
    final path = _config.options['path'] ?? _config.options['database'];
    if (path is! String || path.isEmpty) {
      return null;
    }
    return SqliteSchemaState(database: path, ledgerTable: ledgerTable);
  }

  @override
  Future<bool> createDatabase(
    String name, {
    Map<String, Object?>? options,
  }) async {
    final file = File(name);
    if (await file.exists()) return false;
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    final tempDb = sqlite.sqlite3.open(name);
    tempDb.close();
    return true;
  }

  @override
  Future<bool> dropDatabase(String name) async {
    final file = File(name);
    if (!await file.exists()) {
      throw StateError('Database file does not exist: $name');
    }
    await file.delete();
    return true;
  }

  @override
  Future<bool> dropDatabaseIfExists(String name) async {
    final file = File(name);
    if (!await file.exists()) {
      return false;
    }
    await file.delete();
    return true;
  }

  @override
  Future<List<String>> listDatabases() async {
    throw UnsupportedError('SQLite does not support listing databases');
  }

  @override
  Future<bool> createSchema(String name) async {
    _currentSchema = name;
    return true;
  }

  @override
  Future<bool> dropSchemaIfExists(String name) async {
    if (_currentSchema == name) {
      _currentSchema = 'main';
    }
    return false;
  }

  @override
  Future<void> setCurrentSchema(String name) async {
    _currentSchema = name;
  }

  @override
  Future<String> getCurrentSchema() async => _currentSchema;

  Future<sqlite.Database> _database() async {
    if (_localClosed) {
      throw StateError('SqliteDriverAdapter has already been closed.');
    }
    if (_primaryHandle == null) {
      final handle =
          await _connections.open(_config) as ConnectionHandle<sqlite.Database>;
      _primaryHandle = handle;
    }
    return _primaryHandle!.client;
  }

  dynamic _prepareStatement(sqlite.Database database, String sql) {
    return database.prepare(sql);
  }
}
