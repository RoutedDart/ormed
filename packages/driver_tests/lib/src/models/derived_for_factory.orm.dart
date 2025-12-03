// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'derived_for_factory.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$DerivedForFactoryLayerTwoFlagField = FieldDefinition(
  name: 'layerTwoFlag',
  columnName: 'layerTwoFlag',
  dartType: 'bool',
  resolvedType: 'bool?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$DerivedForFactoryLayerOneNotesField = FieldDefinition(
  name: 'layerOneNotes',
  columnName: 'layerOneNotes',
  dartType: 'Map<String, Object?>',
  resolvedType: 'Map<String, Object?>?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
  codecType: 'json',
);

const FieldDefinition _$DerivedForFactoryIdField = FieldDefinition(
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

const FieldDefinition _$DerivedForFactoryBaseNameField = FieldDefinition(
  name: 'baseName',
  columnName: 'baseName',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<DerivedForFactory> _$DerivedForFactoryModelDefinition =
    ModelDefinition(
      modelName: 'DerivedForFactory',
      tableName: 'derived_for_factories',
      fields: const [
        _$DerivedForFactoryLayerTwoFlagField,
        _$DerivedForFactoryLayerOneNotesField,
        _$DerivedForFactoryIdField,
        _$DerivedForFactoryBaseNameField,
      ],
      relations: const [],
      softDeleteColumn: 'deleted_at',
      metadata: ModelAttributesMetadata(
        hidden: const <String>[],
        visible: const <String>[],
        fillable: const <String>[],
        guarded: const <String>[],
        casts: const <String, String>{},
        fieldOverrides: const {
          'layerTwoFlag': FieldAttributeMetadata(guarded: true),
          'layerOneNotes': FieldAttributeMetadata(cast: 'json'),
          'id': FieldAttributeMetadata(hidden: true),
          'baseName': FieldAttributeMetadata(fillable: true),
        },
        softDeletes: false,
        softDeleteColumn: 'deleted_at',
      ),
      codec: _$DerivedForFactoryModelCodec(),
    );

// ignore: unused_element
final derivedforfactoryModelDefinitionRegistration =
    ModelFactoryRegistry.register<DerivedForFactory>(
      _$DerivedForFactoryModelDefinition,
    );

extension DerivedForFactoryOrmDefinition on DerivedForFactory {
  static ModelDefinition<DerivedForFactory> get definition =>
      _$DerivedForFactoryModelDefinition;
}

class DerivedForFactorys {
  const DerivedForFactorys._();

  static Query<DerivedForFactory> query([String? connection]) =>
      Model.query<DerivedForFactory>(connection: connection);

  static Future<DerivedForFactory?> find(Object id, {String? connection}) =>
      Model.find<DerivedForFactory>(id, connection: connection);

  static Future<DerivedForFactory> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<DerivedForFactory>(id, connection: connection);

  static Future<List<DerivedForFactory>> all({String? connection}) =>
      Model.all<DerivedForFactory>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<DerivedForFactory>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<DerivedForFactory>(connection: connection);

  static Query<DerivedForFactory> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<DerivedForFactory>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<DerivedForFactory> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) =>
      Model.whereIn<DerivedForFactory>(column, values, connection: connection);

  static Query<DerivedForFactory> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<DerivedForFactory>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<DerivedForFactory> limit(int count, {String? connection}) =>
      Model.limit<DerivedForFactory>(count, connection: connection);
}

class DerivedForFactoryModelFactory {
  const DerivedForFactoryModelFactory._();

  static ModelDefinition<DerivedForFactory> get definition =>
      _$DerivedForFactoryModelDefinition;

  static ModelCodec<DerivedForFactory> get codec => definition.codec;

  static DerivedForFactory fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DerivedForFactory model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<DerivedForFactory> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<DerivedForFactory>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<DerivedForFactory> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<DerivedForFactory>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$DerivedForFactoryModelCodec extends ModelCodec<DerivedForFactory> {
  const _$DerivedForFactoryModelCodec();

  @override
  Map<String, Object?> encode(
    DerivedForFactory model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'layerTwoFlag': registry.encodeField(
        _$DerivedForFactoryLayerTwoFlagField,
        model.layerTwoFlag,
      ),
      'layerOneNotes': registry.encodeField(
        _$DerivedForFactoryLayerOneNotesField,
        model.layerOneNotes,
      ),
      'id': registry.encodeField(_$DerivedForFactoryIdField, model.id),
      'baseName': registry.encodeField(
        _$DerivedForFactoryBaseNameField,
        model.baseName,
      ),
    };
  }

  @override
  DerivedForFactory decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final bool? derivedForFactoryLayerTwoFlagValue = registry
        .decodeField<bool?>(
          _$DerivedForFactoryLayerTwoFlagField,
          data['layerTwoFlag'],
        );
    final Map<String, Object?>? derivedForFactoryLayerOneNotesValue = registry
        .decodeField<Map<String, Object?>?>(
          _$DerivedForFactoryLayerOneNotesField,
          data['layerOneNotes'],
        );
    final int derivedForFactoryIdValue =
        registry.decodeField<int>(_$DerivedForFactoryIdField, data['id']) ??
        (throw StateError('Field id on DerivedForFactory cannot be null.'));
    final String? derivedForFactoryBaseNameValue = registry
        .decodeField<String?>(
          _$DerivedForFactoryBaseNameField,
          data['baseName'],
        );
    final model = _$DerivedForFactoryModel(
      id: derivedForFactoryIdValue,
      baseName: derivedForFactoryBaseNameValue,
      layerOneNotes: derivedForFactoryLayerOneNotesValue,
      layerTwoFlag: derivedForFactoryLayerTwoFlagValue,
    );
    model._attachOrmRuntimeMetadata({
      'layerTwoFlag': derivedForFactoryLayerTwoFlagValue,
      'layerOneNotes': derivedForFactoryLayerOneNotesValue,
      'id': derivedForFactoryIdValue,
      'baseName': derivedForFactoryBaseNameValue,
    });
    return model;
  }
}

class _$DerivedForFactoryModel extends DerivedForFactory {
  _$DerivedForFactoryModel({
    required int id,
    String? baseName,
    Map<String, Object?>? layerOneNotes,
    bool? layerTwoFlag,
  }) : super.new(
         id: id,
         baseName: baseName,
         layerOneNotes: layerOneNotes,
         layerTwoFlag: layerTwoFlag,
       ) {
    _attachOrmRuntimeMetadata({
      'layerTwoFlag': layerTwoFlag,
      'layerOneNotes': layerOneNotes,
      'id': id,
      'baseName': baseName,
    });
  }

  @override
  bool? get layerTwoFlag =>
      getAttribute<bool?>('layerTwoFlag') ?? super.layerTwoFlag;

  set layerTwoFlag(bool? value) => setAttribute('layerTwoFlag', value);

  @override
  Map<String, Object?>? get layerOneNotes =>
      getAttribute<Map<String, Object?>?>('layerOneNotes') ??
      super.layerOneNotes;

  set layerOneNotes(Map<String, Object?>? value) =>
      setAttribute('layerOneNotes', value);

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String? get baseName => getAttribute<String?>('baseName') ?? super.baseName;

  set baseName(String? value) => setAttribute('baseName', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$DerivedForFactoryModelDefinition);
  }
}
