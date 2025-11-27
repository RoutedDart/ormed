// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'tag.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$TagIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TagNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TagCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'created_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TagUpdatedAtField = FieldDefinition(
  name: 'updatedAt',
  columnName: 'updated_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Tag> _$TagModelDefinition = ModelDefinition(
  modelName: 'Tag',
  tableName: 'tags',
  fields: const [
    _$TagIdField,
    _$TagNameField,
    _$TagCreatedAtField,
    _$TagUpdatedAtField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$TagModelCodec(),
);

extension TagOrmDefinition on Tag {
  static ModelDefinition<Tag> get definition => _$TagModelDefinition;
}

class TagModelFactory {
  const TagModelFactory._();

  static ModelDefinition<Tag> get definition => TagOrmDefinition.definition;

  static ModelCodec<Tag> get codec => definition.codec;

  static Tag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Tag model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Tag> withConnection(QueryContext context) =>
      ModelFactoryConnection<Tag>(definition: definition, context: context);
}

class _$TagModelCodec extends ModelCodec<Tag> {
  const _$TagModelCodec();

  @override
  Map<String, Object?> encode(Tag model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$TagIdField, model.id),
      'name': registry.encodeField(_$TagNameField, model.name),
      'created_at': registry.encodeField(_$TagCreatedAtField, model.createdAt),
      'updated_at': registry.encodeField(_$TagUpdatedAtField, model.updatedAt),
    };
  }

  @override
  Tag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? tagIdValue = registry.decodeField<int?>(
      _$TagIdField,
      data['id'],
    );
    final String tagNameValue =
        registry.decodeField<String>(_$TagNameField, data['name']) ??
        (throw StateError('Field name on Tag cannot be null.'));
    final DateTime? tagCreatedAtValue = registry.decodeField<DateTime?>(
      _$TagCreatedAtField,
      data['created_at'],
    );
    final DateTime? tagUpdatedAtValue = registry.decodeField<DateTime?>(
      _$TagUpdatedAtField,
      data['updated_at'],
    );
    final model = _$TagModel(
      id: tagIdValue,
      name: tagNameValue,
      createdAt: tagCreatedAtValue,
      updatedAt: tagUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': tagIdValue,
      'name': tagNameValue,
      'created_at': tagCreatedAtValue,
      'updated_at': tagUpdatedAtValue,
    });
    return model;
  }
}

class _$TagModel extends Tag with ModelAttributes, ModelConnection {
  _$TagModel({
    int? id,
    required String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(id: id, name: name, createdAt: createdAt, updatedAt: updatedAt) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  @override
  DateTime? get updatedAt =>
      getAttribute<DateTime?>('updated_at') ?? super.updatedAt;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TagModelDefinition);
  }
}
