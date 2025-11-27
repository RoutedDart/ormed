import 'package:collection/collection.dart';

import 'annotations.dart';
import 'model_mixins/model_attributes.dart';
import 'value_codec.dart';

/// Runtime description of a generated ORM model.
class ModelDefinition<TModel> {
  const ModelDefinition({
    required this.modelName,
    required this.tableName,
    required this.fields,
    required this.codec,
    this.schema,
    this.relations = const [],
    this.softDeleteColumn,
    this.metadata = const ModelAttributesMetadata(),
  });

  final String modelName;
  final String tableName;
  final String? schema;
  final List<FieldDefinition> fields;
  final List<RelationDefinition> relations;
  final ModelCodec<TModel> codec;
  final String? softDeleteColumn;
  final ModelAttributesMetadata metadata;

  Type get modelType => TModel;

  FieldDefinition? fieldByName(String name) =>
      fields.firstWhereOrNull((field) => field.name == name);

  FieldDefinition? fieldByColumn(String column) =>
      fields.firstWhereOrNull((field) => field.columnName == column);

  FieldDefinition? get primaryKeyField =>
      fields.firstWhereOrNull((field) => field.isPrimaryKey);

  bool get usesSoftDeletes => softDeleteField != null;

  FieldDefinition? get softDeleteField {
    if (softDeleteColumn == null) return null;
    return fields.firstWhereOrNull(
      (field) =>
          field.columnName == softDeleteColumn ||
          field.name == softDeleteColumn,
    );
  }

  Map<String, Object?> toMap(TModel model, {ValueCodecRegistry? registry}) =>
      codec.encode(model, registry ?? ValueCodecRegistry.standard());

  TModel fromMap(Map<String, Object?> data, {ValueCodecRegistry? registry}) {
    final model = codec.decode(data, registry ?? ValueCodecRegistry.standard());
    if (model is ModelAttributes) {
      model.attachModelDefinition(this);
      if (usesSoftDeletes) {
        model.attachSoftDeleteColumn(metadata.softDeleteColumn);
      }
    }
    return model;
  }

  ModelDefinition<TModel> copyWith({
    String? modelName,
    String? tableName,
    String? schema,
    List<FieldDefinition>? fields,
    List<RelationDefinition>? relations,
    ModelCodec<TModel>? codec,
    String? softDeleteColumn,
    ModelAttributesMetadata? metadata,
  }) => ModelDefinition<TModel>(
    modelName: modelName ?? this.modelName,
    tableName: tableName ?? this.tableName,
    schema: schema ?? this.schema,
    fields: fields ?? this.fields,
    relations: relations ?? this.relations,
    codec: codec ?? this.codec,
    softDeleteColumn: softDeleteColumn ?? this.softDeleteColumn,
    metadata: metadata ?? this.metadata,
  );
}

/// Annotation-driven metadata for attribute behavior.
class ModelAttributesMetadata {
  const ModelAttributesMetadata({
    this.hidden = const <String>[],
    this.visible = const <String>[],
    this.fillable = const <String>[],
    this.guarded = const <String>[],
    this.casts = const <String, String>{},
    this.fieldOverrides = const {},
    this.connection,
    this.softDeletes = false,
    this.softDeleteColumn = 'deleted_at',
    this.driverAnnotations = const <Object>[],
  });

  final List<String> hidden;
  final List<String> visible;
  final List<String> fillable;
  final List<String> guarded;
  final Map<String, String> casts;
  final Map<String, FieldAttributeMetadata> fieldOverrides;
  final String? connection;
  final bool softDeletes;
  final String softDeleteColumn;
  final List<Object> driverAnnotations;

  ModelAttributesMetadata copyWith({
    List<String>? hidden,
    List<String>? visible,
    List<String>? fillable,
    List<String>? guarded,
    Map<String, String>? casts,
    Map<String, FieldAttributeMetadata>? fieldOverrides,
    String? connection,
    bool? softDeletes,
    String? softDeleteColumn,
    List<Object>? driverAnnotations,
  }) => ModelAttributesMetadata(
    hidden: hidden ?? this.hidden,
    visible: visible ?? this.visible,
    fillable: fillable ?? this.fillable,
    guarded: guarded ?? this.guarded,
    casts: casts ?? this.casts,
    fieldOverrides: fieldOverrides ?? this.fieldOverrides,
    connection: connection ?? this.connection,
    softDeletes: softDeletes ?? this.softDeletes,
    softDeleteColumn: softDeleteColumn ?? this.softDeleteColumn,
    driverAnnotations: driverAnnotations ?? this.driverAnnotations,
  );
}

class FieldAttributeMetadata {
  const FieldAttributeMetadata({
    this.fillable,
    this.guarded,
    this.hidden,
    this.visible,
    this.cast,
  });

  final bool? fillable;
  final bool? guarded;
  final bool? hidden;
  final bool? visible;
  final String? cast;
}

