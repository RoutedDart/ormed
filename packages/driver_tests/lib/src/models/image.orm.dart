// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'image.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ImageIdField = FieldDefinition(
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

const FieldDefinition _$ImageLabelField = FieldDefinition(
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

const RelationDefinition _$ImagePrimaryPhotoRelation = RelationDefinition(
  name: 'primaryPhoto',
  kind: RelationKind.morphOne,
  targetModel: 'Photo',
  foreignKey: 'imageable_id',
  morphType: 'imageable_type',
  morphClass: 'Image',
);

final ModelDefinition<Image> _$ImageModelDefinition = ModelDefinition(
  modelName: 'Image',
  tableName: 'images',
  fields: const [_$ImageIdField, _$ImageLabelField],
  relations: const [_$ImagePrimaryPhotoRelation],
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
  codec: _$ImageModelCodec(),
);

// ignore: unused_element
final imageModelDefinitionRegistration = ModelFactoryRegistry.register<Image>(
  _$ImageModelDefinition,
);

extension ImageOrmDefinition on Image {
  static ModelDefinition<Image> get definition => _$ImageModelDefinition;
}

class ImageModelFactory {
  const ImageModelFactory._();

  static ModelDefinition<Image> get definition => ImageOrmDefinition.definition;

  static ModelCodec<Image> get codec => definition.codec;

  static Image fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Image model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Image> withConnection(QueryContext context) =>
      ModelFactoryConnection<Image>(definition: definition, context: context);

  static Query<Image> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<Image>();
  }

  static ModelFactoryBuilder<Image> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Image>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<Image>> all([String? connection]) =>
      query(connection).get();

  static Future<Image> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$ImageModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Image>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<Image>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$ImageModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Image>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$ImageModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Image>();
    await repo.insertMany(models, returning: false);
  }

  static Future<Image?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<Image> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<Image>> findMany(List<Object> ids, [String? connection]) =>
      query(connection).findMany(ids);

  static Future<Image?> first([String? connection]) =>
      query(connection).first();

  static Future<Image> firstOrFail([String? connection]) async {
    final result = await first(connection);
    if (result == null) throw StateError("No model found");
    return result;
  }

  static Future<int> count([String? connection]) => query(connection).count();

  static Future<bool> exists([String? connection]) async =>
      await count(connection) > 0;

  static Future<int> destroy(List<Object> ids, [String? connection]) async {
    final models = await findMany(ids, connection);
    for (final model in models) {
      await model.delete();
    }
    return models.length;
  }

  static Query<Image> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<Image> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<Image> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<Image> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension ImageModelHelpers on Image {
  // Factory
  static ModelFactoryBuilder<Image> factory({
    GeneratorProvider? generatorProvider,
  }) => ImageModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<Image> query([String? connection]) =>
      ImageModelFactory.query(connection);

  // CRUD operations
  static Future<List<Image>> all([String? connection]) =>
      ImageModelFactory.all(connection);

  static Future<Image?> find(Object id, [String? connection]) =>
      ImageModelFactory.find(id, connection);

  static Future<Image> findOrFail(Object id, [String? connection]) =>
      ImageModelFactory.findOrFail(id, connection);

  static Future<List<Image>> findMany(List<Object> ids, [String? connection]) =>
      ImageModelFactory.findMany(ids, connection);

  static Future<Image?> first([String? connection]) =>
      ImageModelFactory.first(connection);

  static Future<Image> firstOrFail([String? connection]) =>
      ImageModelFactory.firstOrFail(connection);

  static Future<Image> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => ImageModelFactory.create(attributes, connection);

  static Future<List<Image>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => ImageModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => ImageModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      ImageModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      ImageModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      ImageModelFactory.exists(connection);

  static Query<Image> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => ImageModelFactory.where(column, value, connection);

  static Query<Image> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => ImageModelFactory.whereIn(column, values, connection);

  static Query<Image> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => ImageModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Image> limit(int count, [String? connection]) =>
      ImageModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? ImageModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Image>();
    final primaryKeys = ImageModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: ImageModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$ImageModelCodec extends ModelCodec<Image> {
  const _$ImageModelCodec();

  @override
  Map<String, Object?> encode(Image model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ImageIdField, model.id),
      'label': registry.encodeField(_$ImageLabelField, model.label),
    };
  }

  @override
  Image decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int imageIdValue =
        registry.decodeField<int>(_$ImageIdField, data['id']) ??
        (throw StateError('Field id on Image cannot be null.'));
    final String imageLabelValue =
        registry.decodeField<String>(_$ImageLabelField, data['label']) ??
        (throw StateError('Field label on Image cannot be null.'));
    final model = _$ImageModel(id: imageIdValue, label: imageLabelValue);
    model._attachOrmRuntimeMetadata({
      'id': imageIdValue,
      'label': imageLabelValue,
    });
    return model;
  }
}

class _$ImageModel extends Image {
  _$ImageModel({required int id, required String label})
    : super.new(id: id, label: label) {
    _attachOrmRuntimeMetadata({'id': id, 'label': label});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get label => getAttribute<String>('label') ?? super.label;

  set label(String value) => setAttribute('label', value);

  @override
  Photo? get primaryPhoto {
    if (relationLoaded('primaryPhoto')) {
      return getRelation<Photo>('primaryPhoto');
    }
    return super.primaryPhoto;
  }

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ImageModelDefinition);
  }
}

extension ImageAttributeSetters on Image {
  set id(int value) => setAttribute('id', value);
  set label(String value) => setAttribute('label', value);
}
