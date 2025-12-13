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
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
  insertable: false,
  defaultDartValue: 0,
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

const FieldDefinition _$CommentDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'deleted_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<$Comment> _$CommentDefinition = ModelDefinition(
  modelName: 'Comment',
  tableName: 'comments',
  fields: const [_$CommentIdField, _$CommentBodyField, _$CommentDeletedAtField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$CommentCodec(),
);

// ignore: unused_element
final commentModelDefinitionRegistration =
    ModelFactoryRegistry.register<$Comment>(_$CommentDefinition);

extension CommentOrmDefinition on Comment {
  static ModelDefinition<$Comment> get definition => _$CommentDefinition;
}

class Comments {
  const Comments._();

  static Query<$Comment> query([String? connection]) =>
      Model.query<$Comment>(connection: connection);

  static Future<$Comment?> find(Object id, {String? connection}) =>
      Model.find<$Comment>(id, connection: connection);

  static Future<$Comment> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Comment>(id, connection: connection);

  static Future<List<$Comment>> all({String? connection}) =>
      Model.all<$Comment>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Comment>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Comment>(connection: connection);

  static Query<$Comment> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Comment>(column, operator, value, connection: connection);

  static Query<$Comment> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Comment>(column, values, connection: connection);

  static Query<$Comment> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Comment>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Comment> limit(int count, {String? connection}) =>
      Model.limit<$Comment>(count, connection: connection);

  static Repository<$Comment> repo([String? connection]) =>
      Model.repository<$Comment>(connection: connection);
}

class CommentModelFactory {
  const CommentModelFactory._();

  static ModelDefinition<$Comment> get definition => _$CommentDefinition;

  static ModelCodec<$Comment> get codec => definition.codec;

  static Comment fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Comment model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Comment> withConnection(QueryContext context) =>
      ModelFactoryConnection<Comment>(definition: definition, context: context);

  static ModelFactoryBuilder<Comment> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Comment>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CommentCodec extends ModelCodec<$Comment> {
  const _$CommentCodec();
  @override
  Map<String, Object?> encode($Comment model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$CommentIdField, model.id),
      'body': registry.encodeField(_$CommentBodyField, model.body),
      'deleted_at': registry.encodeField(
        _$CommentDeletedAtField,
        (model is ModelAttributes
            ? model.getAttribute<DateTime?>('deleted_at')
            : null),
      ),
    };
  }

  @override
  $Comment decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int commentIdValue =
        registry.decodeField<int>(_$CommentIdField, data['id']) ?? 0;
    final String commentBodyValue =
        registry.decodeField<String>(_$CommentBodyField, data['body']) ??
        (throw StateError('Field body on Comment cannot be null.'));
    final DateTime? commentDeletedAtValue = registry.decodeField<DateTime?>(
      _$CommentDeletedAtField,
      data['deleted_at'],
    );
    final model = $Comment(id: commentIdValue, body: commentBodyValue);
    model._attachOrmRuntimeMetadata({
      'id': commentIdValue,
      'body': commentBodyValue,
      'deleted_at': commentDeletedAtValue,
    });
    return model;
  }
}

/// Generated tracked model class for [Comment].
///
/// This class extends the user-defined [Comment] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Comment extends Comment with ModelAttributes, SoftDeletesImpl {
  $Comment({int id = 0, required String body}) : super.new(id: id, body: body) {
    _attachOrmRuntimeMetadata({'id': id, 'body': body});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Comment.fromModel(Comment model) {
    return $Comment(id: model.id, body: model.body);
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get body => getAttribute<String>('body') ?? super.body;

  set body(String value) => setAttribute('body', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CommentDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension CommentOrmExtension on Comment {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Comment;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Comment toTracked() {
    return $Comment.fromModel(this);
  }
}
