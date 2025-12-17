import 'package:ormed/src/driver/statement/statement_payload.dart';

/// SQL statement emitted by relational drivers.
class SqlStatementPayload extends StatementPayload {
  const SqlStatementPayload({required this.sql, this.parameters = const []});

  /// SQL statement text.
  final String sql;

  /// Bindings associated with [sql].
  final List<Object?> parameters;

  @override
  String get summary => sql;

  @override
  Map<String, Object?> toJson() => {
    'type': 'sql',
    'sql': sql,
    if (parameters.isNotEmpty) 'parameters': parameters,
  };

  @override
  NormalizedPreview get normalized => NormalizedPreview(
    type: 'sql',
    command: sql,
    parameters: List<Object?>.unmodifiable(parameters),
    arguments: const <String, Object?>{},
    metadata: const <String, Object?>{},
  );
}
