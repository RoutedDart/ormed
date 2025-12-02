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

class AuthorModelFactory {
  const AuthorModelFactory._();

  static ModelDefinition<Author> get definition =>
      AuthorOrmDefinition.definition;

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

  static Query<Author> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<Author>();
  }

  static ModelFactoryBuilder<Author> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Author>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<Author>> all([String? connection]) =>
      query(connection).get();

  static Future<Author> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$AuthorModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Author>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<Author>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$AuthorModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Author>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$AuthorModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Author>();
    await repo.insertMany(models, returning: false);
  }

  static Future<Author?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<Author> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<Author>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<Author?> first([String? connection]) =>
      query(connection).first();

  static Future<Author> firstOrFail([String? connection]) async {
    final result = await first(connection);
    if (result == null) throw StateError("No model found");
    return result;
  }

  static Future<int> count([String? connection]) => query(connection).count();

  static Future<bool> exists([String? connection]) async =>
      await count(connection) > 0;

  static Future<int> destroy(List<Object> ids, [String? connection]) async {
    final models = await findMany(ids, connection);
    for (final model in models) {
      await model.delete();
    }
    return models.length;
  }

  static Query<Author> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<Author> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<Author> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<Author> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension AuthorModelHelpers on Author {
  // Factory
  static ModelFactoryBuilder<Author> factory({
    GeneratorProvider? generatorProvider,
  }) => AuthorModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<Author> query([String? connection]) =>
      AuthorModelFactory.query(connection);

  // CRUD operations
  static Future<List<Author>> all([String? connection]) =>
      AuthorModelFactory.all(connection);

  static Future<Author?> find(Object id, [String? connection]) =>
      AuthorModelFactory.find(id, connection);

  static Future<Author> findOrFail(Object id, [String? connection]) =>
      AuthorModelFactory.findOrFail(id, connection);

  static Future<List<Author>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => AuthorModelFactory.findMany(ids, connection);

  static Future<Author?> first([String? connection]) =>
      AuthorModelFactory.first(connection);

  static Future<Author> firstOrFail([String? connection]) =>
      AuthorModelFactory.firstOrFail(connection);

  static Future<Author> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => AuthorModelFactory.create(attributes, connection);

  static Future<List<Author>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => AuthorModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => AuthorModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      AuthorModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      AuthorModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      AuthorModelFactory.exists(connection);

  static Query<Author> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => AuthorModelFactory.where(column, value, connection);

  static Query<Author> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => AuthorModelFactory.whereIn(column, values, connection);

  static Query<Author> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => AuthorModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Author> limit(int count, [String? connection]) =>
      AuthorModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? AuthorModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Author>();
    final primaryKeys = AuthorModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: AuthorModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
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
  _$AuthorModel({required int id, required String name, bool active = false})
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

  @override
  List<Post> get posts {
    if (relationLoaded('posts')) {
      return getRelationList<Post>('posts');
    }
    return super.posts;
  }

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuthorModelDefinition);
  }
}

extension AuthorAttributeSetters on Author {
  set id(int value) => setAttribute('id', value);
  set name(String value) => setAttribute('name', value);
  set active(bool value) => setAttribute('active', value);
}
