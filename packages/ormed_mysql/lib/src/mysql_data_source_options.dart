library;

import 'package:ormed/ormed.dart';

import 'mysql_adapter.dart';

/// Ergonomic MySQL/MariaDB helpers for bootstrapping [DataSource] instances.
extension MySqlDataSourceRegistryExtensions on ModelRegistry {
  /// Builds [DataSourceOptions] for MySQL using explicit connection details.
  DataSourceOptions mySqlDataSourceOptions({
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
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    final options = <String, Object?>{
      'host': host,
      'port': port,
      'database': database,
      'username': username,
      'ssl': secure,
      'timezone': timezone,
      if (password != null && password.trim().isNotEmpty) 'password': password,
      if (charset != null && charset.trim().isNotEmpty) 'charset': charset,
      if (collation != null && collation.trim().isNotEmpty)
        'collation': collation,
      if (sqlMode != null && sqlMode.trim().isNotEmpty) 'sqlMode': sqlMode,
    };
    return DataSourceOptions(
      name: name,
      driver: MySqlDriverAdapter.custom(
        config: DatabaseConfig(driver: 'mysql', options: options),
        extensions: driverExtensions,
      ),
      registry: this,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      database: database,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
    );
  }

  /// Builds [DataSourceOptions] for MariaDB using explicit connection details.
  DataSourceOptions mariaDbDataSourceOptions({
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
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    final options = <String, Object?>{
      'host': host,
      'port': port,
      'database': database,
      'username': username,
      'ssl': secure,
      'timezone': timezone,
      if (password != null && password.trim().isNotEmpty) 'password': password,
      if (charset != null && charset.trim().isNotEmpty) 'charset': charset,
      if (collation != null && collation.trim().isNotEmpty)
        'collation': collation,
      if (sqlMode != null && sqlMode.trim().isNotEmpty) 'sqlMode': sqlMode,
    };
    return DataSourceOptions(
      name: name,
      driver: MySqlDriverAdapter.custom(
        config: DatabaseConfig(driver: 'mariadb', options: options),
        driverName: 'mariadb',
        isMariaDb: true,
        extensions: driverExtensions,
      ),
      registry: this,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      database: database,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
    );
  }

  /// Builds [DataSourceOptions] for MySQL using common environment variables.
  ///
  /// Recognized variables:
  /// - `DB_URL` (or `DATABASE_URL`)
  /// - `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
  /// - `DB_SSLMODE`, `DB_TIMEZONE`, `DB_CHARSET`, `DB_COLLATION`
  DataSourceOptions mySqlDataSourceOptionsFromEnv({
    String name = 'default',
    Map<String, String>? environment,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    final env = OrmedEnvironment(environment);
    final url = env.firstNonEmpty(['DB_URL', 'DATABASE_URL']);
    if (url != null) {
      final collation = env.firstNonEmpty(['DB_COLLATION']);
      return DataSourceOptions(
        name: name,
        driver: MySqlDriverAdapter.custom(
          config: DatabaseConfig(
            driver: 'mysql',
            options: {
              'url': url,
              'ssl': _sslFromEnv(env, fallback: false),
              'timezone': env.string('DB_TIMEZONE', fallback: '+00:00'),
              'charset': env.string('DB_CHARSET', fallback: 'utf8mb4'),
              if (collation != null) 'collation': collation,
            },
          ),
          extensions: driverExtensions,
        ),
        registry: this,
        scopeRegistry: scopeRegistry,
        codecs: codecs,
        logging: logging,
        tablePrefix: tablePrefix,
        defaultSchema: defaultSchema,
        carbonTimezone: carbonTimezone,
        carbonLocale: carbonLocale,
        enableNamedTimezones: enableNamedTimezones,
      );
    }

    return mySqlDataSourceOptions(
      host: env.string('DB_HOST', fallback: '127.0.0.1'),
      port: env.intValue('DB_PORT', fallback: 3306),
      database: env.string('DB_NAME', fallback: 'mysql'),
      username: env.string('DB_USER', fallback: 'root'),
      password: env.firstNonEmpty(['DB_PASSWORD']),
      secure: _sslFromEnv(env, fallback: false),
      timezone: env.string('DB_TIMEZONE', fallback: '+00:00'),
      charset: env.string('DB_CHARSET', fallback: 'utf8mb4'),
      collation: env.firstNonEmpty(['DB_COLLATION']),
      sqlMode: env.firstNonEmpty(['DB_SQL_MODE']),
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
  }

  /// Builds a MySQL [DataSource] using explicit details.
  DataSource mySqlDataSource({
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
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    return DataSource(
      mySqlDataSourceOptions(
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
      ),
    );
  }

  /// Builds a MySQL [DataSource] from environment variables.
  DataSource mySqlDataSourceFromEnv({
    String name = 'default',
    Map<String, String>? environment,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    return DataSource(
      mySqlDataSourceOptionsFromEnv(
        name: name,
        environment: environment,
        scopeRegistry: scopeRegistry,
        codecs: codecs,
        logging: logging,
        tablePrefix: tablePrefix,
        defaultSchema: defaultSchema,
        carbonTimezone: carbonTimezone,
        carbonLocale: carbonLocale,
        enableNamedTimezones: enableNamedTimezones,
        driverExtensions: driverExtensions,
      ),
    );
  }

  /// Builds a MariaDB [DataSource] using explicit details.
  DataSource mariaDbDataSource({
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
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    return DataSource(
      mariaDbDataSourceOptions(
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
      ),
    );
  }
}

bool _sslFromEnv(OrmedEnvironment env, {required bool fallback}) {
  final mode = env.firstNonEmpty(['DB_SSLMODE']);
  if (mode == null) return fallback;
  final normalized = mode.toLowerCase();
  if (normalized == 'disable' || normalized == 'false' || normalized == '0') {
    return false;
  }
  return true;
}
