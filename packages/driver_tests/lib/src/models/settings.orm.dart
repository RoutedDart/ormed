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
  autoIncrement: false,
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
);

final ModelDefinition<Setting> _$SettingModelDefinition = ModelDefinition(
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
  codec: _$SettingModelCodec(),
);

// ignore: unused_element
final _SettingModelDefinitionRegistration =
    ModelFactoryRegistry.register<Setting>(_$SettingModelDefinition);

extension SettingOrmDefinition on Setting {
  static ModelDefinition<Setting> get definition => _$SettingModelDefinition;
}

class SettingModelFactory {
  const SettingModelFactory._();

  static ModelDefinition<Setting> get definition =>
      SettingOrmDefinition.definition;

  static ModelCodec<Setting> get codec => definition.codec;

  static Setting fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Setting model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

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

extension SettingModelFactoryExtension on Setting {
  static ModelFactoryBuilder<Setting> factory({
    GeneratorProvider? generatorProvider,
  }) => SettingModelFactory.factory(generatorProvider: generatorProvider);
}

class _$SettingModelCodec extends ModelCodec<Setting> {
  const _$SettingModelCodec();

  @override
  Map<String, Object?> encode(Setting model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$SettingIdField, model.id),
      'payload': registry.encodeField(_$SettingPayloadField, model.payload),
    };
  }

  @override
  Setting decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int settingIdValue =
        registry.decodeField<int>(_$SettingIdField, data['id']) ??
        (throw StateError('Field id on Setting cannot be null.'));
    final Map<String, dynamic> settingPayloadValue =
        registry.decodeField<Map<String, dynamic>>(
          _$SettingPayloadField,
          data['payload'],
        ) ??
        (throw StateError('Field payload on Setting cannot be null.'));
    final model = _$SettingModel(
      id: settingIdValue,
      payload: settingPayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': settingIdValue,
      'payload': settingPayloadValue,
    });
    return model;
  }
}

class _$SettingModel extends Setting {
  _$SettingModel({required int id, required Map<String, dynamic> payload})
    : super(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
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
    attachModelDefinition(_$SettingModelDefinition);
  }
}

extension SettingAttributeSetters on Setting {
  set id(int value) => setAttribute('id', value);
  set payload(Map<String, dynamic> value) => setAttribute('payload', value);
}
