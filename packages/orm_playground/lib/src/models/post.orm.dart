// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'post.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PostIdField = FieldDefinition(
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

const FieldDefinition _$PostUserIdField = FieldDefinition(
  name: 'userId',
  columnName: 'user_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTitleField = FieldDefinition(
  name: 'title',
  columnName: 'title',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostBodyField = FieldDefinition(
  name: 'body',
  columnName: 'body',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostPublishedField = FieldDefinition(
  name: 'published',
  columnName: 'published',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostPublishedAtField = FieldDefinition(
  name: 'publishedAt',
  columnName: 'published_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostCreatedAtField = FieldDefinition(
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

const FieldDefinition _$PostUpdatedAtField = FieldDefinition(
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

const RelationDefinition _$PostAuthorRelation = RelationDefinition(
  name: 'author',
  kind: RelationKind.belongsTo,
  targetModel: 'User',
  foreignKey: 'user_id',
  localKey: 'id',
);

const RelationDefinition _$PostTagsRelation = RelationDefinition(
  name: 'tags',
  kind: RelationKind.manyToMany,
  targetModel: 'Tag',
  through: 'post_tags',
  pivotForeignKey: 'post_id',
  pivotRelatedKey: 'tag_id',
);

const RelationDefinition _$PostCommentsRelation = RelationDefinition(
  name: 'comments',
  kind: RelationKind.hasMany,
  targetModel: 'Comment',
  foreignKey: 'post_id',
  localKey: 'id',
);

final ModelDefinition<Post> _$PostModelDefinition = ModelDefinition(
  modelName: 'Post',
  tableName: 'posts',
  fields: const [
    _$PostIdField,
    _$PostUserIdField,
    _$PostTitleField,
    _$PostBodyField,
    _$PostPublishedField,
    _$PostPublishedAtField,
    _$PostCreatedAtField,
    _$PostUpdatedAtField,
  ],
  relations: const [
    _$PostAuthorRelation,
    _$PostTagsRelation,
    _$PostCommentsRelation,
  ],
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
  codec: _$PostModelCodec(),
);

extension PostOrmDefinition on Post {
  static ModelDefinition<Post> get definition => _$PostModelDefinition;
}

class PostModelFactory {
  const PostModelFactory._();

  static ModelDefinition<Post> get definition => PostOrmDefinition.definition;

  static ModelCodec<Post> get codec => definition.codec;

  static Post fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Post model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Post> withConnection(QueryContext context) =>
      ModelFactoryConnection<Post>(definition: definition, context: context);
}

class _$PostModelCodec extends ModelCodec<Post> {
  const _$PostModelCodec();

  @override
  Map<String, Object?> encode(Post model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$PostIdField, model.id),
      'user_id': registry.encodeField(_$PostUserIdField, model.userId),
      'title': registry.encodeField(_$PostTitleField, model.title),
      'body': registry.encodeField(_$PostBodyField, model.body),
      'published': registry.encodeField(_$PostPublishedField, model.published),
      'published_at': registry.encodeField(
        _$PostPublishedAtField,
        model.publishedAt,
      ),
      'created_at': registry.encodeField(_$PostCreatedAtField, model.createdAt),
      'updated_at': registry.encodeField(_$PostUpdatedAtField, model.updatedAt),
    };
  }

  @override
  Post decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? postIdValue = registry.decodeField<int?>(
      _$PostIdField,
      data['id'],
    );
    final int postUserIdValue =
        registry.decodeField<int>(_$PostUserIdField, data['user_id']) ??
        (throw StateError('Field userId on Post cannot be null.'));
    final String postTitleValue =
        registry.decodeField<String>(_$PostTitleField, data['title']) ??
        (throw StateError('Field title on Post cannot be null.'));
    final String? postBodyValue = registry.decodeField<String?>(
      _$PostBodyField,
      data['body'],
    );
    final bool postPublishedValue =
        registry.decodeField<bool>(_$PostPublishedField, data['published']) ??
        (throw StateError('Field published on Post cannot be null.'));
    final DateTime? postPublishedAtValue = registry.decodeField<DateTime?>(
      _$PostPublishedAtField,
      data['published_at'],
    );
    final DateTime? postCreatedAtValue = registry.decodeField<DateTime?>(
      _$PostCreatedAtField,
      data['created_at'],
    );
    final DateTime? postUpdatedAtValue = registry.decodeField<DateTime?>(
      _$PostUpdatedAtField,
      data['updated_at'],
    );
    final model = _$PostModel(
      id: postIdValue,
      userId: postUserIdValue,
      title: postTitleValue,
      body: postBodyValue,
      published: postPublishedValue,
      publishedAt: postPublishedAtValue,
      createdAt: postCreatedAtValue,
      updatedAt: postUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': postIdValue,
      'user_id': postUserIdValue,
      'title': postTitleValue,
      'body': postBodyValue,
      'published': postPublishedValue,
      'published_at': postPublishedAtValue,
      'created_at': postCreatedAtValue,
      'updated_at': postUpdatedAtValue,
    });
    return model;
  }
}

class _$PostModel extends Post with ModelAttributes, ModelConnection {
  _$PostModel({
    int? id,
    required int userId,
    required String title,
    String? body,
    bool published = false,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
         id: id,
         userId: userId,
         title: title,
         body: body,
         published: published,
         publishedAt: publishedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'published': published,
      'published_at': publishedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  @override
  int get userId => getAttribute<int>('user_id') ?? super.userId;

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  @override
  String? get body => getAttribute<String?>('body') ?? super.body;

  @override
  bool get published => getAttribute<bool>('published') ?? super.published;

  @override
  DateTime? get publishedAt =>
      getAttribute<DateTime?>('published_at') ?? super.publishedAt;

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  @override
  DateTime? get updatedAt =>
      getAttribute<DateTime?>('updated_at') ?? super.updatedAt;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostModelDefinition);
  }
}
