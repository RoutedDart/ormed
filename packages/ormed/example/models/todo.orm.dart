// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'todo.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$TodoIdField = FieldDefinition(
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

const FieldDefinition _$TodoTitleField = FieldDefinition(
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

const FieldDefinition _$TodoCompletedField = FieldDefinition(
  name: 'completed',
  columnName: 'completed',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Todo> _$TodoModelDefinition = ModelDefinition(
  modelName: 'Todo',
  tableName: 'todos',
  fields: const [_$TodoIdField, _$TodoTitleField, _$TodoCompletedField],
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
  codec: _$TodoModelCodec(),
);

extension TodoOrmDefinition on Todo {
  static ModelDefinition<Todo> get definition => _$TodoModelDefinition;
}

class TodoModelFactory {
  const TodoModelFactory._();

  static ModelDefinition<Todo> get definition => TodoOrmDefinition.definition;

  static ModelCodec<Todo> get codec => definition.codec;

  static Todo fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Todo model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Todo> withConnection(QueryContext context) =>
      ModelFactoryConnection<Todo>(definition: definition, context: context);

  static Query<Todo> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<Todo>();
  }

  static ModelFactoryBuilder<Todo> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Todo>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<Todo>> all([String? connection]) =>
      query(connection).get();

  static Future<Todo> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$TodoModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Todo>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<Todo>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) =>
              const _$TodoModelCodec().decode(r, ValueCodecRegistry.standard()),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Todo>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) =>
              const _$TodoModelCodec().decode(r, ValueCodecRegistry.standard()),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Todo>();
    await repo.insertMany(models, returning: false);
  }

  static Future<Todo?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<Todo> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<Todo>> findMany(List<Object> ids, [String? connection]) =>
      query(connection).findMany(ids);

  static Future<Todo?> first([String? connection]) => query(connection).first();

  static Future<Todo> firstOrFail([String? connection]) async {
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

  static Query<Todo> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<Todo> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<Todo> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<Todo> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension TodoModelHelpers on Todo {
  // Factory
  static ModelFactoryBuilder<Todo> factory({
    GeneratorProvider? generatorProvider,
  }) => TodoModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<Todo> query([String? connection]) =>
      TodoModelFactory.query(connection);

  // CRUD operations
  static Future<List<Todo>> all([String? connection]) =>
      TodoModelFactory.all(connection);

  static Future<Todo?> find(Object id, [String? connection]) =>
      TodoModelFactory.find(id, connection);

  static Future<Todo> findOrFail(Object id, [String? connection]) =>
      TodoModelFactory.findOrFail(id, connection);

  static Future<List<Todo>> findMany(List<Object> ids, [String? connection]) =>
      TodoModelFactory.findMany(ids, connection);

  static Future<Todo?> first([String? connection]) =>
      TodoModelFactory.first(connection);

  static Future<Todo> firstOrFail([String? connection]) =>
      TodoModelFactory.firstOrFail(connection);

  static Future<Todo> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => TodoModelFactory.create(attributes, connection);

  static Future<List<Todo>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => TodoModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => TodoModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      TodoModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      TodoModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      TodoModelFactory.exists(connection);

  static Query<Todo> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => TodoModelFactory.where(column, value, connection);

  static Query<Todo> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => TodoModelFactory.whereIn(column, values, connection);

  static Query<Todo> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => TodoModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Todo> limit(int count, [String? connection]) =>
      TodoModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? TodoModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Todo>();
    final primaryKeys = TodoModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: TodoModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$TodoModelCodec extends ModelCodec<Todo> {
  const _$TodoModelCodec();

  @override
  Map<String, Object?> encode(Todo model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$TodoIdField, model.id),
      'title': registry.encodeField(_$TodoTitleField, model.title),
      'completed': registry.encodeField(_$TodoCompletedField, model.completed),
    };
  }

  @override
  Todo decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int todoIdValue =
        registry.decodeField<int>(_$TodoIdField, data['id']) ??
        (throw StateError('Field id on Todo cannot be null.'));
    final String todoTitleValue =
        registry.decodeField<String>(_$TodoTitleField, data['title']) ??
        (throw StateError('Field title on Todo cannot be null.'));
    final bool todoCompletedValue =
        registry.decodeField<bool>(_$TodoCompletedField, data['completed']) ??
        (throw StateError('Field completed on Todo cannot be null.'));
    final model = _$TodoModel(
      id: todoIdValue,
      title: todoTitleValue,
      completed: todoCompletedValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': todoIdValue,
      'title': todoTitleValue,
      'completed': todoCompletedValue,
    });
    return model;
  }
}

class _$TodoModel extends Todo {
  _$TodoModel({required int id, required String title, bool completed = false})
    : super.new(id: id, title: title, completed: completed) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'title': title,
      'completed': completed,
    });
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  set title(String value) => setAttribute('title', value);

  @override
  bool get completed => getAttribute<bool>('completed') ?? super.completed;

  set completed(bool value) => setAttribute('completed', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TodoModelDefinition);
  }
}

extension TodoAttributeSetters on Todo {
  set id(int value) => setAttribute('id', value);
  set title(String value) => setAttribute('title', value);
  set completed(bool value) => setAttribute('completed', value);
}
