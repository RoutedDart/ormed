library;

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';

import 'd1_transport.dart';

class D1DriverAdapter extends SqliteRemoteAdapterBase {
  D1DriverAdapter.custom({
    required DatabaseConfig config,
    D1Transport? transport,
    List<DriverExtension> extensions = const [],
  }) : _transport = transport ?? D1HttpTransport.fromOptions(config.options),
       super(
         driverName: 'd1',
         options: config.options,
         extensions: extensions,
         supportsQueryDeletes: true,
         requiresPrimaryKeyForQueryUpdate: true,
         queryUpdateRowIdentifier: QueryRowIdentifier(
           column: 'rowid',
           expression: 'rowid',
         ),
         capabilities: {
           DriverCapability.joins,
           DriverCapability.insertUsing,
           DriverCapability.queryDeletes,
           DriverCapability.schemaIntrospection,
           DriverCapability.adHocQueryUpdates,
           DriverCapability.rawSQL,
           DriverCapability.increment,
           DriverCapability.relationAggregates,
           DriverCapability.caseInsensitiveLike,
           DriverCapability.foreignKeyConstraintControl,
         },
       );

  final D1Transport _transport;

  static void registerCodecs() {
    registerSqliteLikeDriverCodecs('d1');
  }

  @override
  Future<void> closeBackend() => _transport.close();

  @override
  Future<int> executeStatement(String sql, List<Object?> parameters) async {
    final result = await _transport.execute(sql, parameters);
    return result.affectedRows;
  }

  @override
  Future<List<Map<String, Object?>>> queryStatement(
    String sql,
    List<Object?> parameters,
  ) async {
    final result = await _transport.query(sql, parameters);
    return result.rows;
  }

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    // Cloudflare D1 HTTP API does not allow explicit BEGIN/COMMIT statements.
    return action();
  }

  @override
  Future<void> beginTransaction() async {
    throw UnsupportedError(
      'Cloudflare D1 HTTP API does not support BEGIN TRANSACTION statements.',
    );
  }

  @override
  Future<void> commitTransaction() async {
    throw UnsupportedError(
      'Cloudflare D1 HTTP API does not support COMMIT statements.',
    );
  }

  @override
  Future<void> rollbackTransaction() async {
    throw UnsupportedError(
      'Cloudflare D1 HTTP API does not support ROLLBACK statements.',
    );
  }
}
