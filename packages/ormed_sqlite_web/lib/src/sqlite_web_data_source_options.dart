library;

import 'package:ormed/ormed.dart';

import 'sqlite_web_adapter.dart';
import 'sqlite_web_transport.dart';

extension SqliteWebDataSourceRegistryExtensions on ModelRegistry {
  DataSourceOptions sqliteWebDataSourceOptions({
    required String database,
    required String workerUri,
    required String wasmUri,
    String implementation = 'recommended',
    bool onlyOpenVfs = false,
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
    SqliteWebTransport? transport,
  }) {
    final options = <String, Object?>{
      'database': database,
      'workerUri': workerUri,
      'wasmUri': wasmUri,
      'implementation': implementation,
      'onlyOpenVfs': onlyOpenVfs,
    };

    return DataSourceOptions(
      name: name,
      driver: SqliteWebDriverAdapter.custom(
        config: DatabaseConfig(driver: 'sqlite_web', options: options),
        transport: transport,
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

  DataSource sqliteWebDataSource({
    required String database,
    required String workerUri,
    required String wasmUri,
    String implementation = 'recommended',
    bool onlyOpenVfs = false,
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
    SqliteWebTransport? transport,
  }) {
    return DataSource(
      sqliteWebDataSourceOptions(
        database: database,
        workerUri: workerUri,
        wasmUri: wasmUri,
        implementation: implementation,
        onlyOpenVfs: onlyOpenVfs,
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
        transport: transport,
      ),
    );
  }
}
