// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'cli_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CliUserIdField = FieldDefinition(
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

const FieldDefinition _$CliUserEmailField = FieldDefinition(
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

const FieldDefinition _$CliUserActiveField = FieldDefinition(
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

final ModelDefinition<$CliUser> _$CliUserDefinition = ModelDefinition(
  modelName: 'CliUser',
  tableName: 'users',
  fields: const [_$CliUserIdField, _$CliUserEmailField, _$CliUserActiveField],
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
  codec: _$CliUserCodec(),
);

extension CliUserOrmDefinition on CliUser {
  static ModelDefinition<$CliUser> get definition => _$CliUserDefinition;
}

class CliUsers {
  const CliUsers._();

  static Query<$CliUser> query([String? connection]) =>
      Model.query<$CliUser>(connection: connection);

  static Future<$CliUser?> find(Object id, {String? connection}) =>
      Model.find<$CliUser>(id, connection: connection);

  static Future<$CliUser> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$CliUser>(id, connection: connection);

  static Future<List<$CliUser>> all({String? connection}) =>
      Model.all<$CliUser>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$CliUser>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$CliUser>(connection: connection);

  static Query<$CliUser> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$CliUser>(column, operator, value, connection: connection);

  static Query<$CliUser> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$CliUser>(column, values, connection: connection);

  static Query<$CliUser> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$CliUser>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$CliUser> limit(int count, {String? connection}) =>
      Model.limit<$CliUser>(count, connection: connection);

  static Repository<$CliUser> repo([String? connection]) =>
      Model.repository<$CliUser>(connection: connection);
}

class CliUserModelFactory {
  const CliUserModelFactory._();

  static ModelDefinition<$CliUser> get definition => _$CliUserDefinition;

  static ModelCodec<$CliUser> get codec => definition.codec;

  static CliUser fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    CliUser model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<CliUser> withConnection(QueryContext context) =>
      ModelFactoryConnection<CliUser>(definition: definition, context: context);

  static ModelFactoryBuilder<CliUser> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<CliUser>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CliUserCodec extends ModelCodec<$CliUser> {
  const _$CliUserCodec();
  @override
  Map<String, Object?> encode($CliUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$CliUserIdField, model.id),
      'email': registry.encodeField(_$CliUserEmailField, model.email),
      'active': registry.encodeField(_$CliUserActiveField, model.active),
    };
  }

  @override
  $CliUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int cliUserIdValue =
        registry.decodeField<int>(_$CliUserIdField, data['id']) ??
        (throw StateError('Field id on CliUser cannot be null.'));
    final String cliUserEmailValue =
        registry.decodeField<String>(_$CliUserEmailField, data['email']) ??
        (throw StateError('Field email on CliUser cannot be null.'));
    final bool cliUserActiveValue =
        registry.decodeField<bool>(_$CliUserActiveField, data['active']) ??
        (throw StateError('Field active on CliUser cannot be null.'));
    final model = $CliUser(
      id: cliUserIdValue,
      email: cliUserEmailValue,
      active: cliUserActiveValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': cliUserIdValue,
      'email': cliUserEmailValue,
      'active': cliUserActiveValue,
    });
    return model;
  }
}

/// Insert DTO for [CliUser].
///
/// Auto-increment/DB-generated fields are omitted by default.
class CliUserInsertDto implements InsertDto<$CliUser> {
  const CliUserInsertDto({this.id, this.email, this.active});
  final int? id;
  final String? email;
  final bool? active;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
    };
  }
}

/// Update DTO for [CliUser].
///
/// All fields are optional; only provided entries are used in SET clauses.
class CliUserUpdateDto implements UpdateDto<$CliUser> {
  const CliUserUpdateDto({this.id, this.email, this.active});
  final int? id;
  final String? email;
  final bool? active;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
    };
  }
}

/// Partial projection for [CliUser].
///
/// All fields are nullable; intended for subset SELECTs.
class CliUserPartial implements PartialEntity<$CliUser> {
  const CliUserPartial({this.id, this.email, this.active});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory CliUserPartial.fromRow(Map<String, Object?> row) {
    return CliUserPartial(
      id: row['id'] as int?,
      email: row['email'] as String?,
      active: row['active'] as bool?,
    );
  }

  final int? id;
  final String? email;
  final bool? active;

  @override
  $CliUser toEntity() {
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
    return $CliUser(id: idValue, email: emailValue, active: activeValue);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (active != null) 'active': active,
    };
  }
}

/// Generated tracked model class for [CliUser].
///
/// This class extends the user-defined [CliUser] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $CliUser extends CliUser with ModelAttributes implements OrmEntity {
  $CliUser({required int id, required String email, required bool active})
    : super.new(id: id, email: email, active: active) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email, 'active': active});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $CliUser.fromModel(CliUser model) {
    return $CliUser(id: model.id, email: model.email, active: model.active);
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
    attachModelDefinition(_$CliUserDefinition);
  }
}

extension CliUserOrmExtension on CliUser {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $CliUser;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $CliUser toTracked() {
    return $CliUser.fromModel(this);
  }
}
