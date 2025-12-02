// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$UserIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$UserEmailField = FieldDefinition(
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

const FieldDefinition _$UserNameField = FieldDefinition(
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

const FieldDefinition _$UserActiveField = FieldDefinition(
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

const FieldDefinition _$UserCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'created_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$UserUpdatedAtField = FieldDefinition(
  name: 'updatedAt',
  columnName: 'updated_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<User> _$UserModelDefinition = ModelDefinition(
  modelName: 'User',
  tableName: 'users',
  fields: const [
    _$UserIdField,
    _$UserEmailField,
    _$UserNameField,
    _$UserActiveField,
    _$UserCreatedAtField,
    _$UserUpdatedAtField,
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
  codec: _$UserModelCodec(),
);

extension UserOrmDefinition on User {
  static ModelDefinition<User> get definition => _$UserModelDefinition;
}

class Users {
  const Users._();

  static Query<User> query([String? connection]) =>
      Model.query<User>(connection: connection);

  static Future<User?> find(Object id, {String? connection}) =>
      Model.find<User>(id, connection: connection);

  static Future<User> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<User>(id, connection: connection);

  static Future<List<User>> all({String? connection}) =>
      Model.all<User>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<User>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<User>(connection: connection);

  static Query<User> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<User>(column, operator, value, connection: connection);

  static Query<User> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<User>(column, values, connection: connection);

  static Query<User> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) =>
      Model.orderBy<User>(column, direction: direction, connection: connection);

  static Query<User> limit(int count, {String? connection}) =>
      Model.limit<User>(count, connection: connection);
}

class UserModelFactory {
  const UserModelFactory._();

  static ModelDefinition<User> get definition => _$UserModelDefinition;

  static ModelCodec<User> get codec => definition.codec;

  static User fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    User model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryBuilder<User> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<User>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$UserModelCodec extends ModelCodec<User> {
  const _$UserModelCodec();

  @override
  Map<String, Object?> encode(User model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserIdField, model.id),
      'email': registry.encodeField(_$UserEmailField, model.email),
      'name': registry.encodeField(_$UserNameField, model.name),
      'active': registry.encodeField(_$UserActiveField, model.active),
      'created_at': registry.encodeField(_$UserCreatedAtField, model.createdAt),
      'updated_at': registry.encodeField(_$UserUpdatedAtField, model.updatedAt),
    };
  }

  @override
  User decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? userIdValue = registry.decodeField<int?>(
      _$UserIdField,
      data['id'],
    );
    final String userEmailValue =
        registry.decodeField<String>(_$UserEmailField, data['email']) ??
        (throw StateError('Field email on User cannot be null.'));
    final String userNameValue =
        registry.decodeField<String>(_$UserNameField, data['name']) ??
        (throw StateError('Field name on User cannot be null.'));
    final bool userActiveValue =
        registry.decodeField<bool>(_$UserActiveField, data['active']) ??
        (throw StateError('Field active on User cannot be null.'));
    final DateTime? userCreatedAtValue = registry.decodeField<DateTime?>(
      _$UserCreatedAtField,
      data['created_at'],
    );
    final DateTime? userUpdatedAtValue = registry.decodeField<DateTime?>(
      _$UserUpdatedAtField,
      data['updated_at'],
    );
    final model = _$UserModel(
      id: userIdValue,
      email: userEmailValue,
      name: userNameValue,
      active: userActiveValue,
      createdAt: userCreatedAtValue,
      updatedAt: userUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userIdValue,
      'email': userEmailValue,
      'name': userNameValue,
      'active': userActiveValue,
      'created_at': userCreatedAtValue,
      'updated_at': userUpdatedAtValue,
    });
    return model;
  }
}

class _$UserModel extends User {
  _$UserModel({
    int? id,
    required String email,
    required String name,
    required bool active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         email: email,
         name: name,
         active: active,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'name': name,
      'active': active,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  set email(String value) => setAttribute('email', value);

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  set name(String value) => setAttribute('name', value);

  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  set active(bool value) => setAttribute('active', value);

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  set createdAt(DateTime? value) => setAttribute('created_at', value);

  @override
  DateTime? get updatedAt =>
      getAttribute<DateTime?>('updated_at') ?? super.updatedAt;

  set updatedAt(DateTime? value) => setAttribute('updated_at', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserModelDefinition);
  }
}

extension UserAttributeSetters on User {
  set id(int? value) => setAttribute('id', value);
  set email(String value) => setAttribute('email', value);
  set name(String value) => setAttribute('name', value);
  set active(bool value) => setAttribute('active', value);
  set createdAt(DateTime? value) => setAttribute('created_at', value);
  set updatedAt(DateTime? value) => setAttribute('updated_at', value);
}
