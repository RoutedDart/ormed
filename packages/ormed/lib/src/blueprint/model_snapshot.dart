import 'package:collection/collection.dart';
import 'package:ormed/ormed.dart';

/// Captures the tables derived from the current [ModelDefinition] registry.
class ModelGraphSnapshot {
  ModelGraphSnapshot(Iterable<ModelDefinition<dynamic>> definitions)
    : tables = List.unmodifiable(
        definitions.map(ModelTableSnapshot.fromDefinition),
      );

  final List<ModelTableSnapshot> tables;

  ModelTableSnapshot? tableByName(String table) =>
      tables.firstWhereOrNull((value) => value.tableName == table);
}

/// Snapshot of a single model's table shape.
class ModelTableSnapshot {
  ModelTableSnapshot({
    required this.modelName,
    required this.tableName,
    required this.schema,
    required this.columns,
  });

  factory ModelTableSnapshot.fromDefinition(
    ModelDefinition<dynamic> definition,
  ) {
    final columns = definition.fields
        .map(
          (field) => ModelColumnSnapshot(
            name: field.name,
            columnName: field.columnName,
            resolvedType: field.resolvedType,
            columnType: field.columnType,
            isNullable: field.isNullable,
            isPrimaryKey: field.isPrimaryKey,
            isUnique: field.isUnique,
            isIndexed: field.isIndexed,
            autoIncrement: field.autoIncrement,
          ),
        )
        .toList(growable: false);

    return ModelTableSnapshot(
      modelName: definition.modelName,
      tableName: definition.tableName,
      schema: definition.schema,
      columns: columns,
    );
  }

  final String modelName;
  final String tableName;
  final String? schema;
  final List<ModelColumnSnapshot> columns;

  /// Produces a [TableBlueprint] that mirrors the current model definition.
  TableBlueprint toCreateBlueprint() {
    final blueprint = TableBlueprint.create(tableName);
    for (final column in columns) {
      final builder = blueprint.column(
        column.columnName,
        column.effectiveColumnType(),
      );
      if (column.isNullable) {
        builder.nullable();
      }
      if (column.isUnique) {
        builder.unique();
      }
      if (column.isIndexed) {
        builder.indexed();
      }
      if (column.isPrimaryKey) {
        builder.primaryKey();
      }
      if (column.autoIncrement) {
        builder.autoIncrement();
      }
    }
    return blueprint;
  }
}

/// Snapshot of a single column derived from a model field.
class ModelColumnSnapshot {
  ModelColumnSnapshot({
    required this.name,
    required this.columnName,
    required this.resolvedType,
    required this.columnType,
    required this.isNullable,
    required this.isPrimaryKey,
    required this.isUnique,
    required this.isIndexed,
    required this.autoIncrement,
  });

  final String name;
  final String columnName;
  final String resolvedType;
  final String? columnType;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isUnique;
  final bool isIndexed;
  final bool autoIncrement;

  ColumnType effectiveColumnType() {
    if (columnType != null && columnType!.isNotEmpty) {
      return ColumnType.custom(columnType!);
    }

    switch (resolvedType) {
      case 'int':
      case 'int?':
        return const ColumnType.integer();
      case 'double':
      case 'double?':
        return const ColumnType.decimal();
      case 'String':
      case 'String?':
        return const ColumnType.string();
      case 'DateTime':
      case 'DateTime?':
        return const ColumnType.timestamp(timezoneAware: true);
      case 'bool':
      case 'bool?':
        return const ColumnType.boolean();
      default:
        return const ColumnType.json();
    }
  }
}
