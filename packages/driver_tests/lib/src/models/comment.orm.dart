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

final ModelDefinition<Comment> _$CommentModelDefinition = ModelDefinition(
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
  codec: _$CommentModelCodec(),
);

// ignore: unused_element
final commentModelDefinitionRegistration =
    ModelFactoryRegistry.register<Comment>(_$CommentModelDefinition);

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

  static Query<Comment> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<Comment>();
  }

  static ModelFactoryBuilder<Comment> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Comment>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<Comment>> all([String? connection]) =>
      query(connection).get();

  static Future<Comment> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$CommentModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Comment>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<Comment>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$CommentModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Comment>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$CommentModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Comment>();
    await repo.insertMany(models, returning: false);
  }

  static Future<Comment?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<Comment> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<Comment>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<Comment?> first([String? connection]) =>
      query(connection).first();

  static Future<Comment> firstOrFail([String? connection]) async {
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

  static Query<Comment> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<Comment> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<Comment> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<Comment> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension CommentModelHelpers on Comment {
  // Factory
  static ModelFactoryBuilder<Comment> factory({
    GeneratorProvider? generatorProvider,
  }) => CommentModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<Comment> query([String? connection]) =>
      CommentModelFactory.query(connection);

  // CRUD operations
  static Future<List<Comment>> all([String? connection]) =>
      CommentModelFactory.all(connection);

  static Future<Comment?> find(Object id, [String? connection]) =>
      CommentModelFactory.find(id, connection);

  static Future<Comment> findOrFail(Object id, [String? connection]) =>
      CommentModelFactory.findOrFail(id, connection);

  static Future<List<Comment>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => CommentModelFactory.findMany(ids, connection);

  static Future<Comment?> first([String? connection]) =>
      CommentModelFactory.first(connection);

  static Future<Comment> firstOrFail([String? connection]) =>
      CommentModelFactory.firstOrFail(connection);

  static Future<Comment> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => CommentModelFactory.create(attributes, connection);

  static Future<List<Comment>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => CommentModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => CommentModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      CommentModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      CommentModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      CommentModelFactory.exists(connection);

  static Query<Comment> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => CommentModelFactory.where(column, value, connection);

  static Query<Comment> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => CommentModelFactory.whereIn(column, values, connection);

  static Query<Comment> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => CommentModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Comment> limit(int count, [String? connection]) =>
      CommentModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? CommentModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Comment>();
    final primaryKeys = CommentModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: CommentModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$CommentModelCodec extends ModelCodec<Comment> {
  const _$CommentModelCodec();

  @override
  Map<String, Object?> encode(Comment model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$CommentIdField, model.id),
      'body': registry.encodeField(_$CommentBodyField, model.body),
      'deleted_at': registry.encodeField(
        _$CommentDeletedAtField,
        model.getAttribute<DateTime?>('deleted_at'),
      ),
    };
  }

  @override
  Comment decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int commentIdValue =
        registry.decodeField<int>(_$CommentIdField, data['id']) ??
        (throw StateError('Field id on Comment cannot be null.'));
    final String commentBodyValue =
        registry.decodeField<String>(_$CommentBodyField, data['body']) ??
        (throw StateError('Field body on Comment cannot be null.'));
    final DateTime? commentDeletedAtValue = registry.decodeField<DateTime?>(
      _$CommentDeletedAtField,
      data['deleted_at'],
    );
    final model = _$CommentModel(id: commentIdValue, body: commentBodyValue);
    model._attachOrmRuntimeMetadata({
      'id': commentIdValue,
      'body': commentBodyValue,
      'deleted_at': commentDeletedAtValue,
    });
    return model;
  }
}

class _$CommentModel extends Comment {
  _$CommentModel({required int id, required String body})
    : super.new(id: id, body: body) {
    _attachOrmRuntimeMetadata({'id': id, 'body': body});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get body => getAttribute<String>('body') ?? super.body;

  set body(String value) => setAttribute('body', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CommentModelDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension CommentAttributeSetters on Comment {
  set id(int value) => setAttribute('id', value);
  set body(String value) => setAttribute('body', value);
}
