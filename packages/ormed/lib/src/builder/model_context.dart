import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:ormed/src/annotations.dart';
import 'package:ormed/src/model_definition.dart';
import 'package:ormed/src/model_mixins/soft_deletes.dart';

import 'descriptors.dart';
import 'helpers.dart';

final _modelChecker = TypeChecker.fromUrl('package:ormed/src/model.dart#Model');

class ModelContext {
  ModelContext(this.element, this.annotation)
    : className = element.displayName,
      tableName = annotation.peek('table')?.stringValue,
      schema = annotation.peek('schema')?.stringValue,
      generateCodec = annotation.peek('generateCodec')?.boolValue ?? true,
      mixinSoftDeletes = element.mixins.any(isSoftDeletesMixin),
      mixinModelAttributes = classOrSuperHasMixin(
        element,
        isModelAttributesMixin,
      ),
      mixinModelConnection = classOrSuperHasMixin(
        element,
        isModelConnectionMixin,
      ),
      mixinModelFactory = classOrSuperHasMixin(element, isModelFactoryMixin),
      extendsModel = _modelChecker.isAssignableFromType(element.thisType),
      annotationSoftDeletesFlag =
          annotation.peek('softDeletes')?.boolValue ?? false,
      annotationSoftDeleteColumnOverride = annotation
          .peek('softDeletesColumn')
          ?.stringValue,
      hiddenAnnotation = readStringList(annotation.peek('hidden')),
      visibleAnnotation = readStringList(annotation.peek('visible')),
      fillableAnnotation = readStringList(annotation.peek('fillable')),
      guardedAnnotation = readStringList(annotation.peek('guarded')),
      castsAnnotation = readStringMap(annotation.peek('casts')),
      driverAnnotations = readStringList(annotation.peek('driverAnnotations')),
      annotationPrimaryKeys = readStringList(annotation.peek('primaryKey')),
      connectionAnnotation = annotation.peek('connection')?.stringValue,
      constructorOverride = normalizeConstructorOverride(annotation) {
    if (tableName == null || tableName!.isEmpty) {
      throw InvalidGenerationSourceError(
        '@OrmModel requires a non-empty table name.',
        element: element,
      );
    }

    fields = _collectFields();
    _applyAnnotationPrimaryKeys(fields);
    if (fields.isEmpty) {
      throw InvalidGenerationSourceError(
        'No fields detected for $className. Add final fields to generate metadata.',
        element: element,
      );
    }

    relations = _collectRelations();
    scopes =
        []; // _collectScopes(); // TODO: Re-enable scopes after fixing ParameterElement type issue

    final softDeleteFields = fields
        .where((field) => field.isSoftDelete)
        .toList();
    if (softDeleteFields.length > 1) {
      throw InvalidGenerationSourceError(
        'Only one field can be annotated with @OrmSoftDelete for $className.',
        element: element,
      );
    }

    final effectiveSoftDeletes = annotationSoftDeletesFlag || mixinSoftDeletes;
    var softDeleteColumn = softDeleteFields.isEmpty
        ? null
        : (softDeleteFields.single.softDeleteColumnName ??
              softDeleteFields.single.columnName);
    softDeleteColumn ??= annotationSoftDeleteColumnOverride;
    if (softDeleteColumn == null && effectiveSoftDeletes) {
      softDeleteColumn = SoftDeletes.defaultColumn;
    }

    this.softDeleteColumn = softDeleteColumn;
    this.effectiveSoftDeletes = effectiveSoftDeletes;

    _markPrimaryKeyFallback(fields);
    constructor = _resolveConstructor();
  }

  final ConstantReader annotation;
  final ClassElement element;
  final String className;
  final String? tableName;
  final String? schema;
  final bool generateCodec;
  final bool mixinSoftDeletes;
  final bool mixinModelAttributes;
  final bool mixinModelConnection;
  final bool mixinModelFactory;
  final bool extendsModel;
  final bool annotationSoftDeletesFlag;
  final String? annotationSoftDeleteColumnOverride;
  final List<String> hiddenAnnotation;
  final List<String> visibleAnnotation;
  final List<String> fillableAnnotation;
  final List<String> guardedAnnotation;
  final List<String> driverAnnotations;
  final List<String> annotationPrimaryKeys;
  final Map<String, String> castsAnnotation;
  final String? connectionAnnotation;
  final String? constructorOverride;

  late final List<FieldDescriptor> fields;
  late final List<RelationDescriptor> relations;
  late final List<ScopeDescriptor> scopes;
  late final String? softDeleteColumn;
  late final bool effectiveSoftDeletes;
  late final ConstructorElement constructor;

