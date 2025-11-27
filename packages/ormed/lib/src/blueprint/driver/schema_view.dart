/// Metadata describing a database view.
///
/// Returned by [SchemaDriver.listViews].
class SchemaView {
  const SchemaView({required this.name, this.schema, this.definition});

  /// View name without schema qualification.
  final String name;

  /// Schema that contains the view, if provided.
  final String? schema;

  /// SQL definition used to create the view.
  final String? definition;

  /// Fully qualified name including schema when applicable.
  String get schemaQualifiedName => schema == null ? name : '$schema.$name';

  Map<String, Object?> toJson() => {
    'name': name,
    if (schema != null) 'schema': schema,
    if (definition != null) 'definition': definition,
  };

  factory SchemaView.fromJson(Map<String, Object?> json) => SchemaView(
    name: json['name'] as String,
    schema: json['schema'] as String?,
    definition: json['definition'] as String?,
  );
}
