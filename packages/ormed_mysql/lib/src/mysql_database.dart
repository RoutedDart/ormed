import 'package:ormed/ormed.dart';

import 'mysql_data_source_options.dart';

/// High-level MySQL connection helpers that do not require generated code.
class MySqlDatabase {
  MySqlDatabase._();

  /// Opens a MySQL database using explicit connection details.
  static Future<OrmDatabase> connect({
    String host = '127.0.0.1',
    int port = 3306,
    String database = 'mysql',
    String username = 'root',
    String? password,
    bool secure = false,
    String timezone = '+00:00',
    String? charset = 'utf8mb4',
    String? collation,
    String? sqlMode,
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
  }) {
    final models = registry ?? ModelRegistry();
    final options = models.mySqlDataSourceOptions(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      secure: secure,
      timezone: timezone,
      charset: charset,
      collation: collation,
      sqlMode: sqlMode,
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
    );
    return OrmDatabase.fromDataSource(
      DataSource(options.copyWith(interceptors: interceptors)),
    );
  }

  /// Opens a MariaDB database using explicit connection details.
  static Future<OrmDatabase> connectMariaDb({
    String host = '127.0.0.1',
    int port = 3306,
    String database = 'mysql',
    String username = 'root',
    String? password,
    bool secure = false,
    String timezone = '+00:00',
    String? charset = 'utf8mb4',
    String? collation,
    String? sqlMode,
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
  }) {
    final models = registry ?? ModelRegistry();
    final options = models.mariaDbDataSourceOptions(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      secure: secure,
      timezone: timezone,
      charset: charset,
      collation: collation,
      sqlMode: sqlMode,
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
    );
    return OrmDatabase.fromDataSource(
      DataSource(options.copyWith(interceptors: interceptors)),
    );
  }
}
