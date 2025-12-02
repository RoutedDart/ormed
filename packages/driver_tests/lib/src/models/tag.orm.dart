// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'tag.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$TagIdField = FieldDefinition(
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

const FieldDefinition _$TagLabelField = FieldDefinition(
  name: 'label',
  columnName: 'label',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$TagPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.manyToMany,
  targetModel: 'Post',
  through: 'post_tags',
  pivotForeignKey: 'tag_id',
  pivotRelatedKey: 'post_id',
);

final ModelDefinition<Tag> _$TagModelDefinition = ModelDefinition(
  modelName: 'Tag',
  tableName: 'tags',
  fields: const [_$TagIdField, _$TagLabelField],
  relations: const [_$TagPostsRelation],
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
  codec: _$TagModelCodec(),
);

// ignore: unused_element
final tagModelDefinitionRegistration = ModelFactoryRegistry.register<Tag>(
  _$TagModelDefinition,
);

extension TagOrmDefinition on Tag {
  static ModelDefinition<Tag> get definition => _$TagModelDefinition;
}

class TagModelFactory {
  const TagModelFactory._();

  static ModelDefinition<Tag> get definition => TagOrmDefinition.definition;

  static ModelCodec<Tag> get codec => definition.codec;

  static Tag fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Tag model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Tag> withConnection(QueryContext context) =>
      ModelFactoryConnection<Tag>(definition: definition, context: context);

  static Query<Tag> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<Tag>();
  }

  static ModelFactoryBuilder<Tag> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Tag>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<Tag>> all([String? connection]) => query(connection).get();

  static Future<Tag> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$TagModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Tag>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<Tag>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) =>
              const _$TagModelCodec().decode(r, ValueCodecRegistry.standard()),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Tag>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) =>
              const _$TagModelCodec().decode(r, ValueCodecRegistry.standard()),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Tag>();
    await repo.insertMany(models, returning: false);
  }

  static Future<Tag?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<Tag> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<Tag>> findMany(List<Object> ids, [String? connection]) =>
      query(connection).findMany(ids);

  static Future<Tag?> first([String? connection]) => query(connection).first();

  static Future<Tag> firstOrFail([String? connection]) async {
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

  static Query<Tag> where(String column, dynamic value, [String? connection]) =>
      query(connection).where(column, value);

  static Query<Tag> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<Tag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<Tag> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension TagModelHelpers on Tag {
  // Factory
  static ModelFactoryBuilder<Tag> factory({
    GeneratorProvider? generatorProvider,
  }) => TagModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<Tag> query([String? connection]) =>
      TagModelFactory.query(connection);

  // CRUD operations
  static Future<List<Tag>> all([String? connection]) =>
      TagModelFactory.all(connection);

  static Future<Tag?> find(Object id, [String? connection]) =>
      TagModelFactory.find(id, connection);

  static Future<Tag> findOrFail(Object id, [String? connection]) =>
      TagModelFactory.findOrFail(id, connection);

  static Future<List<Tag>> findMany(List<Object> ids, [String? connection]) =>
      TagModelFactory.findMany(ids, connection);

  static Future<Tag?> first([String? connection]) =>
      TagModelFactory.first(connection);

  static Future<Tag> firstOrFail([String? connection]) =>
      TagModelFactory.firstOrFail(connection);

  static Future<Tag> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => TagModelFactory.create(attributes, connection);

  static Future<List<Tag>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => TagModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => TagModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      TagModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      TagModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      TagModelFactory.exists(connection);

  static Query<Tag> where(String column, dynamic value, [String? connection]) =>
      TagModelFactory.where(column, value, connection);

  static Query<Tag> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => TagModelFactory.whereIn(column, values, connection);

  static Query<Tag> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => TagModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Tag> limit(int count, [String? connection]) =>
      TagModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? TagModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Tag>();
    final primaryKeys = TagModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: TagModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$TagModelCodec extends ModelCodec<Tag> {
  const _$TagModelCodec();

  @override
  Map<String, Object?> encode(Tag model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$TagIdField, model.id),
      'label': registry.encodeField(_$TagLabelField, model.label),
    };
  }

  @override
  Tag decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int tagIdValue =
        registry.decodeField<int>(_$TagIdField, data['id']) ??
        (throw StateError('Field id on Tag cannot be null.'));
    final String tagLabelValue =
        registry.decodeField<String>(_$TagLabelField, data['label']) ??
        (throw StateError('Field label on Tag cannot be null.'));
    final model = _$TagModel(id: tagIdValue, label: tagLabelValue);
    model._attachOrmRuntimeMetadata({'id': tagIdValue, 'label': tagLabelValue});
    return model;
  }
}

class _$TagModel extends Tag {
  _$TagModel({required int id, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get label => getAttribute<String>('label') ?? super.label;

  set label(String value) => setAttribute('label', value);

  @override
  List<Post> get posts {
    if (relationLoaded('posts')) {
      return getRelationList<Post>('posts');
    }
    return super.posts;
  }

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TagModelDefinition);
  }
}

extension TagAttributeSetters on Tag {
  set id(int value) => setAttribute('id', value);
  set label(String value) => setAttribute('label', value);
}
