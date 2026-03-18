import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

Builder ormRegistryBuilder(BuilderOptions options) =>
    _OrmRegistryBuilder(options);

class _OrmRegistryBuilder implements Builder {
  static final _ormPartGlob = Glob('lib/**.orm.dart');

  _OrmRegistryBuilder(BuilderOptions options)
    : outputPath =
          (options.config['output'] as String?)?.trim() ??
          'lib/src/database/orm_registry.g.dart' {
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
    final summariesByKey = <String, ModelSummary>{};
    await for (final asset in buildStep.findAssets(_ormPartGlob)) {
      final content = await buildStep.readAsString(asset);
      final importPath = _inferImportPath(asset.path, content);
      if (importPath == null || importPath.isEmpty) {
        continue;
      }

      final factoryCapableModels = _inferFactoryCapableModels(content);
      final eventHandlerModels = _inferEventHandlerModels(content);
      final scopeModels = _inferScopeModels(content);

      for (final entry in _inferOrmDefinitions(content)) {
        final className = entry.className;
        final definition = '${entry.extensionName}.definition';
        final key = '$importPath::$className';
        summariesByKey.putIfAbsent(
          key,
          () => ModelSummary(
            className: className,
            importPath: importPath,
            definition: definition,
            hasFactory: factoryCapableModels.contains(className),
            hasEventHandlers: eventHandlerModels.contains(className),
            hasScopes: scopeModels.contains(className),
          ),
        );
      }
    }

    final content = renderRegistryContent(
      summariesByKey.values.toList(),
      packageName: buildStep.inputId.package,
    );
    final outputId = AssetId(buildStep.inputId.package, outputPath);
    await buildStep.writeAsString(outputId, content);
  }
}

String? _inferImportPath(String ormPartPath, String content) {
  final partOfMatch = RegExp(
    r"""part of\s+['"]([^'"]+)['"]\s*;""",
  ).firstMatch(content);
  if (partOfMatch == null) return null;

  final partOfUri = partOfMatch.group(1);
  if (partOfUri == null || partOfUri.isEmpty) return null;

  final dir = p.posix.dirname(ormPartPath);
  final libraryAssetPath = p.posix.normalize(p.posix.join(dir, partOfUri));
  if (!libraryAssetPath.startsWith('lib/')) return null;
  return libraryAssetPath.substring('lib/'.length);
}

Iterable<_OrmDefinitionEntry> _inferOrmDefinitions(String content) sync* {
  final re = RegExp(r'extension\s+([A-Za-z0-9_]+)\s+on\s+([A-Za-z0-9_]+)\s*\{');
  for (final match in re.allMatches(content)) {
    final extensionName = match.group(1);
    final className = match.group(2);
    if (extensionName == null ||
        className == null ||
        !extensionName.endsWith('OrmDefinition')) {
      continue;
    }
    yield _OrmDefinitionEntry(
      extensionName: extensionName,
      className: className,
    );
  }
}

Set<String> _inferFactoryCapableModels(String content) {
  final re = RegExp(r'ModelFactoryRegistry\.register<\$([A-Za-z0-9_]+)>\(');
  return {for (final m in re.allMatches(content)) m.group(1)!};
}

Set<String> _inferScopeModels(String content) {
  final re = RegExp(r'void\s+register([A-Za-z0-9_]+)Scopes\(');
  return {for (final m in re.allMatches(content)) m.group(1)!};
}

Set<String> _inferEventHandlerModels(String content) {
  final models = <String>{};
  final re = RegExp(
    r'void\s+register([A-Za-z0-9_]+)EventHandlers\s*\(\s*EventBus\s+bus\s*\)\s*\{',
  );
  for (final match in re.allMatches(content)) {
    final className = match.group(1);
    if (className == null) continue;
    final block = _extractBraceBlock(content, match.end - 1);
    if (block != null && block.contains('bus.on<')) {
      models.add(className);
    }
  }
  return models;
}

String? _extractBraceBlock(String source, int braceIndex) {
  if (braceIndex < 0 || braceIndex >= source.length) return null;
  if (source.codeUnitAt(braceIndex) != '{'.codeUnitAt(0)) {
    final next = source.indexOf('{', braceIndex);
    if (next == -1) return null;
    braceIndex = next;
  }

  var depth = 0;
  for (var i = braceIndex; i < source.length; i++) {
    final ch = source.codeUnitAt(i);
    if (ch == '{'.codeUnitAt(0)) {
      depth++;
      continue;
    }
    if (ch == '}'.codeUnitAt(0)) {
      depth--;
      if (depth == 0) {
        return source.substring(braceIndex, i + 1);
      }
    }
  }
  return null;
}

String renderRegistryContent(List<ModelSummary> models, {String? packageName}) {
  final summaries = List<ModelSummary>.from(models)
    ..sort((a, b) => a.className.compareTo(b.className));
  final uniqueImports = <String>{};
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// coverage:ignore-file')
    ..writeln("import 'package:ormed/ormed.dart';");

  for (final summary in summaries) {
    if (uniqueImports.add(summary.importPath)) {
      final importPath = packageName == null
          ? summary.importPath
          : 'package:$packageName/${summary.importPath}';
      buffer.writeln("import '$importPath';");
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
    buffer.writeln('  final busInstance = bus ?? EventBus.instance;');
    for (final summary in handlerModels) {
      buffer.writeln(
        '  register${summary.className}EventHandlers(busInstance);',
      );
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
    buffer.writeln(
      '  final scopeRegistryInstance = scopeRegistry ?? ScopeRegistry.instance;',
    );
    for (final summary in scopeModels) {
      buffer.writeln(
        '  register${summary.className}Scopes(scopeRegistryInstance);',
      );
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
  buffer.writeln('  if (registry != null) {');
  buffer.writeln('    reg.registerGeneratedModels();');
  buffer.writeln('  }');
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

class _OrmDefinitionEntry {
  const _OrmDefinitionEntry({
    required this.extensionName,
    required this.className,
  });
  final String extensionName;
  final String className;
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
