// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'author.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AuthorIdField = FieldDefinition(
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

const FieldDefinition _$AuthorNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AuthorActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$AuthorPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.hasMany,
  targetModel: 'Post',
  foreignKey: 'author_id',
  localKey: 'id',
);

final ModelDefinition<Author> _$AuthorModelDefinition = ModelDefinition(
  modelName: 'Author',
  tableName: 'authors',
  fields: const [_$AuthorIdField, _$AuthorNameField, _$AuthorActiveField],
  relations: const [_$AuthorPostsRelation],
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
  codec: _$AuthorModelCodec(),
);

// ignore: unused_element
final authorModelDefinitionRegistration = ModelFactoryRegistry.register<Author>(
  _$AuthorModelDefinition,
);

extension AuthorOrmDefinition on Author {
  static ModelDefinition<Author> get definition => _$AuthorModelDefinition;
}

class Authors {
  const Authors._();

  static Query<Author> query([String? connection]) =>
      Model.query<Author>(connection: connection);

  static Future<Author?> find(Object id, {String? connection}) =>
      Model.find<Author>(id, connection: connection);

  static Future<Author> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<Author>(id, connection: connection);

  static Future<List<Author>> all({String? connection}) =>
      Model.all<Author>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<Author>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<Author>(connection: connection);

  static Query<Author> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<Author>(column, operator, value, connection: connection);

  static Query<Author> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<Author>(column, values, connection: connection);

  static Query<Author> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<Author>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Author> limit(int count, {String? connection}) =>
      Model.limit<Author>(count, connection: connection);
}

class AuthorModelFactory {
  const AuthorModelFactory._();

  static ModelDefinition<Author> get definition => _$AuthorModelDefinition;

  static ModelCodec<Author> get codec => definition.codec;

  static Author fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Author model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Author> withConnection(QueryContext context) =>
      ModelFactoryConnection<Author>(definition: definition, context: context);

  static ModelFactoryBuilder<Author> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Author>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AuthorModelCodec extends ModelCodec<Author> {
  const _$AuthorModelCodec();

  @override
  Map<String, Object?> encode(Author model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$AuthorIdField, model.id),
      'name': registry.encodeField(_$AuthorNameField, model.name),
      'active': registry.encodeField(_$AuthorActiveField, model.active),
    };
  }

  @override
  Author decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int authorIdValue =
        registry.decodeField<int>(_$AuthorIdField, data['id']) ??
        (throw StateError('Field id on Author cannot be null.'));
    final String authorNameValue =
        registry.decodeField<String>(_$AuthorNameField, data['name']) ??
        (throw StateError('Field name on Author cannot be null.'));
    final bool authorActiveValue =
        registry.decodeField<bool>(_$AuthorActiveField, data['active']) ??
        (throw StateError('Field active on Author cannot be null.'));
    final model = _$AuthorModel(
      id: authorIdValue,
      name: authorNameValue,
      active: authorActiveValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': authorIdValue,
      'name': authorNameValue,
      'active': authorActiveValue,
    });
    return model;
  }
}

class _$AuthorModel extends Author {
  _$AuthorModel({required int id, required String name, required bool active})
    : super.new(id: id, name: name, active: active) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name, 'active': active});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  set name(String value) => setAttribute('name', value);

  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  set active(bool value) => setAttribute('active', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuthorModelDefinition);
  }

  @override
  List<Post> get posts {
    if (relationLoaded('posts')) {
      return getRelationList<Post>('posts');
    }
    return super.posts;
  }
}

extension AuthorRelationQueries on Author {
  Query<Post> postsQuery() {
    return Model.query<Post>().where('author_id', id);
  }
}
