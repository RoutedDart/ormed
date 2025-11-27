import 'schema_column.dart';
import 'schema_driver.dart';

/// High-level helper that mirrors Laravel's schema inspector.
///
/// ```dart
/// final inspector = SchemaInspector(driver);
/// final hasUsers = await inspector.hasTable('users');
/// ```
class SchemaInspector {
  SchemaInspector(this.driver);

  /// Schema driver instance that the inspector queries.
  final SchemaDriver driver;

  Future<bool> hasTable(String table, {String? schema}) async {
    final id = _identifier(table, schema);
    final tables = await driver.listTables(schema: id.schema);
    return tables.any(
      (t) =>
          _equalsIgnoreCase(t.name, id.name) ||
          _equalsIgnoreCase(t.schemaQualifiedName, id.schemaQualifiedName),
    );
  }

  Future<bool> hasColumn(String table, String column, {String? schema}) async {
    final id = _identifier(table, schema);
    final columns = await driver.listColumns(id.name, schema: id.schema);
    return columns.any((c) => _equalsIgnoreCase(c.name, column));
  }

  Future<String?> columnType(
    String table,
    String column, {
    String? schema,
  }) async {
    final id = _identifier(table, schema);
    final columns = await driver.listColumns(id.name, schema: id.schema);
    final match = columns.firstWhere(
      (c) => _equalsIgnoreCase(c.name, column),
      orElse: () => const SchemaColumn(name: '', dataType: '', tableName: ''),
    );
    return match.name.isEmpty ? null : match.dataType;
  }

  Future<List<String>> tableListing({
    String? schema,
    bool schemaQualified = true,
  }) async {
    final tables = await driver.listTables(schema: schema);
    return tables
        .map(
          (table) => schemaQualified ? table.schemaQualifiedName : table.name,
        )
        .toList(growable: false);
  }

  /// Normalizes [table] and [schema] into a [SchemaTableIdentifier].
  SchemaTableIdentifier _identifier(String table, String? schema) {
    if (schema != null && schema.isNotEmpty) {
      return SchemaTableIdentifier(schema, table);
    }
    final parts = table.split('.');
    if (parts.length == 2) {
      return SchemaTableIdentifier(parts[0], parts[1]);
    }
    return SchemaTableIdentifier(null, table);
  }
}

/// Identifier that pairs a schema with a table name for comparisons.
class SchemaTableIdentifier {
  const SchemaTableIdentifier(this.schema, this.name);

  final String? schema;
  final String name;

  String get schemaQualifiedName => schema == null ? name : '$schema.$name';
}

/// Returns true when [a] and [b] match case-insensitively.
bool _equalsIgnoreCase(String? a, String? b) =>
    a?.toLowerCase() == b?.toLowerCase();
