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

class ActiveUsers {
  const ActiveUsers._();

  static Query<ActiveUser> query([String? connection]) =>
      Model.query<ActiveUser>(connection: connection);

  static Future<ActiveUser?> find(Object id, {String? connection}) =>
      Model.find<ActiveUser>(id, connection: connection);

  static Future<ActiveUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<ActiveUser>(id, connection: connection);

  static Future<List<ActiveUser>> all({String? connection}) =>
      Model.all<ActiveUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<ActiveUser>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<ActiveUser>(connection: connection);

  static Query<ActiveUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<ActiveUser>(column, operator, value, connection: connection);

  static Query<ActiveUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<ActiveUser>(column, values, connection: connection);

  static Query<ActiveUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<ActiveUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<ActiveUser> limit(int count, {String? connection}) =>
      Model.limit<ActiveUser>(count, connection: connection);
}

class ActiveUserModelFactory {
  const ActiveUserModelFactory._();

  static ModelDefinition<ActiveUser> get definition =>
      _$ActiveUserModelDefinition;

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

  static ModelFactoryBuilder<ActiveUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<ActiveUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
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
    required Map<String, Object?> settings,
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
