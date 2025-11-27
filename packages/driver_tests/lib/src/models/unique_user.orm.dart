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
final _UniqueUserModelDefinitionRegistration =
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

  static ModelFactoryBuilder<UniqueUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<UniqueUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

extension UniqueUserModelFactoryExtension on UniqueUser {
  static ModelFactoryBuilder<UniqueUser> factory({
    GeneratorProvider? generatorProvider,
  }) => UniqueUserModelFactory.factory(generatorProvider: generatorProvider);
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
  }) : super(id: id, email: email, active: active) {
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
