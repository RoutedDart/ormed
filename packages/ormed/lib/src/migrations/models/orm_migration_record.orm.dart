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

final ModelDefinition<$OrmMigrationRecord> _$OrmMigrationRecordDefinition =
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
      codec: _$OrmMigrationRecordCodec(),
    );

extension OrmMigrationRecordOrmDefinition on OrmMigrationRecord {
  static ModelDefinition<$OrmMigrationRecord> get definition =>
      _$OrmMigrationRecordDefinition;
}

class OrmMigrationRecords {
  const OrmMigrationRecords._();

  static Query<$OrmMigrationRecord> query([String? connection]) =>
      Model.query<$OrmMigrationRecord>(connection: connection);

  static Future<$OrmMigrationRecord?> find(Object id, {String? connection}) =>
      Model.find<$OrmMigrationRecord>(id, connection: connection);

  static Future<$OrmMigrationRecord> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$OrmMigrationRecord>(id, connection: connection);

  static Future<List<$OrmMigrationRecord>> all({String? connection}) =>
      Model.all<$OrmMigrationRecord>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$OrmMigrationRecord>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$OrmMigrationRecord>(connection: connection);

  static Query<$OrmMigrationRecord> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$OrmMigrationRecord>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$OrmMigrationRecord> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$OrmMigrationRecord>(
    column,
    values,
    connection: connection,
  );

  static Query<$OrmMigrationRecord> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$OrmMigrationRecord>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$OrmMigrationRecord> limit(int count, {String? connection}) =>
      Model.limit<$OrmMigrationRecord>(count, connection: connection);

  static Repository<$OrmMigrationRecord> repo([String? connection]) =>
      Model.repository<$OrmMigrationRecord>(connection: connection);
}

class OrmMigrationRecordModelFactory {
  const OrmMigrationRecordModelFactory._();

  static ModelDefinition<$OrmMigrationRecord> get definition =>
      _$OrmMigrationRecordDefinition;

  static ModelCodec<$OrmMigrationRecord> get codec => definition.codec;

  static OrmMigrationRecord fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    OrmMigrationRecord model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<OrmMigrationRecord> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<OrmMigrationRecord>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<OrmMigrationRecord> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<OrmMigrationRecord>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$OrmMigrationRecordCodec extends ModelCodec<$OrmMigrationRecord> {
  const _$OrmMigrationRecordCodec();
  @override
  Map<String, Object?> encode(
    $OrmMigrationRecord model,
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
  $OrmMigrationRecord decode(
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
    final model = $OrmMigrationRecord(
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

/// Insert DTO for [OrmMigrationRecord].
///
/// Auto-increment/DB-generated fields are omitted by default.
class OrmMigrationRecordInsertDto implements InsertDto<$OrmMigrationRecord> {
  const OrmMigrationRecordInsertDto({
    this.id,
    this.checksum,
    this.appliedAt,
    this.batch,
  });
  final String? id;
  final String? checksum;
  final DateTime? appliedAt;
  final int? batch;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (checksum != null) 'checksum': checksum,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (batch != null) 'batch': batch,
    };
  }
}

/// Update DTO for [OrmMigrationRecord].
///
/// All fields are optional; only provided entries are used in SET clauses.
class OrmMigrationRecordUpdateDto implements UpdateDto<$OrmMigrationRecord> {
  const OrmMigrationRecordUpdateDto({
    this.id,
    this.checksum,
    this.appliedAt,
    this.batch,
  });
  final String? id;
  final String? checksum;
  final DateTime? appliedAt;
  final int? batch;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (checksum != null) 'checksum': checksum,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (batch != null) 'batch': batch,
    };
  }
}

/// Partial projection for [OrmMigrationRecord].
///
/// All fields are nullable; intended for subset SELECTs.
class OrmMigrationRecordPartial implements PartialEntity<$OrmMigrationRecord> {
  const OrmMigrationRecordPartial({
    this.id,
    this.checksum,
    this.appliedAt,
    this.batch,
  });

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory OrmMigrationRecordPartial.fromRow(Map<String, Object?> row) {
    return OrmMigrationRecordPartial(
      id: row['id'] as String?,
      checksum: row['checksum'] as String?,
      appliedAt: row['applied_at'] as DateTime?,
      batch: row['batch'] as int?,
    );
  }

  final String? id;
  final String? checksum;
  final DateTime? appliedAt;
  final int? batch;

  @override
  $OrmMigrationRecord toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? idValue = id;
    if (idValue == null) {
      throw StateError('Missing required field: id');
    }
    final String? checksumValue = checksum;
    if (checksumValue == null) {
      throw StateError('Missing required field: checksum');
    }
    final DateTime? appliedAtValue = appliedAt;
    if (appliedAtValue == null) {
      throw StateError('Missing required field: appliedAt');
    }
    final int? batchValue = batch;
    if (batchValue == null) {
      throw StateError('Missing required field: batch');
    }
    return $OrmMigrationRecord(
      id: idValue,
      checksum: checksumValue,
      appliedAt: appliedAtValue,
      batch: batchValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (checksum != null) 'checksum': checksum,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (batch != null) 'batch': batch,
    };
  }
}

/// Generated tracked model class for [OrmMigrationRecord].
///
/// This class extends the user-defined [OrmMigrationRecord] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $OrmMigrationRecord extends OrmMigrationRecord
    with ModelAttributes
    implements OrmEntity {
  $OrmMigrationRecord({
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

  /// Creates a tracked model instance from a user-defined model instance.
  factory $OrmMigrationRecord.fromModel(OrmMigrationRecord model) {
    return $OrmMigrationRecord(
      id: model.id,
      checksum: model.checksum,
      appliedAt: model.appliedAt,
      batch: model.batch,
    );
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
    attachModelDefinition(_$OrmMigrationRecordDefinition);
  }
}

extension OrmMigrationRecordOrmExtension on OrmMigrationRecord {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $OrmMigrationRecord;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $OrmMigrationRecord toTracked() {
    return $OrmMigrationRecord.fromModel(this);
  }
}
