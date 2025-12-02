// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'photo.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$PhotoIdField = FieldDefinition(
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

const FieldDefinition _$PhotoImageableIdField = FieldDefinition(
  name: 'imageableId',
  columnName: 'imageable_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PhotoImageableTypeField = FieldDefinition(
  name: 'imageableType',
  columnName: 'imageable_type',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PhotoPathField = FieldDefinition(
  name: 'path',
  columnName: 'path',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Photo> _$PhotoModelDefinition = ModelDefinition(
  modelName: 'Photo',
  tableName: 'photos',
  fields: const [
    _$PhotoIdField,
    _$PhotoImageableIdField,
    _$PhotoImageableTypeField,
    _$PhotoPathField,
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
  codec: _$PhotoModelCodec(),
);

// ignore: unused_element
final photoModelDefinitionRegistration = ModelFactoryRegistry.register<Photo>(
  _$PhotoModelDefinition,
);

extension PhotoOrmDefinition on Photo {
  static ModelDefinition<Photo> get definition => _$PhotoModelDefinition;
}

class PhotoModelFactory {
  const PhotoModelFactory._();

  static ModelDefinition<Photo> get definition => PhotoOrmDefinition.definition;

  static ModelCodec<Photo> get codec => definition.codec;

  static Photo fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Photo model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Photo> withConnection(QueryContext context) =>
      ModelFactoryConnection<Photo>(definition: definition, context: context);

  static Query<Photo> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<Photo>();
  }

  static ModelFactoryBuilder<Photo> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Photo>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<Photo>> all([String? connection]) =>
      query(connection).get();

  static Future<Photo> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$PhotoModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Photo>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<Photo>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$PhotoModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Photo>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$PhotoModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Photo>();
    await repo.insertMany(models, returning: false);
  }

  static Future<Photo?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<Photo> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<Photo>> findMany(List<Object> ids, [String? connection]) =>
      query(connection).findMany(ids);

  static Future<Photo?> first([String? connection]) =>
      query(connection).first();

  static Future<Photo> firstOrFail([String? connection]) async {
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

  static Query<Photo> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<Photo> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<Photo> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<Photo> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension PhotoModelHelpers on Photo {
  // Factory
  static ModelFactoryBuilder<Photo> factory({
    GeneratorProvider? generatorProvider,
  }) => PhotoModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<Photo> query([String? connection]) =>
      PhotoModelFactory.query(connection);

  // CRUD operations
  static Future<List<Photo>> all([String? connection]) =>
      PhotoModelFactory.all(connection);

  static Future<Photo?> find(Object id, [String? connection]) =>
      PhotoModelFactory.find(id, connection);

  static Future<Photo> findOrFail(Object id, [String? connection]) =>
      PhotoModelFactory.findOrFail(id, connection);

  static Future<List<Photo>> findMany(List<Object> ids, [String? connection]) =>
      PhotoModelFactory.findMany(ids, connection);

  static Future<Photo?> first([String? connection]) =>
      PhotoModelFactory.first(connection);

  static Future<Photo> firstOrFail([String? connection]) =>
      PhotoModelFactory.firstOrFail(connection);

  static Future<Photo> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => PhotoModelFactory.create(attributes, connection);

  static Future<List<Photo>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => PhotoModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => PhotoModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      PhotoModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      PhotoModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      PhotoModelFactory.exists(connection);

  static Query<Photo> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => PhotoModelFactory.where(column, value, connection);

  static Query<Photo> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => PhotoModelFactory.whereIn(column, values, connection);

  static Query<Photo> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => PhotoModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Photo> limit(int count, [String? connection]) =>
      PhotoModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? PhotoModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Photo>();
    final primaryKeys = PhotoModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: PhotoModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$PhotoModelCodec extends ModelCodec<Photo> {
  const _$PhotoModelCodec();

  @override
  Map<String, Object?> encode(Photo model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$PhotoIdField, model.id),
      'imageable_id': registry.encodeField(
        _$PhotoImageableIdField,
        model.imageableId,
      ),
      'imageable_type': registry.encodeField(
        _$PhotoImageableTypeField,
        model.imageableType,
      ),
      'path': registry.encodeField(_$PhotoPathField, model.path),
    };
  }

  @override
  Photo decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int photoIdValue =
        registry.decodeField<int>(_$PhotoIdField, data['id']) ??
        (throw StateError('Field id on Photo cannot be null.'));
    final int photoImageableIdValue =
        registry.decodeField<int>(
          _$PhotoImageableIdField,
          data['imageable_id'],
        ) ??
        (throw StateError('Field imageableId on Photo cannot be null.'));
    final String photoImageableTypeValue =
        registry.decodeField<String>(
          _$PhotoImageableTypeField,
          data['imageable_type'],
        ) ??
        (throw StateError('Field imageableType on Photo cannot be null.'));
    final String photoPathValue =
        registry.decodeField<String>(_$PhotoPathField, data['path']) ??
        (throw StateError('Field path on Photo cannot be null.'));
    final model = _$PhotoModel(
      id: photoIdValue,
      imageableId: photoImageableIdValue,
      imageableType: photoImageableTypeValue,
      path: photoPathValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': photoIdValue,
      'imageable_id': photoImageableIdValue,
      'imageable_type': photoImageableTypeValue,
      'path': photoPathValue,
    });
    return model;
  }
}

class _$PhotoModel extends Photo {
  _$PhotoModel({
    required int id,
    required int imageableId,
    required String imageableType,
    required String path,
  }) : super.new(
         id: id,
         imageableId: imageableId,
         imageableType: imageableType,
         path: path,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'imageable_id': imageableId,
      'imageable_type': imageableType,
      'path': path,
    });
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  int get imageableId => getAttribute<int>('imageable_id') ?? super.imageableId;

  set imageableId(int value) => setAttribute('imageable_id', value);

  @override
  String get imageableType =>
      getAttribute<String>('imageable_type') ?? super.imageableType;

  set imageableType(String value) => setAttribute('imageable_type', value);

  @override
  String get path => getAttribute<String>('path') ?? super.path;

  set path(String value) => setAttribute('path', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PhotoModelDefinition);
  }
}

extension PhotoAttributeSetters on Photo {
  set id(int value) => setAttribute('id', value);
  set imageableId(int value) => setAttribute('imageable_id', value);
  set imageableType(String value) => setAttribute('imageable_type', value);
  set path(String value) => setAttribute('path', value);
}
