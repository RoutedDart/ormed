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
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
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

final ModelDefinition<User> _$UserModelDefinition = ModelDefinition(
  modelName: 'User',
  tableName: 'users',
  fields: const [_$UserIdField, _$UserEmailField, _$UserActiveField],
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

// ignore: unused_element
final _UserModelDefinitionRegistration = ModelFactoryRegistry.register<User>(
  _$UserModelDefinition,
);

extension UserOrmDefinition on User {
  static ModelDefinition<User> get definition => _$UserModelDefinition;
}

class UserModelFactory {
  const UserModelFactory._();

  static ModelDefinition<User> get definition => UserOrmDefinition.definition;

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

  static ModelFactoryConnection<User> withConnection(QueryContext context) =>
      ModelFactoryConnection<User>(definition: definition, context: context);

  static ModelFactoryBuilder<User> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<User>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

extension UserModelFactoryExtension on User {
  static ModelFactoryBuilder<User> factory({
    GeneratorProvider? generatorProvider,
  }) => UserModelFactory.factory(generatorProvider: generatorProvider);
}

class _$UserModelCodec extends ModelCodec<User> {
  const _$UserModelCodec();

  @override
  Map<String, Object?> encode(User model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserIdField, model.id),
      'email': registry.encodeField(_$UserEmailField, model.email),
      'active': registry.encodeField(_$UserActiveField, model.active),
    };
  }

  @override
  User decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int userIdValue =
        registry.decodeField<int>(_$UserIdField, data['id']) ??
        (throw StateError('Field id on User cannot be null.'));
    final String userEmailValue =
        registry.decodeField<String>(_$UserEmailField, data['email']) ??
        (throw StateError('Field email on User cannot be null.'));
    final bool userActiveValue =
        registry.decodeField<bool>(_$UserActiveField, data['active']) ??
        (throw StateError('Field active on User cannot be null.'));
    final model = _$UserModel(
      id: userIdValue,
      email: userEmailValue,
      active: userActiveValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userIdValue,
      'email': userEmailValue,
      'active': userActiveValue,
    });
    return model;
  }
}

class _$UserModel extends User {
  _$UserModel({required int id, required String email, required bool active})
    : super.new(id: id, email: email, active: active) {
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
    attachModelDefinition(_$UserModelDefinition);
  }
}

extension UserAttributeSetters on User {
  set id(int value) => setAttribute('id', value);
  set email(String value) => setAttribute('email', value);
  set active(bool value) => setAttribute('active', value);
}
