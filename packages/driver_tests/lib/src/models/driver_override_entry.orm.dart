// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'driver_override_entry.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DriverOverrideEntryIdField = FieldDefinition(
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

const FieldDefinition _$DriverOverrideEntryPayloadField = FieldDefinition(
  name: 'payload',
  columnName: 'payload',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  columnType: 'TEXT',
  driverOverrides: {
    'postgres': FieldDriverOverride(
      columnType: 'jsonb',
      codecType: 'PostgresPayloadCodec',
    ),
    'sqlite': FieldDriverOverride(
      columnType: 'TEXT',
      codecType: 'SqlitePayloadCodec',
    ),
    'mysql': FieldDriverOverride(
      columnType: 'JSON',
      codecType: 'MariaDbPayloadCodec',
    ),
    'mariadb': FieldDriverOverride(
      columnType: 'JSON',
      codecType: 'MariaDbPayloadCodec',
    ),
  },
);

final ModelDefinition<DriverOverrideEntry>
_$DriverOverrideEntryModelDefinition = ModelDefinition(
  modelName: 'DriverOverrideEntry',
  tableName: 'driver_override_entries',
  fields: const [
    _$DriverOverrideEntryIdField,
    _$DriverOverrideEntryPayloadField,
  ],
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
  codec: _$DriverOverrideEntryModelCodec(),
);

// ignore: unused_element
final driveroverrideentryModelDefinitionRegistration =
    ModelFactoryRegistry.register<DriverOverrideEntry>(
      _$DriverOverrideEntryModelDefinition,
    );

extension DriverOverrideEntryOrmDefinition on DriverOverrideEntry {
  static ModelDefinition<DriverOverrideEntry> get definition =>
      _$DriverOverrideEntryModelDefinition;
}

class DriverOverrideEntryModelFactory {
  const DriverOverrideEntryModelFactory._();

  static ModelDefinition<DriverOverrideEntry> get definition =>
      DriverOverrideEntryOrmDefinition.definition;

  static ModelCodec<DriverOverrideEntry> get codec => definition.codec;

  static DriverOverrideEntry fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DriverOverrideEntry model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DriverOverrideEntry> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DriverOverrideEntry>(
    definition: definition,
    context: context,
  );

  static Query<DriverOverrideEntry> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<DriverOverrideEntry>();
  }

  static ModelFactoryBuilder<DriverOverrideEntry> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DriverOverrideEntry>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<DriverOverrideEntry>> all([String? connection]) =>
      query(connection).get();

  static Future<DriverOverrideEntry> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$DriverOverrideEntryModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DriverOverrideEntry>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<DriverOverrideEntry>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$DriverOverrideEntryModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DriverOverrideEntry>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$DriverOverrideEntryModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DriverOverrideEntry>();
    await repo.insertMany(models, returning: false);
  }

  static Future<DriverOverrideEntry?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<DriverOverrideEntry> findOrFail(
    Object id, [
    String? connection,
  ]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<DriverOverrideEntry>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<DriverOverrideEntry?> first([String? connection]) =>
      query(connection).first();

  static Future<DriverOverrideEntry> firstOrFail([String? connection]) async {
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

  static Query<DriverOverrideEntry> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<DriverOverrideEntry> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<DriverOverrideEntry> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<DriverOverrideEntry> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension DriverOverrideEntryModelHelpers on DriverOverrideEntry {
  // Factory
  static ModelFactoryBuilder<DriverOverrideEntry> factory({
    GeneratorProvider? generatorProvider,
  }) => DriverOverrideEntryModelFactory.factory(
    generatorProvider: generatorProvider,
  );

  // Query builder
  static Query<DriverOverrideEntry> query([String? connection]) =>
      DriverOverrideEntryModelFactory.query(connection);

  // CRUD operations
  static Future<List<DriverOverrideEntry>> all([String? connection]) =>
      DriverOverrideEntryModelFactory.all(connection);

  static Future<DriverOverrideEntry?> find(Object id, [String? connection]) =>
      DriverOverrideEntryModelFactory.find(id, connection);

  static Future<DriverOverrideEntry> findOrFail(
    Object id, [
    String? connection,
  ]) => DriverOverrideEntryModelFactory.findOrFail(id, connection);

  static Future<List<DriverOverrideEntry>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => DriverOverrideEntryModelFactory.findMany(ids, connection);

  static Future<DriverOverrideEntry?> first([String? connection]) =>
      DriverOverrideEntryModelFactory.first(connection);

  static Future<DriverOverrideEntry> firstOrFail([String? connection]) =>
      DriverOverrideEntryModelFactory.firstOrFail(connection);

  static Future<DriverOverrideEntry> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => DriverOverrideEntryModelFactory.create(attributes, connection);

  static Future<List<DriverOverrideEntry>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => DriverOverrideEntryModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => DriverOverrideEntryModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      DriverOverrideEntryModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      DriverOverrideEntryModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      DriverOverrideEntryModelFactory.exists(connection);

  static Query<DriverOverrideEntry> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => DriverOverrideEntryModelFactory.where(column, value, connection);

  static Query<DriverOverrideEntry> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => DriverOverrideEntryModelFactory.whereIn(column, values, connection);

  static Query<DriverOverrideEntry> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => DriverOverrideEntryModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<DriverOverrideEntry> limit(int count, [String? connection]) =>
      DriverOverrideEntryModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ??
        DriverOverrideEntryModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DriverOverrideEntry>();
    final primaryKeys = DriverOverrideEntryModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: DriverOverrideEntryModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$DriverOverrideEntryModelCodec extends ModelCodec<DriverOverrideEntry> {
  const _$DriverOverrideEntryModelCodec();

  @override
  Map<String, Object?> encode(
    DriverOverrideEntry model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$DriverOverrideEntryIdField, model.id),
      'payload': registry.encodeField(
        _$DriverOverrideEntryPayloadField,
        model.payload,
      ),
    };
  }

  @override
  DriverOverrideEntry decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int driverOverrideEntryIdValue =
        registry.decodeField<int>(_$DriverOverrideEntryIdField, data['id']) ??
        (throw StateError('Field id on DriverOverrideEntry cannot be null.'));
    final Map<String, Object?> driverOverrideEntryPayloadValue =
        registry.decodeField<Map<String, Object?>>(
          _$DriverOverrideEntryPayloadField,
          data['payload'],
        ) ??
        (throw StateError(
          'Field payload on DriverOverrideEntry cannot be null.',
        ));
    final model = _$DriverOverrideEntryModel(
      id: driverOverrideEntryIdValue,
      payload: driverOverrideEntryPayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': driverOverrideEntryIdValue,
      'payload': driverOverrideEntryPayloadValue,
    });
    return model;
  }
}

class _$DriverOverrideEntryModel extends DriverOverrideEntry {
  _$DriverOverrideEntryModel({
    required int id,
    required Map<String, Object?> payload,
  }) : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  Map<String, Object?> get payload =>
      getAttribute<Map<String, Object?>>('payload') ?? super.payload;

  set payload(Map<String, Object?> value) => setAttribute('payload', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$DriverOverrideEntryModelDefinition);
  }
}

extension DriverOverrideEntryAttributeSetters on DriverOverrideEntry {
  set id(int value) => setAttribute('id', value);
  set payload(Map<String, Object?> value) => setAttribute('payload', value);
}
