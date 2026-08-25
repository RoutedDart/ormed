import 'dart:io';

import 'package:ormed/ormed.dart';

import 'd1_adapter.dart';
import 'd1_registration.dart';

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

/// Installs the config/CLI D1 driver registrations on VM targets.
void ensureD1DriverRegistration() => _d1DriverRegistration;
