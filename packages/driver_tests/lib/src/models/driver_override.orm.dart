// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'driver_override.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DriverOverrideModelIdField = FieldDefinition(
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

const FieldDefinition _$DriverOverrideModelPayloadField = FieldDefinition(
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
  },
);

final ModelDefinition<$DriverOverrideModel> _$DriverOverrideModelDefinition =
    ModelDefinition(
      modelName: 'DriverOverrideModel',
      tableName: 'driver_overrides',
      fields: const [
        _$DriverOverrideModelIdField,
        _$DriverOverrideModelPayloadField,
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
      codec: _$DriverOverrideModelCodec(),
    );

extension DriverOverrideModelOrmDefinition on DriverOverrideModel {
  static ModelDefinition<$DriverOverrideModel> get definition =>
      _$DriverOverrideModelDefinition;
}

class DriverOverrideModelFactory {
  const DriverOverrideModelFactory._();

  static ModelDefinition<DriverOverrideModel> get definition =>
      DriverOverrideModelOrmDefinition.definition;

  static ModelCodec<DriverOverrideModel> get codec => definition.codec;

  static DriverOverrideModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DriverOverrideModel model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DriverOverrideModel> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DriverOverrideModel>(
    definition: definition,
    context: context,
  );

  static Query<DriverOverrideModel> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<DriverOverrideModel>();
  }

  static ModelFactoryBuilder<DriverOverrideModel> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DriverOverrideModel>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<DriverOverrideModel>> all([String? connection]) =>
      query(connection).get();

  static Future<DriverOverrideModel> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$DriverOverrideModelCodec().decode(
      attributes,
      ValueCodecRegistry.instance,
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DriverOverrideModel>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<DriverOverrideModel>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$DriverOverrideModelCodec().decode(
            r,
            ValueCodecRegistry.instance,
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DriverOverrideModel>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$DriverOverrideModelCodec().decode(
            r,
            ValueCodecRegistry.instance,
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DriverOverrideModel>();
    await repo.insertMany(models, returning: false);
  }

  static Future<DriverOverrideModel?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<DriverOverrideModel> findOrFail(
    Object id, [
    String? connection,
  ]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<DriverOverrideModel>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<DriverOverrideModel?> first([String? connection]) =>
      query(connection).first();

  static Future<DriverOverrideModel> firstOrFail([String? connection]) async {
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

  static Query<DriverOverrideModel> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<DriverOverrideModel> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<DriverOverrideModel> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<DriverOverrideModel> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension DriverOverrideModelModelHelpers on DriverOverrideModel {
  // Factory
  static ModelFactoryBuilder<DriverOverrideModel> factory({
    GeneratorProvider? generatorProvider,
  }) =>
      DriverOverrideModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<DriverOverrideModel> query([String? connection]) =>
      DriverOverrideModelFactory.query(connection);

  // CRUD operations
  static Future<List<DriverOverrideModel>> all([String? connection]) =>
      DriverOverrideModelFactory.all(connection);

  static Future<DriverOverrideModel?> find(Object id, [String? connection]) =>
      DriverOverrideModelFactory.find(id, connection);

  static Future<DriverOverrideModel> findOrFail(
    Object id, [
    String? connection,
  ]) => DriverOverrideModelFactory.findOrFail(id, connection);

  static Future<List<DriverOverrideModel>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => DriverOverrideModelFactory.findMany(ids, connection);

  static Future<DriverOverrideModel?> first([String? connection]) =>
      DriverOverrideModelFactory.first(connection);

  static Future<DriverOverrideModel> firstOrFail([String? connection]) =>
      DriverOverrideModelFactory.firstOrFail(connection);

  static Future<DriverOverrideModel> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => DriverOverrideModelFactory.create(attributes, connection);

  static Future<List<DriverOverrideModel>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => DriverOverrideModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => DriverOverrideModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      DriverOverrideModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      DriverOverrideModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      DriverOverrideModelFactory.exists(connection);

  static Query<DriverOverrideModel> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => DriverOverrideModelFactory.where(column, value, connection);

  static Query<DriverOverrideModel> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => DriverOverrideModelFactory.whereIn(column, values, connection);

  static Query<DriverOverrideModel> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => DriverOverrideModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<DriverOverrideModel> limit(int count, [String? connection]) =>
      DriverOverrideModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? DriverOverrideModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DriverOverrideModel>();
    final primaryKeys = DriverOverrideModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: DriverOverrideModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$DriverOverrideModelCodec extends ModelCodec<$DriverOverrideModel> {
  const _$DriverOverrideModelCodec();
  @override
  Map<String, Object?> encode(
    $DriverOverrideModel model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$DriverOverrideModelIdField, model.id),
      'payload': registry.encodeField(
        _$DriverOverrideModelPayloadField,
        model.payload,
      ),
    };
  }

  @override
  $DriverOverrideModel decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int driverOverrideModelIdValue =
        registry.decodeField<int>(_$DriverOverrideModelIdField, data['id']) ??
        (throw StateError('Field id on DriverOverrideModel cannot be null.'));
    final Map<String, Object?> driverOverrideModelPayloadValue =
        registry.decodeField<Map<String, Object?>>(
          _$DriverOverrideModelPayloadField,
          data['payload'],
        ) ??
        (throw StateError(
          'Field payload on DriverOverrideModel cannot be null.',
        ));
    final model = $DriverOverrideModel(
      id: driverOverrideModelIdValue,
      payload: driverOverrideModelPayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': driverOverrideModelIdValue,
      'payload': driverOverrideModelPayloadValue,
    });
    return model;
  }
}

/// Generated tracked model class for [DriverOverrideModel].
///
/// This class extends the user-defined [DriverOverrideModel] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $DriverOverrideModel extends DriverOverrideModel
    with ModelAttributes, ModelConnection, ModelRelations {
  $DriverOverrideModel({required int id, required Map<String, Object?> payload})
    : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $DriverOverrideModel.fromModel(DriverOverrideModel model) {
    return $DriverOverrideModel(id: model.id, payload: model.payload);
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
    attachModelDefinition(_$DriverOverrideModelDefinition);
  }
}

extension DriverOverrideModelOrmExtension on DriverOverrideModel {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $DriverOverrideModel;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $DriverOverrideModel toTracked() {
    return $DriverOverrideModel.fromModel(this);
  }
}
