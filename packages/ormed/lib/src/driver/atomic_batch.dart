import 'package:ormed/src/driver/mutation/mutation_plan.dart';
import 'package:ormed/src/query/query_plan.dart';

/// A query or mutation that can be staged for atomic execution.
///
/// Operations in a batch are fixed before execution starts. They cannot depend
/// on the Dart result of an earlier operation in the same batch.
sealed class AtomicBatchOperation {
  const AtomicBatchOperation();

  /// Stages a read plan.
  const factory AtomicBatchOperation.query(
    QueryPlan plan, {
    Object? sourceContext,
  }) = AtomicBatchQueryOperation;

  /// Stages a mutation plan.
  const factory AtomicBatchOperation.mutation(
    MutationPlan plan, {
    Object? sourceContext,
  }) = AtomicBatchMutationOperation;

  /// The driver for which this operation was built, when specified.
  String? get driverName;

  /// The query context that staged this operation, when available.
  ///
  /// This is an identity marker used to prevent plans from one query context
  /// being executed through another context's hooks, cache, codecs, and
  /// change feed. Operations constructed directly from plans may omit it.
  Object? get sourceContext;
}

/// A staged query operation.
final class AtomicBatchQueryOperation extends AtomicBatchOperation {
  const AtomicBatchQueryOperation(this.plan, {this.sourceContext});

  /// The immutable query plan to execute.
  final QueryPlan plan;

  @override
  final Object? sourceContext;

  @override
  String? get driverName => plan.driverName;
}

/// A staged mutation operation.
final class AtomicBatchMutationOperation extends AtomicBatchOperation {
  const AtomicBatchMutationOperation(this.plan, {this.sourceContext});

  /// The immutable mutation plan to execute.
  final MutationPlan plan;

  @override
  final Object? sourceContext;

  @override
  String? get driverName => plan.driverName;
}

/// The result of one operation in an atomic batch.
class AtomicBatchResult {
  const AtomicBatchResult({
    required this.operation,
    this.rows = const <Map<String, Object?>>[],
    this.affectedRows = 0,
    this.generatedIds = const <Object?>[],
    this.statementMetadata = const <Map<String, Object?>>[],
  });

  /// The operation that produced this result.
  final AtomicBatchOperation operation;

  /// Rows returned by a query or by a mutation with `RETURNING`.
  final List<Map<String, Object?>> rows;

  /// Rows affected by a mutation.
  final int affectedRows;

  /// Generated or returned identity values, when the driver exposes them.
  ///
  /// Values are ordered by the physical insert-like statements in the
  /// originating operation. Drivers may leave this empty when the backend
  /// does not expose generated identities.
  final List<Object?> generatedIds;

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
