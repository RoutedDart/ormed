library;

import 'dart:io';

import 'package:ormed/ormed.dart';

import 'src/postgres_adapter.dart';

export 'src/postgres_adapter.dart';
export 'src/postgres_connector.dart';
export 'src/postgres_codecs.dart';
export 'src/postgres_grammar.dart';
export 'src/postgres_schema_dialect.dart';

OrmConnectionHandle registerPostgresOrmConnection({
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
      final adapter = PostgresDriverAdapter.custom(
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

final _postgresDriverRegistration = (() {
  DriverRegistry.registerDriver('postgres', ({
    required Directory root,
    required ConnectionManager manager,
    required ModelRegistry registry,
    required String connectionName,
    required ConnectionDefinition definition,
  }) {
    final options = Map<String, Object?>.from(definition.driver.options);
    final databaseConfig = DatabaseConfig(driver: 'postgres', options: options);
    return registerPostgresOrmConnection(
      name: connectionName,
      database: databaseConfig,
      registry: registry,
      connection: ConnectionConfig(
        name: connectionName,
        options: options,
        defaultSchema: options['schema']?.toString() ?? 'public',
      ),
      manager: manager,
      singleton: true,
    );
  });
  return null;
})();

/// Ensures the postgres driver registers with [DriverRegistry].
void ensurePostgresDriverRegistration() => _postgresDriverRegistration;
