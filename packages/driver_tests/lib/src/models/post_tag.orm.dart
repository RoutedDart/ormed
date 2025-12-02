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
  isPrimaryKey: true,
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

// ignore: unused_element
final posttagModelDefinitionRegistration =
    ModelFactoryRegistry.register<PostTag>(_$PostTagModelDefinition);

extension PostTagOrmDefinition on PostTag {
  static ModelDefinition<PostTag> get definition => _$PostTagModelDefinition;
}

class PostTagModelFactory {
  const PostTagModelFactory._();

  static ModelDefinition<PostTag> get definition =>
      PostTagOrmDefinition.definition;

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

  static Query<PostTag> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<PostTag>();
  }

  static ModelFactoryBuilder<PostTag> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<PostTag>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<PostTag>> all([String? connection]) =>
      query(connection).get();

  static Future<PostTag> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$PostTagModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<PostTag>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<PostTag>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$PostTagModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<PostTag>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$PostTagModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<PostTag>();
    await repo.insertMany(models, returning: false);
  }

  static Future<PostTag?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<PostTag> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<PostTag>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<PostTag?> first([String? connection]) =>
      query(connection).first();

  static Future<PostTag> firstOrFail([String? connection]) async {
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

  static Query<PostTag> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<PostTag> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<PostTag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<PostTag> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension PostTagModelHelpers on PostTag {
  // Factory
  static ModelFactoryBuilder<PostTag> factory({
    GeneratorProvider? generatorProvider,
  }) => PostTagModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<PostTag> query([String? connection]) =>
      PostTagModelFactory.query(connection);

  // CRUD operations
  static Future<List<PostTag>> all([String? connection]) =>
      PostTagModelFactory.all(connection);

  static Future<PostTag?> find(Object id, [String? connection]) =>
      PostTagModelFactory.find(id, connection);

  static Future<PostTag> findOrFail(Object id, [String? connection]) =>
      PostTagModelFactory.findOrFail(id, connection);

  static Future<List<PostTag>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => PostTagModelFactory.findMany(ids, connection);

  static Future<PostTag?> first([String? connection]) =>
      PostTagModelFactory.first(connection);

  static Future<PostTag> firstOrFail([String? connection]) =>
      PostTagModelFactory.firstOrFail(connection);

  static Future<PostTag> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => PostTagModelFactory.create(attributes, connection);

  static Future<List<PostTag>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => PostTagModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => PostTagModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      PostTagModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      PostTagModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      PostTagModelFactory.exists(connection);

  static Query<PostTag> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => PostTagModelFactory.where(column, value, connection);

  static Query<PostTag> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => PostTagModelFactory.whereIn(column, values, connection);

  static Query<PostTag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => PostTagModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<PostTag> limit(int count, [String? connection]) =>
      PostTagModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? PostTagModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<PostTag>();
    final primaryKeys = PostTagModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: PostTagModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
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

extension PostTagAttributeSetters on PostTag {
  set postId(int value) => setAttribute('post_id', value);
  set tagId(int value) => setAttribute('tag_id', value);
}
