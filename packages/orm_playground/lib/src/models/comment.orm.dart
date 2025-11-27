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

class CommentModelFactory {
  const CommentModelFactory._();

  static ModelDefinition<Comment> get definition =>
      CommentOrmDefinition.definition;

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

  static ModelFactoryConnection<Comment> withConnection(QueryContext context) =>
      ModelFactoryConnection<Comment>(definition: definition, context: context);
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

class _$CommentModel extends Comment with ModelAttributes, ModelConnection {
  _$CommentModel({
    int? id,
    required int postId,
    int? userId,
    required String body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
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

  @override
  int get postId => getAttribute<int>('post_id') ?? super.postId;

  @override
  int? get userId => getAttribute<int?>('user_id') ?? super.userId;

  @override
  String get body => getAttribute<String>('body') ?? super.body;

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  @override
  DateTime? get updatedAt =>
      getAttribute<DateTime?>('updated_at') ?? super.updatedAt;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CommentModelDefinition);
  }
}
