// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'article.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ArticleIdField = FieldDefinition(
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

const FieldDefinition _$ArticleTitleField = FieldDefinition(
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

const FieldDefinition _$ArticleBodyField = FieldDefinition(
  name: 'body',
  columnName: 'body',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticleStatusField = FieldDefinition(
  name: 'status',
  columnName: 'status',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticleRatingField = FieldDefinition(
  name: 'rating',
  columnName: 'rating',
  dartType: 'double',
  resolvedType: 'double',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticlePriorityField = FieldDefinition(
  name: 'priority',
  columnName: 'priority',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticlePublishedAtField = FieldDefinition(
  name: 'publishedAt',
  columnName: 'published_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticleReviewedAtField = FieldDefinition(
  name: 'reviewedAt',
  columnName: 'reviewed_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$ArticleCategoryIdField = FieldDefinition(
  name: 'categoryId',
  columnName: 'category_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Article> _$ArticleModelDefinition = ModelDefinition(
  modelName: 'Article',
  tableName: 'articles',
  fields: const [
    _$ArticleIdField,
    _$ArticleTitleField,
    _$ArticleBodyField,
    _$ArticleStatusField,
    _$ArticleRatingField,
    _$ArticlePriorityField,
    _$ArticlePublishedAtField,
    _$ArticleReviewedAtField,
    _$ArticleCategoryIdField,
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
  codec: _$ArticleModelCodec(),
);

// ignore: unused_element
final articleModelDefinitionRegistration =
    ModelFactoryRegistry.register<Article>(_$ArticleModelDefinition);

extension ArticleOrmDefinition on Article {
  static ModelDefinition<Article> get definition => _$ArticleModelDefinition;
}

class ArticleModelFactory {
  const ArticleModelFactory._();

  static ModelDefinition<Article> get definition =>
      ArticleOrmDefinition.definition;

  static ModelCodec<Article> get codec => definition.codec;

  static Article fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Article model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Article> withConnection(QueryContext context) =>
      ModelFactoryConnection<Article>(definition: definition, context: context);

  static Query<Article> query([String? connection]) {
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    return conn.query<Article>();
  }

  static ModelFactoryBuilder<Article> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Article>(
    definition: definition,
    generatorProvider: generatorProvider,
  );

  static Future<List<Article>> all([String? connection]) =>
      query(connection).get();

  static Future<Article> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) async {
    final model = const _$ArticleModelCodec().decode(
      attributes,
      ValueCodecRegistry.standard(),
    );
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Article>();
    final result = await repo.insertMany([model], returning: true);
    return result.first;
  }

  static Future<List<Article>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$ArticleModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Article>();
    return await repo.insertMany(models, returning: true);
  }

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) async {
    final models = records
        .map(
          (r) => const _$ArticleModelCodec().decode(
            r,
            ValueCodecRegistry.standard(),
          ),
        )
        .toList();
    final connName = connection ?? definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Article>();
    await repo.insertMany(models, returning: false);
  }

  static Future<Article?> find(Object id, [String? connection]) =>
      query(connection).find(id);

  static Future<Article> findOrFail(Object id, [String? connection]) async {
    final result = await find(id, connection);
    if (result == null) throw StateError("Model not found with id: $id");
    return result;
  }

  static Future<List<Article>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => query(connection).findMany(ids);

  static Future<Article?> first([String? connection]) =>
      query(connection).first();

  static Future<Article> firstOrFail([String? connection]) async {
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

  static Query<Article> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => query(connection).where(column, value);

  static Query<Article> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => query(connection).whereIn(column, values);

  static Query<Article> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => query(
    connection,
  ).orderBy(column, descending: direction.toLowerCase() == "desc");

  static Query<Article> limit(int count, [String? connection]) =>
      query(connection).limit(count);
}

extension ArticleModelHelpers on Article {
  // Factory
  static ModelFactoryBuilder<Article> factory({
    GeneratorProvider? generatorProvider,
  }) => ArticleModelFactory.factory(generatorProvider: generatorProvider);

  // Query builder
  static Query<Article> query([String? connection]) =>
      ArticleModelFactory.query(connection);

  // CRUD operations
  static Future<List<Article>> all([String? connection]) =>
      ArticleModelFactory.all(connection);

  static Future<Article?> find(Object id, [String? connection]) =>
      ArticleModelFactory.find(id, connection);

  static Future<Article> findOrFail(Object id, [String? connection]) =>
      ArticleModelFactory.findOrFail(id, connection);

  static Future<List<Article>> findMany(
    List<Object> ids, [
    String? connection,
  ]) => ArticleModelFactory.findMany(ids, connection);

  static Future<Article?> first([String? connection]) =>
      ArticleModelFactory.first(connection);

  static Future<Article> firstOrFail([String? connection]) =>
      ArticleModelFactory.firstOrFail(connection);

  static Future<Article> create(
    Map<String, dynamic> attributes, [
    String? connection,
  ]) => ArticleModelFactory.create(attributes, connection);

  static Future<List<Article>> createMany(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => ArticleModelFactory.createMany(records, connection);

  static Future<void> insert(
    List<Map<String, dynamic>> records, [
    String? connection,
  ]) => ArticleModelFactory.insert(records, connection);

  static Future<int> destroy(List<Object> ids, [String? connection]) =>
      ArticleModelFactory.destroy(ids, connection);

  static Future<int> count([String? connection]) =>
      ArticleModelFactory.count(connection);

  static Future<bool> exists([String? connection]) =>
      ArticleModelFactory.exists(connection);

  static Query<Article> where(
    String column,
    dynamic value, [
    String? connection,
  ]) => ArticleModelFactory.where(column, value, connection);

  static Query<Article> whereIn(
    String column,
    List<dynamic> values, [
    String? connection,
  ]) => ArticleModelFactory.whereIn(column, values, connection);

  static Query<Article> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => ArticleModelFactory.orderBy(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Article> limit(int count, [String? connection]) =>
      ArticleModelFactory.limit(count, connection);

  // Instance method
  Future<void> delete([String? connection]) async {
    final connName =
        connection ?? ArticleModelFactory.definition.metadata.connection;
    final conn = ConnectionManager.instance.connection(
      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",
    );
    final repo = conn.context.repository<Article>();
    final primaryKeys = ArticleModelFactory.definition.fields
        .where((f) => f.isPrimaryKey)
        .toList();
    if (primaryKeys.isEmpty) {
      throw StateError("Cannot delete model without primary key");
    }
    final keyMap = <String, Object?>{
      for (final key in primaryKeys)
        key.columnName: ArticleModelFactory.toMap(this)[key.name],
    };
    await repo.deleteByKeys([keyMap]);
  }
}

class _$ArticleModelCodec extends ModelCodec<Article> {
  const _$ArticleModelCodec();

  @override
  Map<String, Object?> encode(Article model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ArticleIdField, model.id),
      'title': registry.encodeField(_$ArticleTitleField, model.title),
      'body': registry.encodeField(_$ArticleBodyField, model.body),
      'status': registry.encodeField(_$ArticleStatusField, model.status),
      'rating': registry.encodeField(_$ArticleRatingField, model.rating),
      'priority': registry.encodeField(_$ArticlePriorityField, model.priority),
      'published_at': registry.encodeField(
        _$ArticlePublishedAtField,
        model.publishedAt,
      ),
      'reviewed_at': registry.encodeField(
        _$ArticleReviewedAtField,
        model.reviewedAt,
      ),
      'category_id': registry.encodeField(
        _$ArticleCategoryIdField,
        model.categoryId,
      ),
    };
  }

  @override
  Article decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int articleIdValue =
        registry.decodeField<int>(_$ArticleIdField, data['id']) ??
        (throw StateError('Field id on Article cannot be null.'));
    final String articleTitleValue =
        registry.decodeField<String>(_$ArticleTitleField, data['title']) ??
        (throw StateError('Field title on Article cannot be null.'));
    final String? articleBodyValue = registry.decodeField<String?>(
      _$ArticleBodyField,
      data['body'],
    );
    final String articleStatusValue =
        registry.decodeField<String>(_$ArticleStatusField, data['status']) ??
        (throw StateError('Field status on Article cannot be null.'));
    final double articleRatingValue =
        registry.decodeField<double>(_$ArticleRatingField, data['rating']) ??
        (throw StateError('Field rating on Article cannot be null.'));
    final int articlePriorityValue =
        registry.decodeField<int>(_$ArticlePriorityField, data['priority']) ??
        (throw StateError('Field priority on Article cannot be null.'));
    final DateTime articlePublishedAtValue =
        registry.decodeField<DateTime>(
          _$ArticlePublishedAtField,
          data['published_at'],
        ) ??
        (throw StateError('Field publishedAt on Article cannot be null.'));
    final DateTime? articleReviewedAtValue = registry.decodeField<DateTime?>(
      _$ArticleReviewedAtField,
      data['reviewed_at'],
    );
    final int articleCategoryIdValue =
        registry.decodeField<int>(
          _$ArticleCategoryIdField,
          data['category_id'],
        ) ??
        (throw StateError('Field categoryId on Article cannot be null.'));
    final model = _$ArticleModel(
      id: articleIdValue,
      title: articleTitleValue,
      body: articleBodyValue,
      status: articleStatusValue,
      rating: articleRatingValue,
      priority: articlePriorityValue,
      publishedAt: articlePublishedAtValue,
      reviewedAt: articleReviewedAtValue,
      categoryId: articleCategoryIdValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': articleIdValue,
      'title': articleTitleValue,
      'body': articleBodyValue,
      'status': articleStatusValue,
      'rating': articleRatingValue,
      'priority': articlePriorityValue,
      'published_at': articlePublishedAtValue,
      'reviewed_at': articleReviewedAtValue,
      'category_id': articleCategoryIdValue,
    });
    return model;
  }
}

class _$ArticleModel extends Article {
  _$ArticleModel({
    required int id,
    required String title,
    String? body,
    required String status,
    required double rating,
    required int priority,
    required DateTime publishedAt,
    DateTime? reviewedAt,
    required int categoryId,
  }) : super.new(
         id: id,
         title: title,
         body: body,
         status: status,
         rating: rating,
         priority: priority,
         publishedAt: publishedAt,
         reviewedAt: reviewedAt,
         categoryId: categoryId,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'title': title,
      'body': body,
      'status': status,
      'rating': rating,
      'priority': priority,
      'published_at': publishedAt,
      'reviewed_at': reviewedAt,
      'category_id': categoryId,
    });
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  set title(String value) => setAttribute('title', value);

  @override
  String? get body => getAttribute<String?>('body') ?? super.body;

  set body(String? value) => setAttribute('body', value);

  @override
  String get status => getAttribute<String>('status') ?? super.status;

  set status(String value) => setAttribute('status', value);

  @override
  double get rating => getAttribute<double>('rating') ?? super.rating;

  set rating(double value) => setAttribute('rating', value);

  @override
  int get priority => getAttribute<int>('priority') ?? super.priority;

  set priority(int value) => setAttribute('priority', value);

  @override
  DateTime get publishedAt =>
      getAttribute<DateTime>('published_at') ?? super.publishedAt;

  set publishedAt(DateTime value) => setAttribute('published_at', value);

  @override
  DateTime? get reviewedAt =>
      getAttribute<DateTime?>('reviewed_at') ?? super.reviewedAt;

  set reviewedAt(DateTime? value) => setAttribute('reviewed_at', value);

  @override
  int get categoryId => getAttribute<int>('category_id') ?? super.categoryId;

  set categoryId(int value) => setAttribute('category_id', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ArticleModelDefinition);
  }
}

extension ArticleAttributeSetters on Article {
  set id(int value) => setAttribute('id', value);
  set title(String value) => setAttribute('title', value);
  set body(String? value) => setAttribute('body', value);
  set status(String value) => setAttribute('status', value);
  set rating(double value) => setAttribute('rating', value);
  set priority(int value) => setAttribute('priority', value);
  set publishedAt(DateTime value) => setAttribute('published_at', value);
  set reviewedAt(DateTime? value) => setAttribute('reviewed_at', value);
  set categoryId(int value) => setAttribute('category_id', value);
}
