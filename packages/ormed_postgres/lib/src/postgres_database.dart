import 'package:ormed/ormed.dart';

import 'postgres_data_source_options.dart';

/// High-level PostgreSQL connection helpers that do not require generated code.
class PostgresDatabase {
  PostgresDatabase._();

  /// Opens a PostgreSQL database using explicit connection details.
  static Future<OrmDatabase> connect({
    String host = 'localhost',
    int port = 5432,
    String database = 'postgres',
    String username = 'postgres',
    String? password,
    String sslmode = 'disable',
    String timezone = 'UTC',
    String? applicationName,
    String name = 'default',
    ModelRegistry? registry,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema = 'public',
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    List<QueryInterceptor> interceptors = const [],
  }) {
    final models = registry ?? ModelRegistry();
    final options = models.postgresDataSourceOptions(
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
    );
    return OrmDatabase.fromDataSource(
      DataSource(options.copyWith(interceptors: interceptors)),
    );
  }

  /// Opens PostgreSQL using the conventional `DB_*` environment variables.
  static Future<OrmDatabase> connectFromEnv({
    String name = 'default',
    Map<String, String>? environment,
    ModelRegistry? registry,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema = 'public',
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    List<QueryInterceptor> interceptors = const [],
  }) {
    final models = registry ?? ModelRegistry();
    final options = models.postgresDataSourceOptionsFromEnv(
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
    );
    return OrmDatabase.fromDataSource(
      DataSource(options.copyWith(interceptors: interceptors)),
    );
  }
}
