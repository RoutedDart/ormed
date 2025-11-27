// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$UserIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'String',
  resolvedType: 'String',
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

const FieldDefinition _$UserProfileField = FieldDefinition(
  name: 'profile',
  columnName: 'profile',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'JsonMapCodec',
);

const FieldDefinition _$UserCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'createdAt',
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
    _$UserProfileField,
    _$UserCreatedAtField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>['profile'],
    visible: const <String>[],
    fillable: const <String>['email'],
    guarded: const <String>['id'],
    casts: const <String, String>{'createdAt': 'datetime'},
    connection: 'analytics',
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$UserModelCodec(),
);

extension UserOrmDefinition on User {
  static ModelDefinition<User> get definition => _$UserModelDefinition;
}

class _$UserModelCodec extends ModelCodec<User> {
  const _$UserModelCodec();

  @override
  Map<String, Object?> encode(User model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserIdField, model.id),
      'email': registry.encodeField(_$UserEmailField, model.email),
      'profile': registry.encodeField(_$UserProfileField, model.profile),
      'createdAt': registry.encodeField(_$UserCreatedAtField, model.createdAt),
    };
  }

  @override
  User decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final String userIdValue =
        registry.decodeField<String>(_$UserIdField, data['id']) ??
        (throw StateError('Field id on User cannot be null.'));
    final String userEmailValue =
        registry.decodeField<String>(_$UserEmailField, data['email']) ??
        (throw StateError('Field email on User cannot be null.'));
    final Map<String, Object?>? userProfileValue = registry
        .decodeField<Map<String, Object?>?>(
          _$UserProfileField,
          data['profile'],
        );
    final DateTime? userCreatedAtValue = registry.decodeField<DateTime?>(
      _$UserCreatedAtField,
      data['createdAt'],
    );
    final model = _$UserModel(
      id: userIdValue,
      email: userEmailValue,
      profile: userProfileValue,
      createdAt: userCreatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userIdValue,
      'email': userEmailValue,
      'profile': userProfileValue,
      'createdAt': userCreatedAtValue,
    });
    return model;
  }
}

class _$UserModel extends User with ModelAttributes, ModelConnection {
  _$UserModel({
    required String id,
    required String email,
    Map<String, Object?>? profile,
    DateTime? createdAt,
  }) : super(id: id, email: email, profile: profile, createdAt: createdAt) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'profile': profile,
      'createdAt': createdAt,
    });
  }

  @override
  String get id => getAttribute<String>('id') ?? super.id;

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  @override
  Map<String, Object?>? get profile =>
      getAttribute<Map<String, Object?>?>('profile') ?? super.profile;

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('createdAt') ?? super.createdAt;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserModelDefinition);
  }
}
