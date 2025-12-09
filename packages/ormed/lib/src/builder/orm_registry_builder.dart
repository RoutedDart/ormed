import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

Builder ormRegistryBuilder(BuilderOptions options) =>
    _OrmRegistryBuilder(options);

class _OrmRegistryBuilder implements Builder {
  static final _summaryGlob = Glob('lib/**.orm_model.json');

  _OrmRegistryBuilder(BuilderOptions options)
    : outputPath =
          (options.config['output'] as String?)?.trim() ??
          'lib/orm_registry.g.dart' {
    if (outputPath.isEmpty) {
      throw StateError('The orm_registry output path cannot be empty.');
    }
    if (outputPath.startsWith('/')) {
      throw StateError('The orm_registry output path must be relative.');
    }
  }

  final String outputPath;

  @override
  Map<String, List<String>> get buildExtensions => {
    'pubspec.yaml': [outputPath],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final summaries = <ModelSummary>[];
    await for (final asset in buildStep.findAssets(_summaryGlob)) {
      final content = await buildStep.readAsString(asset);
      final data = jsonDecode(content) as Map<String, dynamic>;
      final importPath = data['import'] as String?;
      final className = data['className'] as String?;
      final definition = data['definition'] as String?;
      if (importPath == null ||
          className == null ||
          definition == null ||
          importPath.isEmpty) {
        continue;
      }
      summaries.add(
        ModelSummary(
          className: className,
          importPath: importPath,
          definition: definition,
        ),
      );
    }

    final content = renderRegistryContent(summaries);
    final outputId = AssetId(
      buildStep.inputId.package,
      'lib/orm_registry.g.dart',
    );
    await buildStep.writeAsString(outputId, content);
  }
}

String renderRegistryContent(List<ModelSummary> models) {
  final summaries = List<ModelSummary>.from(models)
    ..sort((a, b) => a.className.compareTo(b.className));
  final uniqueImports = <String>{};
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// coverage:ignore-file')
    ..writeln("import 'package:ormed/ormed.dart';");

  for (final summary in summaries) {
    if (uniqueImports.add(summary.importPath)) {
      buffer.writeln("import '${summary.importPath}';");
    }
  }

  buffer
    ..writeln('')
    ..writeln(
      'final List<ModelDefinition<dynamic>> _\$ormModelDefinitions = [',
    );
  for (final summary in summaries) {
    buffer.writeln('  ${summary.definition},');
  }
  buffer
    ..writeln('];')
    ..writeln('')
    ..writeln('ModelRegistry buildOrmRegistry() => ModelRegistry()')
    ..writeln('  ..registerAll(_\$ormModelDefinitions)')
    ..write('  ');
  
  // Register user type aliases
  for (final summary in summaries) {
    final userClassName = summary.className.startsWith('\$') 
        ? summary.className.substring(1) 
        : summary.className;
    buffer.writeln('..registerTypeAlias<$userClassName>(_\$ormModelDefinitions[${summaries.indexOf(summary)}])');
    buffer.write('  ');
  }
  
  buffer
    ..writeln(';')
    ..writeln('')
    ..writeln(
      'List<ModelDefinition<dynamic>> get generatedOrmModelDefinitions =>',
    )
    ..writeln('    List.unmodifiable(_\$ormModelDefinitions);')
    ..writeln('')
    ..writeln('extension GeneratedOrmModels on ModelRegistry {')
    ..writeln('  ModelRegistry registerGeneratedModels() {')
    ..writeln('    registerAll(_\$ormModelDefinitions);');
    
  // Register user type aliases in extension too
  for (final summary in summaries) {
    final userClassName = summary.className.startsWith('\$') 
        ? summary.className.substring(1) 
        : summary.className;
    buffer.writeln('    registerTypeAlias<$userClassName>(_\$ormModelDefinitions[${summaries.indexOf(summary)}]);');
  }
  
  buffer
    ..writeln('    return this;')
    ..writeln('  }')
    ..writeln('}');
  return buffer.toString();
}

class ModelSummary {
  ModelSummary({
    required this.className,
    required this.importPath,
    required this.definition,
  });

  final String className;
  final String importPath;
  final String definition;
}
