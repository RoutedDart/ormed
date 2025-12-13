// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'custom_soft_delete.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CustomSoftDeleteIdField = FieldDefinition(
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

const FieldDefinition _$CustomSoftDeleteTitleField = FieldDefinition(
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

const FieldDefinition _$CustomSoftDeleteDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'removed_on',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<$CustomSoftDelete> _$CustomSoftDeleteDefinition =
    ModelDefinition(
      modelName: 'CustomSoftDelete',
      tableName: 'custom_soft_delete_models',
      fields: const [
        _$CustomSoftDeleteIdField,
        _$CustomSoftDeleteTitleField,
        _$CustomSoftDeleteDeletedAtField,
      ],
      relations: const [],
      softDeleteColumn: 'removed_on',
      metadata: ModelAttributesMetadata(
        hidden: const <String>[],
        visible: const <String>[],
        fillable: const <String>[],
        guarded: const <String>[],
        casts: const <String, String>{},
        softDeletes: true,
        softDeleteColumn: 'removed_on',
      ),
      codec: _$CustomSoftDeleteCodec(),
    );

// ignore: unused_element
final customsoftdeleteModelDefinitionRegistration =
    ModelFactoryRegistry.register<$CustomSoftDelete>(
      _$CustomSoftDeleteDefinition,
    );

extension CustomSoftDeleteOrmDefinition on CustomSoftDelete {
  static ModelDefinition<$CustomSoftDelete> get definition =>
      _$CustomSoftDeleteDefinition;
}

class CustomSoftDeletes {
  const CustomSoftDeletes._();

  static Query<$CustomSoftDelete> query([String? connection]) =>
      Model.query<$CustomSoftDelete>(connection: connection);

  static Future<$CustomSoftDelete?> find(Object id, {String? connection}) =>
      Model.find<$CustomSoftDelete>(id, connection: connection);

  static Future<$CustomSoftDelete> findOrFail(
    Object id, {
    String? connection,
  }) => Model.findOrFail<$CustomSoftDelete>(id, connection: connection);

  static Future<List<$CustomSoftDelete>> all({String? connection}) =>
      Model.all<$CustomSoftDelete>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$CustomSoftDelete>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$CustomSoftDelete>(connection: connection);

  static Query<$CustomSoftDelete> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$CustomSoftDelete>(
    column,
    operator,
    value,
    connection: connection,
  );

  static Query<$CustomSoftDelete> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) =>
      Model.whereIn<$CustomSoftDelete>(column, values, connection: connection);

  static Query<$CustomSoftDelete> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$CustomSoftDelete>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$CustomSoftDelete> limit(int count, {String? connection}) =>
      Model.limit<$CustomSoftDelete>(count, connection: connection);

  static Repository<$CustomSoftDelete> repo([String? connection]) =>
      Model.repository<$CustomSoftDelete>(connection: connection);
}

class CustomSoftDeleteModelFactory {
  const CustomSoftDeleteModelFactory._();

  static ModelDefinition<$CustomSoftDelete> get definition =>
      _$CustomSoftDeleteDefinition;

  static ModelCodec<$CustomSoftDelete> get codec => definition.codec;

  static CustomSoftDelete fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    CustomSoftDelete model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<CustomSoftDelete> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<CustomSoftDelete>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<CustomSoftDelete> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<CustomSoftDelete>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$CustomSoftDeleteCodec extends ModelCodec<$CustomSoftDelete> {
  const _$CustomSoftDeleteCodec();
  @override
  Map<String, Object?> encode(
    $CustomSoftDelete model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$CustomSoftDeleteIdField, model.id),
      'title': registry.encodeField(_$CustomSoftDeleteTitleField, model.title),
      'removed_on': registry.encodeField(
        _$CustomSoftDeleteDeletedAtField,
        (model is ModelAttributes
            ? model.getAttribute<DateTime?>('removed_on')
            : null),
      ),
    };
  }

  @override
  $CustomSoftDelete decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final int customSoftDeleteIdValue =
        registry.decodeField<int>(_$CustomSoftDeleteIdField, data['id']) ??
        (throw StateError('Field id on CustomSoftDelete cannot be null.'));
    final String customSoftDeleteTitleValue =
        registry.decodeField<String>(
          _$CustomSoftDeleteTitleField,
          data['title'],
        ) ??
        (throw StateError('Field title on CustomSoftDelete cannot be null.'));
    final DateTime? customSoftDeleteDeletedAtValue = registry
        .decodeField<DateTime?>(
          _$CustomSoftDeleteDeletedAtField,
          data['removed_on'],
        );
    final model = $CustomSoftDelete(
      id: customSoftDeleteIdValue,
      title: customSoftDeleteTitleValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': customSoftDeleteIdValue,
      'title': customSoftDeleteTitleValue,
      'removed_on': customSoftDeleteDeletedAtValue,
    });
    return model;
  }
}

/// Generated tracked model class for [CustomSoftDelete].
///
/// This class extends the user-defined [CustomSoftDelete] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $CustomSoftDelete extends CustomSoftDelete
    with ModelAttributes, SoftDeletesImpl {
  $CustomSoftDelete({required int id, required String title})
    : super.new(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  /// Creates a tracked model instance from a user-defined model instance.
  factory $CustomSoftDelete.fromModel(CustomSoftDelete model) {
    return $CustomSoftDelete(id: model.id, title: model.title);
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  set title(String value) => setAttribute('title', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CustomSoftDeleteDefinition);
    attachSoftDeleteColumn('removed_on');
  }
}

extension CustomSoftDeleteOrmExtension on CustomSoftDelete {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $CustomSoftDelete;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $CustomSoftDelete toTracked() {
    return $CustomSoftDelete.fromModel(this);
  }
}
