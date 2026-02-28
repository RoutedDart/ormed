library;

import 'dart:io';

import 'package:ormed/ormed.dart';

import 'src/d1_adapter.dart';
import 'src/d1_transport.dart';

export 'src/d1_adapter.dart';
export 'src/d1_data_source_options.dart';
export 'src/d1_transport.dart';

OrmConnectionHandle registerD1OrmConnection({
  required String name,
  required DatabaseConfig database,
  required ModelRegistry registry,
  ConnectionConfig? connection,
  ConnectionManager? manager,
  bool singleton = true,
  D1Transport? transport,
}) {
  D1DriverAdapter.registerCodecs();

  final factory = OrmConnectionFactory(manager: manager);
  final connectionConfig = connection ?? ConnectionConfig(name: name);
  return factory.register(
    name: name,
    connection: connectionConfig,
    singleton: singleton,
    builder: (_) {
      final adapter = D1DriverAdapter.custom(
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

final _d1DriverRegistration = (() {
  DriverAdapterRegistry.register('d1', (config) {
    return D1DriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'd1',
        options: Map<String, Object?>.from(config.options),
      ),
    );
  });

  DriverRegistry.registerDriver('d1', ({
    required Directory root,
    required ConnectionManager manager,
    required ModelRegistry registry,
    required String connectionName,
    required ConnectionDefinition definition,
  }) {
    final options = Map<String, Object?>.from(definition.driver.options);
    final databaseConfig = DatabaseConfig(driver: 'd1', options: options);
    return registerD1OrmConnection(
      name: connectionName,
      database: databaseConfig,
      registry: registry,
      connection: ConnectionConfig(name: connectionName, options: options),
      manager: manager,
      singleton: true,
    );
  });

  return null;
})();

void ensureD1DriverRegistration() => _d1DriverRegistration;
