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

final ModelDefinition<$Todo> _$TodoDefinition = ModelDefinition(
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
  codec: _$TodoCodec(),
);

extension TodoOrmDefinition on Todo {
  static ModelDefinition<$Todo> get definition => _$TodoDefinition;
}

class Todos {
  const Todos._();

  static Query<$Todo> query([String? connection]) =>
      Model.query<$Todo>(connection: connection);

  static Future<$Todo?> find(Object id, {String? connection}) =>
      Model.find<$Todo>(id, connection: connection);

  static Future<$Todo> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Todo>(id, connection: connection);

  static Future<List<$Todo>> all({String? connection}) =>
      Model.all<$Todo>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Todo>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Todo>(connection: connection);

  static Query<$Todo> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Todo>(column, operator, value, connection: connection);

  static Query<$Todo> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Todo>(column, values, connection: connection);

  static Query<$Todo> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Todo>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Todo> limit(int count, {String? connection}) =>
      Model.limit<$Todo>(count, connection: connection);

  static Repository<$Todo> repo([String? connection]) =>
      Model.repository<$Todo>(connection: connection);
}

class TodoModelFactory {
  const TodoModelFactory._();

  static ModelDefinition<$Todo> get definition => _$TodoDefinition;

  static ModelCodec<$Todo> get codec => definition.codec;

  static Todo fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Todo model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Todo> withConnection(QueryContext context) =>
      ModelFactoryConnection<Todo>(definition: definition, context: context);

  static ModelFactoryBuilder<Todo> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Todo>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$TodoCodec extends ModelCodec<$Todo> {
  const _$TodoCodec();
  @override
  Map<String, Object?> encode($Todo model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$TodoIdField, model.id),
      'title': registry.encodeField(_$TodoTitleField, model.title),
      'completed': registry.encodeField(_$TodoCompletedField, model.completed),
    };
  }

  @override
  $Todo decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int todoIdValue =
        registry.decodeField<int>(_$TodoIdField, data['id']) ??
        (throw StateError('Field id on Todo cannot be null.'));
    final String todoTitleValue =
        registry.decodeField<String>(_$TodoTitleField, data['title']) ??
        (throw StateError('Field title on Todo cannot be null.'));
    final bool todoCompletedValue =
        registry.decodeField<bool>(_$TodoCompletedField, data['completed']) ??
        (throw StateError('Field completed on Todo cannot be null.'));
    final model = $Todo(
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

/// Generated tracked model class for [Todo].
///
/// This class extends the user-defined [Todo] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Todo extends Todo with ModelAttributes {
  $Todo({required int id, required String title, required bool completed})
    : super.new(id: id, title: title, completed: completed) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'title': title,
      'completed': completed,
    });
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Todo.fromModel(Todo model) {
    return $Todo(id: model.id, title: model.title, completed: model.completed);
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
    attachModelDefinition(_$TodoDefinition);
  }
}

extension TodoOrmExtension on Todo {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Todo;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Todo toTracked() {
    return $Todo.fromModel(this);
  }
}
