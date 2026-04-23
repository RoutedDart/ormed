library;

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart' show SqliteWebTransport;

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
    Map<String, Object?> driverOptions = const {},
    String? workerUri,
    String? wasmUri,
    String implementation = 'recommended',
    bool onlyOpenVfs = false,
    SqliteWebTransport? transport,
  }) {
    final effectiveOptions = _sqliteDriverOptions(
      base: driverOptions,
      workerUri: workerUri,
      wasmUri: wasmUri,
      implementation: implementation,
      onlyOpenVfs: onlyOpenVfs,
    );

    return DataSourceOptions(
      name: name,
      driver: SqliteDriverAdapter.file(
        path,
        extensions: driverExtensions,
        options: effectiveOptions,
        transport: transport,
      ),
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
    Map<String, Object?> driverOptions = const {},
    String? workerUri,
    String? wasmUri,
    String implementation = 'recommended',
    bool onlyOpenVfs = false,
    SqliteWebTransport? transport,
  }) {
    final effectiveOptions = _sqliteDriverOptions(
      base: driverOptions,
      workerUri: workerUri,
      wasmUri: wasmUri,
      implementation: implementation,
      onlyOpenVfs: onlyOpenVfs,
    );

    return DataSourceOptions(
      name: name,
      driver: SqliteDriverAdapter.inMemory(
        extensions: driverExtensions,
        options: effectiveOptions,
        transport: transport,
      ),
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
    Map<String, Object?> driverOptions = const {},
    String? workerUri,
    String? wasmUri,
    String implementation = 'recommended',
    bool onlyOpenVfs = false,
    SqliteWebTransport? transport,
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
        driverOptions: driverOptions,
        workerUri: workerUri,
        wasmUri: wasmUri,
        implementation: implementation,
        onlyOpenVfs: onlyOpenVfs,
        transport: transport,
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
    Map<String, Object?> driverOptions = const {},
    String? workerUri,
    String? wasmUri,
    String implementation = 'recommended',
    bool onlyOpenVfs = false,
    SqliteWebTransport? transport,
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
        driverOptions: driverOptions,
        workerUri: workerUri,
        wasmUri: wasmUri,
        implementation: implementation,
        onlyOpenVfs: onlyOpenVfs,
        transport: transport,
      ),
    );
  }
}

Map<String, Object?> _sqliteDriverOptions({
  required Map<String, Object?> base,
  String? workerUri,
  String? wasmUri,
  required String implementation,
  required bool onlyOpenVfs,
}) {
  final options = <String, Object?>{...base};
  if (workerUri != null && workerUri.isNotEmpty) {
    options['workerUri'] = workerUri;
  }
  if (wasmUri != null && wasmUri.isNotEmpty) {
    options['wasmUri'] = wasmUri;
  }
  if (implementation != 'recommended') {
    options['implementation'] = implementation;
  }
  if (onlyOpenVfs) {
    options['onlyOpenVfs'] = true;
  }
  return options;
}
