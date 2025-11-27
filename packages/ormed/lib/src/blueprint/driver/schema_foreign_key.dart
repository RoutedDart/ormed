/// Metadata describing a foreign key constraint.
///
/// Returned by [SchemaDriver.listForeignKeys].
class SchemaForeignKey {
  const SchemaForeignKey({
    required this.name,
    required this.columns,
    required this.referencedTable,
    required this.referencedColumns,
    this.tableName,
    this.schema,
    this.referencedSchema,
    this.onUpdate,
    this.onDelete,
  });

  /// Constraint name.
  final String name;

  /// Columns participating in the foreign key.
  final List<String> columns;

  /// Target table that this foreign key references.
  final String referencedTable;

  /// Target columns that this foreign key references.
  final List<String> referencedColumns;

  /// Table that owns the foreign key.
  final String? tableName;

  /// Schema that contains the foreign key.
  final String? schema;

  /// Schema containing the referenced table.
  final String? referencedSchema;

  /// Action taken when the referenced row updates.
  final String? onUpdate;

  /// Action taken when the referenced row deletes.
  final String? onDelete;

  Map<String, Object?> toJson() => {
    'name': name,
    'columns': columns,
    if (tableName != null) 'tableName': tableName,
    'referencedTable': referencedTable,
    'referencedColumns': referencedColumns,
    if (schema != null) 'schema': schema,
    if (referencedSchema != null) 'referencedSchema': referencedSchema,
    if (onUpdate != null) 'onUpdate': onUpdate,
    if (onDelete != null) 'onDelete': onDelete,
  };

  factory SchemaForeignKey.fromJson(Map<String, Object?> json) =>
      SchemaForeignKey(
        name: json['name'] as String,
        columns: (json['columns'] as List).cast<String>(),
        referencedTable: json['referencedTable'] as String,
        referencedColumns: (json['referencedColumns'] as List).cast<String>(),
        tableName: json['tableName'] as String?,
        schema: json['schema'] as String?,
        referencedSchema: json['referencedSchema'] as String?,
        onUpdate: json['onUpdate'] as String?,
        onDelete: json['onDelete'] as String?,
      );
}
