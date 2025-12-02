// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'unique_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$UniqueUserIdField = FieldDefinition(
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

const FieldDefinition _$UniqueUserEmailField = FieldDefinition(
  name: 'email',
  columnName: 'email',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$UniqueUserActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<UniqueUser> _$UniqueUserModelDefinition = ModelDefinition(
  modelName: 'UniqueUser',
  tableName: 'unique_users',
  fields: const [
    _$UniqueUserIdField,
    _$UniqueUserEmailField,
    _$UniqueUserActiveField,
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
  codec: _$UniqueUserModelCodec(),
);

// ignore: unused_element
final uniqueuserModelDefinitionRegistration =
    ModelFactoryRegistry.register<UniqueUser>(_$UniqueUserModelDefinition);

extension UniqueUserOrmDefinition on UniqueUser {
  static ModelDefinition<UniqueUser> get definition =>
      _$UniqueUserModelDefinition;
}

class UniqueUserModelFactory {
  const UniqueUserModelFactory._();

  static ModelDefinition<UniqueUser> get definition =>
      UniqueUserOrmDefinition.definition;

  static ModelCodec<UniqueUser> get codec => definition.codec;

  static UniqueUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    UniqueUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<UniqueUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<UniqueUser>(
    definition: definition,
    context: context,
  );

  static Query<UniqueUser> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<UniqueUser>();
  }

  static ModelFactoryBuilder<UniqueUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<UniqueUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<UniqueUser>> all([String? connection]) =>
      query(connection).get();

  static Future<UniqueUser> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$UniqueUserModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<UniqueUser>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<UniqueUser>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$UniqueUserModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<UniqueUser>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$UniqueUserModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<UniqueUser>();
    await repo.insertMany(models, returning: false);
  }

  static Future<UniqueUser?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<UniqueUser> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<UniqueUser>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<UniqueUser?> first([String? connection]) =>
      query(connection).first();

  static Future<UniqueUser> firstOrFail([String? connection]) async {
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

  static Query<UniqueUser> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<UniqueUser> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<UniqueUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<UniqueUser> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension UniqueUserModelHelpers on UniqueUser {
  // Factory
  static ModelFactoryBuilder<UniqueUser> factory({
    GeneratorProvider? generatorProvider,
  }) => UniqueUserModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<UniqueUser> query([String? connection]) =>
      UniqueUserModelFactory.query(connection);

  // CRUD operations
  static Future<List<UniqueUser>> all([String? connection]) =>
      UniqueUserModelFactory.all(connection);

  static Future<UniqueUser?> find(Object id, [String? connection]) =>
      UniqueUserModelFactory.find(id, connection);

  static Future<UniqueUser> findOrFail(Object id, [String? connection]) =>
      UniqueUserModelFactory.findOrFail(id, connection);

  static Future<List<UniqueUser>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => UniqueUserModelFactory.findMany(ids, connection);

  static Future<UniqueUser?> first([String? connection]) =>
      UniqueUserModelFactory.first(connection);

  static Future<UniqueUser> firstOrFail([String? connection]) =>
      UniqueUserModelFactory.firstOrFail(connection);

  static Future<UniqueUser> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => UniqueUserModelFactory.create(attributes, connection);

  static Future<List<UniqueUser>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => UniqueUserModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => UniqueUserModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      UniqueUserModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      UniqueUserModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      UniqueUserModelFactory.exists(connection);

  static Query<UniqueUser> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => UniqueUserModelFactory.where(column, value, connection);

  static Query<UniqueUser> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => UniqueUserModelFactory.whereIn(column, values, connection);

  static Query<UniqueUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => UniqueUserModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<UniqueUser> limit(int count, [String? connection]) =>
      UniqueUserModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? UniqueUserModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<UniqueUser>();
    final primaryKeys = UniqueUserModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: UniqueUserModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$UniqueUserModelCodec extends ModelCodec<UniqueUser> {
  const _$UniqueUserModelCodec();

  @override
  Map<String, Object?> encode(UniqueUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UniqueUserIdField, model.id),
      'email': registry.encodeField(_$UniqueUserEmailField, model.email),
      'active': registry.encodeField(_$UniqueUserActiveField, model.active),
    };
  }

  @override
  UniqueUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int uniqueUserIdValue =
        registry.decodeField<int>(_$UniqueUserIdField, data['id']) ??
        (throw StateError('Field id on UniqueUser cannot be null.'));
    final String uniqueUserEmailValue =
        registry.decodeField<String>(_$UniqueUserEmailField, data['email']) ??
        (throw StateError('Field email on UniqueUser cannot be null.'));
    final bool uniqueUserActiveValue =
        registry.decodeField<bool>(_$UniqueUserActiveField, data['active']) ??
        (throw StateError('Field active on UniqueUser cannot be null.'));
    final model = _$UniqueUserModel(
      id: uniqueUserIdValue,
      email: uniqueUserEmailValue,
      active: uniqueUserActiveValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': uniqueUserIdValue,
      'email': uniqueUserEmailValue,
      'active': uniqueUserActiveValue,
    });
    return model;
  }
}

class _$UniqueUserModel extends UniqueUser {
  _$UniqueUserModel({
    required int id,
    required String email,
    required bool active,
  }) : super.new(id: id, email: email, active: active) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email, 'active': active});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  set email(String value) => setAttribute('email', value);

  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  set active(bool value) => setAttribute('active', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UniqueUserModelDefinition);
  }
}

extension UniqueUserAttributeSetters on UniqueUser {
  set id(int value) => setAttribute('id', value);
  set email(String value) => setAttribute('email', value);
  set active(bool value) => setAttribute('active', value);
}
