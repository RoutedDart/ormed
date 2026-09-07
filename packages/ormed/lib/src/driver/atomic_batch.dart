import 'package:ormed/src/driver/mutation/mutation_plan.dart';
import 'package:ormed/src/query/query_plan.dart';

/// A query or mutation that can be staged for atomic execution.
///
/// Operations in a batch are fixed before execution starts. They cannot depend
/// on the Dart result of an earlier operation in the same batch.
sealed class AtomicBatchOperation {
  const AtomicBatchOperation();

  /// Stages a read plan.
  const factory AtomicBatchOperation.query(QueryPlan plan) =
      AtomicBatchQueryOperation;

  /// Stages a mutation plan.
  const factory AtomicBatchOperation.mutation(MutationPlan plan) =
      AtomicBatchMutationOperation;

  /// The driver for which this operation was built, when specified.
  String? get driverName;
}

/// A staged query operation.
final class AtomicBatchQueryOperation extends AtomicBatchOperation {
  const AtomicBatchQueryOperation(this.plan);

  /// The immutable query plan to execute.
  final QueryPlan plan;

  @override
  String? get driverName => plan.driverName;
}

/// A staged mutation operation.
final class AtomicBatchMutationOperation extends AtomicBatchOperation {
  const AtomicBatchMutationOperation(this.plan);

  /// The immutable mutation plan to execute.
  final MutationPlan plan;

  @override
  String? get driverName => plan.driverName;
}

/// The result of one operation in an atomic batch.
class AtomicBatchResult {
  const AtomicBatchResult({
    required this.operation,
    this.rows = const <Map<String, Object?>>[],
    this.affectedRows = 0,
    this.statementMetadata = const <Map<String, Object?>>[],
  });

  /// The operation that produced this result.
  final AtomicBatchOperation operation;

  /// Rows returned by a query or by a mutation with `RETURNING`.
  final List<Map<String, Object?>> rows;

  /// Rows affected by a mutation.
  final int affectedRows;

  /// Driver metadata for each physical statement used by this operation.
  ///
  /// Transaction-backed implementations may leave this empty when their
  /// backend does not expose per-statement metadata.
  final List<Map<String, Object?>> statementMetadata;

  /// Whether this result belongs to a query operation.
  bool get isQuery => operation is AtomicBatchQueryOperation;

  /// Whether this result belongs to a mutation operation.
  bool get isMutation => operation is AtomicBatchMutationOperation;
}

/// Optional driver contract for a backend-native atomic batch.
///
/// Drivers without this contract can still use Ormed's atomic batch API when
/// they support transactions. Ormed executes those operations sequentially
/// inside one transaction.
abstract interface class AtomicBatchDriver {
  /// Executes all [operations] atomically and returns results in input order.
  Future<List<AtomicBatchResult>> runAtomicBatch(
    List<AtomicBatchOperation> operations,
  );
}
