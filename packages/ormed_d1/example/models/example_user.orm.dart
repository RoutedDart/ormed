// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'example_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ExampleUserIdField = FieldDefinition(
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

const FieldDefinition _$ExampleUserEmailField = FieldDefinition(
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

const FieldDefinition _$ExampleUserNameField = FieldDefinition(
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

const FieldDefinition _$ExampleUserActiveField = FieldDefinition(
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

const FieldDefinition _$ExampleUserCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'created_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'datetime',
);

Map<String, Object?> _encodeExampleUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as ExampleUser;
  return <String, Object?>{
    'id': registry.encodeField(_$ExampleUserIdField, m.id),
    'email': registry.encodeField(_$ExampleUserEmailField, m.email),
    'name': registry.encodeField(_$ExampleUserNameField, m.name),
    'active': registry.encodeField(_$ExampleUserActiveField, m.active),
    'created_at': registry.encodeField(
      _$ExampleUserCreatedAtField,
      m.createdAt,
    ),
  };
}

final ModelDefinition<$ExampleUser> _$ExampleUserDefinition = ModelDefinition(
  modelName: 'ExampleUser',
  tableName: 'example_users',
  fields: const [
    _$ExampleUserIdField,
    _$ExampleUserEmailField,
    _$ExampleUserNameField,
    _$ExampleUserActiveField,
    _$ExampleUserCreatedAtField,
  ],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    appends: const <String>[],
    touches: const <String>[],
    timestamps: true,
    fieldOverrides: const {
      'created_at': FieldAttributeMetadata(cast: 'datetime'),
    },
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  untrackedToMap: _encodeExampleUserUntracked,
  codec: _$ExampleUserCodec(),
);

// ignore: unused_element
final exampleuserModelDefinitionRegistration =
    ModelFactoryRegistry.register<$ExampleUser>(_$ExampleUserDefinition);

extension ExampleUserOrmDefinition on ExampleUser {
  static ModelDefinition<$ExampleUser> get definition =>
      _$ExampleUserDefinition;
}

class ExampleUsers {
  const ExampleUsers._();

  /// Starts building a query for [$ExampleUser].
  ///
  /// {@macro ormed.query}
  static Query<$ExampleUser> query([String? connection]) =>
      Model.query<$ExampleUser>(connection: connection);

  static Future<$ExampleUser?> find(Object id, {String? connection}) =>
      Model.find<$ExampleUser>(id, connection: connection);

  static Future<$ExampleUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$ExampleUser>(id, connection: connection);

  static Future<List<$ExampleUser>> all({String? connection}) =>
      Model.all<$ExampleUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$ExampleUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$ExampleUser>(connection: connection);

  static Query<$ExampleUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$ExampleUser>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$ExampleUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$ExampleUser>(column, values, connection: connection);

  static Query<$ExampleUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$ExampleUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$ExampleUser> limit(int count, {String? connection}) =>
      Model.limit<$ExampleUser>(count, connection: connection);

  /// Creates a [Repository] for [$ExampleUser].
  ///
  /// {@macro ormed.repository}
  static Repository<$ExampleUser> repo([String? connection]) =>
      Model.repository<$ExampleUser>(connection: connection);

  /// Builds a tracked model from a column/value map.
  static $ExampleUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ExampleUserDefinition.fromMap(data, registry: registry);

  /// Converts a tracked model to a column/value map.
  static Map<String, Object?> toMap(
    $ExampleUser model, {
    ValueCodecRegistry? registry,
  }) => _$ExampleUserDefinition.toMap(model, registry: registry);
}

class ExampleUserModelFactory {
  const ExampleUserModelFactory._();

  static ModelDefinition<$ExampleUser> get definition =>
      _$ExampleUserDefinition;

  static ModelCodec<$ExampleUser> get codec => definition.codec;

  static ExampleUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    ExampleUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<ExampleUser> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<ExampleUser>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<ExampleUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryRegistry.factoryFor<ExampleUser>(
    generatorProvider: generatorProvider,
  );
}

class _$ExampleUserCodec extends ModelCodec<$ExampleUser> {
  const _$ExampleUserCodec();
  @override
  Map<String, Object?> encode($ExampleUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ExampleUserIdField, model.id),
      'email': registry.encodeField(_$ExampleUserEmailField, model.email),
      'name': registry.encodeField(_$ExampleUserNameField, model.name),
      'active': registry.encodeField(_$ExampleUserActiveField, model.active),
      'created_at': registry.encodeField(
        _$ExampleUserCreatedAtField,
        model.createdAt,
      ),
    };
  }

  @override
  $ExampleUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int exampleUserIdValue =
        registry.decodeField<int>(_$ExampleUserIdField, data['id']) ?? 0;
    final String exampleUserEmailValue =
        registry.decodeField<String>(_$ExampleUserEmailField, data['email']) ??
        (throw StateError('Field email on ExampleUser cannot be null.'));
    final String? exampleUserNameValue = registry.decodeField<String?>(
      _$ExampleUserNameField,
      data['name'],
    );
    final bool exampleUserActiveValue =
        registry.decodeField<bool>(_$ExampleUserActiveField, data['active']) ??
        (throw StateError('Field active on ExampleUser cannot be null.'));
    final DateTime? exampleUserCreatedAtValue = registry.decodeField<DateTime?>(
      _$ExampleUserCreatedAtField,
      data['created_at'],
    );
    final model = $ExampleUser(
      id: exampleUserIdValue,
      email: exampleUserEmailValue,
      name: exampleUserNameValue,
      active: exampleUserActiveValue,
      createdAt: exampleUserCreatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': exampleUserIdValue,
      'email': exampleUserEmailValue,
      'name': exampleUserNameValue,
      'active': exampleUserActiveValue,
      'created_at': exampleUserCreatedAtValue,
    });
    return model;
  }
}

