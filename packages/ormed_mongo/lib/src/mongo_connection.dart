import 'dart:io';

import 'package:ormed/ormed.dart';

import 'mongo_driver.dart';

/// Registers a reusable MongoDB connection with the global `ConnectionManager`.
OrmConnectionHandle registerMongoOrmConnection({
  required String name,
  required DatabaseConfig database,
  required ModelRegistry registry,
  ConnectionConfig? connection,
  ConnectionManager? manager,
  bool singleton = true,
  ValueCodecRegistry? codecRegistry,
}) {
  final factory = OrmConnectionFactory(manager: manager);
  final connectionConfig = connection ?? ConnectionConfig(name: name);
  return factory.register(
    name: name,
    connection: connectionConfig,
    singleton: singleton,
    builder: (_) {
      final adapter = MongoDriverAdapter.custom(
        config: database,
        codecRegistry: codecRegistry,
      );
      final context = QueryContext(
        registry: registry,
        driver: adapter,
        codecRegistry: adapter.codecs,
      );
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

final _mongoDriverRegistration = (() {
  DriverRegistry.registerDriver('mongo', ({
    required Directory root,
    required ConnectionManager manager,
    required ModelRegistry registry,
    required String connectionName,
    required ConnectionDefinition definition,
  }) {
    final options = Map<String, Object?>.from(definition.driver.options);
    final databaseConfig = DatabaseConfig(driver: 'mongo', options: options);
    return registerMongoOrmConnection(
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

/// Ensures the mongo driver registers with [DriverRegistry].
void ensureMongoDriverRegistration() => _mongoDriverRegistration;
