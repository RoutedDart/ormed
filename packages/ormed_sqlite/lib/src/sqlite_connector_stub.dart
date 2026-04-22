import 'package:ormed/ormed.dart';

class SqliteConnector extends Connector<Object> {
  SqliteConnector();

  @override
  Future<ConnectionHandle<Object>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    throw UnsupportedError(
      'SqliteConnector uses the native sqlite3 backend and is not available on '
      'web. Use SqliteDriverAdapter from package:ormed_sqlite instead.',
    );
  }
}