/// Metadata for a single model field/column.
class FieldDefinition {
  const FieldDefinition({
    required this.name,
    required this.columnName,
    required this.dartType,
    required this.resolvedType,
    required this.isPrimaryKey,
    required this.isNullable,
    this.isUnique = false,
    this.isIndexed = false,
    this.autoIncrement = false,
    this.columnType,
    this.defaultValueSql,
    this.codecType,
    this.driverOverrides = const {},
  });

  final String name;
  final String columnName;
  final String dartType;
  final String resolvedType;
  final bool isPrimaryKey;
  final bool isNullable;
  final bool isUnique;
  final bool isIndexed;
  final bool autoIncrement;
  final String? columnType;
  final String? defaultValueSql;
  final String? codecType;
  final Map<String, FieldDriverOverride> driverOverrides;

  FieldDriverOverride? overrideFor(String? driver) {
    if (driver == null) return null;
    final normalized = _normalizeDriver(driver);
    return driverOverrides[normalized];
  }

  String? columnTypeForDriver(String? driver) =>
      overrideFor(driver)?.columnType ?? columnType;

  String? defaultValueSqlForDriver(String? driver) =>
      overrideFor(driver)?.defaultValueSql ?? defaultValueSql;

  String? codecTypeForDriver(String? driver) =>
      overrideFor(driver)?.codecType ?? codecType;
}

/// Driver-specific metadata for a field definition.
class FieldDriverOverride {
  const FieldDriverOverride({
    this.columnType,
    this.defaultValueSql,
    this.codecType,
  });

  final String? columnType;
  final String? defaultValueSql;
  final String? codecType;
}

String _normalizeDriver(String driver) => driver.trim().toLowerCase();

/// Metadata for a relationship between two models.
class RelationDefinition {
  const RelationDefinition({
    required this.name,
    required this.kind,
    required this.targetModel,
    this.foreignKey,
    this.localKey,
    this.through,
    this.pivotForeignKey,
    this.pivotRelatedKey,
    this.morphType,
    this.morphClass,
  });

  final String name;
  final RelationKind kind;
  final String targetModel;
  final String? foreignKey;
  final String? localKey;
  final String? through;
  final String? pivotForeignKey;
  final String? pivotRelatedKey;
  final String? morphType;
  final String? morphClass;
}

/// Base contract for generated model codecs.
abstract class ModelCodec<TModel> {
  const ModelCodec();

  Map<String, Object?> encode(TModel model, ValueCodecRegistry registry);
  TModel decode(Map<String, Object?> data, ValueCodecRegistry registry);
}

class AdHocModelDefinition extends ModelDefinition<Map<String, Object?>> {
  AdHocModelDefinition({
    required super.tableName,
    super.schema,
    this.alias,
    List<AdHocColumn> columns = const [],
  }) : _fields = <String, FieldDefinition>{},
       super(
         modelName: 'AdHoc<$tableName>',
         fields: const [],
         codec: const _MapModelCodec(),
       ) {
    for (final column in columns) {
      registerColumn(column);
    }
  }

  final String? alias;
  final Map<String, FieldDefinition> _fields;

  FieldDefinition fieldFor(String name) {
    final existing = _fields[name];
    if (existing != null) {
      return existing;
    }
    final definition = FieldDefinition(
      name: name,
      columnName: name,
      dartType: 'Object?',
      resolvedType: 'Object?',
      isPrimaryKey: false,
      isNullable: true,
    );
    _registerField(definition, name);
    return definition;
  }

  void registerColumn(AdHocColumn column) {
    final definition = FieldDefinition(
      name: column.name,
      columnName: column.columnName ?? column.name,
      dartType: column.dartType ?? 'Object?',
      resolvedType: column.resolvedType ?? column.dartType ?? 'Object?',
      isPrimaryKey: column.isPrimaryKey,
      isNullable: column.isNullable,
      columnType: column.columnType,
      defaultValueSql: column.defaultValueSql,
    );
    _registerField(definition, column.name);
    if (column.columnName != null && column.columnName != column.name) {
      _fields[column.columnName!] = definition;
    }
  }

  void _registerField(FieldDefinition field, String key) {
    _fields[key] = field;
  }
}

class AdHocColumn {
  const AdHocColumn({
    required this.name,
    this.columnName,
    this.dartType,
    this.resolvedType,
    this.columnType,
    this.defaultValueSql,
    this.isNullable = true,
    this.isPrimaryKey = false,
  });

  final String name;
  final String? columnName;
  final String? dartType;
  final String? resolvedType;
  final String? columnType;
  final String? defaultValueSql;
  final bool isNullable;
  final bool isPrimaryKey;
}

class _MapModelCodec extends ModelCodec<Map<String, Object?>> {
  const _MapModelCodec();

  @override
  Map<String, Object?> encode(
    Map<String, Object?> model,
    ValueCodecRegistry registry,
  ) => Map<String, Object?>.from(model);

  @override
  Map<String, Object?> decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) => Map<String, Object?>.from(data);
}
