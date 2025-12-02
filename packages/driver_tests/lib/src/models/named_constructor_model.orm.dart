// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'named_constructor_model.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$NamedConstructorModelIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$NamedConstructorModelNameField = FieldDefinition(
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

const FieldDefinition _$NamedConstructorModelValueField = FieldDefinition(
  name: 'value',
  columnName: 'value',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<NamedConstructorModel>
_$NamedConstructorModelModelDefinition = ModelDefinition(
  modelName: 'NamedConstructorModel',
  tableName: 'named_constructor_models',
  fields: const [
    _$NamedConstructorModelIdField,
    _$NamedConstructorModelNameField,
    _$NamedConstructorModelValueField,
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
  codec: _$NamedConstructorModelModelCodec(),
);

extension NamedConstructorModelOrmDefinition on NamedConstructorModel {
  static ModelDefinition<NamedConstructorModel> get definition =>
      _$NamedConstructorModelModelDefinition;
}

class NamedConstructorModelModelFactory {
  const NamedConstructorModelModelFactory._();

  static ModelDefinition<NamedConstructorModel> get definition =>
      NamedConstructorModelOrmDefinition.definition;

  static ModelCodec<NamedConstructorModel> get codec => definition.codec;

  static NamedConstructorModel fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    NamedConstructorModel model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<NamedConstructorModel> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<NamedConstructorModel>(
    definition: definition,
    context: context,
  );

  static Query<NamedConstructorModel> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<NamedConstructorModel>();
  }

  static ModelFactoryBuilder<NamedConstructorModel> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<NamedConstructorModel>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<NamedConstructorModel>> all([String? connection]) =>
      query(connection).get();

  static Future<NamedConstructorModel> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$NamedConstructorModelModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<NamedConstructorModel>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<NamedConstructorModel>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$NamedConstructorModelModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<NamedConstructorModel>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$NamedConstructorModelModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<NamedConstructorModel>();
    await repo.insertMany(models, returning: false);
  }

  static Future<NamedConstructorModel?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<NamedConstructorModel> findOrFail(
    Object id, [
    String? connection,
  ]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<NamedConstructorModel>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<NamedConstructorModel?> first([String? connection]) =>
      query(connection).first();

  static Future<NamedConstructorModel> firstOrFail([String? connection]) async {
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

  static Query<NamedConstructorModel> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<NamedConstructorModel> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<NamedConstructorModel> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<NamedConstructorModel> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension NamedConstructorModelModelHelpers on NamedConstructorModel {
  // Factory
  static ModelFactoryBuilder<NamedConstructorModel> factory({
    GeneratorProvider? generatorProvider,
  }) => NamedConstructorModelModelFactory.factory(
    generatorProvider: generatorProvider,
  );

  // Query builder
  static Query<NamedConstructorModel> query([String? connection]) =>
      NamedConstructorModelModelFactory.query(connection);

  // CRUD operations
  static Future<List<NamedConstructorModel>> all([String? connection]) =>
      NamedConstructorModelModelFactory.all(connection);

  static Future<NamedConstructorModel?> find(Object id, [String? connection]) =>
      NamedConstructorModelModelFactory.find(id, connection);

  static Future<NamedConstructorModel> findOrFail(
    Object id, [
    String? connection,
  ]) => NamedConstructorModelModelFactory.findOrFail(id, connection);

  static Future<List<NamedConstructorModel>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => NamedConstructorModelModelFactory.findMany(ids, connection);

  static Future<NamedConstructorModel?> first([String? connection]) =>
      NamedConstructorModelModelFactory.first(connection);

  static Future<NamedConstructorModel> firstOrFail([String? connection]) =>
      NamedConstructorModelModelFactory.firstOrFail(connection);

  static Future<NamedConstructorModel> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => NamedConstructorModelModelFactory.create(attributes, connection);

  static Future<List<NamedConstructorModel>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => NamedConstructorModelModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => NamedConstructorModelModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      NamedConstructorModelModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      NamedConstructorModelModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      NamedConstructorModelModelFactory.exists(connection);

  static Query<NamedConstructorModel> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => NamedConstructorModelModelFactory.where(column, value, connection);

  static Query<NamedConstructorModel> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => NamedConstructorModelModelFactory.whereIn(column, values, connection);

  static Query<NamedConstructorModel> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => NamedConstructorModelModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<NamedConstructorModel> limit(int count, [String? connection]) =>
      NamedConstructorModelModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ??
        NamedConstructorModelModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<NamedConstructorModel>();
    final primaryKeys = NamedConstructorModelModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: NamedConstructorModelModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$NamedConstructorModelModelCodec
    extends ModelCodec<NamedConstructorModel> {
  const _$NamedConstructorModelModelCodec();

  @override
  Map<String, Object?> encode(
    NamedConstructorModel model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$NamedConstructorModelIdField, model.id),
      'name': registry.encodeField(
        _$NamedConstructorModelNameField,
        model.name,
      ),
      'value': registry.encodeField(
        _$NamedConstructorModelValueField,
        model.value,
      ),
    };
  }

  @override
  NamedConstructorModel decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int? namedConstructorModelIdValue = registry.decodeField<int?>(
      _$NamedConstructorModelIdField,
      data['id'],
    );
    final String namedConstructorModelNameValue =
        registry.decodeField<String>(
          _$NamedConstructorModelNameField,
          data['name'],
        ) ??
        (throw StateError(
          'Field name on NamedConstructorModel cannot be null.',
        ));
    final int namedConstructorModelValueValue =
        registry.decodeField<int>(
          _$NamedConstructorModelValueField,
          data['value'],
        ) ??
        (throw StateError(
          'Field value on NamedConstructorModel cannot be null.',
        ));
    final model = _$NamedConstructorModelModel(
      id: namedConstructorModelIdValue,
      name: namedConstructorModelNameValue,
      value: namedConstructorModelValueValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': namedConstructorModelIdValue,
      'name': namedConstructorModelNameValue,
      'value': namedConstructorModelValueValue,
    });
    return model;
  }
}

class _$NamedConstructorModelModel extends NamedConstructorModel {
  _$NamedConstructorModelModel({
    required int? id,
    required String name,
    required int value,
  }) : super.fromDatabase(id: id, name: name, value: value) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name, 'value': value});
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  set name(String value) => setAttribute('name', value);

  @override
  int get value => getAttribute<int>('value') ?? super.value;

  set value(int value) => setAttribute('value', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$NamedConstructorModelModelDefinition);
  }
}

extension NamedConstructorModelAttributeSetters on NamedConstructorModel {
  set id(int? value) => setAttribute('id', value);
  set name(String value) => setAttribute('name', value);
  set value(int value) => setAttribute('value', value);
}
