import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../../ormed.dart';

final _modelChecker = TypeChecker.fromUrl('package:ormed/src/model.dart#Model');

class OrmModelGenerator extends GeneratorForAnnotation<OrmModel> {
  OrmModelGenerator(this.options);

  final BuilderOptions options;

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@OrmModel can only target classes.',
        element: element,
      );
    }

    final emitter = _ModelEmitter(element, annotation);
    return emitter.emit(buildStep);
  }
}

class _ModelEmitter {
  _ModelEmitter(this.element, ConstantReader annotation)
    : annotation = annotation,
      className = element.displayName,
      tableName = annotation.peek('table')?.stringValue,
      schema = annotation.peek('schema')?.stringValue,
      generateCodec = annotation.peek('generateCodec')?.boolValue ?? true,
      mixinSoftDeletes = element.mixins.any(_isSoftDeletesMixin),
      mixinModelAttributes = _classOrSuperHasMixin(
        element,
        _isModelAttributesMixin,
      ),
      mixinModelConnection = _classOrSuperHasMixin(
        element,
        _isModelConnectionMixin,
      ),
      mixinModelFactory = _classOrSuperHasMixin(element, _isModelFactoryMixin),
      extendsModel = _modelChecker.isAssignableFromType(element.thisType),
      annotationSoftDeletesFlag =
          annotation.peek('softDeletes')?.boolValue ?? false,
      annotationSoftDeleteColumnOverride = annotation
          .peek('softDeletesColumn')
          ?.stringValue,
      hiddenAnnotation = _readStringList(annotation.peek('hidden')),
      visibleAnnotation = _readStringList(annotation.peek('visible')),
      fillableAnnotation = _readStringList(annotation.peek('fillable')),
      guardedAnnotation = _readStringList(annotation.peek('guarded')),
      castsAnnotation = _readStringMap(annotation.peek('casts')),
      driverAnnotations = _readStringList(annotation.peek('driverAnnotations')),
      annotationPrimaryKeys = _readStringList(annotation.peek('primaryKey')),
      connectionAnnotation = annotation.peek('connection')?.stringValue,
      constructorOverride = _normalizeConstructorOverride(annotation) {
    if (tableName == null || tableName!.isEmpty) {
      throw InvalidGenerationSourceError(
        '@OrmModel requires a non-empty table name.',
        element: element,
      );
    }
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

  Future<String> emit(BuildStep buildStep) async {
    final fields = _collectFields();
    _applyAnnotationPrimaryKeys(fields);
    if (fields.isEmpty) {
      throw InvalidGenerationSourceError(
        'No fields detected for $className. Add final fields to generate metadata.',
        element: element,
      );
    }

    final relations = _collectRelations();
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
    _markPrimaryKeyFallback(fields);

    final constructor = _resolveConstructor();
    final buffer = StringBuffer();

    for (final field in fields) {
      buffer.writeln(
        'const FieldDefinition ${field.identifier} = FieldDefinition(',
      );
      buffer.writeln("  name: '${_escape(field.name)}',");
      buffer.writeln("  columnName: '${_escape(field.columnName)}',");
      buffer.writeln("  dartType: '${field.dartType}',");
      buffer.writeln("  resolvedType: '${field.resolvedType}',");
      buffer.writeln('  isPrimaryKey: ${field.isPrimaryKey},');
      buffer.writeln('  isNullable: ${field.isNullable},');
      buffer.writeln('  isUnique: ${field.isUnique},');
      buffer.writeln('  isIndexed: ${field.isIndexed},');
      buffer.writeln('  autoIncrement: ${field.autoIncrement},');
      if (field.columnType != null) {
        buffer.writeln("  columnType: '${_escape(field.columnType!)}',");
      }
      if (field.defaultValueSql != null) {
        buffer.writeln(
          "  defaultValueSql: '${_escape(field.defaultValueSql!)}',",
        );
      }
      if (field.codecType != null) {
        buffer.writeln("  codecType: '${field.codecType}',");
      }
      if (field.driverOverrides.isNotEmpty) {
        buffer.writeln('  driverOverrides: const {');
        field.driverOverrides.forEach((driver, override) {
          buffer.writeln("    '${_escape(driver)}': FieldDriverOverride(");
          if (override.columnType != null) {
            buffer.writeln(
              "      columnType: '${_escape(override.columnType!)}',",
            );
          }
          if (override.defaultValueSql != null) {
            buffer.writeln(
              "      defaultValueSql: '${_escape(override.defaultValueSql!)}',",
            );
          }
          if (override.codecType != null) {
            buffer.writeln("      codecType: '${override.codecType}',");
          }
          buffer.writeln('    ),');
        });
        buffer.writeln('  },');
      }
      buffer.writeln(');\n');
    }

    for (final relation in relations) {
      buffer.writeln(
        'const RelationDefinition ${relation.identifier} = RelationDefinition(',
      );
      buffer.writeln("  name: '${_escape(relation.name)}',");
      buffer.writeln('  kind: RelationKind.${relation.kind.name},');
      buffer.writeln("  targetModel: '${_escape(relation.targetModel)}',");
      if (relation.foreignKey != null) {
        buffer.writeln("  foreignKey: '${_escape(relation.foreignKey!)}',");
      }
      if (relation.localKey != null) {
        buffer.writeln("  localKey: '${_escape(relation.localKey!)}',");
      }
      if (relation.through != null) {
        buffer.writeln("  through: '${_escape(relation.through!)}',");
      }
      if (relation.pivotForeignKey != null) {
        buffer.writeln(
          "  pivotForeignKey: '${_escape(relation.pivotForeignKey!)}',",
        );
      }
      if (relation.pivotRelatedKey != null) {
        buffer.writeln(
          "  pivotRelatedKey: '${_escape(relation.pivotRelatedKey!)}',",
        );
      }
      if (relation.morphType != null) {
        buffer.writeln("  morphType: '${_escape(relation.morphType!)}',");
      }
      if (relation.morphClass != null) {
        buffer.writeln("  morphClass: '${_escape(relation.morphClass!)}',");
      }
      buffer.writeln(');\n');
    }

    final modelVar = '_\$${className}ModelDefinition';
    buffer.writeln(
      'final ModelDefinition<$className> $modelVar = ModelDefinition(',
    );
    buffer.writeln("  modelName: '${_escape(className)}',");
    buffer.writeln("  tableName: '${_escape(tableName!)}',");
    if (schema != null) {
      buffer.writeln("  schema: '${_escape(schema!)}',");
    }
    buffer.writeln('  fields: const [');
    for (final field in fields) {
      buffer.writeln('    ${field.identifier},');
    }
    buffer.writeln('  ],');
    buffer.writeln('  relations: const [');
    for (final relation in relations) {
      buffer.writeln('    ${relation.identifier},');
    }
    buffer.writeln('  ],');
    if (softDeleteColumn != null) {
      buffer.writeln("  softDeleteColumn: '${_escape(softDeleteColumn)}',");
    }
    buffer.writeln('  metadata: ModelAttributesMetadata(');
    buffer.writeln('    hidden: ${_stringListLiteral(hiddenAnnotation)},');
    buffer.writeln('    visible: ${_stringListLiteral(visibleAnnotation)},');
    buffer.writeln('    fillable: ${_stringListLiteral(fillableAnnotation)},');
    buffer.writeln('    guarded: ${_stringListLiteral(guardedAnnotation)},');
    buffer.writeln('    casts: ${_stringMapLiteral(castsAnnotation)},');
    final fieldOverrides = fields.where((f) => f.attributeMetadata != null);
    if (fieldOverrides.isNotEmpty) {
      buffer.writeln('    fieldOverrides: const {');
      for (final field in fieldOverrides) {
        final override = field.attributeMetadata!;
        buffer.writeln(
          "      '${_escape(field.columnName)}': FieldAttributeMetadata(",
        );
        if (override.fillable != null) {
          buffer.writeln(
            '      fillable: ${_boolLiteral(override.fillable!)},',
          );
        }
        if (override.guarded != null) {
          buffer.writeln('      guarded: ${_boolLiteral(override.guarded!)},');
        }
        if (override.hidden != null) {
          buffer.writeln('      hidden: ${_boolLiteral(override.hidden!)},');
        }
        if (override.visible != null) {
          buffer.writeln('      visible: ${_boolLiteral(override.visible!)},');
        }
        if (override.cast != null) {
          buffer.writeln("      cast: '${_escape(override.cast!)}',");
        }
        buffer.writeln('      ),');
      }
      buffer.writeln('    },');
    }
    if (driverAnnotations.isNotEmpty) {
      buffer.writeln('    driverAnnotations: const [');
      for (final driver in driverAnnotations) {
        buffer.writeln("      DriverModel('${_escape(driver)}'),");
      }
      buffer.writeln('    ],');
    }
    if (connectionAnnotation != null) {
      buffer.writeln("    connection: '${_escape(connectionAnnotation!)}',");
    }
    buffer.writeln(
      '    softDeletes: ${effectiveSoftDeletes ? 'true' : 'false'},',
    );
    final metadataSoftDeleteColumn =
        softDeleteColumn ?? SoftDeletes.defaultColumn;
    buffer.writeln(
      "    softDeleteColumn: '${_escape(metadataSoftDeleteColumn)}',",
    );
    buffer.writeln('  ),');
    if (generateCodec) {
      buffer.writeln('  codec: _\$${className}ModelCodec(),');
    } else {
      buffer.writeln('  codec: _\$${className}UnsupportedCodec(),');
    }
    buffer.writeln(');\n');

    if (mixinModelFactory) {
      buffer.writeln('// ignore: unused_element');
      buffer.writeln(
        'final _${className}ModelDefinitionRegistration = ModelFactoryRegistry.register<$className>(',
      );
      buffer.writeln('  $modelVar,');
      buffer.writeln(');\n');
    }

    buffer.writeln('extension ${className}OrmDefinition on $className {');
    buffer.writeln(
      '  static ModelDefinition<$className> get definition => $modelVar;',
    );
    buffer.writeln('}\n');
    if (mixinModelFactory) {
      buffer.writeln(_modelHelperClass());
    }

    if (generateCodec) {
      buffer.writeln(_codecFor(constructor, fields));
    } else {
      buffer.writeln(_unsupportedCodec(className));
    }

    buffer.writeln(
      _modelSubclass(
        constructor,
        fields,
        modelVar,
        effectiveSoftDeletes,
        metadataSoftDeleteColumn,
        mixinModelAttributes,
        mixinModelConnection,
        extendsModel,
      ),
    );

    await _writeModelSummary(buildStep);
    return buffer.toString();
  }

  Future<void> _writeModelSummary(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    if (!inputId.path.startsWith('lib/')) return;
    final relativeImport = inputId.path.substring('lib/'.length);
    final summary = jsonEncode({
      'className': className,
      'import': relativeImport.replaceAll(r'\', '/'),
      'definition': '${className}OrmDefinition.definition',
    });
    final outputId = inputId.changeExtension('.orm_model.json');
    await buildStep.writeAsString(outputId, summary);
  }

  String _codecFor(
    ConstructorElement constructor,
    List<_FieldDescriptor> fields,
  ) {
    final className = this.className;
    final codecName = '_\$${className}ModelCodec';
    final buffer = StringBuffer();
    buffer.writeln('class $codecName extends ModelCodec<$className> {');
    buffer.writeln('  const $codecName();');
    buffer.writeln('\n  @override');
    buffer.writeln(
      '  Map<String, Object?> encode($className model, ValueCodecRegistry registry) {',
    );
    buffer.writeln('    return <String, Object?>{');
    for (final field in fields) {
      final accessor = field.isVirtual
          ? "model.getAttribute<${field.resolvedType}>('${field.columnName}')"
          : 'model.${field.name}';
      buffer.writeln(
        "      '${field.columnName}': registry.encodeField(${field.identifier}, $accessor),",
      );
    }
    buffer.writeln('    };');
    buffer.writeln('  }\n');

    buffer.writeln('  @override');
    buffer.writeln(
      '  $className decode(Map<String, Object?> data, ValueCodecRegistry registry) {',
    );
    for (final field in fields) {
      buffer.writeln(
        '    final ${field.resolvedType} ${field.localIdentifier} = ${_decodeExpression(field)};',
      );
    }
    buffer.writeln(
      '    final model = ${_constructorInvocation(constructor, fields, subclass: true)};',
    );
    buffer.writeln('    model._attachOrmRuntimeMetadata({');
    for (final field in fields) {
      buffer.writeln("      '${field.columnName}': ${field.localIdentifier},");
    }
    buffer.writeln('    });');
    buffer.writeln('    return model;');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
    return buffer.toString();
  }

  String _constructorInvocation(
    ConstructorElement constructor,
    List<_FieldDescriptor> fields, {
    bool subclass = false,
  }) {
    final buffer = StringBuffer();
    final targetClass = subclass ? _modelSubclassName : className;
    buffer.writeln('$targetClass(');
    if (constructor.formalParameters.isEmpty) {
      buffer.writeln('    ');
    } else if (constructor.formalParameters.every((param) => param.isNamed)) {
      for (final parameter in constructor.formalParameters) {
        final paramName = parameter.displayName;
        final field = fields.firstWhereOrNull(
          (f) => !f.isVirtual && f.name == paramName,
        );
        if (field == null) {
          throw InvalidGenerationSourceError(
            'Constructor parameter $paramName is not backed by a field.',
            element: constructor,
          );
        }
        buffer.writeln('      $paramName: ${field.localIdentifier},');
      }
    } else if (constructor.formalParameters.every(
      (param) => param.isPositional,
    )) {
      for (final parameter in constructor.formalParameters) {
        final paramName = parameter.displayName;
        final field = fields.firstWhereOrNull(
          (f) => !f.isVirtual && f.name == paramName,
        );
        if (field == null) {
          throw InvalidGenerationSourceError(
            'Positional parameter $paramName must map to a field.',
            element: constructor,
          );
        }
        buffer.writeln('      ${field.localIdentifier},');
      }
    } else {
      throw InvalidGenerationSourceError(
        'Mixed positional/named constructors are not supported yet.',
        element: constructor,
      );
    }
    buffer.writeln('    )');
    return buffer.toString();
  }

  String _decodeExpression(_FieldDescriptor field) {
    final access =
        "registry.decodeField<${field.resolvedType}>(${field.identifier}, data['${field.columnName}'])";
    if (field.isNullable) {
      return access;
    }
    return "$access ?? (throw StateError('Field ${field.name} on $className cannot be null.'))";
  }

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

  List<_FieldDescriptor> _collectFields() {
    final descriptors = <_FieldDescriptor>[];
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
        _FieldDescriptor(
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

  _FieldDescriptor? _buildFieldDescriptor(FieldElement field) {
    final reader = _readAnnotation(field, 'OrmField');
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
    final softDeleteReader = _readAnnotation(field, 'OrmSoftDelete');
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

    return _FieldDescriptor(
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
      codecType: _maybeTypeName(codecType),
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

  List<_RelationDescriptor> _collectRelations() {
    final relations = <_RelationDescriptor>[];
    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic || field.isPrivate) {
        continue;
      }
      final annotation = _readAnnotation(field, 'OrmRelation');
      if (annotation == null) {
        continue;
      }
      relations.add(
        _RelationDescriptor(
          owner: className,
          name: field.displayName,
          kind: _readRelationKind(annotation.peek('kind')?.objectValue),
          targetModel: _typeOrDynamic(annotation.peek('target')?.typeValue),
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

  RelationKind _readRelationKind(DartObject? object) {
    if (object == null) {
      return RelationKind.hasOne;
    }
    final index = object.getField('index')?.toIntValue();
    return RelationKind.values[index ?? 0];
  }

  void _applyAnnotationPrimaryKeys(List<_FieldDescriptor> fields) {
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

  void _markPrimaryKeyFallback(List<_FieldDescriptor> fields) {
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

  String _unsupportedCodec(String className) =>
      'class _\$${className}UnsupportedCodec extends ModelCodec<$className> {\n'
      '  const _\$${className}UnsupportedCodec();\n'
      '  @override Map<String, Object?> encode($className model, ValueCodecRegistry registry) =>\n'
      "      throw UnsupportedError('Codec generation disabled for $className');\n"
      '  @override $className decode(Map<String, Object?> data, ValueCodecRegistry registry) =>\n'
      "      throw UnsupportedError('Codec generation disabled for $className');\n"
      '}\n';

  Map<String, _DriverFieldOverrideDescriptor> _readDriverOverrides(
    ConstantReader? reader,
    FieldElement field,
  ) {
    if (reader == null || reader.isNull) return const {};
    final overrides = <String, _DriverFieldOverrideDescriptor>{};
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
      overrides[normalized] = _DriverFieldOverrideDescriptor(
        columnType: overrideReader.peek('columnType')?.stringValue,
        defaultValueSql: overrideReader.peek('defaultValueSql')?.stringValue,
        codecType: _maybeTypeName(overrideReader.peek('codec')?.typeValue),
      );
    });
    return Map.unmodifiable(overrides);
  }

  String _modelSubclass(
    ConstructorElement constructor,
    List<_FieldDescriptor> fields,
    String modelDefinitionVar,
    bool usesSoftDeletes,
    String softDeleteColumn,
    bool baseHasModelAttributes,
    bool baseHasModelConnection,
    bool extendsModel,
  ) {
    final buffer = StringBuffer();
    final mixins = <String>[];
    if (!baseHasModelAttributes) {
      mixins.add('ModelAttributes');
    }
    if (!baseHasModelConnection) {
      mixins.add('ModelConnection');
    }
    final mixinSuffix = mixins.isEmpty ? '' : ' with ${mixins.join(', ')}';
    buffer.writeln(
      'class $_modelSubclassName extends $className$mixinSuffix {',
    );
    buffer.writeln(
      '  $_modelSubclassName${_constructorParameters(constructor, fields)}',
    );
    buffer.writeln('      : super${_superInvocation(constructor)} {');
    buffer.writeln('    _attachOrmRuntimeMetadata({');
    for (final field in fields.where((f) => !f.isVirtual)) {
      buffer.writeln("      '${field.columnName}': ${field.name},");
    }
    buffer.writeln('    });');
    buffer.writeln('  }\n');

    for (final field in fields.where((f) => !f.isVirtual)) {
      buffer.writeln('  @override');
      buffer.writeln(
        '  ${field.resolvedType} get ${field.name} => getAttribute<${field.resolvedType}>(\'${field.columnName}\') ?? super.${field.name};',
      );
      buffer.writeln();
      if (baseHasModelAttributes) {
        buffer.writeln('  set ${field.name}(${field.resolvedType} value) =>');
        buffer.writeln('      setAttribute(\'${field.columnName}\', value);');
        buffer.writeln();
      }
    }

    buffer.writeln('  void _attachOrmRuntimeMetadata(');
    buffer.writeln('    Map<String, Object?> values,');
    buffer.writeln('  ) {');
    buffer.writeln('    replaceAttributes(values);');
    buffer.writeln('    attachModelDefinition($modelDefinitionVar);');
    if (usesSoftDeletes) {
      buffer.writeln(
        "    attachSoftDeleteColumn('${_escape(softDeleteColumn)}');",
      );
    }
    buffer.writeln('  }\n');

    buffer.writeln('}');
    if (extendsModel) {
      buffer.writeln('extension ${className}AttributeSetters on $className {');
      for (final field in fields.where((f) => !f.isVirtual)) {
        buffer.writeln('  set ${field.name}(${field.resolvedType} value) =>');
        buffer.writeln('      setAttribute(\'${field.columnName}\', value);');
      }
      buffer.writeln('}');
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _modelHelperClass() {
    final buffer = StringBuffer();
    buffer.writeln('class ${className}ModelFactory {');
    buffer.writeln('  const ${className}ModelFactory._();');
    buffer.writeln();
    buffer.writeln('  static ModelDefinition<$className> get definition =>');
    buffer.writeln('      ${className}OrmDefinition.definition;');
    buffer.writeln();
    buffer.writeln(
      '  static ModelCodec<$className> get codec => definition.codec;',
    );
    buffer.writeln();
    buffer.writeln('  static $className fromMap(');
    buffer.writeln('    Map<String, Object?> data, {');
    buffer.writeln('    ValueCodecRegistry? registry,');
    buffer.writeln('  }) =>');
    buffer.writeln('      definition.fromMap(data, registry: registry);');
    buffer.writeln();
    buffer.writeln('  static Map<String, Object?> toMap(');
    buffer.writeln('    $className model, {');
    buffer.writeln('    ValueCodecRegistry? registry,');
    buffer.writeln('  }) =>');
    buffer.writeln('      definition.toMap(model, registry: registry);');
    buffer.writeln();
    buffer.writeln('  static void registerWith(ModelRegistry registry) =>');
    buffer.writeln('      registry.register(definition);');
    buffer.writeln();
    buffer.writeln(
      '  static ModelFactoryConnection<$className> withConnection(QueryContext context) =>',
    );
    buffer.writeln(
      '      ModelFactoryConnection<$className>(definition: definition, context: context);',
    );
    buffer.writeln();
    buffer.writeln('  static ModelFactoryBuilder<$className> factory({');
    buffer.writeln('    GeneratorProvider? generatorProvider,');
    buffer.writeln('  }) =>');
    buffer.writeln('      ModelFactoryBuilder<$className>(');
    buffer.writeln('        definition: definition,');
    buffer.writeln('        generatorProvider: generatorProvider,');
    buffer.writeln('      );');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln(
      'extension ${className}ModelFactoryExtension on $className {',
    );
    buffer.writeln('  static ModelFactoryBuilder<$className> factory({');
    buffer.writeln('    GeneratorProvider? generatorProvider,');
    buffer.writeln('  }) =>');
    buffer.writeln(
      '      ${className}ModelFactory.factory(generatorProvider: generatorProvider);',
    );
    buffer.writeln('}');
    buffer.writeln();
    return buffer.toString();
  }

  String _constructorParameters(
    ConstructorElement constructor,
    List<_FieldDescriptor> fields,
  ) {
    if (constructor.formalParameters.isEmpty) {
      return '()';
    }
    final buffer = StringBuffer();
    if (constructor.formalParameters.every((param) => param.isNamed)) {
      buffer.writeln('({');
      for (final parameter in constructor.formalParameters) {
        final descriptor = _fieldForParameter(parameter, fields);
        final requiredPrefix = parameter.isRequiredNamed ? 'required ' : '';
        final defaultValue = parameter.defaultValueCode;
        final defaultSuffix = defaultValue == null ? '' : ' = $defaultValue';
        buffer.writeln(
          '    $requiredPrefix${descriptor.resolvedType} ${descriptor.name}$defaultSuffix,',
        );
      }
      buffer.write('  })');
    } else if (constructor.formalParameters.every(
      (param) => param.isPositional,
    )) {
      buffer.write('(');
      var openedOptional = false;
      for (final parameter in constructor.formalParameters) {
        if (parameter.isOptionalPositional && !openedOptional) {
          buffer.writeln('  [');
          openedOptional = true;
        }
        final descriptor = _fieldForParameter(parameter, fields);
        final defaultValue = parameter.defaultValueCode;
        final defaultSuffix = defaultValue == null ? '' : ' = $defaultValue';
        buffer.writeln(
          '    ${descriptor.resolvedType} ${descriptor.name}$defaultSuffix,',
        );
      }
      if (openedOptional) {
        buffer.write('  ]');
      }
      buffer.write('  )');
    } else {
      throw InvalidGenerationSourceError(
        'Mixed positional/named constructors are not supported yet.',
        element: constructor,
      );
    }
    return buffer.toString();
  }

  String _superInvocation(ConstructorElement constructor) {
    final effectiveConstructorName =
        (constructorOverride != null && constructorOverride!.isNotEmpty)
        ? constructorOverride!
        : constructor.name;

    final constructorSuffix =
        (effectiveConstructorName == null || effectiveConstructorName.isEmpty)
        ? ''
        : '.$effectiveConstructorName';

    if (constructor.formalParameters.isEmpty) {
      return '$constructorSuffix()';
    }
    final buffer = StringBuffer();
    buffer.write(constructorSuffix);
    if (constructor.formalParameters.every((param) => param.isNamed)) {
      buffer.writeln('(');
      for (final parameter in constructor.formalParameters) {
        final name = parameter.displayName;
        buffer.writeln('        $name: $name,');
      }
      buffer.write('      )');
    } else {
      buffer.writeln('(');
      for (final parameter in constructor.formalParameters) {
        buffer.writeln('        ${parameter.displayName},');
      }
      buffer.write('      )');
    }
    return buffer.toString();
  }

  _FieldDescriptor _fieldForParameter(
    FormalParameterElement parameter,
    List<_FieldDescriptor> fields,
  ) {
    final field = fields.firstWhereOrNull(
      (f) => !f.isVirtual && f.name == parameter.displayName,
    );
    if (field == null) {
      throw InvalidGenerationSourceError(
        'Constructor parameter ${parameter.displayName} is not backed by a field.',
        element: parameter,
      );
    }
    return field;
  }

  String get _modelSubclassName => '_\$${className}Model';
}

class _FieldDescriptor {
  _FieldDescriptor({
    required this.owner,
    required this.name,
    required this.columnName,
    required this.dartType,
    required this.resolvedType,
    required this.isPrimaryKey,
    required this.isNullable,
    required this.isUnique,
    required this.isIndexed,
    required this.autoIncrement,
    required this.columnType,
    required this.defaultValueSql,
    required this.codecType,
    required this.isSoftDelete,
    this.isVirtual = false,
    this.softDeleteColumnName,
    this.driverOverrides = const {},
    this.attributeMetadata,
  });

  final String owner;
  final String name;
  final String columnName;
  final String dartType;
  final String resolvedType;
  bool isPrimaryKey;
  final bool isNullable;
  final bool isUnique;
  final bool isIndexed;
  final bool autoIncrement;
  final String? columnType;
  final String? defaultValueSql;
  final String? codecType;
  final bool isSoftDelete;
  final bool isVirtual;
  final String? softDeleteColumnName;
  final Map<String, _DriverFieldOverrideDescriptor> driverOverrides;
  final FieldAttributeMetadata? attributeMetadata;

  String get identifier => '_\$$owner${_pascalize(name)}Field';

  String get localIdentifier {
    final prefix = owner.isEmpty
        ? ''
        : owner[0].toLowerCase() + owner.substring(1);
    return '$prefix${_pascalize(name)}Value';
  }
}

class _DriverFieldOverrideDescriptor {
  const _DriverFieldOverrideDescriptor({
    this.columnType,
    this.defaultValueSql,
    this.codecType,
  });

  final String? columnType;
  final String? defaultValueSql;
  final String? codecType;
}

class _RelationDescriptor {
  _RelationDescriptor({
    required this.owner,
    required this.name,
    required this.kind,
    required this.targetModel,
    this.foreignKey,
    this.localKey,
    this.through,
    this.pivotForeignKey,
    this.pivotRelatedKey,
    this.morphType,
    this.morphClass,
  });

  final String owner;
  final String name;
  final RelationKind kind;
  final String targetModel;
  final String? foreignKey;
  final String? localKey;
  final String? through;
  final String? pivotForeignKey;
  final String? pivotRelatedKey;
  final String? morphType;
  final String? morphClass;

  String get identifier => '_\$$owner${_pascalize(name)}Relation';
}

const _annotationsLibraryUri = 'package:ormed/src/annotations.dart';

ConstantReader? _readAnnotation(Element element, String className) {
  for (final metadata in element.metadata.annotations) {
    final annotationElement = metadata.element;
    if (annotationElement is! ConstructorElement) {
      continue;
    }
    final enclosingElement = annotationElement.enclosingElement;
    final uri = enclosingElement.library.uri.toString();
    if (enclosingElement.name != className || uri != _annotationsLibraryUri) {
      continue;
    }
    final value = metadata.computeConstantValue();
    if (value == null) {
      continue;
    }
    return ConstantReader(value);
  }
  return null;
}

String _pascalize(String value) {
  final cleaned = value.replaceAll(RegExp(r'^_+'), '');
  final segments = cleaned
      .split(RegExp(r'[_-]'))
      .where((segment) => segment.isNotEmpty)
      .map((segment) => segment[0].toUpperCase() + segment.substring(1))
      .join();
  return segments.isEmpty
      ? value.isEmpty
            ? ''
            : value[0].toUpperCase() + value.substring(1)
      : segments;
}

String _escape(String input) =>
    input.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

String _boolLiteral(bool value) => value ? 'true' : 'false';

String? _maybeTypeName(DartType? type) =>
    type == null ? null : _nonNullableTypeName(type);

String _typeOrDynamic(DartType? type) =>
    type == null ? 'dynamic' : _nonNullableTypeName(type);

String _nonNullableTypeName(DartType type) {
  final display = type.getDisplayString();
  return type.nullabilitySuffix == NullabilitySuffix.question
      ? display.substring(0, display.length - 1)
      : display;
}

bool _isSoftDeletesMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'SoftDeletes' &&
      libraryUri == 'package:ormed/src/model_mixins/soft_deletes.dart';
}

bool _isModelAttributesMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'ModelAttributes' &&
      libraryUri == 'package:ormed/src/model_mixins/model_attributes.dart';
}

bool _isModelConnectionMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'ModelConnection' &&
      libraryUri == 'package:ormed/src/model_mixins/model_connection.dart';
}

bool _isModelFactoryMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'ModelFactoryCapable' &&
      libraryUri == 'package:ormed/src/model_mixins/model_factory.dart';
}

bool _classOrSuperHasMixin(
  ClassElement element,
  bool Function(InterfaceType type) predicate,
) {
  if (element.mixins.any(predicate)) {
    return true;
  }
  for (final supertype in element.allSupertypes) {
    if (predicate(supertype)) {
      return true;
    }
    final superElement = supertype.element;
    if (superElement.mixins.any(predicate)) {
      return true;
    }
  }
  return false;
}

List<String> _readStringList(ConstantReader? reader) {
  if (reader == null || reader.isNull) return const [];
  return reader.listValue
      .map((value) => value.toStringValue())
      .whereType<String>()
      .toList(growable: false);
}

Map<String, String> _readStringMap(ConstantReader? reader) {
  if (reader == null || reader.isNull) return const {};
  final map = <String, String>{};
  reader.mapValue.forEach((key, value) {
    final mapKey = key?.toStringValue();
    final mapValue = value?.toStringValue();
    if (mapKey != null && mapValue != null) {
      map[mapKey] = mapValue;
    }
  });
  return Map.unmodifiable(map);
}

String _stringListLiteral(List<String> values) {
  if (values.isEmpty) return 'const <String>[]';
  final entries = values.map((entry) => "'${_escape(entry)}'");
  return 'const <String>[${entries.join(', ')}]';
}

String _stringMapLiteral(Map<String, String> values) {
  if (values.isEmpty) return 'const <String, String>{}';
  final entries = values.entries.map(
    (entry) => "'${_escape(entry.key)}': '${_escape(entry.value)}'",
  );
  return 'const <String, String>{${entries.join(', ')}}';
}

String? _normalizeConstructorOverride(ConstantReader annotation) {
  final value = annotation.peek('constructor')?.stringValue;
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
