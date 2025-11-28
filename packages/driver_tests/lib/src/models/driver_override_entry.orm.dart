// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'driver_override_entry.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DriverOverrideEntryIdField = FieldDefinition(
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

const FieldDefinition _$DriverOverrideEntryPayloadField = FieldDefinition(
  name: 'payload',
  columnName: 'payload',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  columnType: 'TEXT',
  driverOverrides: {
    'postgres': FieldDriverOverride(
      columnType: 'jsonb',
      codecType: 'PostgresPayloadCodec',
    ),
    'sqlite': FieldDriverOverride(
      columnType: 'TEXT',
      codecType: 'SqlitePayloadCodec',
    ),
  },
);

final ModelDefinition<DriverOverrideEntry>
_$DriverOverrideEntryModelDefinition = ModelDefinition(
  modelName: 'DriverOverrideEntry',
  tableName: 'settings',
  fields: const [
    _$DriverOverrideEntryIdField,
    _$DriverOverrideEntryPayloadField,
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
  codec: _$DriverOverrideEntryModelCodec(),
);

// ignore: unused_element
final _DriverOverrideEntryModelDefinitionRegistration =
    ModelFactoryRegistry.register<DriverOverrideEntry>(
      _$DriverOverrideEntryModelDefinition,
    );

extension DriverOverrideEntryOrmDefinition on DriverOverrideEntry {
  static ModelDefinition<DriverOverrideEntry> get definition =>
      _$DriverOverrideEntryModelDefinition;
}

class DriverOverrideEntryModelFactory {
  const DriverOverrideEntryModelFactory._();

  static ModelDefinition<DriverOverrideEntry> get definition =>
      DriverOverrideEntryOrmDefinition.definition;

  static ModelCodec<DriverOverrideEntry> get codec => definition.codec;

  static DriverOverrideEntry fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DriverOverrideEntry model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DriverOverrideEntry> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DriverOverrideEntry>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<DriverOverrideEntry> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DriverOverrideEntry>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

extension DriverOverrideEntryModelFactoryExtension on DriverOverrideEntry {
  static ModelFactoryBuilder<DriverOverrideEntry> factory({
    GeneratorProvider? generatorProvider,
  }) => DriverOverrideEntryModelFactory.factory(
    generatorProvider: generatorProvider,
  );
}

class _$DriverOverrideEntryModelCodec extends ModelCodec<DriverOverrideEntry> {
  const _$DriverOverrideEntryModelCodec();

  @override
  Map<String, Object?> encode(
    DriverOverrideEntry model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$DriverOverrideEntryIdField, model.id),
      'payload': registry.encodeField(
        _$DriverOverrideEntryPayloadField,
        model.payload,
      ),
    };
  }

  @override
  DriverOverrideEntry decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int driverOverrideEntryIdValue =
        registry.decodeField<int>(_$DriverOverrideEntryIdField, data['id']) ??
        (throw StateError('Field id on DriverOverrideEntry cannot be null.'));
    final Map<String, Object?> driverOverrideEntryPayloadValue =
        registry.decodeField<Map<String, Object?>>(
          _$DriverOverrideEntryPayloadField,
          data['payload'],
        ) ??
        (throw StateError(
          'Field payload on DriverOverrideEntry cannot be null.',
        ));
    final model = _$DriverOverrideEntryModel(
      id: driverOverrideEntryIdValue,
      payload: driverOverrideEntryPayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': driverOverrideEntryIdValue,
      'payload': driverOverrideEntryPayloadValue,
    });
    return model;
  }
}

class _$DriverOverrideEntryModel extends DriverOverrideEntry {
  _$DriverOverrideEntryModel({
    required int id,
    required Map<String, Object?> payload,
  }) : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  Map<String, Object?> get payload =>
      getAttribute<Map<String, Object?>>('payload') ?? super.payload;

  set payload(Map<String, Object?> value) => setAttribute('payload', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$DriverOverrideEntryModelDefinition);
  }
}

extension DriverOverrideEntryAttributeSetters on DriverOverrideEntry {
  set id(int value) => setAttribute('id', value);
  set payload(Map<String, Object?> value) => setAttribute('payload', value);
}
