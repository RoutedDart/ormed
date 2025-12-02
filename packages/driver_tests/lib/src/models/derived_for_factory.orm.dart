// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'derived_for_factory.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DerivedForFactoryLayerTwoFlagField = FieldDefinition(
  name: 'layerTwoFlag',
  columnName: 'layerTwoFlag',
  dartType: 'bool',
  resolvedType: 'bool?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$DerivedForFactoryLayerOneNotesField = FieldDefinition(
  name: 'layerOneNotes',
  columnName: 'layerOneNotes',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$DerivedForFactoryIdField = FieldDefinition(
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

const FieldDefinition _$DerivedForFactoryBaseNameField = FieldDefinition(
  name: 'baseName',
  columnName: 'baseName',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<DerivedForFactory> _$DerivedForFactoryModelDefinition =
    ModelDefinition(
      modelName: 'DerivedForFactory',
      tableName: 'derived_for_factories',
      fields: const [
        _$DerivedForFactoryLayerTwoFlagField,
        _$DerivedForFactoryLayerOneNotesField,
        _$DerivedForFactoryIdField,
        _$DerivedForFactoryBaseNameField,
      ],
      relations: const [],
      softDeleteColumn: 'deleted_at',
      metadata: ModelAttributesMetadata(
        hidden: const <String>[],
        visible: const <String>[],
        fillable: const <String>[],
        guarded: const <String>[],
        casts: const <String, String>{},
        fieldOverrides: const {
          'layerTwoFlag': FieldAttributeMetadata(guarded: true),
          'layerOneNotes': FieldAttributeMetadata(cast: 'json'),
          'id': FieldAttributeMetadata(hidden: true),
          'baseName': FieldAttributeMetadata(fillable: true),
        },
        softDeletes: false,
        softDeleteColumn: 'deleted_at',
      ),
      codec: _$DerivedForFactoryModelCodec(),
    );

// ignore: unused_element
final derivedforfactoryModelDefinitionRegistration =
    ModelFactoryRegistry.register<DerivedForFactory>(
      _$DerivedForFactoryModelDefinition,
    );

extension DerivedForFactoryOrmDefinition on DerivedForFactory {
  static ModelDefinition<DerivedForFactory> get definition =>
      _$DerivedForFactoryModelDefinition;
}

class DerivedForFactoryModelFactory {
  const DerivedForFactoryModelFactory._();

  static ModelDefinition<DerivedForFactory> get definition =>
      DerivedForFactoryOrmDefinition.definition;

  static ModelCodec<DerivedForFactory> get codec => definition.codec;

  static DerivedForFactory fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DerivedForFactory model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DerivedForFactory> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DerivedForFactory>(
    definition: definition,
    context: context,
  );

  static Query<DerivedForFactory> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<DerivedForFactory>();
  }

  static ModelFactoryBuilder<DerivedForFactory> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DerivedForFactory>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<DerivedForFactory>> all([String? connection]) =>
      query(connection).get();

  static Future<DerivedForFactory> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$DerivedForFactoryModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DerivedForFactory>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<DerivedForFactory>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$DerivedForFactoryModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DerivedForFactory>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$DerivedForFactoryModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DerivedForFactory>();
    await repo.insertMany(models, returning: false);
  }

  static Future<DerivedForFactory?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<DerivedForFactory> findOrFail(
    Object id, [
    String? connection,
  ]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<DerivedForFactory>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<DerivedForFactory?> first([String? connection]) =>
      query(connection).first();

  static Future<DerivedForFactory> firstOrFail([String? connection]) async {
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

  static Query<DerivedForFactory> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<DerivedForFactory> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<DerivedForFactory> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<DerivedForFactory> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension DerivedForFactoryModelHelpers on DerivedForFactory {
  // Factory
  static ModelFactoryBuilder<DerivedForFactory> factory({
    GeneratorProvider? generatorProvider,
  }) => DerivedForFactoryModelFactory.factory(
    generatorProvider: generatorProvider,
  );

  // Query builder
  static Query<DerivedForFactory> query([String? connection]) =>
      DerivedForFactoryModelFactory.query(connection);

  // CRUD operations
  static Future<List<DerivedForFactory>> all([String? connection]) =>
      DerivedForFactoryModelFactory.all(connection);

  static Future<DerivedForFactory?> find(Object id, [String? connection]) =>
      DerivedForFactoryModelFactory.find(id, connection);

  static Future<DerivedForFactory> findOrFail(
    Object id, [
    String? connection,
  ]) => DerivedForFactoryModelFactory.findOrFail(id, connection);

  static Future<List<DerivedForFactory>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => DerivedForFactoryModelFactory.findMany(ids, connection);

  static Future<DerivedForFactory?> first([String? connection]) =>
      DerivedForFactoryModelFactory.first(connection);

  static Future<DerivedForFactory> firstOrFail([String? connection]) =>
      DerivedForFactoryModelFactory.firstOrFail(connection);

  static Future<DerivedForFactory> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => DerivedForFactoryModelFactory.create(attributes, connection);

  static Future<List<DerivedForFactory>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => DerivedForFactoryModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => DerivedForFactoryModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      DerivedForFactoryModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      DerivedForFactoryModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      DerivedForFactoryModelFactory.exists(connection);

  static Query<DerivedForFactory> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => DerivedForFactoryModelFactory.where(column, value, connection);

  static Query<DerivedForFactory> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => DerivedForFactoryModelFactory.whereIn(column, values, connection);

  static Query<DerivedForFactory> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => DerivedForFactoryModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<DerivedForFactory> limit(int count, [String? connection]) =>
      DerivedForFactoryModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ??
        DerivedForFactoryModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<DerivedForFactory>();
    final primaryKeys = DerivedForFactoryModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: DerivedForFactoryModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$DerivedForFactoryModelCodec extends ModelCodec<DerivedForFactory> {
  const _$DerivedForFactoryModelCodec();

  @override
  Map<String, Object?> encode(
    DerivedForFactory model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'layerTwoFlag': registry.encodeField(
        _$DerivedForFactoryLayerTwoFlagField,
        model.layerTwoFlag,
      ),
      'layerOneNotes': registry.encodeField(
        _$DerivedForFactoryLayerOneNotesField,
        model.layerOneNotes,
      ),
      'id': registry.encodeField(_$DerivedForFactoryIdField, model.id),
      'baseName': registry.encodeField(
        _$DerivedForFactoryBaseNameField,
        model.baseName,
      ),
    };
  }

  @override
  DerivedForFactory decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final bool? derivedForFactoryLayerTwoFlagValue = registry
        .decodeField<bool?>(
          _$DerivedForFactoryLayerTwoFlagField,
          data['layerTwoFlag'],
        );
    final Map<String, Object?>? derivedForFactoryLayerOneNotesValue = registry
        .decodeField<Map<String, Object?>?>(
          _$DerivedForFactoryLayerOneNotesField,
          data['layerOneNotes'],
        );
    final int derivedForFactoryIdValue =
        registry.decodeField<int>(_$DerivedForFactoryIdField, data['id']) ??
        (throw StateError('Field id on DerivedForFactory cannot be null.'));
    final String? derivedForFactoryBaseNameValue = registry
        .decodeField<String?>(
          _$DerivedForFactoryBaseNameField,
          data['baseName'],
        );
    final model = _$DerivedForFactoryModel(
      id: derivedForFactoryIdValue,
      baseName: derivedForFactoryBaseNameValue,
      layerOneNotes: derivedForFactoryLayerOneNotesValue,
      layerTwoFlag: derivedForFactoryLayerTwoFlagValue,
    );
    model._attachOrmRuntimeMetadata({
      'layerTwoFlag': derivedForFactoryLayerTwoFlagValue,
      'layerOneNotes': derivedForFactoryLayerOneNotesValue,
      'id': derivedForFactoryIdValue,
      'baseName': derivedForFactoryBaseNameValue,
    });
    return model;
  }
}

class _$DerivedForFactoryModel extends DerivedForFactory {
  _$DerivedForFactoryModel({
    required int id,
    String? baseName,
    Map<String, Object?>? layerOneNotes,
    bool? layerTwoFlag,
  }) : super.new(
         id: id,
         baseName: baseName,
         layerOneNotes: layerOneNotes,
         layerTwoFlag: layerTwoFlag,
       ) {
    _attachOrmRuntimeMetadata({
      'layerTwoFlag': layerTwoFlag,
      'layerOneNotes': layerOneNotes,
      'id': id,
      'baseName': baseName,
    });
  }

  @override
  bool? get layerTwoFlag =>
      getAttribute<bool?>('layerTwoFlag') ?? super.layerTwoFlag;

  set layerTwoFlag(bool? value) => setAttribute('layerTwoFlag', value);

  @override
  Map<String, Object?>? get layerOneNotes =>
      getAttribute<Map<String, Object?>?>('layerOneNotes') ??
      super.layerOneNotes;

  set layerOneNotes(Map<String, Object?>? value) =>
      setAttribute('layerOneNotes', value);

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String? get baseName => getAttribute<String?>('baseName') ?? super.baseName;

  set baseName(String? value) => setAttribute('baseName', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$DerivedForFactoryModelDefinition);
  }
}

extension DerivedForFactoryAttributeSetters on DerivedForFactory {
  set layerTwoFlag(bool? value) => setAttribute('layerTwoFlag', value);
  set layerOneNotes(Map<String, Object?>? value) =>
      setAttribute('layerOneNotes', value);
  set id(int value) => setAttribute('id', value);
  set baseName(String? value) => setAttribute('baseName', value);
}
