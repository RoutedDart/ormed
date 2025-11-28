// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'mutation_target.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$MutationTargetIdField = FieldDefinition(
  name: 'id',
  columnName: '_id',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$MutationTargetCategoryField = FieldDefinition(
  name: 'category',
  columnName: 'category',
  dartType: 'String',
  resolvedType: 'String?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<MutationTarget> _$MutationTargetModelDefinition =
    ModelDefinition(
      modelName: 'MutationTarget',
      tableName: 'mutation_targets',
      fields: const [
        _$MutationTargetIdField,
        _$MutationTargetNameField,
        _$MutationTargetActiveField,
        _$MutationTargetCategoryField,
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
      codec: _$MutationTargetModelCodec(),
    );

// ignore: unused_element
final _MutationTargetModelDefinitionRegistration =
    ModelFactoryRegistry.register<MutationTarget>(
      _$MutationTargetModelDefinition,
    );

extension MutationTargetOrmDefinition on MutationTarget {
  static ModelDefinition<MutationTarget> get definition =>
      _$MutationTargetModelDefinition;
}

class MutationTargetModelFactory {
  const MutationTargetModelFactory._();

  static ModelDefinition<MutationTarget> get definition =>
      MutationTargetOrmDefinition.definition;

  static ModelCodec<MutationTarget> get codec => definition.codec;

  static MutationTarget fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    MutationTarget model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<MutationTarget> withConnection(
    QueryContext context,
  ) => ModelFactoryConnection<MutationTarget>(
    definition: definition,
    context: context,
  );

  static ModelFactoryBuilder<MutationTarget> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<MutationTarget>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

extension MutationTargetModelFactoryExtension on MutationTarget {
  static ModelFactoryBuilder<MutationTarget> factory({
    GeneratorProvider? generatorProvider,
  }) =>
      MutationTargetModelFactory.factory(generatorProvider: generatorProvider);
}

class _$MutationTargetModelCodec extends ModelCodec<MutationTarget> {
  const _$MutationTargetModelCodec();

  @override
  Map<String, Object?> encode(
    MutationTarget model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      '_id': registry.encodeField(_$MutationTargetIdField, model.id),
      'name': registry.encodeField(_$MutationTargetNameField, model.name),
      'active': registry.encodeField(_$MutationTargetActiveField, model.active),
      'category': registry.encodeField(
        _$MutationTargetCategoryField,
        model.category,
      ),
    };
  }

  @override
  MutationTarget decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    final String mutationTargetIdValue =
        registry.decodeField<String>(_$MutationTargetIdField, data['_id']) ??
        (throw StateError('Field id on MutationTarget cannot be null.'));
    final String? mutationTargetNameValue = registry.decodeField<String?>(
      _$MutationTargetNameField,
      data['name'],
    );
    final bool? mutationTargetActiveValue = registry.decodeField<bool?>(
      _$MutationTargetActiveField,
      data['active'],
    );
    final String? mutationTargetCategoryValue = registry.decodeField<String?>(
      _$MutationTargetCategoryField,
      data['category'],
    );
    final model = _$MutationTargetModel(
      id: mutationTargetIdValue,
      name: mutationTargetNameValue,
      active: mutationTargetActiveValue,
      category: mutationTargetCategoryValue,
    );
    model._attachOrmRuntimeMetadata({
      '_id': mutationTargetIdValue,
      'name': mutationTargetNameValue,
      'active': mutationTargetActiveValue,
      'category': mutationTargetCategoryValue,
    });
    return model;
  }
}

class _$MutationTargetModel extends MutationTarget {
  _$MutationTargetModel({
    required String id,
    String? name,
    bool? active,
    String? category,
  }) : super.new(id: id, name: name, active: active, category: category) {
    _attachOrmRuntimeMetadata({
      '_id': id,
      'name': name,
      'active': active,
      'category': category,
    });
  }

  @override
  String get id => getAttribute<String>('_id') ?? super.id;

  set id(String value) => setAttribute('_id', value);

  @override
  String? get name => getAttribute<String?>('name') ?? super.name;

  set name(String? value) => setAttribute('name', value);

  @override
  bool? get active => getAttribute<bool?>('active') ?? super.active;

  set active(bool? value) => setAttribute('active', value);

  @override
  String? get category => getAttribute<String?>('category') ?? super.category;

  set category(String? value) => setAttribute('category', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$MutationTargetModelDefinition);
  }
}

extension MutationTargetAttributeSetters on MutationTarget {
  set id(String value) => setAttribute('_id', value);
  set name(String? value) => setAttribute('name', value);
  set active(bool? value) => setAttribute('active', value);
  set category(String? value) => setAttribute('category', value);
}
