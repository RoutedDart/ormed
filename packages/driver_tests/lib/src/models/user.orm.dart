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
  autoIncrement: true,
  insertable: false,
  defaultDartValue: 0,
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
  defaultValueSql: '1',
);

const FieldDefinition _$UserNameField = FieldDefinition(
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

const FieldDefinition _$UserAgeField = FieldDefinition(
  name: 'age',
  columnName: 'age',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
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
  codecType: 'datetime',
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

const FieldDefinition _$UserMetadataField = FieldDefinition(
  name: 'metadata',
  columnName: 'metadata',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'JsonMapCodec',
);

final ModelDefinition<$User> _$UserDefinition = ModelDefinition(
  modelName: 'User',
  tableName: 'users',
  fields: const [
    _$UserIdField,
    _$UserEmailField,
    _$UserActiveField,
    _$UserNameField,
    _$UserAgeField,
    _$UserCreatedAtField,
    _$UserProfileField,
    _$UserMetadataField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>['profile'],
    visible: const <String>[],
    fillable: const <String>['email'],
    guarded: const <String>['id'],
    casts: const <String, String>{'createdAt': 'datetime'},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$UserCodec(),
);

// ignore: unused_element
final userModelDefinitionRegistration = ModelFactoryRegistry.register<$User>(
  _$UserDefinition,
);

extension UserOrmDefinition on User {
  static ModelDefinition<$User> get definition => _$UserDefinition;
}

class Users {
  const Users._();

  static Query<$User> query([String? connection]) =>
      Model.query<$User>(connection: connection);

  static Future<$User?> find(Object id, {String? connection}) =>
      Model.find<$User>(id, connection: connection);

  static Future<$User> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$User>(id, connection: connection);

  static Future<List<$User>> all({String? connection}) =>
      Model.all<$User>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$User>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$User>(connection: connection);

  static Query<$User> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$User>(column, operator, value, connection: connection);

  static Query<$User> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$User>(column, values, connection: connection);

  static Query<$User> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$User>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$User> limit(int count, {String? connection}) =>
      Model.limit<$User>(count, connection: connection);

  static Repository<$User> repo([String? connection]) =>
      Model.repository<$User>(connection: connection);
}

class UserModelFactory {
  const UserModelFactory._();

  static ModelDefinition<$User> get definition => _$UserDefinition;

  static ModelCodec<$User> get codec => definition.codec;

  static User fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    User model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

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

class _$UserCodec extends ModelCodec<$User> {
  const _$UserCodec();
  @override
  Map<String, Object?> encode($User model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$UserIdField, model.id),
      'email': registry.encodeField(_$UserEmailField, model.email),
      'active': registry.encodeField(_$UserActiveField, model.active),
      'name': registry.encodeField(_$UserNameField, model.name),
      'age': registry.encodeField(_$UserAgeField, model.age),
      'createdAt': registry.encodeField(_$UserCreatedAtField, model.createdAt),
      'profile': registry.encodeField(_$UserProfileField, model.profile),
      'metadata': registry.encodeField(_$UserMetadataField, model.metadata),
    };
  }

  @override
  $User decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int userIdValue =
        registry.decodeField<int>(_$UserIdField, data['id']) ?? 0;
    final String userEmailValue =
        registry.decodeField<String>(_$UserEmailField, data['email']) ??
        (throw StateError('Field email on User cannot be null.'));
    final bool userActiveValue =
        registry.decodeField<bool>(_$UserActiveField, data['active']) ?? false;
    final String? userNameValue = registry.decodeField<String?>(
      _$UserNameField,
      data['name'],
    );
    final int? userAgeValue = registry.decodeField<int?>(
      _$UserAgeField,
      data['age'],
    );
    final DateTime? userCreatedAtValue = registry.decodeField<DateTime?>(
      _$UserCreatedAtField,
      data['createdAt'],
    );
    final Map<String, Object?>? userProfileValue = registry
        .decodeField<Map<String, Object?>?>(
          _$UserProfileField,
          data['profile'],
        );
    final Map<String, Object?>? userMetadataValue = registry
        .decodeField<Map<String, Object?>?>(
          _$UserMetadataField,
          data['metadata'],
        );
    final model = $User(
      id: userIdValue,
      email: userEmailValue,
      active: userActiveValue,
      name: userNameValue,
      age: userAgeValue,
      profile: userProfileValue,
      metadata: userMetadataValue,
      createdAt: userCreatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userIdValue,
      'email': userEmailValue,
      'active': userActiveValue,
      'name': userNameValue,
      'age': userAgeValue,
      'createdAt': userCreatedAtValue,
      'profile': userProfileValue,
      'metadata': userMetadataValue,
    });
    return model;
  }
}

