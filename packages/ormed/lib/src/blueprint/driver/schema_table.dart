import 'schema_column.dart';

/// Metadata describing a database table (excluding views).
///
/// Returned by [SchemaDriver.listTables].
class SchemaTable {
  const SchemaTable({
    required this.name,
    this.schema,
    this.type,
    this.sizeBytes,
    this.comment,
    this.engine,
    this.fields = const <SchemaColumn>[],
  });

  /// Table name without schema qualification.
  final String name;

  /// Schema that owns the table, if any.
  final String? schema;

  /// Table type hint (e.g., BASE TABLE or VIEW).
  final String? type;

  /// Byte size of the table data when reported by the database.
  final int? sizeBytes;

  /// Optional human-readable comment attached to the table.
  final String? comment;

  /// Storage engine reported for the table (e.g., InnoDB).
  final String? engine;

  /// Columns included in the table.
  final List<SchemaColumn> fields;

  /// Fully qualified name including the schema when available.
  String get schemaQualifiedName => schema == null ? name : '$schema.$name';

  Map<String, Object?> toJson() => {
    'name': name,
    if (schema != null) 'schema': schema,
    if (type != null) 'type': type,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
    if (comment != null) 'comment': comment,
    if (engine != null) 'engine': engine,
    if (fields.isNotEmpty)
      'fields': fields.map((column) => column.toJson()).toList(),
  };

  factory SchemaTable.fromJson(Map<String, Object?> json) => SchemaTable(
    name: json['name'] as String,
    schema: json['schema'] as String?,
    type: json['type'] as String?,
    sizeBytes: json['sizeBytes'] as int?,
    comment: json['comment'] as String?,
    engine: json['engine'] as String?,
    fields:
        (json['fields'] as List?)
            ?.map(
              (entry) =>
                  SchemaColumn.fromJson((entry as Map).cast<String, Object?>()),
            )
            .toList() ??
        const <SchemaColumn>[],
  );
}
