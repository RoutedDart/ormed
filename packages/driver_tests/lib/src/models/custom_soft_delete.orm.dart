// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'custom_soft_delete.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CustomSoftDeleteIdField = FieldDefinition(
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

const FieldDefinition _$CustomSoftDeleteTitleField = FieldDefinition(
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

const FieldDefinition _$CustomSoftDeleteDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'removed_on',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<CustomSoftDelete> _$CustomSoftDeleteModelDefinition =
    ModelDefinition(
      modelName: 'CustomSoftDelete',
      tableName: 'custom_soft_delete_models',
      fields: const [
        _$CustomSoftDeleteIdField,
        _$CustomSoftDeleteTitleField,
        _$CustomSoftDeleteDeletedAtField,
      ],
      relations: const [],
      softDeleteColumn: 'removed_on',
      metadata: ModelAttributesMetadata(
        hidden: const <String>[],
        visible: const <String>[],
        fillable: const <String>[],
        guarded: const <String>[],
        casts: const <String, String>{},
        softDeletes: true,
        softDeleteColumn: 'removed_on',
      ),
      codec: _$CustomSoftDeleteModelCodec(),
    );

extension CustomSoftDeleteOrmDefinition on CustomSoftDelete {
  static ModelDefinition<CustomSoftDelete> get definition =>
      _$CustomSoftDeleteModelDefinition;
}

class CustomSoftDeleteModelFactory {
  const CustomSoftDeleteModelFactory._();

  static ModelDefinition<CustomSoftDelete> get definition =>
      CustomSoftDeleteOrmDefinition.definition;

  static ModelCodec<CustomSoftDelete> get codec => definition.codec;

  static CustomSoftDelete fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    CustomSoftDelete model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<CustomSoftDelete> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<CustomSoftDelete>(
    definition: definition,
    context: context,
  );

  static Query<CustomSoftDelete> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<CustomSoftDelete>();
  }

  static ModelFactoryBuilder<CustomSoftDelete> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<CustomSoftDelete>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<CustomSoftDelete>> all([String? connection]) =>
      query(connection).get();

  static Future<CustomSoftDelete> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$CustomSoftDeleteModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<CustomSoftDelete>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<CustomSoftDelete>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$CustomSoftDeleteModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<CustomSoftDelete>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$CustomSoftDeleteModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<CustomSoftDelete>();
    await repo.insertMany(models, returning: false);
  }

  static Future<CustomSoftDelete?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<CustomSoftDelete> findOrFail(
    Object id, [
    String? connection,
  ]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<CustomSoftDelete>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<CustomSoftDelete?> first([String? connection]) =>
      query(connection).first();

  static Future<CustomSoftDelete> firstOrFail([String? connection]) async {
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

  static Query<CustomSoftDelete> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<CustomSoftDelete> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<CustomSoftDelete> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<CustomSoftDelete> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension CustomSoftDeleteModelHelpers on CustomSoftDelete {
  // Factory
  static ModelFactoryBuilder<CustomSoftDelete> factory({
    GeneratorProvider? generatorProvider,
  }) => CustomSoftDeleteModelFactory.factory(
    generatorProvider: generatorProvider,
  );

  // Query builder
  static Query<CustomSoftDelete> query([String? connection]) =>
      CustomSoftDeleteModelFactory.query(connection);

  // CRUD operations
  static Future<List<CustomSoftDelete>> all([String? connection]) =>
      CustomSoftDeleteModelFactory.all(connection);

  static Future<CustomSoftDelete?> find(Object id, [String? connection]) =>
      CustomSoftDeleteModelFactory.find(id, connection);

  static Future<CustomSoftDelete> findOrFail(Object id, [String? connection]) =>
      CustomSoftDeleteModelFactory.findOrFail(id, connection);

  static Future<List<CustomSoftDelete>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => CustomSoftDeleteModelFactory.findMany(ids, connection);

  static Future<CustomSoftDelete?> first([String? connection]) =>
      CustomSoftDeleteModelFactory.first(connection);

  static Future<CustomSoftDelete> firstOrFail([String? connection]) =>
      CustomSoftDeleteModelFactory.firstOrFail(connection);

  static Future<CustomSoftDelete> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => CustomSoftDeleteModelFactory.create(attributes, connection);

  static Future<List<CustomSoftDelete>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => CustomSoftDeleteModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => CustomSoftDeleteModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      CustomSoftDeleteModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      CustomSoftDeleteModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      CustomSoftDeleteModelFactory.exists(connection);

  static Query<CustomSoftDelete> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => CustomSoftDeleteModelFactory.where(column, value, connection);

  static Query<CustomSoftDelete> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => CustomSoftDeleteModelFactory.whereIn(column, values, connection);

  static Query<CustomSoftDelete> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => CustomSoftDeleteModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<CustomSoftDelete> limit(int count, [String? connection]) =>
      CustomSoftDeleteModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ??
        CustomSoftDeleteModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<CustomSoftDelete>();
    final primaryKeys = CustomSoftDeleteModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: CustomSoftDeleteModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$CustomSoftDeleteModelCodec extends ModelCodec<CustomSoftDelete> {
  const _$CustomSoftDeleteModelCodec();

  @override
  Map<String, Object?> encode(
    CustomSoftDelete model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$CustomSoftDeleteIdField, model.id),
      'title': registry.encodeField(_$CustomSoftDeleteTitleField, model.title),
      'removed_on': registry.encodeField(
        _$CustomSoftDeleteDeletedAtField,
        model.getAttribute<DateTime?>('removed_on'),
      ),
    };
  }

  @override
  CustomSoftDelete decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int customSoftDeleteIdValue =
        registry.decodeField<int>(_$CustomSoftDeleteIdField, data['id']) ??
        (throw StateError('Field id on CustomSoftDelete cannot be null.'));
    final String customSoftDeleteTitleValue =
        registry.decodeField<String>(
          _$CustomSoftDeleteTitleField,
          data['title'],
        ) ??
        (throw StateError('Field title on CustomSoftDelete cannot be null.'));
    final DateTime? customSoftDeleteDeletedAtValue = registry
        .decodeField<DateTime?>(
          _$CustomSoftDeleteDeletedAtField,
          data['removed_on'],
        );
    final model = _$CustomSoftDeleteModel(
      id: customSoftDeleteIdValue,
      title: customSoftDeleteTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': customSoftDeleteIdValue,
      'title': customSoftDeleteTitleValue,
      'removed_on': customSoftDeleteDeletedAtValue,
    });
    return model;
  }
}

class _$CustomSoftDeleteModel extends CustomSoftDelete {
  _$CustomSoftDeleteModel({required int id, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  set title(String value) => setAttribute('title', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CustomSoftDeleteModelDefinition);
    attachSoftDeleteColumn('removed_on');
  }
}

extension CustomSoftDeleteAttributeSetters on CustomSoftDelete {
  set id(int value) => setAttribute('id', value);
  set title(String value) => setAttribute('title', value);
}
