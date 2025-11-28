// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'named_constructor_model.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$NamedConstructorModelIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$NamedConstructorModelNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$NamedConstructorModelValueField = FieldDefinition(
  name: 'value',
  columnName: 'value',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<NamedConstructorModel>
_$NamedConstructorModelModelDefinition = ModelDefinition(
  modelName: 'NamedConstructorModel',
  tableName: 'named_constructor_models',
  fields: const [
    _$NamedConstructorModelIdField,
    _$NamedConstructorModelNameField,
    _$NamedConstructorModelValueField,
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
  codec: _$NamedConstructorModelModelCodec(),
);

extension NamedConstructorModelOrmDefinition on NamedConstructorModel {
  static ModelDefinition<NamedConstructorModel> get definition =>
      _$NamedConstructorModelModelDefinition;
}

class _$NamedConstructorModelModelCodec
    extends ModelCodec<NamedConstructorModel> {
  const _$NamedConstructorModelModelCodec();

  @override
  Map<String, Object?> encode(
    NamedConstructorModel model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$NamedConstructorModelIdField, model.id),
      'name': registry.encodeField(
        _$NamedConstructorModelNameField,
        model.name,
      ),
      'value': registry.encodeField(
        _$NamedConstructorModelValueField,
        model.value,
      ),
    };
  }

  @override
  NamedConstructorModel decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int? namedConstructorModelIdValue = registry.decodeField<int?>(
      _$NamedConstructorModelIdField,
      data['id'],
    );
    final String namedConstructorModelNameValue =
        registry.decodeField<String>(
          _$NamedConstructorModelNameField,
          data['name'],
        ) ??
        (throw StateError(
          'Field name on NamedConstructorModel cannot be null.',
        ));
    final int namedConstructorModelValueValue =
        registry.decodeField<int>(
          _$NamedConstructorModelValueField,
          data['value'],
        ) ??
        (throw StateError(
          'Field value on NamedConstructorModel cannot be null.',
        ));
    final model = _$NamedConstructorModelModel(
      id: namedConstructorModelIdValue,
      name: namedConstructorModelNameValue,
      value: namedConstructorModelValueValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': namedConstructorModelIdValue,
      'name': namedConstructorModelNameValue,
      'value': namedConstructorModelValueValue,
    });
    return model;
  }
}

class _$NamedConstructorModelModel extends NamedConstructorModel {
  _$NamedConstructorModelModel({
    required int? id,
    required String name,
    required int value,
  }) : super.fromDatabase(id: id, name: name, value: value) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name, 'value': value});
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  set name(String value) => setAttribute('name', value);

  @override
  int get value => getAttribute<int>('value') ?? super.value;

  set value(int value) => setAttribute('value', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$NamedConstructorModelModelDefinition);
  }
}

extension NamedConstructorModelAttributeSetters on NamedConstructorModel {
  set id(int? value) => setAttribute('id', value);
  set name(String value) => setAttribute('name', value);
  set value(int value) => setAttribute('value', value);
}
