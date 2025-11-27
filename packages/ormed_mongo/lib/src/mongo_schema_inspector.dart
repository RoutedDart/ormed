import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';

import 'mongo_driver.dart';

/// Inspects MongoDB collections/indexes and (optionally) field-level metadata.
class MongoSchemaInspector {
  MongoSchemaInspector(this._driver);

  final MongoDriverAdapter _driver;

  Future<Db> _database() async {
    return await _driver.databaseInstance();
  }

  Future<List<SchemaTable>> listTables() async {
    final db = await _database();
    final infos = await db.getCollectionInfos();
    return Future.wait(
      infos.map(
        (info) async => _tableFromInfo(info, await _fieldsForInfo(info)),
      ),
    );
  }

  Future<List<SchemaColumn>> listColumns(String collectionName) async {
    final db = await _database();
    final collection = db.collection(collectionName);
    final doc = await collection.findOne();
    if (doc == null) {
      return const [];
    }
    return _columnsFromDocument(collectionName, doc);
  }

  Future<List<SchemaIndex>> listIndexes(String collectionName) async {
    final db = await _database();
    final collection = db.collection(collectionName);
    final indexes = await collection.listIndexes().toList();
    return indexes
        .map((doc) => _indexFromDoc(doc, collectionName))
        .where((index) => index != null)
        .cast<SchemaIndex>()
        .toList(growable: false);
  }

  Future<List<SchemaColumn>> _fieldsForInfo(Map<String, Object?> info) async {
    final validator =
        (info['options'] as Map<String, Object?>?)?['validator']
            as Map<String, Object?>?;
    final columns = _columnsFromValidator(info, validator);
    if (columns.isNotEmpty) return columns;
    final collection = (info['name'] as String?)?.split('.').last ?? '';
    if (collection.isEmpty) return columns;
    return listColumns(collection);
  }

  SchemaTable _tableFromInfo(
    Map<String, Object?> info,
    List<SchemaColumn> fields,
  ) {
    final fullName = info['name'] as String? ?? '';
    final parts = fullName.split('.');
    final name = parts.length == 2 ? parts.last : fullName;
    final schema = parts.length == 2 ? parts.first : null;
    final options = info['options'] as Map<String, Object?>?;
    return SchemaTable(
      name: name,
      schema: schema,
      type: info['type'] as String?,
      comment: _descriptionFromOptions(options),
      fields: fields,
    );
  }

  List<SchemaColumn> _columnsFromValidator(
    Map<String, Object?> info,
    Map<String, Object?>? validator,
  ) {
    final jsonSchema = validator?['\$jsonSchema'] as Map<String, Object?>?;
    final properties = jsonSchema?['properties'] as Map<String, Object?>?;
    if (properties == null) {
      return const [];
    }
    final required = (jsonSchema?['required'] as List?)?.cast<String>() ?? [];
    final collectionName = (info['name'] as String?)?.split('.').last ?? '';
    return properties.entries
        .map(
          (entry) => _columnFromProperty(
            collectionName,
            entry.key,
            entry.value as Map<String, Object?>,
            required.contains(entry.key),
          ),
        )
        .toList(growable: false);
  }

  List<SchemaColumn> _columnsFromDocument(
    String table,
    Map<String, Object?> doc,
  ) => doc.entries
      .where((entry) => entry.key != '_id')
      .map(
        (entry) => SchemaColumn(
          name: entry.key,
          dataType: entry.value?.runtimeType.toString() ?? 'Object',
          tableName: table,
          nullable: entry.value == null,
        ),
      )
      .toList(growable: false);

  SchemaColumn _columnFromProperty(
    String table,
    String name,
    Map<String, Object?> property,
    bool required,
  ) {
    final bsonType = property['bsonType'] ?? property['type'];
    return SchemaColumn(
      name: name,
      dataType: bsonType?.toString() ?? 'Object',
      tableName: table,
      nullable: !required,
      comment: property['description'] as String?,
    );
  }

  SchemaIndex? _indexFromDoc(Map<String, Object?> doc, String table) {
    final key = doc['key'] as Map<String, Object?>?;
    if (key == null) return null;
    final columns = key.keys.map((segment) => segment.toString()).toList();
    return SchemaIndex(
      name: doc['name'] as String? ?? '',
      columns: columns,
      tableName: table,
      unique: doc['unique'] as bool? ?? false,
      primary: doc['name'] == '_id_',
      whereClause: doc['partialFilterExpression']?.toString(),
    );
  }

  String? _descriptionFromOptions(Map<String, Object?>? options) {
    if (options == null) return null;
    final validator = options['validator'];
    if (validator != null) {
      return validator.toString();
    }
    return null;
  }
}
