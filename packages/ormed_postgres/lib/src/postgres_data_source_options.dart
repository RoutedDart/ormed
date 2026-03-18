library;

import 'package:ormed/ormed.dart';

import 'postgres_adapter.dart';

/// Ergonomic PostgreSQL helpers for bootstrapping [DataSource] instances.
extension PostgresDataSourceRegistryExtensions on ModelRegistry {
  /// Builds [DataSourceOptions] for PostgreSQL using explicit connection details.
  DataSourceOptions postgresDataSourceOptions({
    String host = 'localhost',
    int port = 5432,
    String database = 'postgres',
    String username = 'postgres',
    String? password,
    String sslmode = 'disable',
    String timezone = 'UTC',
    String? applicationName,
    String name = 'default',
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema = 'public',
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
      'sslmode': sslmode,
      'timezone': timezone,
      if (password != null && password.trim().isNotEmpty) 'password': password,
      if (applicationName != null && applicationName.trim().isNotEmpty)
        'applicationName': applicationName,
    };
    return DataSourceOptions(
      name: name,
      driver: PostgresDriverAdapter.custom(
        config: DatabaseConfig(driver: 'postgres', options: options),
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

  /// Builds [DataSourceOptions] for PostgreSQL using common environment variables.
  ///
  /// Recognized variables:
  /// - `DB_URL` (or `DATABASE_URL`)
  /// - `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
  /// - `DB_SSLMODE`, `DB_TIMEZONE`, `DB_APP_NAME`
  DataSourceOptions postgresDataSourceOptionsFromEnv({
    String name = 'default',
    Map<String, String>? environment,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema = 'public',
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    final env = OrmedEnvironment(environment);
    final url = env.firstNonEmpty(['DB_URL', 'DATABASE_URL']);
    if (url != null) {
      final applicationName = env.firstNonEmpty(['DB_APP_NAME']);
      return DataSourceOptions(
        name: name,
        driver: PostgresDriverAdapter.custom(
          config: DatabaseConfig(
            driver: 'postgres',
            options: {
              'url': url,
              'sslmode': env.string('DB_SSLMODE', fallback: 'disable'),
              'timezone': env.string('DB_TIMEZONE', fallback: 'UTC'),
              if (applicationName != null) 'applicationName': applicationName,
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

    return postgresDataSourceOptions(
      host: env.string('DB_HOST', fallback: 'localhost'),
      port: env.intValue('DB_PORT', fallback: 5432),
      database: env.string('DB_NAME', fallback: 'postgres'),
      username: env.string('DB_USER', fallback: 'postgres'),
      password: env.firstNonEmpty(['DB_PASSWORD']),
      sslmode: env.string('DB_SSLMODE', fallback: 'disable'),
      timezone: env.string('DB_TIMEZONE', fallback: 'UTC'),
      applicationName: env.firstNonEmpty(['DB_APP_NAME']),
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

  /// Builds a PostgreSQL [DataSource] using explicit details.
  DataSource postgresDataSource({
    String host = 'localhost',
    int port = 5432,
    String database = 'postgres',
    String username = 'postgres',
    String? password,
    String sslmode = 'disable',
    String timezone = 'UTC',
    String? applicationName,
    String name = 'default',
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema = 'public',
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    return DataSource(
      postgresDataSourceOptions(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
        sslmode: sslmode,
        timezone: timezone,
        applicationName: applicationName,
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

  /// Builds a PostgreSQL [DataSource] from environment variables.
  DataSource postgresDataSourceFromEnv({
    String name = 'default',
    Map<String, String>? environment,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema = 'public',
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    return DataSource(
      postgresDataSourceOptionsFromEnv(
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
}