  ConstructorElement _resolveConstructor() {
    final constructorName = constructorOverride;

    if (constructorName != null && constructorName.isNotEmpty) {
      // Look for named constructor
      final namedConstructor = element.constructors.firstWhereOrNull(
        (c) => c.name == constructorName,
      );
      if (namedConstructor == null) {
        throw InvalidGenerationSourceError(
          'Constructor "$constructorName" not found on ${element.name}',
          element: element,
        );
      }
      return namedConstructor;
    }

    // Default behavior: use first generative (non-factory) constructor
    final ctor = element.constructors.firstWhereOrNull(
      (constructor) => !constructor.isFactory,
    );
    if (ctor == null) {
      throw InvalidGenerationSourceError(
        'A generative constructor is required for $className.',
        element: element,
      );
    }
    return ctor;
  }

  List<FieldDescriptor> _collectFields() {
    final descriptors = <FieldDescriptor>[];
    final seen = <String>{};

    void collectFrom(InterfaceElement source) {
      for (final field in source.fields) {
        if (field.isStatic || field.isSynthetic || field.isPrivate) {
          continue;
        }
        if (!field.isFinal) {
          throw InvalidGenerationSourceError(
            'Fields must be final for $className.',
            element: field,
          );
        }
        if (!seen.add(field.displayName)) {
          continue;
        }
        final descriptor = _buildFieldDescriptor(field);
        if (descriptor != null) {
          descriptors.add(descriptor);
        }
      }
      if (source is ClassElement) {
        for (final mixinType in source.mixins) {
          collectFrom(mixinType.element);
        }
        final supertype = source.supertype;
        if (supertype != null && supertype.element.name != 'Object') {
          collectFrom(supertype.element);
        }
      }
    }

    collectFrom(element);

    final requiresSoftDeletes = mixinSoftDeletes || annotationSoftDeletesFlag;
    if (requiresSoftDeletes &&
        !descriptors.any((descriptor) => descriptor.isSoftDelete)) {
      descriptors.add(
        FieldDescriptor(
          owner: className,
          name: 'deletedAt',
          columnName:
              annotationSoftDeleteColumnOverride ?? SoftDeletes.defaultColumn,
          dartType: 'DateTime',
          resolvedType: 'DateTime?',
          isPrimaryKey: false,
          isNullable: true,
          isUnique: false,
          isIndexed: false,
          autoIncrement: false,
          columnType: null,
          defaultValueSql: null,
          codecType: null,
          isSoftDelete: true,
          isVirtual: true,
          softDeleteColumnName:
              annotationSoftDeleteColumnOverride ?? SoftDeletes.defaultColumn,
        ),
      );
    }

    return descriptors;
  }

  FieldDescriptor? _buildFieldDescriptor(FieldElement field) {
    final reader = readAnnotation(field, 'OrmField');
    if (reader?.peek('ignore')?.boolValue ?? false) {
      return null;
    }
    final typeWithNullability = field.type.getDisplayString();
    final type = field.type.nullabilitySuffix == NullabilitySuffix.question
        ? typeWithNullability.substring(0, typeWithNullability.length - 1)
        : typeWithNullability;
    final resolvedType = typeWithNullability;
    final fieldName = field.displayName;
    final nullableOverride = reader?.peek('isNullable');
    final codecType = reader?.peek('codec')?.typeValue;
    final softDeleteReader = readAnnotation(field, 'OrmSoftDelete');
    final softDeleteColumnOverride = softDeleteReader
        ?.peek('columnName')
        ?.stringValue;
    var columnName = reader?.peek('columnName')?.stringValue ?? fieldName;
    var effectiveNullable = nullableOverride == null || nullableOverride.isNull
        ? field.type.nullabilitySuffix == NullabilitySuffix.question
        : nullableOverride.boolValue;

    final softDeleteViaMixin =
        mixinSoftDeletes &&
        softDeleteReader == null &&
        fieldName == 'deletedAt';
    if (softDeleteViaMixin) {
      columnName =
          annotationSoftDeleteColumnOverride ?? SoftDeletes.defaultColumn;
      effectiveNullable = true;
    }

    final driverOverrides = _readDriverOverrides(
      reader?.peek('driverOverrides'),
      field,
    );
    final attributeMetadata = _fieldAttributeMetadata(reader);

    return FieldDescriptor(
      owner: className,
      name: fieldName,
      columnName: columnName,
      dartType: type,
      resolvedType: resolvedType,
      isPrimaryKey: reader?.peek('isPrimaryKey')?.boolValue ?? false,
      isNullable: effectiveNullable,
      isUnique: reader?.peek('isUnique')?.boolValue ?? false,
      isIndexed: reader?.peek('isIndexed')?.boolValue ?? false,
      autoIncrement: reader?.peek('autoIncrement')?.boolValue ?? false,
      columnType: reader?.peek('columnType')?.stringValue,
      defaultValueSql: reader?.peek('defaultValueSql')?.stringValue,
      codecType: maybeTypeName(codecType),
      isSoftDelete: softDeleteReader != null || softDeleteViaMixin,
      softDeleteColumnName:
          softDeleteColumnOverride ??
          (softDeleteViaMixin
              ? columnName
              : reader?.peek('columnName')?.stringValue),
      driverOverrides: driverOverrides,
      attributeMetadata: attributeMetadata,
    );
  }

