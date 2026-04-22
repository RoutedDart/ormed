library;

import 'package:ormed/ormed.dart';

import 'src/sqlite_web_adapter.dart';
import 'src/sqlite_web_transport.dart';

export 'src/sqlite_web_adapter.dart';
export 'src/sqlite_web_data_source_options.dart';
export 'src/sqlite_web_transport.dart';
export 'src/sqlite_web_worker.dart';

OrmConnectionHandle registerSqliteWebOrmConnection({
  required String name,
  required DatabaseConfig database,
  required ModelRegistry registry,
  ConnectionConfig? connection,
  ConnectionManager? manager,
  bool singleton = true,
  SqliteWebTransport? transport,
}) {
  SqliteWebDriverAdapter.registerCodecs();

  final factory = OrmConnectionFactory(manager: manager);
  final connectionConfig = connection ?? ConnectionConfig(name: name);
  return factory.register(
    name: name,
    connection: connectionConfig,
    singleton: singleton,
    builder: (_) {
      final adapter = SqliteWebDriverAdapter.custom(
        config: database,
        transport: transport,
      );
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

final _sqliteWebDriverRegistration = (() {
  DriverAdapterRegistry.register('sqlite_web', (config) {
    return SqliteWebDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'sqlite_web',
        options: Map<String, Object?>.from(config.options),
      ),
    );
  });

  return null;
})();

void ensureSqliteWebDriverRegistration() => _sqliteWebDriverRegistration;
