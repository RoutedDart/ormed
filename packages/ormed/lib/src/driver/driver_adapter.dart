/// Contracts database-specific adapters implement to plug into the ORM query
/// executor abstractions.
library;

import 'package:ormed/src/driver/compiler/plan_compiler.dart';
import 'package:ormed/src/driver/driver_metadata.dart';
import 'package:ormed/src/driver/mutation/mutation_plan.dart';
import 'package:ormed/src/driver/mutation/mutation_result.dart';
import 'package:ormed/src/driver/statement/statement_preview.dart';
import 'package:ormed/src/query/query.dart';
import 'package:ormed/src/value_codec.dart';

/// Handles the lifecycle of connections and query execution for a specific
/// backend.
abstract class DriverAdapter implements QueryExecutor {
  /// Compiler used by this adapter to translate ORM plans.
  PlanCompiler get planCompiler;

  /// Advertises the capabilities supported by this adapter.
  DriverMetadata get metadata;

  /// Registry of codecs used when marshalling values.
  ValueCodecRegistry get codecs;

  /// Executes an arbitrary SQL statement that does not return rows.
  Future<void> executeRaw(String sql, [List<Object?> parameters = const []]);

  /// Executes a structured mutation plan (insert/update/delete).
  Future<MutationResult> runMutation(MutationPlan plan);

  /// Starts a new transaction boundary.
  Future<R> transaction<R>(Future<R> Function() action);

  /// Begins a new database transaction.
  ///
  /// Must be paired with [commitTransaction] or [rollbackTransaction].
  /// Supports nested transactions via savepoints if the driver supports them.
  Future<void> beginTransaction();

  /// Commits the active database transaction.
  Future<void> commitTransaction();

  /// Rolls back the active database transaction.
  Future<void> rollbackTransaction();

  /// Truncates a table, removing all rows and resetting auto-increment counters.
  ///
  /// This is more efficient than deleting all rows and properly resets
  /// sequences/auto-increment values. Each driver implements this using
  /// its native truncate mechanism.
  Future<void> truncateTable(String tableName);

  /// Executes a raw SQL query and returns the resulting rows.
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]);

  /// Closes the underlying connections/resources.
  Future<void> close();

  /// Provides a statement preview for a read [plan] without executing it.
  StatementPreview describeQuery(QueryPlan plan);

  /// Provides a statement preview for a mutation [plan] without executing it.
  StatementPreview describeMutation(MutationPlan plan);

  /// Returns the number of open connections reported by the backend, when
  /// supported.
  Future<int?> threadCount();
}
