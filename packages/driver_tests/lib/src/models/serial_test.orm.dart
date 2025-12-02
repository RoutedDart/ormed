// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'serial_test.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SerialTestIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$SerialTestLabelField = FieldDefinition(
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

final ModelDefinition<SerialTest> _$SerialTestModelDefinition = ModelDefinition(
  modelName: 'SerialTest',
  tableName: 'serial_tests',
  fields: const [_$SerialTestIdField, _$SerialTestLabelField],
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
  codec: _$SerialTestModelCodec(),
);

// ignore: unused_element
final serialtestModelDefinitionRegistration =
    ModelFactoryRegistry.register<SerialTest>(_$SerialTestModelDefinition);

extension SerialTestOrmDefinition on SerialTest {
  static ModelDefinition<SerialTest> get definition =>
      _$SerialTestModelDefinition;
}

class SerialTestModelFactory {
  const SerialTestModelFactory._();

  static ModelDefinition<SerialTest> get definition =>
      SerialTestOrmDefinition.definition;

  static ModelCodec<SerialTest> get codec => definition.codec;

  static SerialTest fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    SerialTest model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<SerialTest> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<SerialTest>(
    definition: definition,
    context: context,
  );

  static Query<SerialTest> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<SerialTest>();
  }

  static ModelFactoryBuilder<SerialTest> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<SerialTest>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<SerialTest>> all([String? connection]) =>
      query(connection).get();

  static Future<SerialTest> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$SerialTestModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<SerialTest>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<SerialTest>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$SerialTestModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<SerialTest>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$SerialTestModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<SerialTest>();
    await repo.insertMany(models, returning: false);
  }

  static Future<SerialTest?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<SerialTest> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<SerialTest>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<SerialTest?> first([String? connection]) =>
      query(connection).first();

  static Future<SerialTest> firstOrFail([String? connection]) async {
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

  static Query<SerialTest> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<SerialTest> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<SerialTest> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<SerialTest> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension SerialTestModelHelpers on SerialTest {
  // Factory
  static ModelFactoryBuilder<SerialTest> factory({
    GeneratorProvider? generatorProvider,
  }) => SerialTestModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<SerialTest> query([String? connection]) =>
      SerialTestModelFactory.query(connection);

  // CRUD operations
  static Future<List<SerialTest>> all([String? connection]) =>
      SerialTestModelFactory.all(connection);

  static Future<SerialTest?> find(Object id, [String? connection]) =>
      SerialTestModelFactory.find(id, connection);

  static Future<SerialTest> findOrFail(Object id, [String? connection]) =>
      SerialTestModelFactory.findOrFail(id, connection);

  static Future<List<SerialTest>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => SerialTestModelFactory.findMany(ids, connection);

  static Future<SerialTest?> first([String? connection]) =>
      SerialTestModelFactory.first(connection);

  static Future<SerialTest> firstOrFail([String? connection]) =>
      SerialTestModelFactory.firstOrFail(connection);

  static Future<SerialTest> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => SerialTestModelFactory.create(attributes, connection);

  static Future<List<SerialTest>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => SerialTestModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => SerialTestModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      SerialTestModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      SerialTestModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      SerialTestModelFactory.exists(connection);

  static Query<SerialTest> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => SerialTestModelFactory.where(column, value, connection);

  static Query<SerialTest> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => SerialTestModelFactory.whereIn(column, values, connection);

  static Query<SerialTest> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => SerialTestModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<SerialTest> limit(int count, [String? connection]) =>
      SerialTestModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? SerialTestModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<SerialTest>();
    final primaryKeys = SerialTestModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: SerialTestModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$SerialTestModelCodec extends ModelCodec<SerialTest> {
  const _$SerialTestModelCodec();

  @override
  Map<String, Object?> encode(SerialTest model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$SerialTestIdField, model.id),
      'label': registry.encodeField(_$SerialTestLabelField, model.label),
    };
  }

  @override
  SerialTest decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int serialTestIdValue =
        registry.decodeField<int>(_$SerialTestIdField, data['id']) ?? 0;
    final String serialTestLabelValue =
        registry.decodeField<String>(_$SerialTestLabelField, data['label']) ??
        (throw StateError('Field label on SerialTest cannot be null.'));
    final model = _$SerialTestModel(
      id: serialTestIdValue,
      label: serialTestLabelValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': serialTestIdValue,
      'label': serialTestLabelValue,
    });
    return model;
  }
}

class _$SerialTestModel extends SerialTest {
  _$SerialTestModel({required int id, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get label => getAttribute<String>('label') ?? super.label;

  set label(String value) => setAttribute('label', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SerialTestModelDefinition);
  }
}

extension SerialTestAttributeSetters on SerialTest {
  set id(int value) => setAttribute('id', value);
  set label(String value) => setAttribute('label', value);
}
