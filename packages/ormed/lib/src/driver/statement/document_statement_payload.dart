import 'package:ormed/src/driver/statement/statement_payload.dart'
    show NormalizedPreview, StatementPayload;

/// Generic command/payload used by document drivers.
class DocumentStatementPayload extends StatementPayload {
  const DocumentStatementPayload({
    required this.command,
    this.arguments = const <String, Object?>{},
    this.metadata,
  });

  /// Driver command name (e.g., `find`, `aggregate`).
  final String command;

  /// Command arguments (filter, projection, pipeline, etc.).
  final Map<String, Object?> arguments;

  /// Optional metadata (options, session hints, etc.).
  final Map<String, Object?>? metadata;

  @override
  String get summary => command;

  @override
  Map<String, Object?> toJson() => {
    'type': 'document',
    'command': command,
    if (arguments.isNotEmpty) 'arguments': arguments,
    if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
  };

  @override
  NormalizedPreview get normalized => NormalizedPreview(
    type: 'document',
    command: command,
    parameters: const <Object?>[],
    arguments: Map<String, Object?>.unmodifiable(arguments),
    metadata: metadata ?? const <String, Object?>{},
  );
}