/// Insert DTO for [ExampleUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ExampleUserInsertDto implements InsertDto<$ExampleUser> {
  const ExampleUserInsertDto({
    this.email,
    this.name,
    this.active,
    this.createdAt,
  });
  final String? email;
  final String? name;
  final bool? active;
  final DateTime? createdAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static const _ExampleUserInsertDtoCopyWithSentinel _copyWithSentinel =
      _ExampleUserInsertDtoCopyWithSentinel();
  ExampleUserInsertDto copyWith({
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
  }) {
    return ExampleUserInsertDto(
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }
}

class _ExampleUserInsertDtoCopyWithSentinel {
  const _ExampleUserInsertDtoCopyWithSentinel();
}

/// Update DTO for [ExampleUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ExampleUserUpdateDto implements UpdateDto<$ExampleUser> {
  const ExampleUserUpdateDto({
    this.id,
    this.email,
    this.name,
    this.active,
    this.createdAt,
  });
  final int? id;
  final String? email;
  final String? name;
  final bool? active;
  final DateTime? createdAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static const _ExampleUserUpdateDtoCopyWithSentinel _copyWithSentinel =
      _ExampleUserUpdateDtoCopyWithSentinel();
  ExampleUserUpdateDto copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
  }) {
    return ExampleUserUpdateDto(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }
}

class _ExampleUserUpdateDtoCopyWithSentinel {
  const _ExampleUserUpdateDtoCopyWithSentinel();
}

