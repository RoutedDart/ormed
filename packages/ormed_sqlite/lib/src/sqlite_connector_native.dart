import 'package:ormed/ormed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'sqlite_connection_settings.dart';

class SqliteConnector extends Connector<sqlite.Database> {
  SqliteConnector();

  @override
  Future<ConnectionHandle<sqlite.Database>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    final options = endpoint.options;
    final inMemory = options['memory'] == true;
    final path = options['path'] as String? ?? options['database'] as String?;
    late final sqlite.Database database;
    if (inMemory) {
      database = sqlite.sqlite3.openInMemory();
    } else if (path != null && path.isNotEmpty) {
      database = sqlite.sqlite3.open(path);
    } else {
      database = sqlite.sqlite3.open(':memory:');
    }

    final sessionOptions = sqliteSessionOptions(options);
    final sessionAllowlist = sqliteSessionAllowlist(options);
    for (final entry in sessionOptions.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) {
        throw ArgumentError.value(
          key,
          'session',
          'SQLite session option keys cannot be empty.',
        );
      }
      validateSqliteSessionKey(key, sessionAllowlist, driverName: 'sqlite');
      database.execute('PRAGMA $key = ${sqlitePragmaValue(entry.value)}');
    }

    final initStatements = sqliteInitStatements(options);
    for (final statement in initStatements) {
      if (statement.trim().isEmpty) continue;
      database.execute(statement);
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
