// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'serial_test.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$SerialTestIdField = FieldDefinition(
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

const FieldDefinition _$SerialTestLabelField = FieldDefinition(
  name: 'label',
  columnName: 'label',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<SerialTest> _$SerialTestModelDefinition = ModelDefinition(
  modelName: 'SerialTest',
  tableName: 'serial_tests',
  fields: const [_$SerialTestIdField, _$SerialTestLabelField],
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
  codec: _$SerialTestModelCodec(),
);

// ignore: unused_element
final serialtestModelDefinitionRegistration =
    ModelFactoryRegistry.register<SerialTest>(_$SerialTestModelDefinition);

extension SerialTestOrmDefinition on SerialTest {
  static ModelDefinition<SerialTest> get definition =>
      _$SerialTestModelDefinition;
}

class SerialTests {
  const SerialTests._();

  static Query<SerialTest> query([String? connection]) =>
      Model.query<SerialTest>(connection: connection);

  static Future<SerialTest?> find(Object id, {String? connection}) =>
      Model.find<SerialTest>(id, connection: connection);

  static Future<SerialTest> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<SerialTest>(id, connection: connection);

  static Future<List<SerialTest>> all({String? connection}) =>
      Model.all<SerialTest>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<SerialTest>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<SerialTest>(connection: connection);

  static Query<SerialTest> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) =>
      Model.where<SerialTest>(column, operator, value, connection: connection);

  static Query<SerialTest> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<SerialTest>(column, values, connection: connection);

  static Query<SerialTest> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<SerialTest>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<SerialTest> limit(int count, {String? connection}) =>
      Model.limit<SerialTest>(count, connection: connection);
}

class SerialTestModelFactory {
  const SerialTestModelFactory._();

  static ModelDefinition<SerialTest> get definition =>
      _$SerialTestModelDefinition;

  static ModelCodec<SerialTest> get codec => definition.codec;

  static SerialTest fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    SerialTest model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<SerialTest> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<SerialTest>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<SerialTest> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<SerialTest>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$SerialTestModelCodec extends ModelCodec<SerialTest> {
  const _$SerialTestModelCodec();

  @override
  Map<String, Object?> encode(SerialTest model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$SerialTestIdField, model.id),
      'label': registry.encodeField(_$SerialTestLabelField, model.label),
    };
  }

  @override
  SerialTest decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int serialTestIdValue =
        registry.decodeField<int>(_$SerialTestIdField, data['id']) ?? 0;
    final String serialTestLabelValue =
        registry.decodeField<String>(_$SerialTestLabelField, data['label']) ??
        (throw StateError('Field label on SerialTest cannot be null.'));
    final model = _$SerialTestModel(
      id: serialTestIdValue,
      label: serialTestLabelValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': serialTestIdValue,
      'label': serialTestLabelValue,
    });
    return model;
  }
}

class _$SerialTestModel extends SerialTest {
  _$SerialTestModel({required int id, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get label => getAttribute<String>('label') ?? super.label;

  set label(String value) => setAttribute('label', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$SerialTestModelDefinition);
  }
}
