import 'package:ormed/ormed.dart';

import 'd1_adapter.dart';
import 'd1_transport.dart';

/// Registers a D1 connection without requiring generated model code.
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