/// Insert DTO for [User].
///
/// Auto-increment/DB-generated fields are omitted by default.
class UserInsertDto implements InsertDto<$User> {
  const UserInsertDto({
    this.email,
    this.active,
    this.name,
    this.age,
    this.createdAt,
    this.profile,
    this.metadata,
  });
  final String? email;
  final bool? active;
  final String? name;
  final int? age;
  final DateTime? createdAt;
  final Map<String, Object?>? profile;
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (createdAt != null) 'createdAt': createdAt,
      if (profile != null) 'profile': profile,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Update DTO for [User].
///
/// All fields are optional; only provided entries are used in SET clauses.
class UserUpdateDto implements UpdateDto<$User> {
  const UserUpdateDto({
    this.id,
    this.email,
    this.active,
    this.name,
    this.age,
    this.createdAt,
    this.profile,
    this.metadata,
  });
  final int? id;
  final String? email;
  final bool? active;
  final String? name;
  final int? age;
  final DateTime? createdAt;
  final Map<String, Object?>? profile;
  final Map<String, Object?>? metadata;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (createdAt != null) 'createdAt': createdAt,
      if (profile != null) 'profile': profile,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Partial projection for [User].
///
/// All fields are nullable; intended for subset SELECTs.
class UserPartial implements PartialEntity<$User> {
  const UserPartial({
    this.id,
    this.email,
    this.active,
    this.name,
    this.age,
    this.createdAt,
    this.profile,
    this.metadata,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory UserPartial.fromRow(Map<String, Object?> row) {
    return UserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      active: row['active'] as bool?,
      name: row['name'] as String?,
      age: row['age'] as int?,
      createdAt: row['createdAt'] as DateTime?,
      profile: row['profile'] as Map<String, Object?>?,
      metadata: row['metadata'] as Map<String, Object?>?,
    );
  }

  final int? id;
  final String? email;
  final bool? active;
  final String? name;
  final int? age;
  final DateTime? createdAt;
  final Map<String, Object?>? profile;
  final Map<String, Object?>? metadata;

  @override
  $User toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    final bool? activeValue = active;
    if (activeValue == null) {
      throw StateError('Missing required field: active');
    }
    return $User(
      id: idValue,
      email: emailValue,
      active: activeValue,
      name: name,
      age: age,
      createdAt: createdAt,
      profile: profile,
      metadata: metadata,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (createdAt != null) 'createdAt': createdAt,
      if (profile != null) 'profile': profile,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Generated tracked model class for [User].
///
/// This class extends the user-defined [User] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $User extends User with ModelAttributes implements OrmEntity {
  $User({
    int id = 0,
    required String email,
    required bool active,
    String? name,
    int? age,
    Map<String, Object?>? profile,
    Map<String, Object?>? metadata,
    DateTime? createdAt,
  }) : super.new(
         id: id,
         email: email,
         active: active,
         name: name,
         age: age,
         profile: profile,
         metadata: metadata,
         createdAt: createdAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'active': active,
      'name': name,
      'age': age,
      'createdAt': createdAt,
      'profile': profile,
      'metadata': metadata,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $User.fromModel(User model) {
    return $User(
      id: model.id,
      email: model.email,
      active: model.active,
      name: model.name,
      age: model.age,
      createdAt: model.createdAt,
      profile: model.profile,
      metadata: model.metadata,
    );
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

  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  set name(String? value) => setAttribute('name', value);

  @override
  int? get age => getAttribute<int?>('age') ?? super.age;

  set age(int? value) => setAttribute('age', value);

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('createdAt') ?? super.createdAt;

  set createdAt(DateTime? value) => setAttribute('createdAt', value);

  @override
  Map<String, Object?>? get profile =>
      getAttribute<Map<String, Object?>?>('profile') ?? super.profile;

  set profile(Map<String, Object?>? value) => setAttribute('profile', value);

  @override
  Map<String, Object?>? get metadata =>
      getAttribute<Map<String, Object?>?>('metadata') ?? super.metadata;

  set metadata(Map<String, Object?>? value) => setAttribute('metadata', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$UserDefinition);
  }
}

extension UserOrmExtension on User {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $User;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $User toTracked() {
    return $User.fromModel(this);
  }
}

void registerUserEventHandlers(EventBus bus) {
  // No event handlers registered for User.
}
