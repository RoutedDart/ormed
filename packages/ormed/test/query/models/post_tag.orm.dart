// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'post_tag.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PostTagPostIdField = FieldDefinition(
  name: 'postId',
  columnName: 'post_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTagTagIdField = FieldDefinition(
  name: 'tagId',
  columnName: 'tag_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<PostTag> _$PostTagModelDefinition = ModelDefinition(
  modelName: 'PostTag',
  tableName: 'post_tags',
  fields: const [_$PostTagPostIdField, _$PostTagTagIdField],
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
  codec: _$PostTagModelCodec(),
);

extension PostTagOrmDefinition on PostTag {
  static ModelDefinition<PostTag> get definition => _$PostTagModelDefinition;
}

class _$PostTagModelCodec extends ModelCodec<PostTag> {
  const _$PostTagModelCodec();

  @override
  Map<String, Object?> encode(PostTag model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'post_id': registry.encodeField(_$PostTagPostIdField, model.postId),
      'tag_id': registry.encodeField(_$PostTagTagIdField, model.tagId),
    };
  }

  @override
  PostTag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int postTagPostIdValue =
        registry.decodeField<int>(_$PostTagPostIdField, data['post_id']) ??
        (throw StateError('Field postId on PostTag cannot be null.'));
    final int postTagTagIdValue =
        registry.decodeField<int>(_$PostTagTagIdField, data['tag_id']) ??
        (throw StateError('Field tagId on PostTag cannot be null.'));
    final model = _$PostTagModel(
      postId: postTagPostIdValue,
      tagId: postTagTagIdValue,
    );
    model._attachOrmRuntimeMetadata({
      'post_id': postTagPostIdValue,
      'tag_id': postTagTagIdValue,
    });
    return model;
  }
}

class _$PostTagModel extends PostTag with ModelAttributes, ModelConnection {
  _$PostTagModel({required int postId, required int tagId})
    : super(postId: postId, tagId: tagId) {
    _attachOrmRuntimeMetadata({'post_id': postId, 'tag_id': tagId});
  }

  @override
  int get postId => getAttribute<int>('post_id') ?? super.postId;

  @override
  int get tagId => getAttribute<int>('tag_id') ?? super.tagId;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostTagModelDefinition);
  }
}
