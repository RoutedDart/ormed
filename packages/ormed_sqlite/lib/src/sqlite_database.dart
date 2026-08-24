import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart' show SqliteWebTransport;

import 'sqlite_data_source_options.dart';

/// High-level SQLite connection helpers that do not require generated code.
///
/// ```dart
/// final db = await SqliteDatabase.connect(path: 'app.db');
/// await db.executeRaw('CREATE TABLE users (id INTEGER PRIMARY KEY)');
/// final rows = await db.queryRaw('SELECT * FROM users');
/// await db.close();
/// ```
class SqliteDatabase {
  SqliteDatabase._();

  /// Opens a file-backed or in-memory SQLite database.
  static Future<OrmDatabase> connect({
    String path = ':memory:',
    String name = 'default',
    ModelRegistry? registry,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    List<QueryInterceptor> interceptors = const [],
    Map<String, Object?> driverOptions = const {},
    String? workerUri,
    String? wasmUri,
    String implementation = 'recommended',
    bool onlyOpenVfs = false,
    SqliteWebTransport? transport,
  }) {
    final models = registry ?? ModelRegistry();
    final options = path == ':memory:'
        ? models.sqliteInMemoryDataSourceOptions(
            name: name,
            scopeRegistry: scopeRegistry,
            codecs: codecs,
            logging: logging,
            tablePrefix: tablePrefix,
            defaultSchema: defaultSchema,
            carbonTimezone: carbonTimezone,
            carbonLocale: carbonLocale,
            enableNamedTimezones: enableNamedTimezones,
            driverExtensions: driverExtensions,
            driverOptions: driverOptions,
            workerUri: workerUri,
            wasmUri: wasmUri,
            implementation: implementation,
            onlyOpenVfs: onlyOpenVfs,
            transport: transport,
          )
        : models.sqliteFileDataSourceOptions(
            path: path,
            name: name,
            scopeRegistry: scopeRegistry,
            codecs: codecs,
            logging: logging,
            tablePrefix: tablePrefix,
            defaultSchema: defaultSchema,
            carbonTimezone: carbonTimezone,
            carbonLocale: carbonLocale,
            enableNamedTimezones: enableNamedTimezones,
            driverExtensions: driverExtensions,
            driverOptions: driverOptions,
            workerUri: workerUri,
            wasmUri: wasmUri,
            implementation: implementation,
            onlyOpenVfs: onlyOpenVfs,
            transport: transport,
          );
    return OrmDatabase.fromDataSource(
      DataSource(options.copyWith(interceptors: interceptors)),
    );
  }
}
