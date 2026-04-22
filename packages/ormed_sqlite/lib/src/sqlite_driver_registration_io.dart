import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:path/path.dart' as p;

import 'sqlite_driver_registration.dart';

void registerSqliteProjectDriver(SqliteConnectionRegistrar registrar) {
  DriverRegistry.registerDriver('sqlite', ({
    required Directory root,
    required ConnectionManager manager,
    required ModelRegistry registry,
    required String connectionName,
    required ConnectionDefinition definition,
  }) {
    final options = Map<String, Object?>.from(definition.driver.options);
    final database = options['database']?.toString() ?? 'database.sqlite';
    final resolved = p.normalize(p.join(root.path, database));
    options['database'] = database;
    options['path'] = resolved;
    return registrar(
      name: connectionName,
      database: DatabaseConfig(driver: 'sqlite', options: options),
      registry: registry,
      connection: ConnectionConfig(
        name: connectionName,
        database: resolved,
        options: Map<String, Object?>.from(options),
      ),
      manager: manager,
      singleton: true,
    );
  });
}
