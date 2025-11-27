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

final ModelDefinition<CustomSoftDelete> _$CustomSoftDeleteModelDefinition =
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
      codec: _$CustomSoftDeleteModelCodec(),
    );

extension CustomSoftDeleteOrmDefinition on CustomSoftDelete {
  static ModelDefinition<CustomSoftDelete> get definition =>
      _$CustomSoftDeleteModelDefinition;
}

class _$CustomSoftDeleteModelCodec extends ModelCodec<CustomSoftDelete> {
  const _$CustomSoftDeleteModelCodec();

  @override
  Map<String, Object?> encode(
    CustomSoftDelete model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': registry.encodeField(_$CustomSoftDeleteIdField, model.id),
      'title': registry.encodeField(_$CustomSoftDeleteTitleField, model.title),
      'removed_on': registry.encodeField(
        _$CustomSoftDeleteDeletedAtField,
        model.getAttribute<DateTime?>('removed_on'),
      ),
    };
  }

  @override
  CustomSoftDelete decode(
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
    final model = _$CustomSoftDeleteModel(
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

class _$CustomSoftDeleteModel extends CustomSoftDelete {
  _$CustomSoftDeleteModel({required int id, required String title})
    : super(id: id, title: title) {
    _attachOrmRuntimeMetadata({'id': id, 'title': title});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get title => getAttribute<String>('title') ?? super.title;

  set title(String value) => setAttribute('title', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CustomSoftDeleteModelDefinition);
    attachSoftDeleteColumn('removed_on');
  }
}
