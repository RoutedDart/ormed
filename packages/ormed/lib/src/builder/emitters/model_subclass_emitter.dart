import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import 'package:ormed/src/annotations.dart';

import '../descriptors.dart';
import '../model_context.dart';

class ModelSubclassEmitter {
  ModelSubclassEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final className = context.className;
    final modelSubclassName = context.trackedModelClassName;

    // Generate documentation for the tracked model class
    buffer.writeln('/// Generated tracked model class for [$className].');
    buffer.writeln('///');
    buffer.writeln(
      '/// This class extends the user-defined [$className] model and adds',
    );
    buffer.writeln(
      '/// attribute tracking, change detection, and relationship management.',
    );
    buffer.writeln(
      '/// Instances of this class are returned by queries and repositories.',
    );
    buffer.writeln('///');
    buffer.writeln(
      '/// **Do not instantiate this class directly.** Use queries, repositories,',
    );
    buffer.writeln('/// or model factories to create tracked model instances.');

    // The generated tracked model class needs ModelAttributes mixin
    // to enable attribute tracking and change detection.
    // Note: The base Model class already includes ModelConnection and ModelRelations,
    // so we only need to add ModelAttributes when extending Model.
    final mixins = <String>[];

    if (context.extendsModel) {
      // User model extends Model, so we only need to add ModelAttributes
      // (Model already includes ModelConnection and ModelRelations)
      mixins.add('ModelAttributes');

      // Add timestamp implementation mixins
      if (context.mixinTimestamps) {
        mixins.add('TimestampsImpl');
      } else if (context.mixinTimestampsTZ) {
        mixins.add('TimestampsTZImpl');
      }

      // Add soft delete implementation mixin
      if (context.mixinSoftDeletesTZ) {
        mixins.add('SoftDeletesTZImpl');
      } else if (context.effectiveSoftDeletes) {
        // Use the implementation mixin, not the marker mixin
        mixins.add('SoftDeletesImpl');
      }
    } else {
      // If not extending Model, we need to add all the mixins
      if (!context.mixinModelAttributes) {
        mixins.add('ModelAttributes');
      }
      if (!context.mixinModelConnection) {
        mixins.add('ModelConnection');
      }
      mixins.add('ModelRelations');

      // Add timestamp implementation mixins
      if (context.mixinTimestamps) {
        mixins.add('TimestampsImpl');
      } else if (context.mixinTimestampsTZ) {
        mixins.add('TimestampsTZImpl');
      }

      // Add soft delete implementation mixin
      if (context.mixinSoftDeletesTZ) {
        mixins.add('SoftDeletesTZImpl');
      } else if (context.effectiveSoftDeletes) {
        // Use the implementation mixin, not the marker mixin
        mixins.add('SoftDeletesImpl');
      }
    }

    final mixinSuffix = mixins.isEmpty ? '' : ' with ${mixins.join(', ')}';
    buffer.writeln(
      'class $modelSubclassName extends $className$mixinSuffix implements OrmEntity {',
    );
    buffer.writeln(
      '  $modelSubclassName${_constructorParameters(context.constructor, context.fields)}',
    );
    buffer.writeln('      : super${_superInvocation(context.constructor)} {');
    buffer.writeln('    _attachOrmRuntimeMetadata({');
    for (final field in context.fields.where((f) => !f.isVirtual)) {
      buffer.writeln("      '${field.columnName}': ${field.name},");
    }
    buffer.writeln('    });');
    buffer.writeln('  }\n');

