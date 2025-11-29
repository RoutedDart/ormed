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

  // Static Query Helpers
  static Query<OrmMigrationRecord> query({String? connection}) =>
      Model.query<OrmMigrationRecord>(connection: connection);

  static Future<List<OrmMigrationRecord>> all({String? connection}) =>
      Model.all<OrmMigrationRecord>(connection: connection);

  static Future<OrmMigrationRecord?> find(dynamic id, {String? connection}) =>
      Model.find<OrmMigrationRecord>(id, connection: connection);

  static Future<OrmMigrationRecord> findOrFail(
    dynamic id, {
    String? connection,
  }) => Model.findOrFail<OrmMigrationRecord>(id, connection: connection);

  static Future<OrmMigrationRecord?> first({String? connection}) =>
      Model.first<OrmMigrationRecord>(connection: connection);

  static Future<OrmMigrationRecord> firstOrFail({String? connection}) =>
      Model.firstOrFail<OrmMigrationRecord>(connection: connection);

  static Query<OrmMigrationRecord> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<OrmMigrationRecord>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<OrmMigrationRecord> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) =>
      Model.whereIn<OrmMigrationRecord>(column, values, connection: connection);

  static Query<OrmMigrationRecord> orderBy(
    String column, {
    String direction = 'asc',
    String? connection,
  }) => Model.orderBy<OrmMigrationRecord>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<OrmMigrationRecord> limit(int count, {String? connection}) =>
      Model.limit<OrmMigrationRecord>(count, connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<OrmMigrationRecord>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<OrmMigrationRecord>(connection: connection);

  static Future<bool> doesntExist({String? connection}) =>
      Model.doesntExist<OrmMigrationRecord>(connection: connection);

  static Future<OrmMigrationRecord> create(
    Map<String, dynamic> attributes, {
    String? connection,
  }) async {
    final q = query(connection: connection);
    final codec = const _$OrmMigrationRecordModelCodec();
    final model = codec.decode(attributes, q.context.codecRegistry);
    return await model.save();
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, {
    String? connection,
  }) async {
    for (final record in records) {
      await create(record, connection: connection);
    }
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
