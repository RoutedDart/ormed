/// Additional metadata about namespaces/schemas available on a connection.
///
/// The metadata is returned by [SchemaDriver.listSchemas].
class SchemaNamespace {
  const SchemaNamespace({
    required this.name,
    this.owner,
    this.isDefault = false,
  });

  /// Namespace name as returned by the driver.
  final String name;

  /// Owner of the namespace, if provided by the database.
  final String? owner;

  /// Whether this namespace is treated as the default one.
  final bool isDefault;

  Map<String, Object?> toJson() => {
    'name': name,
    if (owner != null) 'owner': owner,
    if (isDefault) 'isDefault': true,
  };

  factory SchemaNamespace.fromJson(Map<String, Object?> json) =>
      SchemaNamespace(
        name: json['name'] as String,
        owner: json['owner'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
