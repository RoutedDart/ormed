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

class Tags {
  const Tags._();

  static Query<Tag> query([String? connection]) =>
      Model.query<Tag>(connection: connection);

  static Future<Tag?> find(Object id, {String? connection}) =>
      Model.find<Tag>(id, connection: connection);

  static Future<Tag> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<Tag>(id, connection: connection);

  static Future<List<Tag>> all({String? connection}) =>
      Model.all<Tag>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<Tag>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<Tag>(connection: connection);

  static Query<Tag> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<Tag>(column, operator, value, connection: connection);

  static Query<Tag> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<Tag>(column, values, connection: connection);

  static Query<Tag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) =>
      Model.orderBy<Tag>(column, direction: direction, connection: connection);

  static Query<Tag> limit(int count, {String? connection}) =>
      Model.limit<Tag>(count, connection: connection);
}

class TagModelFactory {
  const TagModelFactory._();

  static ModelDefinition<Tag> get definition => _$TagModelDefinition;

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

  static ModelFactoryBuilder<Tag> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Tag>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
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

class _$TagModel extends Tag {
  _$TagModel({
    int? id,
    required String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         name: name,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  set name(String value) => setAttribute('name', value);

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  set createdAt(DateTime? value) => setAttribute('created_at', value);

  @override
  DateTime? get updatedAt =>
      getAttribute<DateTime?>('updated_at') ?? super.updatedAt;

  set updatedAt(DateTime? value) => setAttribute('updated_at', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TagModelDefinition);
  }
}

extension TagAttributeSetters on Tag {
  set id(int? value) => setAttribute('id', value);
  set name(String value) => setAttribute('name', value);
  set createdAt(DateTime? value) => setAttribute('created_at', value);
  set updatedAt(DateTime? value) => setAttribute('updated_at', value);
}
