/// SQLite adapter for the routed ORM driver interface.
library;

import 'package:ormed/ormed.dart';

import 'src/sqlite_adapter.dart';
import 'src/sqlite_driver_registration.dart' as sqlite_registration;
export 'src/sqlite_grammar.dart';
export 'src/sqlite_adapter.dart';
export 'src/sqlite_data_source_options.dart';
export 'src/sqlite_connector.dart';
export 'src/sqlite_codecs.dart';
export 'package:ormed_sqlite_web/ormed_sqlite_web.dart'
    show
        SqliteWebLockToken,
        SqliteWebStatementResult,
        SqliteWebTransport,
        runSqliteWebWorker;

final _sqliteDriverRegistration = (() {
  DriverAdapterRegistry.register('sqlite', (config) {
    final options = Map<String, Object?>.from(config.options);
    options['database'] ??= 'database.sqlite';
    options.putIfAbsent('path', () => options['database']);
    return SqliteDriverAdapter.custom(
      config: DatabaseConfig(driver: 'sqlite', options: options),
    );
  });
  sqlite_registration.registerSqliteProjectDriver(registerSqliteOrmConnection);
  return null;
})();

/// Ensures sqlite driver registers with [DriverRegistry] and [DriverAdapterRegistry].
void ensureSqliteDriverRegistration() => _sqliteDriverRegistration;

/// Registers a SQLite ORM connection with the [manager].
OrmConnectionHandle registerSqliteOrmConnection({
  required String name,
  required DatabaseConfig database,
  required ModelRegistry registry,
  ConnectionConfig? connection,
  ConnectionManager? manager,
  bool singleton = true,
}) {
  // Ensure SQLite codecs are registered
  SqliteDriverAdapter.registerCodecs();

  final factory = OrmConnectionFactory(manager: manager);
  final connectionConfig = connection ?? ConnectionConfig(name: name);
  return factory.register(
    name: name,
    connection: connectionConfig,
    singleton: singleton,
    builder: (_) {
      final adapter = SqliteDriverAdapter.custom(config: database);
      final context = QueryContext(registry: registry, driver: adapter);
      return OrmConnection(
        config: connectionConfig,
        driver: adapter,
        registry: registry,
        context: context,
      );
    },
    onRelease: singleton
        ? null
        : (connection) async {
            await connection.driver.close();
          },
  );
}
