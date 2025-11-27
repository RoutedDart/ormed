/// Metadata describing a table column.
///
/// Columns are returned by [SchemaDriver.listColumns].
class SchemaColumn {
  const SchemaColumn({
    required this.name,
    required this.dataType,
    this.schema,
    this.tableName,
    this.length,
    this.numericPrecision,
    this.numericScale,
    this.nullable = true,
    this.defaultValue,
    this.autoIncrement = false,
    this.primaryKey = false,
    this.comment,
    this.generatedExpression,
  });

  /// Column name without schema qualification.
  final String name;

  /// Data type string reported by the database.
  final String dataType;

  /// Schema containing the column, when applicable.
  final String? schema;

  /// Table that owns the column, without schema qualification.
  final String? tableName;

  /// Maximum length for text columns.
  final int? length;

  /// Numeric precision when applicable.
  final int? numericPrecision;

  /// Numeric scale when applicable.
  final int? numericScale;

  /// Whether the column allows `NULL` values.
  final bool nullable;

  /// Default expression defined for the column.
  final String? defaultValue;

  /// Whether the column uses auto-increment semantics.
  final bool autoIncrement;

  /// Whether the column is part of the primary key.
  final bool primaryKey;

  /// Column comment provided by the database.
  final String? comment;

  /// Expression used to generate this column, if any.
  final String? generatedExpression;

  Map<String, Object?> toJson() => {
    'name': name,
    'dataType': dataType,
    if (schema != null) 'schema': schema,
    if (tableName != null) 'tableName': tableName,
    if (length != null) 'length': length,
    if (numericPrecision != null) 'numericPrecision': numericPrecision,
    if (numericScale != null) 'numericScale': numericScale,
    if (!nullable) 'nullable': false,
    if (defaultValue != null) 'defaultValue': defaultValue,
    if (autoIncrement) 'autoIncrement': true,
    if (primaryKey) 'primaryKey': true,
    if (comment != null) 'comment': comment,
    if (generatedExpression != null) 'generatedExpression': generatedExpression,
  };

  factory SchemaColumn.fromJson(Map<String, Object?> json) => SchemaColumn(
    name: json['name'] as String,
    dataType: json['dataType'] as String,
    schema: json['schema'] as String?,
    tableName: json['tableName'] as String?,
    length: json['length'] as int?,
    numericPrecision: json['numericPrecision'] as int?,
    numericScale: json['numericScale'] as int?,
    nullable: json['nullable'] as bool? ?? true,
    defaultValue: json['defaultValue'] as String?,
    autoIncrement: json['autoIncrement'] as bool? ?? false,
    primaryKey: json['primaryKey'] as bool? ?? false,
    comment: json['comment'] as String?,
    generatedExpression: json['generatedExpression'] as String?,
  );
}
