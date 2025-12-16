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
      final hasFactory = data['hasFactory'] as bool? ?? false;
      final hasEventHandlers = data['hasEventHandlers'] as bool? ?? false;
      final hasScopes = data['hasScopes'] as bool? ?? false;
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
          hasFactory: hasFactory,
          hasEventHandlers: hasEventHandlers,
          hasScopes: hasScopes,
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
      'final List<ModelDefinition<OrmEntity>> _\$ormModelDefinitions = [',
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
    buffer.writeln(
      '..registerTypeAlias<$userClassName>(_\$ormModelDefinitions[${summaries.indexOf(summary)}])',
    );
    buffer.write('  ');
  }

  buffer
    ..writeln(';')
    ..writeln('')
    ..writeln(
      'List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>',
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
    buffer.writeln(
      '    registerTypeAlias<$userClassName>(_\$ormModelDefinitions[${summaries.indexOf(summary)}]);',
    );
  }

  buffer
    ..writeln('    return this;')
    ..writeln('  }')
    ..writeln('}')
    ..writeln('');

  // Generate registerOrmFactories() for models with factory support
  final factoryModels = summaries.where((s) => s.hasFactory).toList();
  buffer.writeln(
    '/// Registers factory definitions for all models that have factory support.',
  );
  buffer.writeln(
    '/// Call this before using [Model.factory<T>()] to ensure definitions are available.',
  );
  buffer.writeln('void registerOrmFactories() {');
  for (final summary in factoryModels) {
    final userClassName = summary.className.startsWith('\$')
        ? summary.className.substring(1)
        : summary.className;
    buffer.writeln(
      '  ModelFactoryRegistry.registerIfAbsent<$userClassName>(${summary.definition});',
    );
  }
  buffer
    ..writeln('}')
    ..writeln('')
    ..writeln(
      '/// Combined setup: registers both model registry and factories.',
    )
    ..writeln(
      '/// Returns a ModelRegistry with all generated models registered.',
    )
    ..writeln('ModelRegistry buildOrmRegistryWithFactories() {')
    ..writeln('  registerOrmFactories();')
    ..writeln('  return buildOrmRegistry();')
    ..writeln('}');

  // Generate event handler registration if any model declares handlers
  final handlerModels = summaries
      .where((summary) => summary.hasEventHandlers)
      .toList();
  buffer.writeln('');
  buffer.writeln('/// Registers generated model event handlers.');
  buffer.writeln('void registerModelEventHandlers({EventBus? bus}) {');
  if (handlerModels.isEmpty) {
    buffer.writeln('  // No model event handlers were generated.');
  } else {
    buffer.writeln('  final _bus = bus ?? EventBus.instance;');
    for (final summary in handlerModels) {
      buffer.writeln('  register${summary.className}EventHandlers(_bus);');
    }
  }
  buffer.writeln('}');

  // Scope registration if any scopes exist.
  final scopeModels = summaries.where((summary) => summary.hasScopes).toList();
  buffer.writeln('');
  buffer.writeln(
    '/// Registers generated model scopes into a [ScopeRegistry].',
  );
  buffer.writeln('void registerModelScopes({ScopeRegistry? scopeRegistry}) {');
  if (scopeModels.isEmpty) {
    buffer.writeln('  // No model scopes were generated.');
  } else {
    buffer.writeln('  final _registry = scopeRegistry ?? ScopeRegistry.instance;');
    for (final summary in scopeModels) {
      buffer.writeln('  register${summary.className}Scopes(_registry);');
    }
  }
  buffer.writeln('}');

  // Unified bootstrap helper
  buffer.writeln('');
  buffer.writeln(
    '/// Bootstraps generated ORM pieces: registry, factories, event handlers, and scopes.',
  );
  buffer.writeln(
    'ModelRegistry bootstrapOrm({ModelRegistry? registry, EventBus? bus, ScopeRegistry? scopes, bool registerFactories = true, bool registerEventHandlers = true, bool registerScopes = true}) {',
  );
  buffer.writeln('  final reg = registry ?? buildOrmRegistry();');
  buffer.writeln('  if (registerFactories) {');
  buffer.writeln('    registerOrmFactories();');
  buffer.writeln('  }');
  buffer.writeln('  if (registerEventHandlers) {');
  buffer.writeln('    registerModelEventHandlers(bus: bus);');
  buffer.writeln('  }');
  buffer.writeln('  if (registerScopes) {');
  buffer.writeln('    registerModelScopes(scopeRegistry: scopes);');
  buffer.writeln('  }');
  buffer.writeln('  return reg;');
  buffer.writeln('}');

  return buffer.toString();
}

class ModelSummary {
  ModelSummary({
    required this.className,
    required this.importPath,
    required this.definition,
    required this.hasFactory,
    required this.hasEventHandlers,
    required this.hasScopes,
  });

  final String className;
  final String importPath;
  final String definition;
  final bool hasFactory;
  final bool hasEventHandlers;
  final bool hasScopes;
}
