import 'package:meta/meta.dart';

import 'column_definition.dart';
import 'enums.dart';

/// Snapshot of a column mutation.
@immutable
class ColumnCommand {
  const ColumnCommand({
    required this.kind,
    required this.name,
    this.definition,
  });

  /// Command kind describing the mutation.
  final ColumnCommandKind kind;

  /// Column name targeted by the command.
  final String name;

  /// Column definition associated with the command, if any.
  final ColumnDefinition? definition;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'name': name,
    if (definition != null) 'definition': definition!.toJson(),
  };

  factory ColumnCommand.fromJson(Map<String, Object?> json) => ColumnCommand(
    kind: ColumnCommandKind.values.byName(json['kind'] as String),
    name: json['name'] as String,
    definition: json['definition'] == null
        ? null
        : ColumnDefinition.fromJson(json['definition'] as Map<String, Object?>),
  );
}
