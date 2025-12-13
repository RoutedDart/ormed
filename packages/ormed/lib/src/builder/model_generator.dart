import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:ormed/src/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'emitters/companion_class_emitter.dart';
import 'emitters/model_codec_emitter.dart';
import 'emitters/model_definition_emitter.dart';
import 'emitters/model_factory_emitter.dart';
import 'emitters/model_dto_emitter.dart';
import 'emitters/model_partial_emitter.dart';
import 'emitters/model_subclass_emitter.dart';

import 'model_context.dart';
import 'model_helper.dart';
import 'factory_extension.dart';

class OrmModelGenerator extends GeneratorForAnnotation<OrmModel> {
  final BuilderOptions options;

  OrmModelGenerator(this.options);

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@OrmModel can only be applied to classes.',
        element: element,
      );
    }

    final context = ModelContext(element, annotation);
    final buffer = StringBuffer();

    buffer.writeln(ModelDefinitionEmitter(context).emit());

    // Only generate ModelFactory and extension if NOT extending Model
    if (!context.extendsModel) {
      buffer.writeln(modelHelperClass(context.className));
      buffer.writeln(modelFactoryExtension(context.className));
    } else {
      // Generate Companion Class and ModelFactory if extending Model
      buffer.writeln(CompanionClassEmitter(context).emit());
      buffer.writeln(ModelFactoryEmitter(context).emit());
    }

    buffer.writeln(ModelCodecEmitter(context).emit());
    buffer.writeln(ModelDtoEmitter(context).emit());
    buffer.writeln(ModelPartialEmitter(context).emit());
    buffer.writeln(ModelSubclassEmitter(context).emit());

    await _writeModelSummary(buildStep, context);
    return buffer.toString();
  }

  Future<void> _writeModelSummary(
    BuildStep buildStep,
    ModelContext context,
  ) async {
    final inputId = buildStep.inputId;
    if (!inputId.path.startsWith('lib/')) return;
    final relativeImport = inputId.path.substring('lib/'.length);
    final summary = jsonEncode({
      'className': context.className,
      'import': relativeImport.replaceAll(r'\', '/'),
      'definition': '${context.className}OrmDefinition.definition',
      'hasFactory': context.hasFactory,
    });
    final outputId = inputId.changeExtension('.orm_model.json');
    await buildStep.writeAsString(outputId, summary);
  }
}
