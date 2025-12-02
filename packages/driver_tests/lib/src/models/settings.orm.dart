// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'settings.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SettingIdField = FieldDefinition(
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

const FieldDefinition _$SettingPayloadField = FieldDefinition(
  name: 'payload',
  columnName: 'payload',
  dartType: 'Map<String, dynamic>',
  resolvedType: 'Map<String, dynamic>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Setting> _$SettingModelDefinition = ModelDefinition(
  modelName: 'Setting',
  tableName: 'settings',
  fields: const [_$SettingIdField, _$SettingPayloadField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    fieldOverrides: const {'payload': FieldAttributeMetadata(cast: 'json')},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$SettingModelCodec(),
);

// ignore: unused_element
final settingModelDefinitionRegistration =
    ModelFactoryRegistry.register<Setting>(_$SettingModelDefinition);

extension SettingOrmDefinition on Setting {
  static ModelDefinition<Setting> get definition => _$SettingModelDefinition;
}

class SettingModelFactory {
  const SettingModelFactory._();

  static ModelDefinition<Setting> get definition =>
      SettingOrmDefinition.definition;

  static ModelCodec<Setting> get codec => definition.codec;

  static Setting fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Setting model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Setting> withConnection(QueryContext context) =>
      ModelFactoryConnection<Setting>(definition: definition, context: context);

  static Query<Setting> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<Setting>();
  }

  static ModelFactoryBuilder<Setting> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Setting>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<Setting>> all([String? connection]) =>
      query(connection).get();

  static Future<Setting> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$SettingModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Setting>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<Setting>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$SettingModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Setting>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$SettingModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Setting>();
    await repo.insertMany(models, returning: false);
  }

  static Future<Setting?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<Setting> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<Setting>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<Setting?> first([String? connection]) =>
      query(connection).first();

  static Future<Setting> firstOrFail([String? connection]) async {
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

  static Query<Setting> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<Setting> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<Setting> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<Setting> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension SettingModelHelpers on Setting {
  // Factory
  static ModelFactoryBuilder<Setting> factory({
    GeneratorProvider? generatorProvider,
  }) => SettingModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<Setting> query([String? connection]) =>
      SettingModelFactory.query(connection);

  // CRUD operations
  static Future<List<Setting>> all([String? connection]) =>
      SettingModelFactory.all(connection);

  static Future<Setting?> find(Object id, [String? connection]) =>
      SettingModelFactory.find(id, connection);

  static Future<Setting> findOrFail(Object id, [String? connection]) =>
      SettingModelFactory.findOrFail(id, connection);

  static Future<List<Setting>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => SettingModelFactory.findMany(ids, connection);

  static Future<Setting?> first([String? connection]) =>
      SettingModelFactory.first(connection);

  static Future<Setting> firstOrFail([String? connection]) =>
      SettingModelFactory.firstOrFail(connection);

  static Future<Setting> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => SettingModelFactory.create(attributes, connection);

  static Future<List<Setting>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => SettingModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => SettingModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      SettingModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      SettingModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      SettingModelFactory.exists(connection);

  static Query<Setting> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => SettingModelFactory.where(column, value, connection);

  static Query<Setting> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => SettingModelFactory.whereIn(column, values, connection);

  static Query<Setting> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => SettingModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Setting> limit(int count, [String? connection]) =>
      SettingModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? SettingModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Setting>();
    final primaryKeys = SettingModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: SettingModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$SettingModelCodec extends ModelCodec<Setting> {
  const _$SettingModelCodec();

  @override
  Map<String, Object?> encode(Setting model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$SettingIdField, model.id),
      'payload': registry.encodeField(_$SettingPayloadField, model.payload),
    };
  }

  @override
  Setting decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int settingIdValue =
        registry.decodeField<int>(_$SettingIdField, data['id']) ??
        (throw StateError('Field id on Setting cannot be null.'));
    final Map<String, dynamic> settingPayloadValue =
        registry.decodeField<Map<String, dynamic>>(
          _$SettingPayloadField,
          data['payload'],
        ) ??
        (throw StateError('Field payload on Setting cannot be null.'));
    final model = _$SettingModel(
      id: settingIdValue,
      payload: settingPayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': settingIdValue,
      'payload': settingPayloadValue,
    });
    return model;
  }
}

class _$SettingModel extends Setting {
  _$SettingModel({required int id, required Map<String, dynamic> payload})
    : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  Map<String, dynamic> get payload =>
      getAttribute<Map<String, dynamic>>('payload') ?? super.payload;

  set payload(Map<String, dynamic> value) => setAttribute('payload', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SettingModelDefinition);
  }
}

extension SettingAttributeSetters on Setting {
  set id(int value) => setAttribute('id', value);
  set payload(Map<String, dynamic> value) => setAttribute('payload', value);
}
