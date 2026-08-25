library;

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';

import 'd1_binding.dart';
import 'd1_transport.dart';

class D1DriverAdapter extends SqliteRemoteAdapterBase {
  D1DriverAdapter.custom({
    required DatabaseConfig config,
    D1Transport? transport,
    super.extensions,
  }) : _transport = transport ?? D1HttpTransport.fromOptions(config.options),
       super(
         driverName: 'd1',
         options: config.options,
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

  /// Creates an adapter over a native Cloudflare D1 binding.
  D1DriverAdapter.fromBinding({
    required DatabaseConfig config,
    required D1DatabaseBinding binding,
    List<DriverExtension> extensions = const [],
  }) : this.custom(
         config: config,
         transport: D1BindingTransport(binding),
         extensions: extensions,
       );

  final D1Transport _transport;

  /// Executes an atomic D1 batch through a binding-capable transport.
  Future<List<D1StatementResult>> batch(Iterable<D1Statement> statements) {
    final transport = _transport;
    if (transport is D1BatchTransport) {
      return (transport as D1BatchTransport).batch(statements);
    }
    throw UnsupportedError(
      'This D1 transport does not support atomic batches.',
    );
  }

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
    throw UnsupportedError(
      'Cloudflare D1 HTTP API does not support atomic '
      'multi-statement transactions.',
    );
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