  FieldAttributeMetadata? _fieldAttributeMetadata(ConstantReader? reader) {
    if (reader == null) return null;
    final fillable = reader.peek('fillable');
    final guarded = reader.peek('guarded');
    final hidden = reader.peek('hidden');
    final visible = reader.peek('visible');
    final cast = reader.peek('cast');
    if ((fillable == null || fillable.isNull) &&
        (guarded == null || guarded.isNull) &&
        (hidden == null || hidden.isNull) &&
        (visible == null || visible.isNull) &&
        (cast == null || cast.isNull)) {
      return null;
    }
    return FieldAttributeMetadata(
      fillable: fillable?.boolValue,
      guarded: guarded?.boolValue,
      hidden: hidden?.boolValue,
      visible: visible?.boolValue,
      cast: cast?.stringValue,
    );
  }

  List<RelationDescriptor> _collectRelations() {
    final relations = <RelationDescriptor>[];
    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic || field.isPrivate) {
        continue;
      }
      final annotation = readAnnotation(field, 'OrmRelation');
      if (annotation == null) {
        continue;
      }
      relations.add(
        RelationDescriptor(
          owner: className,
          name: field.displayName,
          fieldType: field.type,
          kind: _readRelationKind(annotation.peek('kind')?.objectValue),
          targetModel: typeOrDynamic(annotation.peek('target')?.typeValue),
          foreignKey: annotation.peek('foreignKey')?.stringValue,
          localKey: annotation.peek('localKey')?.stringValue,
          through: annotation.peek('through')?.stringValue,
          pivotForeignKey: annotation.peek('pivotForeignKey')?.stringValue,
          pivotRelatedKey: annotation.peek('pivotRelatedKey')?.stringValue,
          morphType: annotation.peek('morphType')?.stringValue,
          morphClass: annotation.peek('morphClass')?.stringValue,
        ),
      );
    }
    return relations;
  }

  List<ScopeDescriptor> _collectScopes() {
    final scopes = <ScopeDescriptor>[];
    for (final method in element.methods) {
      if (!method.isStatic) continue;
      final annotation = readAnnotation(method, 'OrmScope');
      if (annotation == null) continue;

      scopes.add(
        ScopeDescriptor(
          name: method.name!,
          parameters: (method as dynamic).parameters,
        ),
      );
    }
    return scopes;
  }

  RelationKind _readRelationKind(DartObject? object) {
    if (object == null) {
      return RelationKind.hasOne;
    }
    final index = object.getField('index')?.toIntValue();
    return RelationKind.values[index ?? 0];
  }

  void _applyAnnotationPrimaryKeys(List<FieldDescriptor> fields) {
    if (annotationPrimaryKeys.isEmpty) {
      return;
    }
    final normalized = annotationPrimaryKeys
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) {
      return;
    }
    for (final field in fields) {
      if (normalized.contains(field.columnName) ||
          normalized.contains(field.name)) {
        field.isPrimaryKey = true;
      }
    }
  }

  void _markPrimaryKeyFallback(List<FieldDescriptor> fields) {
    if (fields.any((field) => field.isPrimaryKey && !field.isVirtual)) {
      return;
    }
    final fallback = fields.firstWhereOrNull(
      (field) => !field.isVirtual && field.name == 'id',
    );
    if (fallback == null) {
      throw InvalidGenerationSourceError(
        'At least one field must be marked as primary key for $className.',
        element: element,
      );
    }
    fallback.isPrimaryKey = true;
  }

  Map<String, DriverFieldOverrideDescriptor> _readDriverOverrides(
    ConstantReader? reader,
    FieldElement field,
  ) {
    if (reader == null || reader.isNull) return const {};
    final overrides = <String, DriverFieldOverrideDescriptor>{};
    reader.mapValue.forEach((rawKey, rawValue) {
      final driver = rawKey?.toStringValue()?.trim();
      if (driver == null || driver.isEmpty) {
        throw InvalidGenerationSourceError(
          'driverOverrides keys must be non-empty strings.',
          element: field,
        );
      }
      final normalized = driver.toLowerCase();
      final overrideReader = ConstantReader(rawValue);
      overrides[normalized] = DriverFieldOverrideDescriptor(
        columnType: overrideReader.peek('columnType')?.stringValue,
        defaultValueSql: overrideReader.peek('defaultValueSql')?.stringValue,
        codecType: maybeTypeName(overrideReader.peek('codec')?.typeValue),
      );
    });
    return Map.unmodifiable(overrides);
  }
}
