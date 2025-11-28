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

extension ImageOrmDefinition on Image {
  static ModelDefinition<Image> get definition => _$ImageModelDefinition;
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

class _$ImageModel extends Image with ModelAttributes, ModelConnection {
  _$ImageModel({required int id, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  @override
  String get label => getAttribute<String>('label') ?? super.label;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ImageModelDefinition);
  }
}
