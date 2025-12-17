/// Normalized preview data shared across drivers.
class NormalizedPreview {
  const NormalizedPreview({
    required this.type,
    required this.command,
    required this.parameters,
    required this.arguments,
    required this.metadata,
  });

  final String type;
  final String command;
  final List<Object?> parameters;
  final Map<String, Object?> arguments;
  final Map<String, Object?> metadata;
}

/// Statement payloads produced by drivers (SQL text or backend-specific command).
abstract class StatementPayload {
  const StatementPayload();

  /// Short human-readable summary for logging (SQL text, command name, etc.).
  String get summary;

  /// Normalized preview metadata. Implementations must provide a consistent
  /// structure so shared tooling can rely on a uniform schema.
  NormalizedPreview get normalized;

  /// Structured representation for observability.
  Map<String, Object?> toJson();
}
