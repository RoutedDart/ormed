// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'orm_migration_record.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$OrmMigrationRecordIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$OrmMigrationRecordChecksumField = FieldDefinition(
  name: 'checksum',
  columnName: 'checksum',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$OrmMigrationRecordAppliedAtField = FieldDefinition(
  name: 'appliedAt',
  columnName: 'applied_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$OrmMigrationRecordBatchField = FieldDefinition(
  name: 'batch',
  columnName: 'batch',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<OrmMigrationRecord> _$OrmMigrationRecordModelDefinition =
    ModelDefinition(
      modelName: 'OrmMigrationRecord',
      tableName: 'orm_migrations',
      fields: const [
        _$OrmMigrationRecordIdField,
        _$OrmMigrationRecordChecksumField,
        _$OrmMigrationRecordAppliedAtField,
        _$OrmMigrationRecordBatchField,
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
      codec: _$OrmMigrationRecordModelCodec(),
    );

extension OrmMigrationRecordOrmDefinition on OrmMigrationRecord {
  static ModelDefinition<OrmMigrationRecord> get definition =>
      _$OrmMigrationRecordModelDefinition;
}

class OrmMigrationRecordModelFactory {
  const OrmMigrationRecordModelFactory._();

  static ModelDefinition<OrmMigrationRecord> get definition =>
      OrmMigrationRecordOrmDefinition.definition;

  static ModelCodec<OrmMigrationRecord> get codec => definition.codec;

  static OrmMigrationRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    OrmMigrationRecord model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<OrmMigrationRecord> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<OrmMigrationRecord>(
    definition: definition,
    context: context,
  );

  static Query<OrmMigrationRecord> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<OrmMigrationRecord>();
  }

  static ModelFactoryBuilder<OrmMigrationRecord> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<OrmMigrationRecord>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<OrmMigrationRecord>> all([String? connection]) =>
      query(connection).get();

  static Future<OrmMigrationRecord> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$OrmMigrationRecordModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<OrmMigrationRecord>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<OrmMigrationRecord>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$OrmMigrationRecordModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<OrmMigrationRecord>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$OrmMigrationRecordModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<OrmMigrationRecord>();
    await repo.insertMany(models, returning: false);
  }

  static Future<OrmMigrationRecord?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<OrmMigrationRecord> findOrFail(
    Object id, [
    String? connection,
  ]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<OrmMigrationRecord>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<OrmMigrationRecord?> first([String? connection]) =>
      query(connection).first();

  static Future<OrmMigrationRecord> firstOrFail([String? connection]) async {
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

  static Query<OrmMigrationRecord> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<OrmMigrationRecord> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<OrmMigrationRecord> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<OrmMigrationRecord> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension OrmMigrationRecordModelHelpers on OrmMigrationRecord {
  // Factory
  static ModelFactoryBuilder<OrmMigrationRecord> factory({
    GeneratorProvider? generatorProvider,
  }) => OrmMigrationRecordModelFactory.factory(
    generatorProvider: generatorProvider,
  );

  // Query builder
  static Query<OrmMigrationRecord> query([String? connection]) =>
      OrmMigrationRecordModelFactory.query(connection);

  // CRUD operations
  static Future<List<OrmMigrationRecord>> all([String? connection]) =>
      OrmMigrationRecordModelFactory.all(connection);

  static Future<OrmMigrationRecord?> find(Object id, [String? connection]) =>
      OrmMigrationRecordModelFactory.find(id, connection);

  static Future<OrmMigrationRecord> findOrFail(
    Object id, [
    String? connection,
  ]) => OrmMigrationRecordModelFactory.findOrFail(id, connection);

  static Future<List<OrmMigrationRecord>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => OrmMigrationRecordModelFactory.findMany(ids, connection);

  static Future<OrmMigrationRecord?> first([String? connection]) =>
      OrmMigrationRecordModelFactory.first(connection);

  static Future<OrmMigrationRecord> firstOrFail([String? connection]) =>
      OrmMigrationRecordModelFactory.firstOrFail(connection);

  static Future<OrmMigrationRecord> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => OrmMigrationRecordModelFactory.create(attributes, connection);

  static Future<List<OrmMigrationRecord>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => OrmMigrationRecordModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => OrmMigrationRecordModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      OrmMigrationRecordModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      OrmMigrationRecordModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      OrmMigrationRecordModelFactory.exists(connection);

  static Query<OrmMigrationRecord> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => OrmMigrationRecordModelFactory.where(column, value, connection);

  static Query<OrmMigrationRecord> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => OrmMigrationRecordModelFactory.whereIn(column, values, connection);

  static Query<OrmMigrationRecord> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => OrmMigrationRecordModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<OrmMigrationRecord> limit(int count, [String? connection]) =>
      OrmMigrationRecordModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ??
        OrmMigrationRecordModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<OrmMigrationRecord>();
    final primaryKeys = OrmMigrationRecordModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: OrmMigrationRecordModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$OrmMigrationRecordModelCodec extends ModelCodec<OrmMigrationRecord> {
  const _$OrmMigrationRecordModelCodec();

  @override
  Map<String, Object?> encode(
    OrmMigrationRecord model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$OrmMigrationRecordIdField, model.id),
      'checksum': registry.encodeField(
        _$OrmMigrationRecordChecksumField,
        model.checksum,
      ),
      'applied_at': registry.encodeField(
        _$OrmMigrationRecordAppliedAtField,
        model.appliedAt,
      ),
      'batch': registry.encodeField(
        _$OrmMigrationRecordBatchField,
        model.batch,
      ),
    };
  }

  @override
  OrmMigrationRecord decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final String ormMigrationRecordIdValue =
        registry.decodeField<String>(_$OrmMigrationRecordIdField, data['id']) ??
        (throw StateError('Field id on OrmMigrationRecord cannot be null.'));
    final String ormMigrationRecordChecksumValue =
        registry.decodeField<String>(
          _$OrmMigrationRecordChecksumField,
          data['checksum'],
        ) ??
        (throw StateError(
          'Field checksum on OrmMigrationRecord cannot be null.',
        ));
    final DateTime ormMigrationRecordAppliedAtValue =
        registry.decodeField<DateTime>(
          _$OrmMigrationRecordAppliedAtField,
          data['applied_at'],
        ) ??
        (throw StateError(
          'Field appliedAt on OrmMigrationRecord cannot be null.',
        ));
    final int ormMigrationRecordBatchValue =
        registry.decodeField<int>(
          _$OrmMigrationRecordBatchField,
          data['batch'],
        ) ??
        (throw StateError('Field batch on OrmMigrationRecord cannot be null.'));
    final model = _$OrmMigrationRecordModel(
      id: ormMigrationRecordIdValue,
      checksum: ormMigrationRecordChecksumValue,
      appliedAt: ormMigrationRecordAppliedAtValue,
      batch: ormMigrationRecordBatchValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': ormMigrationRecordIdValue,
      'checksum': ormMigrationRecordChecksumValue,
      'applied_at': ormMigrationRecordAppliedAtValue,
      'batch': ormMigrationRecordBatchValue,
    });
    return model;
  }
}

