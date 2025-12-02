import 'package:ormed/ormed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

class SqliteConnector extends Connector<sqlite.Database> {
  SqliteConnector();

  @override
  Future<ConnectionHandle<sqlite.Database>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    final options = endpoint.options;
    final inMemory = options['memory'] == true;
    final path = options['path'] as String?;
    late final sqlite.Database database;
    if (inMemory) {
      database = sqlite.sqlite3.openInMemory();
    } else if (path != null && path.isNotEmpty) {
      database = sqlite.sqlite3.open(path);
    } else {
      database = sqlite.sqlite3.open(':memory:');
    }

    return ConnectionHandle<sqlite.Database>(
      client: database,
      metadata: ConnectionMetadata(
        driver: endpoint.driver,
        role: role,
        description: inMemory ? ':memory:' : path,
      ),
      onClose: () async {
        database.close();
      },
    );
  }
}
