// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'driver_override.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DriverOverrideModelIdField = FieldDefinition(
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

const FieldDefinition _$DriverOverrideModelPayloadField = FieldDefinition(
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

final ModelDefinition<DriverOverrideModel>
_$DriverOverrideModelModelDefinition = ModelDefinition(
  modelName: 'DriverOverrideModel',
  tableName: 'driver_overrides',
  fields: const [
    _$DriverOverrideModelIdField,
    _$DriverOverrideModelPayloadField,
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
  codec: _$DriverOverrideModelModelCodec(),
);

extension DriverOverrideModelOrmDefinition on DriverOverrideModel {
  static ModelDefinition<DriverOverrideModel> get definition =>
      _$DriverOverrideModelModelDefinition;
}

class _$DriverOverrideModelModelCodec extends ModelCodec<DriverOverrideModel> {
  const _$DriverOverrideModelModelCodec();

  @override
  Map<String, Object?> encode(
    DriverOverrideModel model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$DriverOverrideModelIdField, model.id),
      'payload': registry.encodeField(
        _$DriverOverrideModelPayloadField,
        model.payload,
      ),
    };
  }

  @override
  DriverOverrideModel decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int driverOverrideModelIdValue =
        registry.decodeField<int>(_$DriverOverrideModelIdField, data['id']) ??
        (throw StateError('Field id on DriverOverrideModel cannot be null.'));
    final Map<String, Object?> driverOverrideModelPayloadValue =
        registry.decodeField<Map<String, Object?>>(
          _$DriverOverrideModelPayloadField,
          data['payload'],
        ) ??
        (throw StateError(
          'Field payload on DriverOverrideModel cannot be null.',
        ));
    final model = _$DriverOverrideModelModel(
      id: driverOverrideModelIdValue,
      payload: driverOverrideModelPayloadValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': driverOverrideModelIdValue,
      'payload': driverOverrideModelPayloadValue,
    });
    return model;
  }
}

class _$DriverOverrideModelModel extends DriverOverrideModel
    with ModelAttributes, ModelConnection {
  _$DriverOverrideModelModel({
    required int id,
    required Map<String, Object?> payload,
  }) : super.new(id: id, payload: payload) {
    _attachOrmRuntimeMetadata({'id': id, 'payload': payload});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  @override
  Map<String, Object?> get payload =>
      getAttribute<Map<String, Object?>>('payload') ?? super.payload;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$DriverOverrideModelModelDefinition);
  }
}
