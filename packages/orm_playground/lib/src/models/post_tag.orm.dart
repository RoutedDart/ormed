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

class PostTags {
  const PostTags._();

  static Query<PostTag> query([String? connection]) =>
      Model.query<PostTag>(connection: connection);

  static Future<PostTag?> find(Object id, {String? connection}) =>
      Model.find<PostTag>(id, connection: connection);

  static Future<PostTag> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<PostTag>(id, connection: connection);

  static Future<List<PostTag>> all({String? connection}) =>
      Model.all<PostTag>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<PostTag>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<PostTag>(connection: connection);

  static Query<PostTag> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<PostTag>(column, operator, value, connection: connection);

  static Query<PostTag> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<PostTag>(column, values, connection: connection);

  static Query<PostTag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<PostTag>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<PostTag> limit(int count, {String? connection}) =>
      Model.limit<PostTag>(count, connection: connection);
}

class PostTagModelFactory {
  const PostTagModelFactory._();

  static ModelDefinition<PostTag> get definition => _$PostTagModelDefinition;

  static ModelCodec<PostTag> get codec => definition.codec;

  static PostTag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    PostTag model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<PostTag> withConnection(QueryContext context) =>
      ModelFactoryConnection<PostTag>(definition: definition, context: context);

  static ModelFactoryBuilder<PostTag> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<PostTag>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
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

class _$PostTagModel extends PostTag {
  _$PostTagModel({required int postId, required int tagId})
    : super.new(postId: postId, tagId: tagId) {
    _attachOrmRuntimeMetadata({'post_id': postId, 'tag_id': tagId});
  }

  @override
  int get postId => getAttribute<int>('post_id') ?? super.postId;

  set postId(int value) => setAttribute('post_id', value);

  @override
  int get tagId => getAttribute<int>('tag_id') ?? super.tagId;

  set tagId(int value) => setAttribute('tag_id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostTagModelDefinition);
  }
}
