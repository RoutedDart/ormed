// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'todo.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$TodoIdField = FieldDefinition(
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

const FieldDefinition _$TodoTitleField = FieldDefinition(
  name: 'title',
  columnName: 'title',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$TodoCompletedField = FieldDefinition(
  name: 'completed',
  columnName: 'completed',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Todo> _$TodoModelDefinition = ModelDefinition(
  modelName: 'Todo',
  tableName: 'todos',
  fields: const [_$TodoIdField, _$TodoTitleField, _$TodoCompletedField],
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
  codec: _$TodoModelCodec(),
);

extension TodoOrmDefinition on Todo {
  static ModelDefinition<Todo> get definition => _$TodoModelDefinition;

  // Static Query Helpers
  static Query<Todo> query({String? connection}) =>
      Model.query<Todo>(connection: connection);

  static Future<List<Todo>> all({String? connection}) =>
      Model.all<Todo>(connection: connection);

  static Future<Todo?> find(dynamic id, {String? connection}) =>
      Model.find<Todo>(id, connection: connection);

  static Future<Todo> findOrFail(dynamic id, {String? connection}) =>
      Model.findOrFail<Todo>(id, connection: connection);

  static Future<Todo?> first({String? connection}) =>
      Model.first<Todo>(connection: connection);

  static Future<Todo> firstOrFail({String? connection}) =>
      Model.firstOrFail<Todo>(connection: connection);

  static Query<Todo> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<Todo>(column, operator, value, connection: connection);

  static Query<Todo> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<Todo>(column, values, connection: connection);

  static Query<Todo> orderBy(
    String column, {
    String direction = 'asc',
    String? connection,
  }) =>
      Model.orderBy<Todo>(column, direction: direction, connection: connection);

  static Query<Todo> limit(int count, {String? connection}) =>
      Model.limit<Todo>(count, connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<Todo>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<Todo>(connection: connection);

  static Future<bool> doesntExist({String? connection}) =>
      Model.doesntExist<Todo>(connection: connection);

  static Future<Todo> create(
    Map<String, dynamic> attributes, {
    String? connection,
  }) async {
    final q = query(connection: connection);
    final codec = const _$TodoModelCodec();
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

class _$TodoModelCodec extends ModelCodec<Todo> {
  const _$TodoModelCodec();

  @override
  Map<String, Object?> encode(Todo model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$TodoIdField, model.id),
      'title': registry.encodeField(_$TodoTitleField, model.title),
      'completed': registry.encodeField(_$TodoCompletedField, model.completed),
    };
  }

  @override
  Todo decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int todoIdValue =
        registry.decodeField<int>(_$TodoIdField, data['id']) ??
        (throw StateError('Field id on Todo cannot be null.'));
    final String todoTitleValue =
        registry.decodeField<String>(_$TodoTitleField, data['title']) ??
        (throw StateError('Field title on Todo cannot be null.'));
    final bool todoCompletedValue =
        registry.decodeField<bool>(_$TodoCompletedField, data['completed']) ??
        (throw StateError('Field completed on Todo cannot be null.'));
    final model = _$TodoModel(
      id: todoIdValue,
      title: todoTitleValue,
      completed: todoCompletedValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': todoIdValue,
      'title': todoTitleValue,
      'completed': todoCompletedValue,
    });
    return model;
  }
}

class _$TodoModel extends Todo {
  _$TodoModel({required int id, required String title, bool completed = false})
    : super.new(id: id, title: title, completed: completed) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'title': title,
      'completed': completed,
    });
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  set title(String value) => setAttribute('title', value);

  @override
  bool get completed => getAttribute<bool>('completed') ?? super.completed;

  set completed(bool value) => setAttribute('completed', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$TodoModelDefinition);
  }
}

extension TodoAttributeSetters on Todo {
  set id(int value) => setAttribute('id', value);
  set title(String value) => setAttribute('title', value);
  set completed(bool value) => setAttribute('completed', value);
}
