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

extension PhotoOrmDefinition on Photo {
  static ModelDefinition<Photo> get definition => _$PhotoModelDefinition;

  // Static Query Helpers
  static Query<Photo> query({String? connection}) =>
      Model.query<Photo>(connection: connection);

  static Future<List<Photo>> all({String? connection}) =>
      Model.all<Photo>(connection: connection);

  static Future<Photo?> find(dynamic id, {String? connection}) =>
      Model.find<Photo>(id, connection: connection);

  static Future<Photo> findOrFail(dynamic id, {String? connection}) =>
      Model.findOrFail<Photo>(id, connection: connection);

  static Future<Photo?> first({String? connection}) =>
      Model.first<Photo>(connection: connection);

  static Future<Photo> firstOrFail({String? connection}) =>
      Model.firstOrFail<Photo>(connection: connection);

  static Query<Photo> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<Photo>(column, operator, value, connection: connection);

  static Query<Photo> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<Photo>(column, values, connection: connection);

  static Query<Photo> orderBy(
    String column, {
    String direction = 'asc',
    String? connection,
  }) => Model.orderBy<Photo>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Photo> limit(int count, {String? connection}) =>
      Model.limit<Photo>(count, connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<Photo>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<Photo>(connection: connection);

  static Future<bool> doesntExist({String? connection}) =>
      Model.doesntExist<Photo>(connection: connection);
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

class _$PhotoModel extends Photo
    with ModelAttributes, ModelConnection, ModelRelations {
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

  @override
  int get imageableId => getAttribute<int>('imageable_id') ?? super.imageableId;

  @override
  String get imageableType =>
      getAttribute<String>('imageable_type') ?? super.imageableType;

  @override
  String get path => getAttribute<String>('path') ?? super.path;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$PhotoModelDefinition);
  }
}
