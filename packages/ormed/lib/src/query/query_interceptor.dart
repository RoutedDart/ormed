import '../driver/mutation/mutation_plan.dart';
import 'query_plan.dart';

/// Describes one operation being dispatched through the ORM execution layer.
///
/// Interceptors can use this context for tracing, metrics, authorization, or
/// query policy decisions. The [next] callback supplied to
/// [QueryInterceptor.intercept] is allowed to be skipped when an interceptor
/// intentionally short-circuits an operation.
class QueryExecutionContext {
  /// Creates an execution context.
  QueryExecutionContext({
    required this.driverName,
    required this.sql,
    List<Object?> parameters = const [],
    required this.operationName,
    required this.querySummary,
    this.connectionName,
    this.database,
    this.collectionName,
    this.transactionId,
    this.queryPlan,
    this.mutationPlan,
  }) : parameters = List<Object?>.unmodifiable(parameters);

  /// The driver backend name, such as `sqlite` or `postgres`.
  final String driverName;

  /// The logical connection name, when configured.
  final String? connectionName;

  /// The configured database/catalog identifier, when available.
  final String? database;

  /// The SQL statement being dispatched.
  final String sql;

  /// The bound values associated with [sql].
  final List<Object?> parameters;

  /// A stable operation category, such as `SELECT`, `INSERT`, or `RAW`.
  final String operationName;

  /// A short human-readable description of the operation.
  final String querySummary;

  /// The table or collection affected by the operation, when known.
  final String? collectionName;

  /// The logical transaction identifier, when the operation runs in a
  /// transaction managed by [QueryContext].
  final String? transactionId;

  /// The structured query plan, when this is a query-builder read.
  final QueryPlan? queryPlan;

  /// The structured mutation plan, when this is a query-builder mutation.
  final MutationPlan? mutationPlan;
}

/// Middleware for database operations.
///
/// Interceptors execute in registration order before [next] and can perform
/// work after it completes. They may throw to reject an operation or return a
/// value without calling [next] to short-circuit it.
abstract class QueryInterceptor {
  /// Intercepts a future-based database operation.
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  );

  /// Intercepts a streaming database operation.
  ///
  /// Interceptors that do not need stream-specific behavior can use the
  /// default implementation. A stream interceptor may return a transformed
  /// stream or avoid calling [next] to short-circuit the operation.
  Stream<T> interceptStream<T>(
    QueryExecutionContext context,
    Stream<T> Function() next,
  ) => next();
}

/// Runs database operations through an ordered set of [QueryInterceptor]s.
class QueryInterceptorPipeline {
  /// Creates an execution pipeline for one connection.
  QueryInterceptorPipeline({
    required this.driverName,
    this.connectionName,
    this.database,
    List<QueryInterceptor> interceptors = const [],
  }) : interceptors = List<QueryInterceptor>.unmodifiable(interceptors);

  /// The driver backend name associated with this pipeline.
  final String driverName;

  /// The logical connection name associated with this pipeline.
  final String? connectionName;

  /// The configured database/catalog identifier, when available.
  final String? database;

  /// The ordered interceptor list.
  final List<QueryInterceptor> interceptors;

  int _transactionCounter = 0;

  /// Whether this pipeline has any active interceptors.
  bool get isActive => interceptors.isNotEmpty;

  /// Runs a future-based operation through all interceptors.
  Future<T> run<T>(QueryExecutionContext context, Future<T> Function() next) {
    if (interceptors.isEmpty) return next();
    return _run(0, context, next);
  }

  Future<T> _run<T>(
    int index,
    QueryExecutionContext context,
    Future<T> Function() next,
  ) {
    if (index == interceptors.length) return next();
    return interceptors[index].intercept(
      context,
      () => _run(index + 1, context, next),
    );
  }

  /// Runs a streaming operation through all interceptors.
  Stream<T> runStream<T>(
    QueryExecutionContext context,
    Stream<T> Function() next,
  ) {
    if (interceptors.isEmpty) return next();
    return _runStream(0, context, next);
  }

  Stream<T> _runStream<T>(
    int index,
    QueryExecutionContext context,
    Stream<T> Function() next,
  ) {
    if (index == interceptors.length) return next();
    return interceptors[index].interceptStream(
      context,
      () => _runStream(index + 1, context, next),
    );
  }

  /// Allocates a connection-local identifier for a managed transaction.
  String nextTransactionId() => 'tx_${++_transactionCounter}';
}
