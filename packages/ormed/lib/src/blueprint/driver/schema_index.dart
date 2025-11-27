/// Metadata describing an index.
///
/// Returned by [SchemaDriver.listIndexes].
class SchemaIndex {
  const SchemaIndex({
    required this.name,
    required this.columns,
    this.schema,
    this.tableName,
    this.unique = false,
    this.primary = false,
    this.method,
    this.whereClause,
  });

  /// Index name.
  final String name;

  /// Columns covered by the index.
  final List<String> columns;

  /// Schema that contains the indexed table.
  final String? schema;

  /// Table that owns the index.
  final String? tableName;

  /// Whether the index enforces uniqueness.
  final bool unique;

  /// Whether the index is the primary key.
  final bool primary;

  /// Index method used (such as BTREE).
  final String? method;

  /// WHERE clause limiting the index when it is partial.
  final String? whereClause;

  Map<String, Object?> toJson() => {
    'name': name,
    'columns': columns,
    if (schema != null) 'schema': schema,
    if (tableName != null) 'tableName': tableName,
    if (unique) 'unique': true,
    if (primary) 'primary': true,
    if (method != null) 'method': method,
    if (whereClause != null) 'whereClause': whereClause,
  };

  factory SchemaIndex.fromJson(Map<String, Object?> json) => SchemaIndex(
    name: json['name'] as String,
    columns: (json['columns'] as List).cast<String>(),
    schema: json['schema'] as String?,
    tableName: json['tableName'] as String?,
    unique: json['unique'] as bool? ?? false,
    primary: json['primary'] as bool? ?? false,
    method: json['method'] as String?,
    whereClause: json['whereClause'] as String?,
  );
}
