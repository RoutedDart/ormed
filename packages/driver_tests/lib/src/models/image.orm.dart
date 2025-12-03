// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'image.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ImageIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ImageLabelField = FieldDefinition(
  name: 'label',
  columnName: 'label',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$ImagePrimaryPhotoRelation = RelationDefinition(
  name: 'primaryPhoto',
  kind: RelationKind.morphOne,
  targetModel: 'Photo',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
  morphClass: 'Image',
);

final ModelDefinition<Image> _$ImageModelDefinition = ModelDefinition(
  modelName: 'Image',
  tableName: 'images',
  fields: const [_$ImageIdField, _$ImageLabelField],
  relations: const [_$ImagePrimaryPhotoRelation],
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
  codec: _$ImageModelCodec(),
);

// ignore: unused_element
final imageModelDefinitionRegistration = ModelFactoryRegistry.register<Image>(
  _$ImageModelDefinition,
);

extension ImageOrmDefinition on Image {
  static ModelDefinition<Image> get definition => _$ImageModelDefinition;
}

class Images {
  const Images._();

  static Query<Image> query([String? connection]) =>
      Model.query<Image>(connection: connection);

  static Future<Image?> find(Object id, {String? connection}) =>
      Model.find<Image>(id, connection: connection);

  static Future<Image> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<Image>(id, connection: connection);

  static Future<List<Image>> all({String? connection}) =>
      Model.all<Image>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<Image>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<Image>(connection: connection);

  static Query<Image> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<Image>(column, operator, value, connection: connection);

  static Query<Image> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<Image>(column, values, connection: connection);

  static Query<Image> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<Image>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Image> limit(int count, {String? connection}) =>
      Model.limit<Image>(count, connection: connection);
}

class ImageModelFactory {
  const ImageModelFactory._();

  static ModelDefinition<Image> get definition => _$ImageModelDefinition;

  static ModelCodec<Image> get codec => definition.codec;

  static Image fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Image model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Image> withConnection(QueryContext context) =>
      ModelFactoryConnection<Image>(definition: definition, context: context);

  static ModelFactoryBuilder<Image> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Image>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$ImageModelCodec extends ModelCodec<Image> {
  const _$ImageModelCodec();

  @override
  Map<String, Object?> encode(Image model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ImageIdField, model.id),
      'label': registry.encodeField(_$ImageLabelField, model.label),
    };
  }

  @override
  Image decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int imageIdValue =
        registry.decodeField<int>(_$ImageIdField, data['id']) ??
        (throw StateError('Field id on Image cannot be null.'));
    final String imageLabelValue =
        registry.decodeField<String>(_$ImageLabelField, data['label']) ??
        (throw StateError('Field label on Image cannot be null.'));
    final model = _$ImageModel(id: imageIdValue, label: imageLabelValue);
    model._attachOrmRuntimeMetadata({
      'id': imageIdValue,
      'label': imageLabelValue,
    });
    return model;
  }
}

class _$ImageModel extends Image {
  _$ImageModel({required int id, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get label => getAttribute<String>('label') ?? super.label;

  set label(String value) => setAttribute('label', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ImageModelDefinition);
  }

  @override
  Photo? get primaryPhoto {
    if (relationLoaded('primaryPhoto')) {
      return getRelation<Photo>('primaryPhoto');
    }
    return super.primaryPhoto;
  }
}

extension ImageRelationQueries on Image {
  Query<Photo> primaryPhotoQuery() {
    throw UnimplementedError(
      "Polymorphic relation query generation not yet supported",
    );
  }
}