/// Partial projection for [ExampleUser].
///
/// All fields are nullable; intended for subset SELECTs.
class ExampleUserPartial implements PartialEntity<$ExampleUser> {
  const ExampleUserPartial({
    this.id,
    this.email,
    this.name,
    this.active,
    this.createdAt,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ExampleUserPartial.fromRow(Map<String, Object?> row) {
    return ExampleUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      name: row['name'] as String?,
      active: row['active'] as bool?,
      createdAt: row['created_at'] as DateTime?,
    );
  }

  final int? id;
  final String? email;
  final String? name;
  final bool? active;
  final DateTime? createdAt;

  @override
  $ExampleUser toEntity() {
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
    return $ExampleUser(
      id: idValue,
      email: emailValue,
      name: name,
      active: activeValue,
      createdAt: createdAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static const _ExampleUserPartialCopyWithSentinel _copyWithSentinel =
      _ExampleUserPartialCopyWithSentinel();
  ExampleUserPartial copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
  }) {
    return ExampleUserPartial(
      id: identical(id, _copyWithSentinel) ? this.id : id as int?,
      email: identical(email, _copyWithSentinel)
          ? this.email
          : email as String?,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool?,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }
}

class _ExampleUserPartialCopyWithSentinel {
  const _ExampleUserPartialCopyWithSentinel();
}

/// Generated tracked model class for [ExampleUser].
///
/// This class extends the user-defined [ExampleUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $ExampleUser extends ExampleUser
    with ModelAttributes
    implements OrmEntity {
  /// Internal constructor for [$ExampleUser].
  $ExampleUser({
    required int id,
    required String email,
    String? name,
    bool active = false,
    DateTime? createdAt,
  }) : super(
         id: id,
         email: email,
         name: name,
         active: active,
         createdAt: createdAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'email': email,
      'name': name,
      'active': active,
      'created_at': createdAt,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $ExampleUser.fromModel(ExampleUser model) {
    return $ExampleUser(
      id: model.id,
      email: model.email,
      name: model.name,
      active: model.active,
      createdAt: model.createdAt,
    );
  }

  $ExampleUser copyWith({
    int? id,
    String? email,
    String? name,
    bool? active,
    DateTime? createdAt,
  }) {
    return $ExampleUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Builds a tracked model from a column/value map.
  static $ExampleUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ExampleUserDefinition.fromMap(data, registry: registry);

  /// Converts this tracked model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ExampleUserDefinition.toMap(this, registry: registry);

  /// Tracked getter for [id].
  @override
  int get id => getAttribute<int>('id') ?? super.id;

  /// Tracked setter for [id].
  set id(int value) => setAttribute('id', value);

  /// Tracked getter for [email].
  @override
  String get email => getAttribute<String>('email') ?? super.email;

  /// Tracked setter for [email].
  set email(String value) => setAttribute('email', value);

  /// Tracked getter for [name].
  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  /// Tracked setter for [name].
  set name(String? value) => setAttribute('name', value);

  /// Tracked getter for [active].
  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  /// Tracked setter for [active].
  set active(bool value) => setAttribute('active', value);

  /// Tracked getter for [createdAt].
  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  /// Tracked setter for [createdAt].
  set createdAt(DateTime? value) => setAttribute('created_at', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ExampleUserDefinition);
  }
}

class _ExampleUserCopyWithSentinel {
  const _ExampleUserCopyWithSentinel();
}

extension ExampleUserOrmExtension on ExampleUser {
  static const _ExampleUserCopyWithSentinel _copyWithSentinel =
      _ExampleUserCopyWithSentinel();
  ExampleUser copyWith({
    Object? id = _copyWithSentinel,
    Object? email = _copyWithSentinel,
    Object? name = _copyWithSentinel,
    Object? active = _copyWithSentinel,
    Object? createdAt = _copyWithSentinel,
  }) {
    return ExampleUser(
      id: identical(id, _copyWithSentinel) ? this.id : id as int,
      email: identical(email, _copyWithSentinel) ? this.email : email as String,
      name: identical(name, _copyWithSentinel) ? this.name : name as String?,
      active: identical(active, _copyWithSentinel)
          ? this.active
          : active as bool,
      createdAt: identical(createdAt, _copyWithSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }

  /// Converts this model to a column/value map.
  Map<String, Object?> toMap({ValueCodecRegistry? registry}) =>
      _$ExampleUserDefinition.toMap(this, registry: registry);

  /// Builds a model from a column/value map.
  static ExampleUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => _$ExampleUserDefinition.fromMap(data, registry: registry);

  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $ExampleUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $ExampleUser toTracked() {
    return $ExampleUser.fromModel(this);
  }
}

extension ExampleUserPredicateFields on PredicateBuilder<ExampleUser> {
  PredicateField<ExampleUser, int> get id =>
      PredicateField<ExampleUser, int>(this, 'id');
  PredicateField<ExampleUser, String> get email =>
      PredicateField<ExampleUser, String>(this, 'email');
  PredicateField<ExampleUser, String?> get name =>
      PredicateField<ExampleUser, String?>(this, 'name');
  PredicateField<ExampleUser, bool> get active =>
      PredicateField<ExampleUser, bool>(this, 'active');
  PredicateField<ExampleUser, DateTime?> get createdAt =>
      PredicateField<ExampleUser, DateTime?>(this, 'createdAt');
}

void registerExampleUserEventHandlers(EventBus bus) {
  // No event handlers registered for ExampleUser.
}
