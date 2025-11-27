// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'photo.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PhotoIdField = FieldDefinition(
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

const FieldDefinition _$PhotoImageableIdField = FieldDefinition(
  name: 'imageableId',
  columnName: 'imageable_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PhotoImageableTypeField = FieldDefinition(
  name: 'imageableType',
  columnName: 'imageable_type',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PhotoPathField = FieldDefinition(
  name: 'path',
  columnName: 'path',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Photo> _$PhotoModelDefinition = ModelDefinition(
  modelName: 'Photo',
  tableName: 'photos',
  fields: const [
    _$PhotoIdField,
    _$PhotoImageableIdField,
    _$PhotoImageableTypeField,
    _$PhotoPathField,
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
  codec: _$PhotoModelCodec(),
);

// ignore: unused_element
final _PhotoModelDefinitionRegistration = ModelFactoryRegistry.register<Photo>(
  _$PhotoModelDefinition,
);

extension PhotoOrmDefinition on Photo {
  static ModelDefinition<Photo> get definition => _$PhotoModelDefinition;
}

class PhotoModelFactory {
  const PhotoModelFactory._();

  static ModelDefinition<Photo> get definition => PhotoOrmDefinition.definition;

  static ModelCodec<Photo> get codec => definition.codec;

  static Photo fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Photo model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Photo> withConnection(QueryContext context) =>
      ModelFactoryConnection<Photo>(definition: definition, context: context);

  static ModelFactoryBuilder<Photo> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Photo>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

extension PhotoModelFactoryExtension on Photo {
  static ModelFactoryBuilder<Photo> factory({
    GeneratorProvider? generatorProvider,
  }) => PhotoModelFactory.factory(generatorProvider: generatorProvider);
}

class _$PhotoModelCodec extends ModelCodec<Photo> {
  const _$PhotoModelCodec();

  @override
  Map<String, Object?> encode(Photo model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$PhotoIdField, model.id),
      'imageable_id': registry.encodeField(
        _$PhotoImageableIdField,
        model.imageableId,
      ),
      'imageable_type': registry.encodeField(
        _$PhotoImageableTypeField,
        model.imageableType,
      ),
      'path': registry.encodeField(_$PhotoPathField, model.path),
    };
  }

  @override
  Photo decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int photoIdValue =
        registry.decodeField<int>(_$PhotoIdField, data['id']) ??
        (throw StateError('Field id on Photo cannot be null.'));
    final int photoImageableIdValue =
        registry.decodeField<int>(
          _$PhotoImageableIdField,
          data['imageable_id'],
        ) ??
        (throw StateError('Field imageableId on Photo cannot be null.'));
    final String photoImageableTypeValue =
        registry.decodeField<String>(
          _$PhotoImageableTypeField,
          data['imageable_type'],
        ) ??
        (throw StateError('Field imageableType on Photo cannot be null.'));
    final String photoPathValue =
        registry.decodeField<String>(_$PhotoPathField, data['path']) ??
        (throw StateError('Field path on Photo cannot be null.'));
    final model = _$PhotoModel(
      id: photoIdValue,
      imageableId: photoImageableIdValue,
      imageableType: photoImageableTypeValue,
      path: photoPathValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': photoIdValue,
      'imageable_id': photoImageableIdValue,
      'imageable_type': photoImageableTypeValue,
      'path': photoPathValue,
    });
    return model;
  }
}

class _$PhotoModel extends Photo {
  _$PhotoModel({
    required int id,
    required int imageableId,
    required String imageableType,
    required String path,
  }) : super(
         id: id,
         imageableId: imageableId,
         imageableType: imageableType,
         path: path,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'imageable_id': imageableId,
      'imageable_type': imageableType,
      'path': path,
    });
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  int get imageableId => getAttribute<int>('imageable_id') ?? super.imageableId;

  set imageableId(int value) => setAttribute('imageable_id', value);

  @override
  String get imageableType =>
      getAttribute<String>('imageable_type') ?? super.imageableType;

  set imageableType(String value) => setAttribute('imageable_type', value);

  @override
  String get path => getAttribute<String>('path') ?? super.path;

  set path(String value) => setAttribute('path', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PhotoModelDefinition);
  }
}

extension PhotoAttributeSetters on Photo {
  set id(int value) => setAttribute('id', value);
  set imageableId(int value) => setAttribute('imageable_id', value);
  set imageableType(String value) => setAttribute('imageable_type', value);
  set path(String value) => setAttribute('path', value);
}
