import 'package:meta/meta.dart';

import 'enums.dart';
import 'index_definition.dart';

/// Snapshot of an index mutation.
@immutable
class IndexCommand {
  const IndexCommand._({
    required this.kind,
    required this.name,
    this.definition,
  });

  factory IndexCommand.add(IndexDefinition definition) => IndexCommand._(
    kind: IndexCommandKind.add,
    name: definition.name,
    definition: definition,
  );

  factory IndexCommand.drop(String name) =>
      IndexCommand._(kind: IndexCommandKind.drop, name: name);

  /// Index command kind describing add/drop.
  final IndexCommandKind kind;

  /// Index name targeted by the command.
  final String name;

  /// Optional index definition carried by the command.
  final IndexDefinition? definition;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'name': name,
    if (definition != null) 'definition': definition!.toJson(),
  };

  factory IndexCommand.fromJson(Map<String, Object?> json) => IndexCommand._(
    kind: IndexCommandKind.values.byName(json['kind'] as String),
    name: json['name'] as String,
    definition: json['definition'] == null
        ? null
        : IndexDefinition.fromJson(json['definition'] as Map<String, Object?>),
  );
}
