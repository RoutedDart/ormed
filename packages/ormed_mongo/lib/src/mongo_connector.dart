import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';

/// Connector that creates MongoDB database handles.
class MongoConnector extends Connector<Db> {
  MongoConnector();

  @override
  Future<ConnectionHandle<Db>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    final baseUrl =
        endpoint.options['url'] as String? ?? 'mongodb://127.0.0.1:27017';
    final database = endpoint.options['database'] as String? ?? 'orm';
    final uri = _buildUri(baseUrl, database);
    final db = Db(uri);
    await db.open();
    return ConnectionHandle<Db>(
      client: db,
      metadata: ConnectionMetadata(
        driver: endpoint.driver,
        role: role,
        description: uri,
      ),
      onClose: () async {
        await db.close();
      },
    );
  }
}

String _buildUri(String baseUrl, String database) {
  var trimmed = baseUrl.trim();
  if (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  final queryIndex = trimmed.indexOf('?');
  if (queryIndex == -1) {
    return '$trimmed/$database';
  }
  final beforeQuery = trimmed.substring(0, queryIndex);
  final query = trimmed.substring(queryIndex);
  return '$beforeQuery/$database$query';
}
