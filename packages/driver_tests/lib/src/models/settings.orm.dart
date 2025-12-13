// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'settings.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SettingIdField = FieldDefinition(
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

const FieldDefinition _$SettingPayloadField = FieldDefinition(
  name: 'payload',
  columnName: 'payload',
  dartType: 'Map<String, dynamic>',
  resolvedType: 'Map<String, dynamic>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

final ModelDefinition<$Setting> _$SettingDefinition = ModelDefinition(
  modelName: 'Setting',
  tableName: 'settings',
  fields: const [_$SettingIdField, _$SettingPayloadField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    fieldOverrides: const {'payload': FieldAttributeMetadata(cast: 'json')},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$SettingCodec(),
);

// ignore: unused_element
final settingModelDefinitionRegistration =
    ModelFactoryRegistry.register<$Setting>(_$SettingDefinition);

extension SettingOrmDefinition on Setting {
  static ModelDefinition<$Setting> get definition => _$SettingDefinition;
}

class Settings {
  const Settings._();

  static Query<$Setting> query([String? connection]) =>
      Model.query<$Setting>(connection: connection);

  static Future<$Setting?> find(Object id, {String? connection}) =>
      Model.find<$Setting>(id, connection: connection);

  static Future<$Setting> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Setting>(id, connection: connection);

  static Future<List<$Setting>> all({String? connection}) =>
      Model.all<$Setting>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Setting>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Setting>(connection: connection);

  static Query<$Setting> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Setting>(column, operator, value, connection: connection);

  static Query<$Setting> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Setting>(column, values, connection: connection);

  static Query<$Setting> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Setting>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Setting> limit(int count, {String? connection}) =>
      Model.limit<$Setting>(count, connection: connection);

  static Repository<$Setting> repo([String? connection]) =>
      Model.repository<$Setting>(connection: connection);
}

class SettingModelFactory {
  const SettingModelFactory._();

  static ModelDefinition<$Setting> get definition => _$SettingDefinition;

  static ModelCodec<$Setting> get codec => definition.codec;

  static Setting fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Setting model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Setting> withConnection(QueryContext context) =>
      ModelFactoryConnection<Setting>(definition: definition, context: context);

  static ModelFactoryBuilder<Setting> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Setting>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SettingCodec extends ModelCodec<$Setting> {
  const _$SettingCodec();
  @override
  Map<String, Object?> encode($Setting model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$SettingIdField, model.id),
      'payload': registry.encodeField(_$SettingPayloadField, model.payload),
    };
  }

  @override
  $Setting decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int settingIdValue =
        registry.decodeField<int>(_$SettingIdField, data['id']) ?? 0;
    final Map<String, dynamic> settingPayloadValue =
        registry.decodeField<Map<String, dynamic>>(
          _$SettingPayloadField,
          data['payload'],
        ) ??
        (throw StateError('Field payload on Setting cannot be null.'));
    final model = $Setting(id: settingIdValue, payload: settingPayloadValue);
    model._attachOrmRuntimeMetadata({
      'id': settingIdValue,
      'payload': settingPayloadValue,
    });
    return model;
  }
}

/// Insert DTO for [Setting].
///
/// Auto-increment/DB-generated fields are omitted by default.
class SettingInsertDto implements InsertDto<$Setting> {
  const SettingInsertDto({this.payload});
  final Map<String, dynamic>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{if (payload != null) 'payload': payload};
  }
}

/// Update DTO for [Setting].
///
/// All fields are optional; only provided entries are used in SET clauses.
class SettingUpdateDto implements UpdateDto<$Setting> {
  const SettingUpdateDto({this.id, this.payload});
  final int? id;
  final Map<String, dynamic>? payload;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
    };
  }
}

/// Partial projection for [Setting].
///
/// All fields are nullable; intended for subset SELECTs.
class SettingPartial implements PartialEntity<$Setting> {
  const SettingPartial({this.id, this.payload});
  final int? id;
  final Map<String, dynamic>? payload;

  @override
  $Setting toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final int? idValue = id;
    if (idValue == null) throw StateError('Missing required field: id');
    final Map<String, dynamic>? payloadValue = payload;
    if (payloadValue == null) {
      throw StateError('Missing required field: payload');
    }
    return $Setting(id: idValue, payload: payloadValue);
  }
}

/// Generated tracked model class for [Setting].
///
/// This class extends the user-defined [Setting] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Setting extends Setting with ModelAttributes implements OrmEntity {
  $Setting({int id = 0, required Map<String, dynamic> payload})
    : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Setting.fromModel(Setting model) {
    return $Setting(id: model.id, payload: model.payload);
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  Map<String, dynamic> get payload =>
      getAttribute<Map<String, dynamic>>('payload') ?? super.payload;

  set payload(Map<String, dynamic> value) => setAttribute('payload', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SettingDefinition);
  }
}

extension SettingOrmExtension on Setting {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Setting;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Setting toTracked() {
    return $Setting.fromModel(this);
  }
}
