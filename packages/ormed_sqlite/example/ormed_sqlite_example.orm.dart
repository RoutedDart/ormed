// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ormed_sqlite_example.dart';

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
  autoIncrement: false,
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

Map<String, Object?> _encodeExampleUserUntracked(
  Object model,
  ValueCodecRegistry registry,
) {
  final m = model as ExampleUser;
  return <String, Object?>{
    'id': registry.encodeField(_$ExampleUserIdField, m.id),
    'email': registry.encodeField(_$ExampleUserEmailField, m.email),
  };
}

final ModelDefinition<$ExampleUser> _$ExampleUserDefinition = ModelDefinition(
  modelName: 'ExampleUser',
  tableName: 'users',
  fields: const [_$ExampleUserIdField, _$ExampleUserEmailField],
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
  untrackedToMap: _encodeExampleUserUntracked,
  codec: _$ExampleUserCodec(),
);

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
  }) => ModelFactoryBuilder<ExampleUser>(
    definition: definition,
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
    };
  }

  @override
  $ExampleUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int exampleUserIdValue =
        registry.decodeField<int>(_$ExampleUserIdField, data['id']) ??
        (throw StateError('Field id on ExampleUser cannot be null.'));
    final String exampleUserEmailValue =
        registry.decodeField<String>(_$ExampleUserEmailField, data['email']) ??
        (throw StateError('Field email on ExampleUser cannot be null.'));
    final model = $ExampleUser(
      id: exampleUserIdValue,
      email: exampleUserEmailValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': exampleUserIdValue,
      'email': exampleUserEmailValue,
    });
    return model;
  }
}

/// Insert DTO for [ExampleUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class ExampleUserInsertDto implements InsertDto<$ExampleUser> {
  const ExampleUserInsertDto({this.id, this.email});
  final int? id;
  final String? email;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
    };
  }
}

/// Update DTO for [ExampleUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class ExampleUserUpdateDto implements UpdateDto<$ExampleUser> {
  const ExampleUserUpdateDto({this.id, this.email});
  final int? id;
  final String? email;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
    };
  }
}

/// Partial projection for [ExampleUser].
///
/// All fields are nullable; intended for subset SELECTs.
class ExampleUserPartial implements PartialEntity<$ExampleUser> {
  const ExampleUserPartial({this.id, this.email});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory ExampleUserPartial.fromRow(Map<String, Object?> row) {
    return ExampleUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
    );
  }

  final int? id;
  final String? email;

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
    return $ExampleUser(id: idValue, email: emailValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, if (email != null) 'email': email};
  }
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
  $ExampleUser({required int id, required String email})
    : super.new(id: id, email: email) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $ExampleUser.fromModel(ExampleUser model) {
    return $ExampleUser(id: model.id, email: model.email);
  }

  $ExampleUser copyWith({int? id, String? email}) {
    return $ExampleUser(id: id ?? this.id, email: email ?? this.email);
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  set email(String value) => setAttribute('email', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ExampleUserDefinition);
  }
}

extension ExampleUserOrmExtension on ExampleUser {
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

void registerExampleUserEventHandlers(EventBus bus) {
  // No event handlers registered for ExampleUser.
}
