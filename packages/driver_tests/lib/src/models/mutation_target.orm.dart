// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'mutation_target.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$MutationTargetIdField = FieldDefinition(
  name: 'id',
  columnName: '_id',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetCategoryField = FieldDefinition(
  name: 'category',
  columnName: 'category',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<MutationTarget> _$MutationTargetModelDefinition =
    ModelDefinition(
      modelName: 'MutationTarget',
      tableName: 'mutation_targets',
      fields: const [
        _$MutationTargetIdField,
        _$MutationTargetNameField,
        _$MutationTargetActiveField,
        _$MutationTargetCategoryField,
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
      codec: _$MutationTargetModelCodec(),
    );

// ignore: unused_element
final mutationtargetModelDefinitionRegistration =
    ModelFactoryRegistry.register<MutationTarget>(
      _$MutationTargetModelDefinition,
    );

extension MutationTargetOrmDefinition on MutationTarget {
  static ModelDefinition<MutationTarget> get definition =>
      _$MutationTargetModelDefinition;
}

class MutationTargetModelFactory {
  const MutationTargetModelFactory._();

  static ModelDefinition<MutationTarget> get definition =>
      MutationTargetOrmDefinition.definition;

  static ModelCodec<MutationTarget> get codec => definition.codec;

  static MutationTarget fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MutationTarget model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MutationTarget> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MutationTarget>(
    definition: definition,
    context: context,
  );

  static Query<MutationTarget> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<MutationTarget>();
  }

  static ModelFactoryBuilder<MutationTarget> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MutationTarget>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<MutationTarget>> all([String? connection]) =>
      query(connection).get();

  static Future<MutationTarget> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$MutationTargetModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<MutationTarget>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<MutationTarget>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$MutationTargetModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<MutationTarget>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$MutationTargetModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<MutationTarget>();
    await repo.insertMany(models, returning: false);
  }

  static Future<MutationTarget?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<MutationTarget> findOrFail(
    Object id, [
    String? connection,
  ]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<MutationTarget>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<MutationTarget?> first([String? connection]) =>
      query(connection).first();

  static Future<MutationTarget> firstOrFail([String? connection]) async {
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

  static Query<MutationTarget> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<MutationTarget> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<MutationTarget> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<MutationTarget> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension MutationTargetModelHelpers on MutationTarget {
  // Factory
  static ModelFactoryBuilder<MutationTarget> factory({
    GeneratorProvider? generatorProvider,
  }) =>
      MutationTargetModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<MutationTarget> query([String? connection]) =>
      MutationTargetModelFactory.query(connection);

  // CRUD operations
  static Future<List<MutationTarget>> all([String? connection]) =>
      MutationTargetModelFactory.all(connection);

  static Future<MutationTarget?> find(Object id, [String? connection]) =>
      MutationTargetModelFactory.find(id, connection);

  static Future<MutationTarget> findOrFail(Object id, [String? connection]) =>
      MutationTargetModelFactory.findOrFail(id, connection);

  static Future<List<MutationTarget>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => MutationTargetModelFactory.findMany(ids, connection);

  static Future<MutationTarget?> first([String? connection]) =>
      MutationTargetModelFactory.first(connection);

  static Future<MutationTarget> firstOrFail([String? connection]) =>
      MutationTargetModelFactory.firstOrFail(connection);

  static Future<MutationTarget> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => MutationTargetModelFactory.create(attributes, connection);

  static Future<List<MutationTarget>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => MutationTargetModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => MutationTargetModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      MutationTargetModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      MutationTargetModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      MutationTargetModelFactory.exists(connection);

  static Query<MutationTarget> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => MutationTargetModelFactory.where(column, value, connection);

  static Query<MutationTarget> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => MutationTargetModelFactory.whereIn(column, values, connection);

  static Query<MutationTarget> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => MutationTargetModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<MutationTarget> limit(int count, [String? connection]) =>
      MutationTargetModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? MutationTargetModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<MutationTarget>();
    final primaryKeys = MutationTargetModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: MutationTargetModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$MutationTargetModelCodec extends ModelCodec<MutationTarget> {
  const _$MutationTargetModelCodec();

  @override
  Map<String, Object?> encode(
    MutationTarget model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      '_id': registry.encodeField(_$MutationTargetIdField, model.id),
      'name': registry.encodeField(_$MutationTargetNameField, model.name),
      'active': registry.encodeField(_$MutationTargetActiveField, model.active),
      'category': registry.encodeField(
        _$MutationTargetCategoryField,
        model.category,
      ),
    };
  }

  @override
  MutationTarget decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final String mutationTargetIdValue =
        registry.decodeField<String>(_$MutationTargetIdField, data['_id']) ??
        (throw StateError('Field id on MutationTarget cannot be null.'));
    final String? mutationTargetNameValue = registry.decodeField<String?>(
      _$MutationTargetNameField,
      data['name'],
    );
    final bool? mutationTargetActiveValue = registry.decodeField<bool?>(
      _$MutationTargetActiveField,
      data['active'],
    );
    final String? mutationTargetCategoryValue = registry.decodeField<String?>(
      _$MutationTargetCategoryField,
      data['category'],
    );
    final model = _$MutationTargetModel(
      id: mutationTargetIdValue,
      name: mutationTargetNameValue,
      active: mutationTargetActiveValue,
      category: mutationTargetCategoryValue,
    );
    model._attachOrmRuntimeMetadata({
      '_id': mutationTargetIdValue,
      'name': mutationTargetNameValue,
      'active': mutationTargetActiveValue,
      'category': mutationTargetCategoryValue,
    });
    return model;
  }
}

class _$MutationTargetModel extends MutationTarget {
  _$MutationTargetModel({
    required String id,
    String? name,
    bool? active,
    String? category,
  }) : super.new(id: id, name: name, active: active, category: category) {
    _attachOrmRuntimeMetadata({
      '_id': id,
      'name': name,
      'active': active,
      'category': category,
    });
  }

  @override
  String get id => getAttribute<String>('_id') ?? super.id;

  set id(String value) => setAttribute('_id', value);

  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  set name(String? value) => setAttribute('name', value);

  @override
  bool? get active => getAttribute<bool?>('active') ?? super.active;

  set active(bool? value) => setAttribute('active', value);

  @override
  String? get category => getAttribute<String?>('category') ?? super.category;

  set category(String? value) => setAttribute('category', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MutationTargetModelDefinition);
  }
}

extension MutationTargetAttributeSetters on MutationTarget {
  set id(String value) => setAttribute('_id', value);
  set name(String? value) => setAttribute('name', value);
  set active(bool? value) => setAttribute('active', value);
  set category(String? value) => setAttribute('category', value);
}
