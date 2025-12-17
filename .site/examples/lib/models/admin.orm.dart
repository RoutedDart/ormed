// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'admin.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AdminIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$AdminEmailField = FieldDefinition(
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

const FieldDefinition _$AdminPasswordField = FieldDefinition(
  name: 'password',
  columnName: 'password',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AdminCreatedAtField = FieldDefinition(
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

final ModelDefinition<$Admin> _$AdminDefinition = ModelDefinition(
  modelName: 'Admin',
  tableName: 'admins',
  fields: const [
    _$AdminIdField,
    _$AdminEmailField,
    _$AdminPasswordField,
    _$AdminCreatedAtField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>['password'],
    visible: const <String>[],
    fillable: const <String>['email'],
    guarded: const <String>['id'],
    casts: const <String, String>{'createdAt': 'datetime'},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$AdminCodec(),
);

extension AdminOrmDefinition on Admin {
  static ModelDefinition<$Admin> get definition => _$AdminDefinition;
}

class Admins {
  const Admins._();

  /// Starts building a query for [$Admin].
  ///
  /// {@macro ormed.query}
  static Query<$Admin> query([String? connection]) =>
      Model.query<$Admin>(connection: connection);

  static Future<$Admin?> find(Object id, {String? connection}) =>
      Model.find<$Admin>(id, connection: connection);

  static Future<$Admin> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Admin>(id, connection: connection);

  static Future<List<$Admin>> all({String? connection}) =>
      Model.all<$Admin>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Admin>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Admin>(connection: connection);

  static Query<$Admin> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Admin>(column, operator, value, connection: connection);

  static Query<$Admin> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Admin>(column, values, connection: connection);

  static Query<$Admin> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Admin>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Admin> limit(int count, {String? connection}) =>
      Model.limit<$Admin>(count, connection: connection);

  /// Creates a [Repository] for [$Admin].
  ///
  /// {@macro ormed.repository}
  static Repository<$Admin> repo([String? connection]) =>
      Model.repository<$Admin>(connection: connection);
}

class AdminModelFactory {
  const AdminModelFactory._();

  static ModelDefinition<$Admin> get definition => _$AdminDefinition;

  static ModelCodec<$Admin> get codec => definition.codec;

  static Admin fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Admin model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Admin> withConnection(QueryContext context) =>
      ModelFactoryConnection<Admin>(definition: definition, context: context);

  static ModelFactoryBuilder<Admin> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Admin>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AdminCodec extends ModelCodec<$Admin> {
  const _$AdminCodec();
  @override
  Map<String, Object?> encode($Admin model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$AdminIdField, model.id),
      'email': registry.encodeField(_$AdminEmailField, model.email),
      'password': registry.encodeField(_$AdminPasswordField, model.password),
      'createdAt': registry.encodeField(_$AdminCreatedAtField, model.createdAt),
    };
  }

  @override
  $Admin decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int adminIdValue =
        registry.decodeField<int>(_$AdminIdField, data['id']) ?? 0;
    final String adminEmailValue =
        registry.decodeField<String>(_$AdminEmailField, data['email']) ??
        (throw StateError('Field email on Admin cannot be null.'));
    final String? adminPasswordValue = registry.decodeField<String?>(
      _$AdminPasswordField,
      data['password'],
    );
    final DateTime? adminCreatedAtValue = registry.decodeField<DateTime?>(
      _$AdminCreatedAtField,
      data['createdAt'],
    );
    final model = $Admin(
      id: adminIdValue,
      email: adminEmailValue,
      password: adminPasswordValue,
      createdAt: adminCreatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': adminIdValue,
      'email': adminEmailValue,
      'password': adminPasswordValue,
      'createdAt': adminCreatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [Admin].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AdminInsertDto implements InsertDto<$Admin> {
  const AdminInsertDto({this.email, this.password, this.createdAt});
  final String? email;
  final String? password;
  final DateTime? createdAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

/// Update DTO for [Admin].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AdminUpdateDto implements UpdateDto<$Admin> {
  const AdminUpdateDto({this.id, this.email, this.password, this.createdAt});
  final int? id;
  final String? email;
  final String? password;
  final DateTime? createdAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

/// Partial projection for [Admin].
///
/// All fields are nullable; intended for subset SELECTs.
class AdminPartial implements PartialEntity<$Admin> {
  const AdminPartial({this.id, this.email, this.password, this.createdAt});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AdminPartial.fromRow(Map<String, Object?> row) {
    return AdminPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      password: row['password'] as String?,
      createdAt: row['createdAt'] as DateTime?,
    );
  }

  final int? id;
  final String? email;
  final String? password;
  final DateTime? createdAt;

  @override
  $Admin toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? emailValue = email;
    if (emailValue == null) {
      throw StateError('Missing required field: email');
    }
    return $Admin(
      id: idValue,
      email: emailValue,
      password: password,
      createdAt: createdAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

/// Generated tracked model class for [Admin].
///
/// This class extends the user-defined [Admin] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Admin extends Admin with ModelAttributes implements OrmEntity {
  $Admin({
    int id = 0,
    required String email,
    String? password,
    DateTime? createdAt,
  }) : super.new(
         id: id,
         email: email,
         password: password,
         createdAt: createdAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'password': password,
      'createdAt': createdAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Admin.fromModel(Admin model) {
    return $Admin(
      id: model.id,
      email: model.email,
      password: model.password,
      createdAt: model.createdAt,
    );
  }

  $Admin copyWith({
    int? id,
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return $Admin(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  set email(String value) => setAttribute('email', value);

  @override
  String? get password => getAttribute<String?>('password') ?? super.password;

  set password(String? value) => setAttribute('password', value);

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('createdAt') ?? super.createdAt;

  set createdAt(DateTime? value) => setAttribute('createdAt', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AdminDefinition);
  }
}

extension AdminOrmExtension on Admin {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Admin;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Admin toTracked() {
    return $Admin.fromModel(this);
  }
}

void registerAdminEventHandlers(EventBus bus) {
  // No event handlers registered for Admin.
}
