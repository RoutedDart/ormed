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

final ModelDefinition<$Post> _$PostDefinition = ModelDefinition(
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
  codec: _$PostCodec(),
);

extension PostOrmDefinition on Post {
  static ModelDefinition<$Post> get definition => _$PostDefinition;
}

class Posts {
  const Posts._();

  static Query<$Post> query([String? connection]) =>
      Model.query<$Post>(connection: connection);

  static Future<$Post?> find(Object id, {String? connection}) =>
      Model.find<$Post>(id, connection: connection);

  static Future<$Post> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Post>(id, connection: connection);

  static Future<List<$Post>> all({String? connection}) =>
      Model.all<$Post>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Post>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Post>(connection: connection);

  static Query<$Post> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Post>(column, operator, value, connection: connection);

  static Query<$Post> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Post>(column, values, connection: connection);

  static Query<$Post> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Post>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Post> limit(int count, {String? connection}) =>
      Model.limit<$Post>(count, connection: connection);

  static Repository<$Post> repo([String? connection]) =>
      Model.repository<$Post>(connection: connection);
}

class PostModelFactory {
  const PostModelFactory._();

  static ModelDefinition<$Post> get definition => _$PostDefinition;

  static ModelCodec<$Post> get codec => definition.codec;

  static Post fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Post model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

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

class _$PostCodec extends ModelCodec<$Post> {
  const _$PostCodec();
  @override
  Map<String, Object?> encode($Post model, ValueCodecRegistry registry) {
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
  $Post decode(Map<String, Object?> data, ValueCodecRegistry registry) {
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
    final model = $Post(
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

/// Insert DTO for [Post].
///
/// Auto-increment/DB-generated fields are omitted by default.
class PostInsertDto implements InsertDto<$Post> {
  const PostInsertDto({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.published,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final int? userId;
  final String? title;
  final String? body;
  final bool? published;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (published != null) 'published': published,
      if (publishedAt != null) 'published_at': publishedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

/// Update DTO for [Post].
///
/// All fields are optional; only provided entries are used in SET clauses.
class PostUpdateDto implements UpdateDto<$Post> {
  const PostUpdateDto({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.published,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final int? userId;
  final String? title;
  final String? body;
  final bool? published;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (published != null) 'published': published,
      if (publishedAt != null) 'published_at': publishedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

/// Partial projection for [Post].
///
/// All fields are nullable; intended for subset SELECTs.
class PostPartial implements PartialEntity<$Post> {
  const PostPartial({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.published,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final int? userId;
  final String? title;
  final String? body;
  final bool? published;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  $Post toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? userIdValue = userId;
    if (userIdValue == null) throw StateError('Missing required field: userId');
    final String? titleValue = title;
    if (titleValue == null) throw StateError('Missing required field: title');
    final bool? publishedValue = published;
    if (publishedValue == null)
      throw StateError('Missing required field: published');
    return $Post(
      id: id,
      userId: userIdValue,
      title: titleValue,
      body: body,
      published: publishedValue,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Generated tracked model class for [Post].
///
/// This class extends the user-defined [Post] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Post extends Post with ModelAttributes implements OrmEntity {
  $Post({
    int? id,
    required int userId,
    required String title,
    String? body,
    required bool published,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
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

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Post.fromModel(Post model) {
    return $Post(
      id: model.id,
      userId: model.userId,
      title: model.title,
      body: model.body,
      published: model.published,
      publishedAt: model.publishedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  int get userId => getAttribute<int>('user_id') ?? super.userId;

  set userId(int value) => setAttribute('user_id', value);

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  set title(String value) => setAttribute('title', value);

  @override
  String? get body => getAttribute<String?>('body') ?? super.body;

  set body(String? value) => setAttribute('body', value);

  @override
  bool get published => getAttribute<bool>('published') ?? super.published;

  set published(bool value) => setAttribute('published', value);

  @override
  DateTime? get publishedAt =>
      getAttribute<DateTime?>('published_at') ?? super.publishedAt;

  set publishedAt(DateTime? value) => setAttribute('published_at', value);

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
    attachModelDefinition(_$PostDefinition);
  }

  @override
  User? get author {
    if (relationLoaded('author')) {
      return getRelation<User>('author');
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
  List<Comment> get comments {
    if (relationLoaded('comments')) {
      return getRelationList<Comment>('comments');
    }
    return super.comments;
  }
}

extension PostRelationQueries on Post {
  Query<User> authorQuery() {
    return Model.query<User>().where('id', userId);
  }

  Query<Tag> tagsQuery() {
    throw UnimplementedError("ManyToMany query generation not yet supported");
  }

  Query<Comment> commentsQuery() {
    return Model.query<Comment>().where('post_id', id);
  }
}

extension PostOrmExtension on Post {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Post;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Post toTracked() {
    return $Post.fromModel(this);
  }
}
