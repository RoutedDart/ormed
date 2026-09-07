library;

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';

import 'd1_binding.dart';
import 'd1_transport.dart';

class D1DriverAdapter extends SqliteRemoteAdapterBase
    implements AtomicBatchDriver {
  factory D1DriverAdapter.custom({
    required DatabaseConfig config,
    D1Transport? transport,
    List<DriverExtension> extensions = const [],
  }) {
    final resolvedTransport =
        transport ?? D1HttpTransport.fromOptions(config.options);
    return D1DriverAdapter._(
      config: config,
      transport: resolvedTransport,
      extensions: extensions,
    );
  }

  D1DriverAdapter._({
    required DatabaseConfig config,
    required D1Transport transport,
    required List<DriverExtension> extensions,
  }) : _transport = transport,
       super(
         driverName: 'd1',
         options: config.options,
         supportsTransactions: false,
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
           if (_supportsAtomicBatches(transport))
             DriverCapability.atomicBatches,
         },
         extensions: extensions,
       );

  /// Creates an adapter over a native Cloudflare D1 binding.
  factory D1DriverAdapter.fromBinding({
    required DatabaseConfig config,
    required D1DatabaseBinding binding,
    List<DriverExtension> extensions = const [],
  }) {
    return D1DriverAdapter.custom(
      config: config,
      transport: D1BindingTransport(binding),
      extensions: extensions,
    );
  }

  final D1Transport _transport;

  /// Executes an atomic D1 batch through a binding-capable transport.
  Future<List<D1StatementResult>> batch(Iterable<D1Statement> statements) {
    final transport = _transport;
    if (_supportsAtomicBatches(transport)) {
      return (transport as D1BatchTransport).batch(statements);
    }
    throw UnsupportedError(
      'This D1 transport does not support atomic batches.',
    );
  }

  @override
  Future<List<AtomicBatchResult>> runAtomicBatch(
    List<AtomicBatchOperation> operations,
  ) async {
    final statements = <D1Statement>[];
    final slices = <(int, int)>[];

    for (final operation in operations) {
      final start = statements.length;
      switch (operation) {
        case AtomicBatchQueryOperation(:final plan):
          final preview = describeQuery(plan);
          statements.add(
            D1Statement(
              sql: preview.sql,
              parameters: profile.normalizeParameters(preview.parameters),
            ),
          );
        case AtomicBatchMutationOperation(:final plan):
          final preview = describeMutation(plan);
          if (preview.parameterSets.isEmpty) {
            statements.add(
              D1Statement(
                sql: preview.sql,
                parameters: profile.normalizeParameters(preview.parameters),
              ),
            );
          } else {
            for (final parameters in preview.parameterSets) {
              statements.add(
                D1Statement(
                  sql: preview.sql,
                  parameters: profile.normalizeParameters(parameters),
                ),
              );
            }
          }
      }
      slices.add((start, statements.length - start));
    }

    final statementResults = statements.isEmpty
        ? const <D1StatementResult>[]
        : await batch(statements);
    if (statementResults.length != statements.length) {
      throw StateError(
        'D1 returned ${statementResults.length} results for '
        '${statements.length} statements.',
      );
    }

    for (final result in statementResults) {
      if (!result.success) {
        throw D1RequestException('D1 statement failed: ${result.error}');
      }
    }

    return List<AtomicBatchResult>.generate(operations.length, (index) {
      final operation = operations[index];
      final (start, length) = slices[index];
      final results = statementResults.sublist(start, start + length);
      final definition = switch (operation) {
        AtomicBatchQueryOperation(:final plan) => plan.definition,
        AtomicBatchMutationOperation(:final plan) => plan.definition,
      };
      final rows = <Map<String, Object?>>[];
      final generatedIds = <Object?>[];
      var affectedRows = 0;
      for (final result in results) {
        affectedRows += result.affectedRows;
        final decodedRows = result.rows
            .map((row) => decodeRowValues(definition, row))
            .toList(growable: false);
        rows.addAll(decodedRows);
        if (_isInsertLike(operation)) {
          final primaryKey = definition.primaryKeyField?.columnName;
          final returnedIds = primaryKey == null
              ? const <Object?>[]
              : decodedRows
                    .where(
                      (row) =>
                          row.containsKey(primaryKey) &&
                          row[primaryKey] != null,
                    )
                    .map((row) => row[primaryKey])
                    .toList(growable: false);
          if (returnedIds.isNotEmpty) {
            generatedIds.addAll(returnedIds);
          } else if (result.lastRowId != null) {
            generatedIds.add(result.lastRowId);
          }
        }
      }
      return AtomicBatchResult(
        operation: operation,
        rows: List<Map<String, Object?>>.unmodifiable(rows),
        affectedRows: operation is AtomicBatchMutationOperation
            ? affectedRows
            : 0,
        generatedIds: List<Object?>.unmodifiable(generatedIds),
        statementMetadata: List<Map<String, Object?>>.unmodifiable(
          results.map((result) => result.meta),
        ),
      );
    }, growable: false);
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

bool _isInsertLike(AtomicBatchOperation operation) {
  return switch (operation) {
    AtomicBatchMutationOperation(:final plan) =>
      plan.operation == MutationOperation.insert ||
          plan.operation == MutationOperation.upsert,
    AtomicBatchQueryOperation() => false,
  };
}

bool _supportsAtomicBatches(D1Transport transport) {
  if (transport is! D1BatchTransport) return false;
  if (transport is D1HttpTransport) return transport.supportsAtomicBatches;
  return true;
}
