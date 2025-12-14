import 'orm_connection.dart';

/// Base class for all connection-scoped events.
///
/// Provides access to the connection where the event originated,
/// allowing listeners to access connection metadata and configuration.
abstract class ConnectionEvent {
  ConnectionEvent(this.connection) : connectionName = connection.name;

  /// The connection where this event occurred.
  final OrmConnection connection;

  /// The name of the connection (convenience accessor).
  final String connectionName;
}

/// Fired after every query executes.
///
/// This is the primary event for observing database queries. It includes
/// the SQL that was executed, the bound parameters, and execution timing.
///
/// ## Example
///
/// ```dart
/// connection.listen((event) {
///   print('Query: ${event.sql} took ${event.time}ms');
///   if (event.time > 1000) {
///     logger.warning('Slow query detected: ${event.sql}');
///   }
/// });
/// ```
class QueryExecuted extends ConnectionEvent {
  QueryExecuted({
    required this.sql,
    required this.bindings,
    required this.time,
    required OrmConnection connection,
    this.rowCount,
    this.error,
    this.stackTrace,
  }) : super(connection);

  /// The SQL that was executed.
  final String sql;

  /// The bound parameter values.
  final List<Object?> bindings;

  /// Execution time in milliseconds.
  final double time;

  /// Number of rows returned (for SELECT) or affected (for mutations).
  final int? rowCount;

  /// Error that occurred during execution, if any.
  final Object? error;

  /// Stack trace captured when [error] is populated.
  final StackTrace? stackTrace;

  /// Whether the query completed successfully.
  bool get succeeded => error == null;

  /// Get raw SQL with bindings substituted.
  ///
  /// Note: This is for debugging/logging only. The actual execution uses
  /// parameterized queries for security.
  String toRawSql() {
    var rawSql = sql;
    for (final binding in bindings) {
      final value = binding == null
          ? 'NULL'
          : binding is String
              ? "'${binding.replaceAll("'", "''")}'"
              : binding.toString();
      rawSql = rawSql.replaceFirst('?', value);
    }
    return rawSql;
  }
}

/// Fired when a transaction begins.
///
/// ## Example
///
/// ```dart
/// connection.onEvent<TransactionBeginning>((event) {
///   print('Transaction started on ${event.connectionName}');
/// });
/// ```
class TransactionBeginning extends ConnectionEvent {
  TransactionBeginning(super.connection);
}

/// Fired when a transaction is about to commit.
///
/// This event fires before the actual commit occurs. If you need to
/// perform validation or logging before commit, use this event.
class TransactionCommitting extends ConnectionEvent {
  TransactionCommitting(super.connection);
}

/// Fired after a transaction commits successfully.
///
/// ## Example
///
/// ```dart
/// connection.onEvent<TransactionCommitted>((event) {
///   print('Transaction committed on ${event.connectionName}');
/// });
/// ```
class TransactionCommitted extends ConnectionEvent {
  TransactionCommitted(super.connection);
}

/// Fired after a transaction rolls back.
///
/// ## Example
///
/// ```dart
/// connection.onEvent<TransactionRolledBack>((event) {
///   print('Transaction rolled back on ${event.connectionName}');
///   logger.warning('Transaction failed');
/// });
/// ```
class TransactionRolledBack extends ConnectionEvent {
  TransactionRolledBack(super.connection);
}

/// Fired when a new database connection is established.
///
/// This is useful for connection pool monitoring and initialization tasks.
class ConnectionEstablished extends ConnectionEvent {
  ConnectionEstablished(super.connection);
}
