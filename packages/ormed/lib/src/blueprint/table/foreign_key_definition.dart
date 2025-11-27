import 'package:meta/meta.dart';

import 'enums.dart';

/// Declarative foreign key metadata.
@immutable
class ForeignKeyDefinition {
  const ForeignKeyDefinition({
    required this.name,
    required this.columns,
    required this.referencedTable,
    required this.referencedColumns,
    this.onDelete = ReferenceAction.noAction,
    this.onUpdate = ReferenceAction.noAction,
  });

  /// Constraint name for the foreign key.
  final String name;

  /// Columns participating in the constraint.
  final List<String> columns;

  /// Referenced table name.
  final String referencedTable;

  /// Columns on the referenced table.
  final List<String> referencedColumns;

  /// Cascading action when the referenced row is deleted.
  final ReferenceAction onDelete;

  /// Cascading action when the referenced row is updated.
  final ReferenceAction onUpdate;

  ForeignKeyDefinition copyWith({
    ReferenceAction? onDelete,
    ReferenceAction? onUpdate,
  }) => ForeignKeyDefinition(
    name: name,
    columns: columns,
    referencedTable: referencedTable,
    referencedColumns: referencedColumns,
    onDelete: onDelete ?? this.onDelete,
    onUpdate: onUpdate ?? this.onUpdate,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'columns': columns,
    'references': {'table': referencedTable, 'columns': referencedColumns},
    if (onDelete != ReferenceAction.noAction) 'onDelete': onDelete.name,
    if (onUpdate != ReferenceAction.noAction) 'onUpdate': onUpdate.name,
  };

  factory ForeignKeyDefinition.fromJson(Map<String, Object?> json) {
    final references = json['references'] as Map<String, Object?>;
    return ForeignKeyDefinition(
      name: json['name'] as String,
      columns: (json['columns'] as List).cast<String>(),
      referencedTable: references['table'] as String,
      referencedColumns: (references['columns'] as List).cast<String>(),
      onDelete: json['onDelete'] == null
          ? ReferenceAction.noAction
          : ReferenceAction.values.byName(json['onDelete'] as String),
      onUpdate: json['onUpdate'] == null
          ? ReferenceAction.noAction
          : ReferenceAction.values.byName(json['onUpdate'] as String),
    );
  }
}
