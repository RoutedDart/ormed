// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'active_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ActiveUserIdField = FieldDefinition(
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

const FieldDefinition _$ActiveUserEmailField = FieldDefinition(
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

const FieldDefinition _$ActiveUserNameField = FieldDefinition(
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

const FieldDefinition _$ActiveUserSettingsField = FieldDefinition(
  name: 'settings',
  columnName: 'settings',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  columnType: 'json',
);

const FieldDefinition _$ActiveUserDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'deleted_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<ActiveUser> _$ActiveUserModelDefinition = ModelDefinition(
  modelName: 'ActiveUser',
  tableName: 'active_users',
  fields: const [
    _$ActiveUserIdField,
    _$ActiveUserEmailField,
    _$ActiveUserNameField,
    _$ActiveUserSettingsField,
    _$ActiveUserDeletedAtField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    connection: 'analytics',
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$ActiveUserModelCodec(),
);

extension ActiveUserOrmDefinition on ActiveUser {
  static ModelDefinition<ActiveUser> get definition =>
      _$ActiveUserModelDefinition;
}

class ActiveUserModelFactory {
  const ActiveUserModelFactory._();

  static ModelDefinition<ActiveUser> get definition =>
      ActiveUserOrmDefinition.definition;

  static ModelCodec<ActiveUser> get codec => definition.codec;

  static ActiveUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    ActiveUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<ActiveUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<ActiveUser>(
    definition: definition,
    context: context,
  );

  static Query<ActiveUser> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<ActiveUser>();
  }

  static ModelFactoryBuilder<ActiveUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<ActiveUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<ActiveUser>> all([String? connection]) =>
      query(connection).get();

  static Future<ActiveUser> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$ActiveUserModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<ActiveUser>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<ActiveUser>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$ActiveUserModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<ActiveUser>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$ActiveUserModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<ActiveUser>();
    await repo.insertMany(models, returning: false);
  }

  static Future<ActiveUser?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<ActiveUser> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<ActiveUser>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<ActiveUser?> first([String? connection]) =>
      query(connection).first();

  static Future<ActiveUser> firstOrFail([String? connection]) async {
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

  static Query<ActiveUser> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<ActiveUser> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<ActiveUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<ActiveUser> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension ActiveUserModelHelpers on ActiveUser {
  // Factory
  static ModelFactoryBuilder<ActiveUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ActiveUserModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<ActiveUser> query([String? connection]) =>
      ActiveUserModelFactory.query(connection);

  // CRUD operations
  static Future<List<ActiveUser>> all([String? connection]) =>
      ActiveUserModelFactory.all(connection);

  static Future<ActiveUser?> find(Object id, [String? connection]) =>
      ActiveUserModelFactory.find(id, connection);

  static Future<ActiveUser> findOrFail(Object id, [String? connection]) =>
      ActiveUserModelFactory.findOrFail(id, connection);

  static Future<List<ActiveUser>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => ActiveUserModelFactory.findMany(ids, connection);

  static Future<ActiveUser?> first([String? connection]) =>
      ActiveUserModelFactory.first(connection);

  static Future<ActiveUser> firstOrFail([String? connection]) =>
      ActiveUserModelFactory.firstOrFail(connection);

  static Future<ActiveUser> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => ActiveUserModelFactory.create(attributes, connection);

  static Future<List<ActiveUser>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => ActiveUserModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => ActiveUserModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      ActiveUserModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      ActiveUserModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      ActiveUserModelFactory.exists(connection);

  static Query<ActiveUser> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => ActiveUserModelFactory.where(column, value, connection);

  static Query<ActiveUser> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => ActiveUserModelFactory.whereIn(column, values, connection);

  static Query<ActiveUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => ActiveUserModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<ActiveUser> limit(int count, [String? connection]) =>
      ActiveUserModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? ActiveUserModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<ActiveUser>();
    final primaryKeys = ActiveUserModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: ActiveUserModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$ActiveUserModelCodec extends ModelCodec<ActiveUser> {
  const _$ActiveUserModelCodec();

  @override
  Map<String, Object?> encode(ActiveUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ActiveUserIdField, model.id),
      'email': registry.encodeField(_$ActiveUserEmailField, model.email),
      'name': registry.encodeField(_$ActiveUserNameField, model.name),
      'settings': registry.encodeField(
        _$ActiveUserSettingsField,
        model.settings,
      ),
      'deleted_at': registry.encodeField(
        _$ActiveUserDeletedAtField,
        model.getAttribute<DateTime?>('deleted_at'),
      ),
    };
  }

  @override
  ActiveUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? activeUserIdValue = registry.decodeField<int?>(
      _$ActiveUserIdField,
      data['id'],
    );
    final String activeUserEmailValue =
        registry.decodeField<String>(_$ActiveUserEmailField, data['email']) ??
        (throw StateError('Field email on ActiveUser cannot be null.'));
    final String? activeUserNameValue = registry.decodeField<String?>(
      _$ActiveUserNameField,
      data['name'],
    );
    final Map<String, Object?> activeUserSettingsValue =
        registry.decodeField<Map<String, Object?>>(
          _$ActiveUserSettingsField,
          data['settings'],
        ) ??
        (throw StateError('Field settings on ActiveUser cannot be null.'));
    final DateTime? activeUserDeletedAtValue = registry.decodeField<DateTime?>(
      _$ActiveUserDeletedAtField,
      data['deleted_at'],
    );
    final model = _$ActiveUserModel(
      id: activeUserIdValue,
      email: activeUserEmailValue,
      name: activeUserNameValue,
      settings: activeUserSettingsValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': activeUserIdValue,
      'email': activeUserEmailValue,
      'name': activeUserNameValue,
      'settings': activeUserSettingsValue,
      'deleted_at': activeUserDeletedAtValue,
    });
    return model;
  }
}

class _$ActiveUserModel extends ActiveUser {
  _$ActiveUserModel({
    int? id,
    required String email,
    String? name,
    Map<String, Object?> settings = const <String, Object?>{},
  }) : super.new(id: id, email: email, name: name, settings: settings) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'name': name,
      'settings': settings,
    });
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  set email(String value) => setAttribute('email', value);

  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  set name(String? value) => setAttribute('name', value);

  @override
  Map<String, Object?> get settings =>
      getAttribute<Map<String, Object?>>('settings') ?? super.settings;

  set settings(Map<String, Object?> value) => setAttribute('settings', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ActiveUserModelDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension ActiveUserAttributeSetters on ActiveUser {
  set id(int? value) => setAttribute('id', value);
  set email(String value) => setAttribute('email', value);
  set name(String? value) => setAttribute('name', value);
  set settings(Map<String, Object?> value) => setAttribute('settings', value);
}