    // Add factory constructor to convert from user model
    buffer.writeln(
      '  /// Creates a tracked model instance from a user-defined model instance.',
    );
    buffer.writeln(
      '  factory $modelSubclassName.fromModel($className model) {',
    );
    buffer.writeln('    return $modelSubclassName(');
    for (final field in context.fields.where((f) => !f.isVirtual)) {
      buffer.writeln('      ${field.name}: model.${field.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }\n');

    for (final field in context.fields.where((f) => !f.isVirtual)) {
      buffer.writeln('  @override');
      buffer.writeln(
        '  ${field.resolvedType} get ${field.name} => getAttribute<${field.resolvedType}>(\'${field.columnName}\') ?? super.${field.name};',
      );
      buffer.writeln();
      buffer.writeln(
        '  set ${field.name}(${field.resolvedType} value) => setAttribute(\'${field.columnName}\', value);',
      );
      buffer.writeln();
    }

    buffer.writeln(
      '  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {',
    );
    buffer.writeln('    replaceAttributes(values);');
    buffer.writeln(
      '    attachModelDefinition(_${modelSubclassName}Definition);',
    );
    if (context.effectiveSoftDeletes) {
      buffer.writeln(
        "    attachSoftDeleteColumn('${context.softDeleteColumn}');",
      );
    }
    buffer.writeln('  }');

    // Generate relation getter overrides with loaded checks
    for (final relation in context.relations) {
      final isList = relation.isList;
      final returnType = isList
          ? 'List<${relation.targetModel}>'
          : '${relation.targetModel}?';

      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  $returnType get ${relation.name} {');
      buffer.writeln("    if (relationLoaded('${relation.name}')) {");

      if (isList) {
        buffer.writeln(
          "      return getRelationList<${relation.targetModel}>('${relation.name}');",
        );
      } else {
        buffer.writeln(
          "      return getRelation<${relation.targetModel}>('${relation.name}');",
        );
      }

      buffer.writeln('    }');
      buffer.writeln('    return super.${relation.name};');
      buffer.writeln('  }');
    }

    buffer.writeln('}');
    buffer.writeln();

    // Generate relation query methods as extension
    if (context.relations.isNotEmpty) {
      buffer.writeln('extension ${className}RelationQueries on $className {');
      for (final relation in context.relations) {
        final targetType = relation.targetModel;
        buffer.writeln('  Query<$targetType> ${relation.name}Query() {');

        if (relation.kind == RelationKind.belongsTo) {
          final foreignKeyField = context.fields.firstWhereOrNull(
            (f) => f.columnName == relation.foreignKey,
          );
          final foreignKeyGetter =
              foreignKeyField?.name ?? 'getAttribute("${relation.foreignKey}")';

          buffer.writeln(
            '    return Model.query<$targetType>().where(\'${relation.localKey}\', $foreignKeyGetter);',
          );
        } else if (relation.kind == RelationKind.hasOne ||
            relation.kind == RelationKind.hasMany) {
          final localKeyField = context.fields.firstWhereOrNull(
            (f) => f.columnName == relation.localKey,
          );
          final localKeyGetter =
              localKeyField?.name ?? 'getAttribute("${relation.localKey}")';

          buffer.writeln(
            '    return Model.query<$targetType>().where(\'${relation.foreignKey}\', $localKeyGetter);',
          );
        } else if (relation.kind == RelationKind.manyToMany) {
          buffer.writeln(
            '    throw UnimplementedError("ManyToMany query generation not yet supported");',
          );
        } else if (relation.kind == RelationKind.morphOne ||
            relation.kind == RelationKind.morphMany) {
          buffer.writeln(
            '    throw UnimplementedError("Polymorphic relation query generation not yet supported");',
          );
        } else {
          // Fallback for any other relation kinds
          buffer.writeln(
            '    throw UnimplementedError("Relation query generation not supported for ${relation.kind}");',
          );
        }

        buffer.writeln('  }');
        buffer.writeln();
      }
      buffer.writeln('}');
      buffer.writeln();
    }

    // Generate toTracked() extension for converting user models to ORM-managed models
    final extensionName = '${className}OrmExtension';
    buffer.writeln('extension $extensionName on $className {');
    buffer.writeln('  /// The Type of the generated ORM-managed model class.');
    buffer.writeln(
      '  /// Use this when you need to specify the tracked model type explicitly,',
    );
    buffer.writeln('  /// for example in generic type parameters.');
    buffer.writeln('  static Type get trackedType => $modelSubclassName;');
    buffer.writeln();
    buffer.writeln(
      '  /// Converts this immutable model to a tracked ORM-managed model.',
    );
    buffer.writeln(
      '  /// The tracked model supports attribute tracking, change detection,',
    );
    buffer.writeln('  /// and persistence operations like save() and touch().');
    buffer.writeln('  $modelSubclassName toTracked() {');
    buffer.writeln('    return $modelSubclassName.fromModel(this);');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    // Note: We don't generate an extension with setters on the base class because
    // setAttribute() only exists on the generated subclass (via ModelAttributes mixin).
    // Users should use the generated model type or access via repository/query builder.

    return buffer.toString();
  }

  String _constructorParameters(
    ConstructorElement constructor,
    List<FieldDescriptor> fields,
  ) {
    final buffer = StringBuffer();
    buffer.write('({');
    if (constructor.formalParameters.isEmpty) {
      // No params
    } else if (constructor.formalParameters.every((param) => param.isNamed)) {
      for (final parameter in constructor.formalParameters) {
        final paramName = parameter.displayName;
        final field = fields.firstWhereOrNull(
          (f) => !f.isVirtual && f.name == paramName,
        );
        if (field == null) continue;

        // Check if this field has a default value (e.g., auto-increment sentinel)
        final hasDefaultValue =
            field.defaultDartValue != null ||
            (field.autoIncrement && !field.isNullable);

        if (!hasDefaultValue && (parameter.isRequired || !field.isNullable)) {
          buffer.write('required ');
        }
        buffer.write('${field.resolvedType} $paramName');

        // Add default value for auto-increment fields
        if (hasDefaultValue) {
          final defaultVal =
              field.defaultDartValue ?? (field.autoIncrement ? 0 : null);
          if (defaultVal != null) {
            buffer.write(' = ${_literalValue(defaultVal)}');
          }
        }
        buffer.write(', ');
      }
    } else if (constructor.formalParameters.every(
      (param) => param.isPositional,
    )) {
      for (final parameter in constructor.formalParameters) {
        final paramName = parameter.displayName;
        final field = fields.firstWhereOrNull(
          (f) => !f.isVirtual && f.name == paramName,
        );
        if (field == null) continue;

        // Check if this field has a default value
        final hasDefaultValue =
            field.defaultDartValue != null ||
            (field.autoIncrement && !field.isNullable);

        if (!hasDefaultValue && (parameter.isRequired || !field.isNullable)) {
          buffer.write('required ');
        }
        buffer.write('${field.resolvedType} $paramName');

        // Add default value for auto-increment fields
        if (hasDefaultValue) {
          final defaultVal =
              field.defaultDartValue ?? (field.autoIncrement ? 0 : null);
          if (defaultVal != null) {
            buffer.write(' = ${_literalValue(defaultVal)}');
          }
        }
        buffer.write(', ');
      }
    }
    buffer.write('})');
    return buffer.toString();
  }

  /// Converts a Dart value to its literal string representation.
  String _literalValue(Object? value) {
    if (value == null) return 'null';
    if (value is String) return "'$value'";
    if (value is int || value is double || value is bool) return '$value';
    return '$value';
  }

  String _superInvocation(ConstructorElement constructor) {
    final buffer = StringBuffer();
    if ((constructor.name ?? '').isNotEmpty) {
      buffer.write('.${constructor.name}');
    }
    buffer.write('(');
    if (constructor.formalParameters.isEmpty) {
      // No params
    } else if (constructor.formalParameters.every((param) => param.isNamed)) {
      for (final parameter in constructor.formalParameters) {
        final paramName = parameter.displayName;
        buffer.write('$paramName: $paramName, ');
      }
    } else if (constructor.formalParameters.every(
      (param) => param.isPositional,
    )) {
      for (final parameter in constructor.formalParameters) {
        final paramName = parameter.displayName;
        buffer.write('$paramName, ');
      }
    }
    buffer.write(')');
    return buffer.toString();
  }
}
