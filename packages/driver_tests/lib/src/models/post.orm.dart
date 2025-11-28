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
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostAuthorIdField = FieldDefinition(
  name: 'authorId',
  columnName: 'author_id',
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

const FieldDefinition _$PostContentField = FieldDefinition(
  name: 'content',
  columnName: 'content',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostViewsField = FieldDefinition(
  name: 'views',
  columnName: 'views',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostPublishedAtField = FieldDefinition(
  name: 'publishedAt',
  columnName: 'published_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$PostAuthorRelation = RelationDefinition(
  name: 'author',
  kind: RelationKind.belongsTo,
  targetModel: 'Author',
  foreignKey: 'author_id',
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

const RelationDefinition _$PostPhotosRelation = RelationDefinition(
  name: 'photos',
  kind: RelationKind.morphMany,
  targetModel: 'Photo',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
  morphClass: 'Post',
);

final ModelDefinition<Post> _$PostModelDefinition = ModelDefinition(
  modelName: 'Post',
  tableName: 'posts',
  fields: const [
    _$PostIdField,
    _$PostAuthorIdField,
    _$PostTitleField,
    _$PostContentField,
    _$PostViewsField,
    _$PostPublishedAtField,
  ],
  relations: const [
    _$PostAuthorRelation,
    _$PostTagsRelation,
    _$PostPhotosRelation,
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

// ignore: unused_element
final _PostModelDefinitionRegistration = ModelFactoryRegistry.register<Post>(
  _$PostModelDefinition,
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

  static ModelFactoryBuilder<Post> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Post>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

extension PostModelFactoryExtension on Post {
  static ModelFactoryBuilder<Post> factory({
    GeneratorProvider? generatorProvider,
  }) => PostModelFactory.factory(generatorProvider: generatorProvider);
}

class _$PostModelCodec extends ModelCodec<Post> {
  const _$PostModelCodec();

  @override
  Map<String, Object?> encode(Post model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$PostIdField, model.id),
      'author_id': registry.encodeField(_$PostAuthorIdField, model.authorId),
      'title': registry.encodeField(_$PostTitleField, model.title),
      'content': registry.encodeField(_$PostContentField, model.content),
      'views': registry.encodeField(_$PostViewsField, model.views),
      'published_at': registry.encodeField(
        _$PostPublishedAtField,
        model.publishedAt,
      ),
    };
  }

  @override
  Post decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int postIdValue =
        registry.decodeField<int>(_$PostIdField, data['id']) ??
        (throw StateError('Field id on Post cannot be null.'));
    final int postAuthorIdValue =
        registry.decodeField<int>(_$PostAuthorIdField, data['author_id']) ??
        (throw StateError('Field authorId on Post cannot be null.'));
    final String postTitleValue =
        registry.decodeField<String>(_$PostTitleField, data['title']) ??
        (throw StateError('Field title on Post cannot be null.'));
    final String? postContentValue = registry.decodeField<String?>(
      _$PostContentField,
      data['content'],
    );
    final int? postViewsValue = registry.decodeField<int?>(
      _$PostViewsField,
      data['views'],
    );
    final DateTime postPublishedAtValue =
        registry.decodeField<DateTime>(
          _$PostPublishedAtField,
          data['published_at'],
        ) ??
        (throw StateError('Field publishedAt on Post cannot be null.'));
    final model = _$PostModel(
      id: postIdValue,
      authorId: postAuthorIdValue,
      title: postTitleValue,
      publishedAt: postPublishedAtValue,
      content: postContentValue,
      views: postViewsValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': postIdValue,
      'author_id': postAuthorIdValue,
      'title': postTitleValue,
      'content': postContentValue,
      'views': postViewsValue,
      'published_at': postPublishedAtValue,
    });
    return model;
  }
}

class _$PostModel extends Post {
  _$PostModel({
    required int id,
    required int authorId,
    required String title,
    required DateTime publishedAt,
    String? content,
    int? views,
  }) : super.new(
         id: id,
         authorId: authorId,
         title: title,
         publishedAt: publishedAt,
         content: content,
         views: views,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'author_id': authorId,
      'title': title,
      'content': content,
      'views': views,
      'published_at': publishedAt,
    });
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  int get authorId => getAttribute<int>('author_id') ?? super.authorId;

  set authorId(int value) => setAttribute('author_id', value);

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  set title(String value) => setAttribute('title', value);

  @override
  String? get content => getAttribute<String?>('content') ?? super.content;

  set content(String? value) => setAttribute('content', value);

  @override
  int? get views => getAttribute<int?>('views') ?? super.views;

  set views(int? value) => setAttribute('views', value);

  @override
  DateTime get publishedAt =>
      getAttribute<DateTime>('published_at') ?? super.publishedAt;

  set publishedAt(DateTime value) => setAttribute('published_at', value);

  @override
  Author? get author {
    if (relationLoaded('author')) {
      return getRelation<Author>('author');
    }
    return super.author;
  }

  @override
  List<Tag> get tags {
    if (relationLoaded('tags')) {
      return getRelationList<Tag>('tags');
    }
    return super.tags;
  }

  @override
  List<Photo> get photos {
    if (relationLoaded('photos')) {
      return getRelationList<Photo>('photos');
    }
    return super.photos;
  }

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PostModelDefinition);
  }
}

extension PostAttributeSetters on Post {
  set id(int value) => setAttribute('id', value);
  set authorId(int value) => setAttribute('author_id', value);
  set title(String value) => setAttribute('title', value);
  set content(String? value) => setAttribute('content', value);
  set views(int? value) => setAttribute('views', value);
  set publishedAt(DateTime value) => setAttribute('published_at', value);
}
