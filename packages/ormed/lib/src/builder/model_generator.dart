import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:ormed/src/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'emitters/companion_class_emitter.dart';
import 'emitters/model_codec_emitter.dart';
import 'emitters/model_definition_emitter.dart';
import 'emitters/model_dto_emitter.dart';
import 'emitters/model_event_handler_emitter.dart';
import 'emitters/model_factory_emitter.dart';
import 'emitters/model_partial_emitter.dart';
import 'emitters/model_subclass_emitter.dart';
import 'factory_extension.dart';
import 'model_context.dart';
import 'model_helper.dart';

class OrmModelGenerator extends GeneratorForAnnotation<OrmModel> {
  final BuilderOptions options;

  OrmModelGenerator(this.options);

  static const _modelChecker = TypeChecker.fromUrl(
    'package:ormed/src/annotations.dart#OrmModel',
  );

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
    buffer.writeln(ModelEventHandlerEmitter(context).emit());

    await _writeModelSummary(buildStep, context);
    return buffer.toString();
  }

  Future<void> _writeModelSummary(
    BuildStep buildStep,
    ModelContext context,
  ) async {
    final inputId = buildStep.inputId;
    if (!inputId.path.startsWith('lib/')) return;
    final library = context.element.library;
    final annotatedModels =
        library.classes.where(_modelChecker.hasAnnotationOfExact).toList()
          ..sort((a, b) {
            final aFragment = a.firstFragment;
            final bFragment = b.firstFragment;
            final aUri = aFragment.libraryFragment.source.uri.toString();
            final bUri = bFragment.libraryFragment.source.uri.toString();
            final byUri = aUri.compareTo(bUri);
            if (byUri != 0) return byUri;
            return aFragment.offset.compareTo(bFragment.offset);
          });

    // Write one summary file per library to avoid duplicate output writes when a
    // library contains multiple @OrmModel classes.
    if (annotatedModels.isEmpty || annotatedModels.first != context.element) {
      return;
    }

    final relativeImport = inputId.path
        .substring('lib/'.length)
        .replaceAll(r'\', '/');
    final summaries = <Map<String, Object?>>[];

    for (final model in annotatedModels) {
      final annotation = _modelChecker.firstAnnotationOfExact(model);
      if (annotation == null) {
        continue;
      }
      final modelContext = ModelContext(model, ConstantReader(annotation));
      summaries.add({
        'className': modelContext.className,
        'import': relativeImport,
        'definition': '${modelContext.className}OrmDefinition.definition',
        'hasFactory': modelContext.hasFactory,
        'hasEventHandlers': modelContext.hasEventHandlers,
        'hasScopes': modelContext.scopes.isNotEmpty,
      });
    }

    final outputId = inputId.changeExtension('.orm_model.json');
    await buildStep.writeAsString(outputId, jsonEncode(summaries));
  }
}
