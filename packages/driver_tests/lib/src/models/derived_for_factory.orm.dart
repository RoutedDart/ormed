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
  autoIncrement: true,
  insertable: false,
  defaultDartValue: 0,
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

final ModelDefinition<$DerivedForFactory> _$DerivedForFactoryDefinition =
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
      codec: _$DerivedForFactoryCodec(),
    );

// ignore: unused_element
final derivedforfactoryModelDefinitionRegistration =
    ModelFactoryRegistry.register<$DerivedForFactory>(
      _$DerivedForFactoryDefinition,
    );

extension DerivedForFactoryOrmDefinition on DerivedForFactory {
  static ModelDefinition<$DerivedForFactory> get definition =>
      _$DerivedForFactoryDefinition;
}

class DerivedForFactorys {
  const DerivedForFactorys._();

  static Query<$DerivedForFactory> query([String? connection]) =>
      Model.query<$DerivedForFactory>(connection: connection);

  static Future<$DerivedForFactory?> find(Object id, {String? connection}) =>
      Model.find<$DerivedForFactory>(id, connection: connection);

  static Future<$DerivedForFactory> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$DerivedForFactory>(id, connection: connection);

  static Future<List<$DerivedForFactory>> all({String? connection}) =>
      Model.all<$DerivedForFactory>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$DerivedForFactory>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$DerivedForFactory>(connection: connection);

  static Query<$DerivedForFactory> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$DerivedForFactory>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$DerivedForFactory> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) =>
      Model.whereIn<$DerivedForFactory>(column, values, connection: connection);

  static Query<$DerivedForFactory> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$DerivedForFactory>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$DerivedForFactory> limit(int count, {String? connection}) =>
      Model.limit<$DerivedForFactory>(count, connection: connection);

  static Repository<$DerivedForFactory> repo([String? connection]) =>
      Model.repository<$DerivedForFactory>(connection: connection);
}

class DerivedForFactoryModelFactory {
  const DerivedForFactoryModelFactory._();

  static ModelDefinition<$DerivedForFactory> get definition =>
      _$DerivedForFactoryDefinition;

  static ModelCodec<$DerivedForFactory> get codec => definition.codec;

  static DerivedForFactory fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    DerivedForFactory model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

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

class _$DerivedForFactoryCodec extends ModelCodec<$DerivedForFactory> {
  const _$DerivedForFactoryCodec();
  @override
  Map<String, Object?> encode(
    $DerivedForFactory model,
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
  $DerivedForFactory decode(
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
        registry.decodeField<int>(_$DerivedForFactoryIdField, data['id']) ?? 0;
    final String? derivedForFactoryBaseNameValue = registry
        .decodeField<String?>(
          _$DerivedForFactoryBaseNameField,
          data['baseName'],
        );
    final model = $DerivedForFactory(
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

/// Generated tracked model class for [DerivedForFactory].
///
/// This class extends the user-defined [DerivedForFactory] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $DerivedForFactory extends DerivedForFactory with ModelAttributes {
  $DerivedForFactory({
    int id = 0,
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

  /// Creates a tracked model instance from a user-defined model instance.
  factory $DerivedForFactory.fromModel(DerivedForFactory model) {
    return $DerivedForFactory(
      layerTwoFlag: model.layerTwoFlag,
      layerOneNotes: model.layerOneNotes,
      id: model.id,
      baseName: model.baseName,
    );
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
    attachModelDefinition(_$DerivedForFactoryDefinition);
  }
}

extension DerivedForFactoryOrmExtension on DerivedForFactory {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $DerivedForFactory;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $DerivedForFactory toTracked() {
    return $DerivedForFactory.fromModel(this);
  }
}
