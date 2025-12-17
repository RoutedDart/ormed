import 'package:ormed/src/driver/statement/sql_statement_payload.dart';
import 'package:ormed/src/driver/statement/statement_payload.dart';

/// Preview of a statement produced by a plan compiler.
class StatementPreview {
  const StatementPreview({
    required this.payload,
    List<List<Object?>>? parameterSets,
    this.resolvedText,
  }) : _parameterSets = parameterSets ?? const <List<Object?>>[];

  final StatementPayload payload;
  final List<List<Object?>> _parameterSets;
  final String? resolvedText;

  /// SQL -- or command text -- used for backwards compatibility.
  String get sql => payload is SqlStatementPayload
      ? (payload as SqlStatementPayload).sql
      : payload.summary;

  /// Bindings associated with [sql]. Empty for non-SQL statements.
  List<Object?> get parameters => payload is SqlStatementPayload
      ? (payload as SqlStatementPayload).parameters
      : const [];

  /// Additional parameter batches.
  List<List<Object?>> get parameterSets => _parameterSets;

  /// The final representation shown in logs, including resolved bindings if provided.
  String get sqlWithBindings => resolvedText ?? sql;

  /// Whether the preview represents multiple executions of the same statement.
  bool get hasBatches => _parameterSets.isNotEmpty;

  /// Normalized metadata shared across drivers.
  NormalizedPreview get normalized => payload.normalized;
}