class _$OrmMigrationRecordModel extends OrmMigrationRecord {
  _$OrmMigrationRecordModel({
    required String id,
    required String checksum,
    required DateTime appliedAt,
    required int batch,
  }) : super.new(
         id: id,
         checksum: checksum,
         appliedAt: appliedAt,
         batch: batch,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'checksum': checksum,
      'applied_at': appliedAt,
      'batch': batch,
    });
  }

  @override
  String get id => getAttribute<String>('id') ?? super.id;

  set id(String value) => setAttribute('id', value);

  @override
  String get checksum => getAttribute<String>('checksum') ?? super.checksum;

  set checksum(String value) => setAttribute('checksum', value);

  @override
  DateTime get appliedAt =>
      getAttribute<DateTime>('applied_at') ?? super.appliedAt;

  set appliedAt(DateTime value) => setAttribute('applied_at', value);

  @override
  int get batch => getAttribute<int>('batch') ?? super.batch;

  set batch(int value) => setAttribute('batch', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$OrmMigrationRecordModelDefinition);
  }
}

extension OrmMigrationRecordAttributeSetters on OrmMigrationRecord {
  set id(String value) => setAttribute('id', value);
  set checksum(String value) => setAttribute('checksum', value);
  set appliedAt(DateTime value) => setAttribute('applied_at', value);
  set batch(int value) => setAttribute('batch', value);
}
