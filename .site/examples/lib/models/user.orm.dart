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

final ModelDefinition<$User> _$UserDefinition = ModelDefinition(
  modelName: 'User',
  tableName: 'users',
  fields: const [
    _$UserIdField,
    _$UserEmailField,
    _$UserNameField,
    _$UserCreatedAtField,
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
  codec: _$UserCodec(),
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
      'name': registry.encodeField(_$UserNameField, model.name),
      'createdAt': registry.encodeField(_$UserCreatedAtField, model.createdAt),
    };
  }

  @override
  $User decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int userIdValue =
        registry.decodeField<int>(_$UserIdField, data['id']) ?? 0;
    final String userEmailValue =
        registry.decodeField<String>(_$UserEmailField, data['email']) ??
        (throw StateError('Field email on User cannot be null.'));
    final String? userNameValue = registry.decodeField<String?>(
      _$UserNameField,
      data['name'],
    );
    final DateTime? userCreatedAtValue = registry.decodeField<DateTime?>(
      _$UserCreatedAtField,
      data['createdAt'],
    );
    final model = $User(
      id: userIdValue,
      email: userEmailValue,
      name: userNameValue,
      createdAt: userCreatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': userIdValue,
      'email': userEmailValue,
      'name': userNameValue,
      'createdAt': userCreatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [User].
///
/// Auto-increment/DB-generated fields are omitted by default.
class UserInsertDto implements InsertDto<$User> {
  const UserInsertDto({this.email, this.name, this.createdAt});
  final String? email;
  final String? name;
  final DateTime? createdAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

/// Update DTO for [User].
///
/// All fields are optional; only provided entries are used in SET clauses.
class UserUpdateDto implements UpdateDto<$User> {
  const UserUpdateDto({this.id, this.email, this.name, this.createdAt});
  final int? id;
  final String? email;
  final String? name;
  final DateTime? createdAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

/// Partial projection for [User].
///
/// All fields are nullable; intended for subset SELECTs.
class UserPartial implements PartialEntity<$User> {
  const UserPartial({this.id, this.email, this.name, this.createdAt});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory UserPartial.fromRow(Map<String, Object?> row) {
    return UserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      name: row['name'] as String?,
      createdAt: row['createdAt'] as DateTime?,
    );
  }

  final int? id;
  final String? email;
  final String? name;
  final DateTime? createdAt;

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
    return $User(
      id: idValue,
      email: emailValue,
      name: name,
      createdAt: createdAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (createdAt != null) 'createdAt': createdAt,
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
  $User({int id = 0, required String email, String? name, DateTime? createdAt})
    : super.new(id: id, email: email, name: name, createdAt: createdAt) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $User.fromModel(User model) {
    return $User(
      id: model.id,
      email: model.email,
      name: model.name,
      createdAt: model.createdAt,
    );
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  set email(String value) => setAttribute('email', value);

  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  set name(String? value) => setAttribute('name', value);

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('createdAt') ?? super.createdAt;

  set createdAt(DateTime? value) => setAttribute('createdAt', value);

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
