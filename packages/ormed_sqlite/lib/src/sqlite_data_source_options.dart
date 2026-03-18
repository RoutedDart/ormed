library;

import 'package:ormed/ormed.dart';

import 'sqlite_adapter.dart';

/// Ergonomic SQLite helpers for bootstrapping [DataSource] instances from a [ModelRegistry].
extension SqliteDataSourceRegistryExtensions on ModelRegistry {
  /// Builds [DataSourceOptions] for a file-backed SQLite database.
  DataSourceOptions sqliteFileDataSourceOptions({
    required String path,
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
    return DataSourceOptions(
      name: name,
      driver: SqliteDriverAdapter.file(path, extensions: driverExtensions),
      registry: this,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      database: path,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
    );
  }

  /// Builds [DataSourceOptions] for an in-memory SQLite database.
  DataSourceOptions sqliteInMemoryDataSourceOptions({
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
    return DataSourceOptions(
      name: name,
      driver: SqliteDriverAdapter.inMemory(extensions: driverExtensions),
      registry: this,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      database: ':memory:',
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
    );
  }

  /// Builds a file-backed SQLite [DataSource].
  DataSource sqliteFileDataSource({
    required String path,
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
      sqliteFileDataSourceOptions(
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
      ),
    );
  }

  /// Builds an in-memory SQLite [DataSource].
  DataSource sqliteInMemoryDataSource({
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
      sqliteInMemoryDataSourceOptions(
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
