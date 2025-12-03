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
    final modelSubclassName = '_\$${className}Model';
    final mixins = <String>[];

    if (!context.mixinModelAttributes) {
      mixins.add('ModelAttributes');
    }
    if (!context.mixinModelConnection) {
      mixins.add('ModelConnection');
    }
    // Add ModelRelations only if the base class doesn't extend Model
    // (Model already has ModelRelations mixin)
    if (!context.extendsModel) {
      mixins.add('ModelRelations');
    }

    final mixinSuffix = mixins.isEmpty ? '' : ' with ${mixins.join(', ')}';
    buffer.writeln('class $modelSubclassName extends $className$mixinSuffix {');
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
      '    attachModelDefinition(_\$${className}ModelDefinition);',
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
        if (parameter.isRequired || !field.isNullable) {
          buffer.write('required ');
        }
        buffer.write('${field.resolvedType} $paramName, ');
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
        if (parameter.isRequired || !field.isNullable) {
          buffer.write('required ');
        }
        buffer.write('${field.resolvedType} $paramName, ');
      }
    }
    buffer.write('})');
    return buffer.toString();
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
