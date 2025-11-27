import 'package:meta/meta.dart';

import 'enums.dart';
import 'foreign_key_definition.dart';

/// Snapshot of a foreign key mutation.
@immutable
class ForeignKeyCommand {
  const ForeignKeyCommand._({
    required this.kind,
    required this.name,
    this.definition,
  });

  factory ForeignKeyCommand.add(ForeignKeyDefinition definition) =>
      ForeignKeyCommand._(
        kind: ForeignKeyCommandKind.add,
        name: definition.name,
        definition: definition,
      );

  factory ForeignKeyCommand.drop(String name) =>
      ForeignKeyCommand._(kind: ForeignKeyCommandKind.drop, name: name);

  /// Command kind describing foreign key add/drop.
  final ForeignKeyCommandKind kind;

  /// Name of the foreign key affected by the command.
  final String name;

  /// Optional foreign key definition provided for add commands.
  final ForeignKeyDefinition? definition;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'name': name,
    if (definition != null) 'definition': definition!.toJson(),
  };

  factory ForeignKeyCommand.fromJson(Map<String, Object?> json) =>
      ForeignKeyCommand._(
        kind: ForeignKeyCommandKind.values.byName(json['kind'] as String),
        name: json['name'] as String,
        definition: json['definition'] == null
            ? null
            : ForeignKeyDefinition.fromJson(
                json['definition'] as Map<String, Object?>,
              ),
      );
}
