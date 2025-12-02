// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'comment.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CommentIdField = FieldDefinition(
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

const FieldDefinition _$CommentPostIdField = FieldDefinition(
  name: 'postId',
  columnName: 'post_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CommentUserIdField = FieldDefinition(
  name: 'userId',
  columnName: 'user_id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CommentBodyField = FieldDefinition(
  name: 'body',
  columnName: 'body',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CommentCreatedAtField = FieldDefinition(
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

const FieldDefinition _$CommentUpdatedAtField = FieldDefinition(
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

const RelationDefinition _$CommentAuthorRelation = RelationDefinition(
  name: 'author',
  kind: RelationKind.belongsTo,
  targetModel: 'User',
  foreignKey: 'user_id',
  localKey: 'id',
);

final ModelDefinition<Comment> _$CommentModelDefinition = ModelDefinition(
  modelName: 'Comment',
  tableName: 'comments',
  fields: const [
    _$CommentIdField,
    _$CommentPostIdField,
    _$CommentUserIdField,
    _$CommentBodyField,
    _$CommentCreatedAtField,
    _$CommentUpdatedAtField,
  ],
  relations: const [_$CommentAuthorRelation],
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
  codec: _$CommentModelCodec(),
);

extension CommentOrmDefinition on Comment {
  static ModelDefinition<Comment> get definition => _$CommentModelDefinition;
}

class Comments {
  const Comments._();

  static Query<Comment> query([String? connection]) =>
      Model.query<Comment>(connection: connection);

  static Future<Comment?> find(Object id, {String? connection}) =>
      Model.find<Comment>(id, connection: connection);

  static Future<Comment> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<Comment>(id, connection: connection);

  static Future<List<Comment>> all({String? connection}) =>
      Model.all<Comment>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<Comment>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<Comment>(connection: connection);

  static Query<Comment> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<Comment>(column, operator, value, connection: connection);

  static Query<Comment> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<Comment>(column, values, connection: connection);

  static Query<Comment> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<Comment>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Comment> limit(int count, {String? connection}) =>
      Model.limit<Comment>(count, connection: connection);
}

class CommentModelFactory {
  const CommentModelFactory._();

  static ModelDefinition<Comment> get definition => _$CommentModelDefinition;

  static ModelCodec<Comment> get codec => definition.codec;

  static Comment fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Comment model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryBuilder<Comment> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Comment>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CommentModelCodec extends ModelCodec<Comment> {
  const _$CommentModelCodec();

  @override
  Map<String, Object?> encode(Comment model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$CommentIdField, model.id),
      'post_id': registry.encodeField(_$CommentPostIdField, model.postId),
      'user_id': registry.encodeField(_$CommentUserIdField, model.userId),
      'body': registry.encodeField(_$CommentBodyField, model.body),
      'created_at': registry.encodeField(
        _$CommentCreatedAtField,
        model.createdAt,
      ),
      'updated_at': registry.encodeField(
        _$CommentUpdatedAtField,
        model.updatedAt,
      ),
    };
  }

  @override
  Comment decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? commentIdValue = registry.decodeField<int?>(
      _$CommentIdField,
      data['id'],
    );
    final int commentPostIdValue =
        registry.decodeField<int>(_$CommentPostIdField, data['post_id']) ??
        (throw StateError('Field postId on Comment cannot be null.'));
    final int? commentUserIdValue = registry.decodeField<int?>(
      _$CommentUserIdField,
      data['user_id'],
    );
    final String commentBodyValue =
        registry.decodeField<String>(_$CommentBodyField, data['body']) ??
        (throw StateError('Field body on Comment cannot be null.'));
    final DateTime? commentCreatedAtValue = registry.decodeField<DateTime?>(
      _$CommentCreatedAtField,
      data['created_at'],
    );
    final DateTime? commentUpdatedAtValue = registry.decodeField<DateTime?>(
      _$CommentUpdatedAtField,
      data['updated_at'],
    );
    final model = _$CommentModel(
      id: commentIdValue,
      postId: commentPostIdValue,
      userId: commentUserIdValue,
      body: commentBodyValue,
      createdAt: commentCreatedAtValue,
      updatedAt: commentUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': commentIdValue,
      'post_id': commentPostIdValue,
      'user_id': commentUserIdValue,
      'body': commentBodyValue,
      'created_at': commentCreatedAtValue,
      'updated_at': commentUpdatedAtValue,
    });
    return model;
  }
}

class _$CommentModel extends Comment {
  _$CommentModel({
    int? id,
    required int postId,
    int? userId,
    required String body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         postId: postId,
         userId: userId,
         body: body,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'body': body,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  int get postId => getAttribute<int>('post_id') ?? super.postId;

  set postId(int value) => setAttribute('post_id', value);

  @override
  int? get userId => getAttribute<int?>('user_id') ?? super.userId;

  set userId(int? value) => setAttribute('user_id', value);

  @override
  String get body => getAttribute<String>('body') ?? super.body;

  set body(String value) => setAttribute('body', value);

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
    attachModelDefinition(_$CommentModelDefinition);
  }

  @override
  User? get author {
    if (relationLoaded('author')) {
      return getRelation<User>('author');
    }
    return super.author;
  }
}

extension CommentRelationQueries on Comment {
  Query<User> authorQuery() {
    return Model.query<User>().where('id', userId);
  }
}

extension CommentAttributeSetters on Comment {
  set id(int? value) => setAttribute('id', value);
  set postId(int value) => setAttribute('post_id', value);
  set userId(int? value) => setAttribute('user_id', value);
  set body(String value) => setAttribute('body', value);
  set createdAt(DateTime? value) => setAttribute('created_at', value);
  set updatedAt(DateTime? value) => setAttribute('updated_at', value);
}
