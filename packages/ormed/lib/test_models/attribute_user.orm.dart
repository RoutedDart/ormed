// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'attribute_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AttributeUserIdField = FieldDefinition(
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

const FieldDefinition _$AttributeUserEmailField = FieldDefinition(
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

const FieldDefinition _$AttributeUserSecretField = FieldDefinition(
  name: 'secret',
  columnName: 'secret',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AttributeUserRoleField = FieldDefinition(
  name: 'role',
  columnName: 'role',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AttributeUserProfileField = FieldDefinition(
  name: 'profile',
  columnName: 'profile',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<AttributeUser> _$AttributeUserModelDefinition =
    ModelDefinition(
      modelName: 'AttributeUser',
      tableName: 'attribute_users',
      fields: const [
        _$AttributeUserIdField,
        _$AttributeUserEmailField,
        _$AttributeUserSecretField,
        _$AttributeUserRoleField,
        _$AttributeUserProfileField,
      ],
      relations: const [],
      softDeleteColumn: 'deleted_at',
      metadata: ModelAttributesMetadata(
        hidden: const <String>['secret'],
        visible: const <String>['secret'],
        fillable: const <String>['email', 'role', 'profile'],
        guarded: const <String>['id'],
        casts: const <String, String>{'profile': 'json'},
        fieldOverrides: const {
          'secret': FieldAttributeMetadata(hidden: true),
          'role': FieldAttributeMetadata(fillable: true),
          'profile': FieldAttributeMetadata(cast: 'json'),
        },
        driverAnnotations: const [DriverModel('core')],
        softDeletes: false,
        softDeleteColumn: 'deleted_at',
      ),
      codec: _$AttributeUserModelCodec(),
    );

// ignore: unused_element
final _AttributeUserModelDefinitionRegistration =
    ModelFactoryRegistry.register<AttributeUser>(
      _$AttributeUserModelDefinition,
    );

extension AttributeUserOrmDefinition on AttributeUser {
  static ModelDefinition<AttributeUser> get definition =>
      _$AttributeUserModelDefinition;
}

class AttributeUserModelFactory {
  const AttributeUserModelFactory._();

  static ModelDefinition<AttributeUser> get definition =>
      AttributeUserOrmDefinition.definition;

  static ModelCodec<AttributeUser> get codec => definition.codec;

  static AttributeUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    AttributeUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<AttributeUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<AttributeUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<AttributeUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<AttributeUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

extension AttributeUserModelFactoryExtension on AttributeUser {
  static ModelFactoryBuilder<AttributeUser> factory({
    GeneratorProvider? generatorProvider,
  }) => AttributeUserModelFactory.factory(generatorProvider: generatorProvider);
}

class _$AttributeUserModelCodec extends ModelCodec<AttributeUser> {
  const _$AttributeUserModelCodec();

  @override
  Map<String, Object?> encode(
    AttributeUser model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$AttributeUserIdField, model.id),
      'email': registry.encodeField(_$AttributeUserEmailField, model.email),
      'secret': registry.encodeField(_$AttributeUserSecretField, model.secret),
      'role': registry.encodeField(_$AttributeUserRoleField, model.role),
      'profile': registry.encodeField(
        _$AttributeUserProfileField,
        model.profile,
      ),
    };
  }

  @override
  AttributeUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int attributeUserIdValue =
        registry.decodeField<int>(_$AttributeUserIdField, data['id']) ??
        (throw StateError('Field id on AttributeUser cannot be null.'));
    final String attributeUserEmailValue =
        registry.decodeField<String>(
          _$AttributeUserEmailField,
          data['email'],
        ) ??
        (throw StateError('Field email on AttributeUser cannot be null.'));
    final String attributeUserSecretValue =
        registry.decodeField<String>(
          _$AttributeUserSecretField,
          data['secret'],
        ) ??
        (throw StateError('Field secret on AttributeUser cannot be null.'));
    final String? attributeUserRoleValue = registry.decodeField<String?>(
      _$AttributeUserRoleField,
      data['role'],
    );
    final Map<String, Object?>? attributeUserProfileValue = registry
        .decodeField<Map<String, Object?>?>(
          _$AttributeUserProfileField,
          data['profile'],
        );
    final model = _$AttributeUserModel(
      id: attributeUserIdValue,
      email: attributeUserEmailValue,
      secret: attributeUserSecretValue,
      role: attributeUserRoleValue,
      profile: attributeUserProfileValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': attributeUserIdValue,
      'email': attributeUserEmailValue,
      'secret': attributeUserSecretValue,
      'role': attributeUserRoleValue,
      'profile': attributeUserProfileValue,
    });
    return model;
  }
}

class _$AttributeUserModel extends AttributeUser {
  _$AttributeUserModel({
    required int id,
    required String email,
    required String secret,
    String? role,
    Map<String, Object?>? profile,
  }) : super.new(
         id: id,
         email: email,
         secret: secret,
         role: role,
         profile: profile,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'secret': secret,
      'role': role,
      'profile': profile,
    });
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  set email(String value) => setAttribute('email', value);

  @override
  String get secret => getAttribute<String>('secret') ?? super.secret;

  set secret(String value) => setAttribute('secret', value);

  @override
  String? get role => getAttribute<String?>('role') ?? super.role;

  set role(String? value) => setAttribute('role', value);

  @override
  Map<String, Object?>? get profile =>
      getAttribute<Map<String, Object?>?>('profile') ?? super.profile;

  set profile(Map<String, Object?>? value) => setAttribute('profile', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AttributeUserModelDefinition);
  }
}

extension AttributeUserAttributeSetters on AttributeUser {
  set id(int value) => setAttribute('id', value);
  set email(String value) => setAttribute('email', value);
  set secret(String value) => setAttribute('secret', value);
  set role(String? value) => setAttribute('role', value);
  set profile(Map<String, Object?>? value) => setAttribute('profile', value);
}
