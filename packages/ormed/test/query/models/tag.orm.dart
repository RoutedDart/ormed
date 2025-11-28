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
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TagLabelField = FieldDefinition(
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

const RelationDefinition _$TagPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.manyToMany,
  targetModel: 'Post',
  through: 'post_tags',
  pivotForeignKey: 'tag_id',
  pivotRelatedKey: 'post_id',
);

final ModelDefinition<Tag> _$TagModelDefinition = ModelDefinition(
  modelName: 'Tag',
  tableName: 'tags',
  fields: const [_$TagIdField, _$TagLabelField],
  relations: const [_$TagPostsRelation],
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

class _$TagModelCodec extends ModelCodec<Tag> {
  const _$TagModelCodec();

  @override
  Map<String, Object?> encode(Tag model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$TagIdField, model.id),
      'label': registry.encodeField(_$TagLabelField, model.label),
    };
  }

  @override
  Tag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int tagIdValue =
        registry.decodeField<int>(_$TagIdField, data['id']) ??
        (throw StateError('Field id on Tag cannot be null.'));
    final String tagLabelValue =
        registry.decodeField<String>(_$TagLabelField, data['label']) ??
        (throw StateError('Field label on Tag cannot be null.'));
    final model = _$TagModel(id: tagIdValue, label: tagLabelValue);
    model._attachOrmRuntimeMetadata({'id': tagIdValue, 'label': tagLabelValue});
    return model;
  }
}

class _$TagModel extends Tag with ModelAttributes, ModelConnection {
  _$TagModel({required int id, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  @override
  String get label => getAttribute<String>('label') ?? super.label;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TagModelDefinition);
  }
}
