import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../config.dart';
import 'shared.dart';

class InitCommand extends Command<void> {
  /// For internal testing: allows running from a specific directory without changing CWD.
  @visibleForTesting
  Directory? workingDirectory;

  InitCommand() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Rebuild the scaffolding even if files already exist.',
      )
      ..addFlag(
        'paths',
        negatable: false,
        help: 'Print the canonical path for each scaffolded artifact.',
      )
      ..addMultiOption(
        'only',
        help:
            'Only scaffold selected artifacts (config, migrations, seeders, datasource, tests).',
        allowed: const [
          'config',
          'migrations',
          'seeders',
          'datasource',
          'tests',
        ],
        allowedHelp: const {
          'config': 'ormed.yaml configuration file',
          'migrations': 'Migrations directory + registry',
          'seeders': 'Seeders directory + registry',
          'datasource': 'DataSource entrypoint + code config',
          'tests': 'Sample test harness helper',
        },
      )
      // New: populate existing migrations/seeders into registries if present
      ..addFlag(
        'populate-existing',
        abbr: 'p',
        negatable: true,
        help:
            'Scan existing migrations/seeders and populate registries accordingly.',
      )
      ..addFlag(
        'skip-build',
        negatable: false,
        hide: true,
        help: 'Skip running build_runner (for testing).',
      )
      ..addFlag(
        'with-analyzer',
        negatable: false,
        help: 'Add the Ormed analyzer plugin to analysis_options.yaml.',
      )
      ..addFlag(
        'with-config',
        negatable: false,
        help:
            'Also scaffold ormed.yaml for migration/apply CLI commands. By default, init is code-first.',
      )
      ..addFlag(
        'with-seeders',
        negatable: false,
        help:
            'Also scaffold seeders directory + registry. By default, seed scaffolding is created lazily when needed.',
      )
      ..addFlag(
        'with-tests',
        negatable: false,
        help:
            'Also scaffold sample ORM test helper. By default, test helper scaffolding is opt-in.',
      );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize code-first database scaffolding with datasource + migrations.';

  @override
  Future<void> run() async {
    final force = argResults?['force'] == true;
    final showPaths = argResults?['paths'] == true;
    final populateExisting = argResults?['populate-existing'] == true;
    final skipBuild = argResults?['skip-build'] == true;
    final withAnalyzer = argResults?['with-analyzer'] == true;
    final withConfig = argResults?['with-config'] == true;
    final withSeeders = argResults?['with-seeders'] == true;
    final withTests = argResults?['with-tests'] == true;
    final onlyTargets =
        (argResults?['only'] as List<String>? ?? const <String>[])
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet();
    final restrictScaffold = onlyTargets.isNotEmpty;
    final includeConfig =
        onlyTargets.contains('config') || (!restrictScaffold && withConfig);
    final includeMigrations =
        !restrictScaffold || onlyTargets.contains('migrations');
    final includeSeeders =
        onlyTargets.contains('seeders') || (!restrictScaffold && withSeeders);
    final includeDatasource =
        !restrictScaffold ||
        onlyTargets.contains('datasource') ||
        onlyTargets.contains('tests');
    final includeTestHelpers =
        onlyTargets.contains('tests') || (!restrictScaffold && withTests);
    final root = findProjectRoot(workingDirectory);
    final tracker = _ArtifactTracker(root);
    final packageName = getPackageName(root);
    final configFile = File(p.join(root.path, 'ormed.yaml'));

    // If config exists, offer re-initialize
    if (includeConfig && !force) {
      final legacyFile = File(p.join(root.path, 'ormed.yaml'));

      if (configFile.existsSync()) {
        cliIO.writeln(
          cliIO.style.info('Project already initialized (ormed.yaml exists).'),
        );
        if (!io.confirm('Do you want to re-initialize (overwrite files)?')) {
          if (!populateExisting) return;
        }
      } else if (legacyFile.existsSync()) {
        cliIO.writeln(cliIO.style.warning('Found legacy ormed.yaml.'));
        if (io.confirm('Do you want to rename it to ormed.yaml?')) {
          legacyFile.renameSync(configFile.path);
          cliIO.success('Renamed ormed.yaml to ormed.yaml');
        }
      }
    }

    if (includeConfig) {
      _writeFile(
        file: configFile,
        content: defaultOrmYaml(packageName),
        label: 'ormed.yaml',
        force: force,
        tracker: tracker,
        interactive: true,
      );
    }

    if (includeConfig || includeDatasource) {
      // Create or update .env.example file
      _ensureEnvExample(
        root: root,
        packageName: packageName,
        force: force,
        tracker: tracker,
      );
    }

    // Load config
    final config = configFile.existsSync()
        ? loadOrmProjectConfig(configFile)
        : _defaultOrmProjectConfig(packageName, root);

    if (!skipBuild &&
        (includeDatasource || includeMigrations || includeSeeders)) {
      await _ensureDependencies(root, config: config, skipBuild: skipBuild);
    }
    if (withAnalyzer) {
      _ensureAnalyzerPluginConfig(root: root, tracker: tracker);
    }

    // Directories
    Directory? migrationsDir;
    Directory? seedersDir;
    File? registry;
    File? seedRegistry;
    Directory? schemaDumpDir;
    var hasExistingMigrations = false;
    var hasExistingSeeders = false;

    if (includeMigrations) {
      migrationsDir = Directory(resolvePath(root, config.migrations.directory));
      hasExistingMigrations = _hasDartFiles(migrationsDir);
      _ensureDirectory(migrationsDir, 'migrations directory', tracker);

      registry = File(resolvePath(root, config.migrations.registry));
      _writeFile(
        file: registry,
        content: initialRegistryTemplate,
        label: 'migrations registry',
        force: force,
        tracker: tracker,
        interactive: true,
      );

      // Ensure schema dump parent directory exists
      final schemaDumpPath = resolvePath(root, config.migrations.schemaDump);
      schemaDumpDir = Directory(p.dirname(schemaDumpPath));
      if (!schemaDumpDir.existsSync()) {
        schemaDumpDir.createSync(recursive: true);
        tracker.paths['schema_dir'] = schemaDumpDir.path;
      }
      final gitkeep = File(p.join(schemaDumpDir.path, '.gitkeep'));
      if (!gitkeep.existsSync()) {
        gitkeep.writeAsStringSync('');
      }
    }

    if (includeSeeders) {
      final seeds = config.seeds;
      if (seeds == null) {
        cliIO.warn(
          'No seeds configuration found in ormed.yaml. Skipping seed scaffolding.',
        );
      } else {
        seedersDir = Directory(resolvePath(root, seeds.directory));
        hasExistingSeeders = _hasDartFiles(seedersDir);
        _ensureDirectory(seedersDir, 'seeders directory', tracker);

        seedRegistry = File(resolvePath(root, seeds.registry));
        _writeFile(
          file: seedRegistry,
          content: initialSeedRegistryTemplate.replaceAll(
            '{{package_name}}',
            packageName,
          ),
          label: 'seeders registry',
          force: force,
          tracker: tracker,
          interactive: true,
        );

        final defaultSeeder = File(
          p.join(seedersDir.path, 'database_seeder.dart'),
        );
        _writeFile(
          file: defaultSeeder,
          content: _defaultSeederTemplate,
          label: 'database seeder',
          force: force,
          tracker: tracker,
          interactive: true,
        );
      }
    }

    if (includeDatasource) {
      final datasourceFile = File(
        p.join(root.path, 'lib', 'src', 'database', 'datasource.dart'),
      );
      final databaseConfigFile = File(
        p.join(root.path, 'lib', 'src', 'database', 'config.dart'),
      );

      final driverTypes = config.connections.values
          .map((c) => c.driver.type.toLowerCase())
          .toSet();
      final driverImports = driverTypes
          .map((type) => _driverPackageMapping[type])
          .where((pkg) => pkg != null)
          .map((pkg) => "import 'package:$pkg/$pkg.dart';")
          .join('\n');

      _writeFile(
        file: databaseConfigFile,
        content: _databaseConfigTemplate(
          config: config,
          packageName: packageName,
          driverImports: driverImports,
        ),
        label: 'DataSource config',
        force: force,
        tracker: tracker,
        interactive: true,
      );

      _writeFile(
        file: datasourceFile,
        content: _dataSourceTemplate(config: config),
        label: 'DataSource entrypoint',
        force: force,
        tracker: tracker,
        interactive: true,
      );
    }

    if (includeTestHelpers) {
      final testHelperFile = File(
        p.join(root.path, 'lib', 'test', 'helpers', 'ormed_test_helper.dart'),
      );
      _writeFile(
        file: testHelperFile,
        content: _testHelperTemplate(config: config, packageName: packageName),
        label: 'test helper',
        force: force,
        tracker: tracker,
        interactive: true,
      );
    }

    // Populate existing artifacts into registries
    if (populateExisting && (includeMigrations || includeSeeders)) {
      await _populateExisting(
        io: cliIO,
        root: root,
        config: config,
        packageName: packageName,
        migrationsDir: migrationsDir,
        seedersDir: seedersDir,
        registryFile: registry,
        seedRegistryFile: seedRegistry,
        includeMigrations: includeMigrations,
        includeSeeders: includeSeeders,
      );
    } else {
      // If not explicitly requested, check whether dirs contain files and prompt
      if (hasExistingMigrations || hasExistingSeeders) {
        cliIO.section('Existing artifacts detected');
        if (hasExistingMigrations && migrationsDir != null) {
          cliIO.writeln(
            '• Found existing migrations in ${tracker.relative(migrationsDir.path)}',
          );
        }
        if (hasExistingSeeders && seedersDir != null) {
          cliIO.writeln(
            '• Found existing seeders in ${tracker.relative(seedersDir.path)}',
          );
        }
        // When forcing scaffold recreation, do not auto-populate unless
        // explicitly requested via --populate-existing.
        final shouldPopulate = force
            ? false
            : io.confirm(
                'Do you want to populate registries from existing files?',
              );
        if (shouldPopulate) {
          await _populateExisting(
            io: cliIO,
            root: root,
            config: config,
            packageName: packageName,
            migrationsDir: migrationsDir,
            seedersDir: seedersDir,
            registryFile: registry,
            seedRegistryFile: seedRegistry,
            includeMigrations: includeMigrations,
            includeSeeders: includeSeeders,
          );
        }
      }
    }

    cliIO.newLine();
    if (includeMigrations && schemaDumpDir != null) {
      cliIO.components.horizontalTable({
        'Ledger table': config.migrations.ledgerTable,
        'Schema dump directory': p.relative(
          schemaDumpDir.path,
          from: root.path,
        ),
      });
    }

    if (showPaths) {
      cliIO.section('Scaffolded artifact paths');
      cliIO.components.horizontalTable(
        tracker.paths.map((k, v) => MapEntry(k, tracker.relative(v))),
      );
    }

    // Run build_runner to generate src/database/orm_registry.g.dart
    final shouldBuild =
        !skipBuild &&
        (includeDatasource || includeMigrations || includeSeeders);
    if (shouldBuild) {
      await _runBuildRunner(root);
    }

    cliIO.newLine();
    cliIO.success('Project initialized successfully.');
    _printNextSteps(
      withAnalyzer: withAnalyzer,
      includeSeeders: includeSeeders,
      includeTestHelpers: includeTestHelpers,
    );
  }

  Future<void> _runBuildRunner(Directory root) async {
    // Check if build_runner is available by looking at pubspec.lock
    final pubspecLock = File(p.join(root.path, 'pubspec.lock'));
    if (!pubspecLock.existsSync()) {
      // No lock file means deps not installed - run pub get first
      cliIO.newLine();
      cliIO.section('Installing Dependencies');
      cliIO.writeln('Running dart pub get...');
      final pubGetResult = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: root.path);
      if (pubGetResult.exitCode != 0) {
        cliIO.writeln(
          cliIO.style.warning(
            'Failed to install dependencies. Run: dart pub get',
          ),
        );
        return;
      }
      cliIO.success('Dependencies installed.');
    }

    cliIO.newLine();
    cliIO.section('Code Generation');
    cliIO.writeln('Running build_runner to generate ORM registry...');

    final result = await Process.run('dart', [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], workingDirectory: root.path);

    if (result.exitCode == 0) {
      cliIO.success('Code generation completed.');
    } else {
      cliIO.writeln(
        cliIO.style.warning(
          'Code generation had issues (exit code ${result.exitCode}). '
          'You may need to run: dart run build_runner build',
        ),
      );
      if ((result.stderr as String).isNotEmpty) {
        cliIO.writeln(cliIO.style.muted(result.stderr.toString().trim()));
      }
    }
  }

  Future<void> _ensureDependencies(
    Directory root, {
    OrmProjectConfig? config,
    bool skipBuild = false,
  }) async {
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    final deps = pubspec['dependencies'] as YamlMap?;
    final devDeps = pubspec['dev_dependencies'] as YamlMap?;
    final overrides = pubspec['dependency_overrides'] as YamlMap?;

    bool hasPackage(String name) =>
        (deps?.containsKey(name) ?? false) ||
        (devDeps?.containsKey(name) ?? false) ||
        (overrides?.containsKey(name) ?? false);

    final hasOrmed = hasPackage('ormed');
    final hasOrmedCli = hasPackage('ormed_cli');
    final hasBuildRunner = hasPackage('build_runner');

    final missingDrivers = <String>[];
    if (config != null) {
      final driverTypes = config.connections.values
          .map((c) => c.driver.type)
          .toSet();
      for (final type in driverTypes) {
        final pkg = _driverPackageMapping[type.toLowerCase()];
        if (pkg != null && !hasPackage(pkg)) {
          missingDrivers.add(pkg);
        }
      }
    }

    if (!hasOrmed ||
        !hasOrmedCli ||
        !hasBuildRunner ||
        missingDrivers.isNotEmpty) {
      cliIO.newLine();
      cliIO.section('Dependencies');
      if (io.confirm(
        'Do you want to add missing ormed dependencies to pubspec.yaml?',
      )) {
        if (!hasOrmed) {
          cliIO.writeln('• Adding ormed to dependencies...');
          await Process.run('dart', [
            'pub',
            'add',
            'ormed',
          ], workingDirectory: root.path);
        }

        for (final pkg in missingDrivers) {
          cliIO.writeln('• Adding $pkg to dependencies...');
          await Process.run('dart', [
            'pub',
            'add',
            pkg,
          ], workingDirectory: root.path);
        }

        final devToAdd = <String>[];
        if (!hasOrmedCli) devToAdd.add('ormed_cli');
        if (!hasBuildRunner) devToAdd.add('build_runner');

        if (devToAdd.isNotEmpty) {
          cliIO.writeln(
            '• Adding ${devToAdd.join(', ')} to dev_dependencies...',
          );
          await Process.run('dart', [
            'pub',
            'add',
            '--dev',
            ...devToAdd,
          ], workingDirectory: root.path);
        }
        cliIO.success('Dependencies updated.');
      }
    }
  }

  /// Ensures a .env.example file exists and optionally updates existing .env
  void _ensureEnvExample({
    required Directory root,
    required String packageName,
    required bool force,
    required _ArtifactTracker tracker,
  }) {
    final envExampleFile = File(p.join(root.path, '.env.example'));
    final envFile = File(p.join(root.path, '.env'));
    final envExampleContent = defaultEnvExample(packageName);

    // Write .env.example
    _writeFile(
      file: envExampleFile,
      content: envExampleContent,
      label: '.env.example',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    // Check if .env exists and offer to update it
    if (envFile.existsSync()) {
      final existingContent = envFile.readAsStringSync();
      final newVars = _extractEnvVariables(envExampleContent);
      final existingVars = _extractEnvVariables(existingContent);
      final missingVars = newVars
          .where((v) => !existingVars.contains(v))
          .toList();

      if (missingVars.isNotEmpty) {
        cliIO.writeln(
          cliIO.style.info(
            'Found existing .env file with ${missingVars.length} new variable(s) available.',
          ),
        );
        if (io.confirm('Do you want to append missing variables to .env?')) {
          final varsToAppend = missingVars
              .map((varName) {
                // Find the line from .env.example for this variable
                final lines = envExampleContent.split('\n');
                final varLine = lines.firstWhere(
                  (line) =>
                      line.trim().startsWith('$varName=') ||
                      line.trim().startsWith('# $varName='),
                  orElse: () => '$varName=',
                );
                return varLine;
              })
              .join('\n');

          final separator = existingContent.trim().isEmpty
              ? ''
              : (existingContent.endsWith('\n') ? '\n' : '\n\n');
          envFile.writeAsStringSync(
            '$separator# Added by ormed init\n$varsToAppend\n',
            mode: FileMode.append,
          );
          cliIO.success(
            'Updated .env with ${missingVars.length} new variable(s): ${missingVars.join(', ')}',
          );
        }
      } else {
        cliIO.writeln(
          '${cliIO.style.foreground(Colors.muted).render('○')} .env already contains all variables',
        );
      }
    } else {
      cliIO.writeln(
        cliIO.style.info(
          'Tip: Copy .env.example to .env and configure your environment variables.',
        ),
      );
    }
  }

  /// Extract variable names from env file content (both commented and uncommented)
  Set<String> _extractEnvVariables(String content) {
    final varPattern = RegExp(r'^#?\s*([A-Z_][A-Z0-9_]*)=', multiLine: true);
    return varPattern
        .allMatches(content)
        .map((match) => match.group(1)!)
        .where((name) => !name.startsWith('#'))
        .toSet();
  }
}

void _printNextSteps({
  required bool withAnalyzer,
  required bool includeSeeders,
  required bool includeTestHelpers,
}) {
  cliIO.newLine();
  cliIO.section('Next steps');
  cliIO.writeln('• Configure runtime DB in `lib/src/database/config.dart`');
  cliIO.writeln('• Add models and include `part \'<model>.orm.dart\';`');
  cliIO.writeln('• Run: dart run build_runner build');
  if (!includeSeeders) {
    cliIO.writeln(
      '• Optional: scaffold seed registry when needed with `ormed init --only=seeders`',
    );
  }
  if (!includeTestHelpers) {
    cliIO.writeln(
      '• Optional: scaffold test helper with `ormed init --only=tests`',
    );
  }
  cliIO.writeln(
    '• Optional for custom/multi-connection CLI flows: run `ormed init --only=config` to scaffold ormed.yaml',
  );
  if (withAnalyzer) {
    cliIO.writeln('• Restart your analyzer to pick up the Ormed plugin');
  }
}

void _ensureAnalyzerPluginConfig({
  required Directory root,
  required _ArtifactTracker tracker,
}) {
  final file = File(p.join(root.path, 'analysis_options.yaml'));
  final pluginLine = '- ormed';
  if (!file.existsSync()) {
    file.writeAsStringSync('analyzer:\n  plugins:\n    $pluginLine\n');
    tracker.paths['analysis_options.yaml'] = file.path;
    return;
  }

  final lines = file.readAsLinesSync();
  if (lines.any((line) => line.trim() == pluginLine)) {
    return;
  }

  int analyzerIndex = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() == 'analyzer:') {
      analyzerIndex = i;
      break;
    }
  }

  if (analyzerIndex == -1) {
    lines.add('');
    lines.add('analyzer:');
    lines.add('  plugins:');
    lines.add('    $pluginLine');
    file.writeAsStringSync(lines.join('\n'));
    return;
  }

  int pluginsIndex = -1;
  for (var i = analyzerIndex + 1; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.endsWith(':') && !trimmed.startsWith('plugins:')) {
      break;
    }
    if (trimmed == 'plugins:') {
      pluginsIndex = i;
      break;
    }
  }

  if (pluginsIndex == -1) {
    lines.insert(analyzerIndex + 1, '  plugins:');
    lines.insert(analyzerIndex + 2, '    $pluginLine');
    file.writeAsStringSync(lines.join('\n'));
    return;
  }

  lines.insert(pluginsIndex + 1, '    $pluginLine');
  file.writeAsStringSync(lines.join('\n'));
}

String _dataSourceTemplate({required OrmProjectConfig config}) {
  final perConnection = _buildPerConnectionDataSourceHelpers(config);
  return '''
import 'package:ormed/ormed.dart';
import 'config.dart';

/// Creates a new DataSource using driver-specific helper options.
DataSource createDataSource({
  DataSourceOptions? options,
  String? connection,
}) {
  return DataSource(
    options ?? buildDataSourceOptions(connection: connection),
  );
}

/// Creates DataSources for every generated connection.
Map<String, DataSource> createDataSources({
  Map<String, DataSourceOptions> overrides = const {},
}) {
  final sources = <String, DataSource>{};
  for (final connection in generatedDataSourceConnections) {
    final options =
        overrides[connection] ??
        buildDataSourceOptions(connection: connection);
    sources[connection] = DataSource(options);
  }
  return sources;
}

$perConnection
''';
}

String _testHelperTemplate({
  required OrmProjectConfig config,
  required String packageName,
}) {
  final perConnectionConfigs = _buildPerConnectionTestConfigHelpers(config);
  final perConnectionConnections = _buildPerConnectionTestConnectionHelpers(
    config,
  );
  final supportedConnections = config.connections.keys
      .map(_dartStringLiteral)
      .join(', ');
  final singleConnectionName = config.connections.length == 1
      ? _dartStringLiteral(config.connections.keys.first)
      : null;
  final unknownConnectionError = singleConnectionName == null
      ? 'Unknown generated datasource connection. Expected one of: $supportedConnections'
      : 'Generated test helper has a single datasource connection: $singleConnectionName';

  return '''
import 'package:ormed/ormed.dart';
import 'package:$packageName/src/database/config.dart';
import 'package:$packageName/src/database/datasource.dart';

final Map<String, DataSource> _generatedTestDataSources =
    <String, DataSource>{};

final Map<String, OrmedTestConfig> _generatedTestConfigs =
    <String, OrmedTestConfig>{};

DataSource _ensureGeneratedTestDataSource(String connection) {
  final existing = _generatedTestDataSources[connection];
  if (existing != null) {
    return existing;
  }
  final created = createDataSource(connection: connection);
  _generatedTestDataSources[connection] = created;
  return created;
}

OrmedTestConfig _ensureGeneratedTestConfig(String connection) {
  final existing = _generatedTestConfigs[connection];
  if (existing != null) {
    return existing;
  }
  final created = setUpOrmed(
    dataSource: _ensureGeneratedTestDataSource(connection),
    migrations: const [_CreateTestUsersTable()],
  );
  _generatedTestConfigs[connection] = created;
  return created;
}

OrmedTestConfig testConfig({String? connection}) {
  final selectedConnection = (connection ?? defaultDataSourceConnection).trim();
  final selectedConfig = _generatedTestConfigs[selectedConnection];
  if (selectedConfig == null) {
    if (!generatedDataSourceConnections.contains(selectedConnection)) {
      throw ArgumentError.value(
        selectedConnection,
        'connection',
        '$unknownConnectionError',
      );
    }
    return _ensureGeneratedTestConfig(selectedConnection);
  }
  return selectedConfig;
}

OrmConnection testConnection({String? connection}) {
  final selectedConnection = (connection ?? defaultDataSourceConnection).trim();
  if (!_generatedTestConfigs.containsKey(selectedConnection)) {
    if (!generatedDataSourceConnections.contains(selectedConnection)) {
      throw ArgumentError.value(
        selectedConnection,
        'connection',
        '$unknownConnectionError',
      );
    }
    _ensureGeneratedTestConfig(selectedConnection);
  }
  return ConnectionManager.instance.connection(selectedConnection);
}

$perConnectionConfigs

$perConnectionConnections

class _CreateTestUsersTable extends Migration {
  const _CreateTestUsersTable();

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('users', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('email').unique();
      table.string('name');
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('users', ifExists: true);
  }
}
''';
}

String _databaseConfigTemplate({
  required OrmProjectConfig config,
  required String packageName,
  required String driverImports,
}) {
  final optionsBuilder = _buildDataSourceOptionsSwitch(
    config: config,
    packageName: packageName,
  );
  final envParseHelpers = _buildGeneratedEnvParseHelpers(config);
  final perConnectionHelpers = _buildPerConnectionOptionsHelpers(config);
  final defaultConnectionName = _dartStringLiteral(config.connectionName);
  final generatedConnections = config.connections.keys
      .map((name) => "  '${_dartStringLiteral(name)}',")
      .join('\n');
  return '''
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:$packageName/src/database/orm_registry.g.dart';
${driverImports.isEmpty ? '' : '$driverImports\n'}

/// Code-first runtime DataSource configuration used by [createDataSource].
///
/// Keep `ormed.yaml` for CLI migration/seed workflows when needed.
const String defaultDataSourceConnection = '$defaultConnectionName';

/// Connections baked into this generated scaffold.
const List<String> generatedDataSourceConnections = <String>[
$generatedConnections
];

DataSourceOptions buildDataSourceOptions({String? connection}) {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = bootstrapOrm();
$optionsBuilder
}

/// Builds DataSource options for all generated connections.
Map<String, DataSourceOptions> buildAllDataSourceOptions() {
  final options = <String, DataSourceOptions>{};
  for (final connection in generatedDataSourceConnections) {
    options[connection] = buildDataSourceOptions(connection: connection);
  }
  return options;
}

$envParseHelpers

$perConnectionHelpers
''';
}

const Map<String, String> _driverPackageMapping = {
  'sqlite': 'ormed_sqlite',
  'd1': 'ormed_d1',
  'mysql': 'ormed_mysql',
  'mariadb': 'ormed_mysql',
  'postgres': 'ormed_postgres',
  'postgresql': 'ormed_postgres',
};

String _buildGeneratedEnvParseHelpers(OrmProjectConfig config) {
  final driverTypes = config.connections.values
      .map((connection) => connection.driver.type.trim().toLowerCase())
      .toSet();

  final needsIntParse = driverTypes.any(
    (driver) => const {
      'd1',
      'postgres',
      'postgresql',
      'mysql',
      'mariadb',
    }.contains(driver),
  );
  final needsBoolParse = driverTypes.any(
    (driver) => const {'d1', 'mysql', 'mariadb'}.contains(driver),
  );

  if (!needsIntParse && !needsBoolParse) {
    return '';
  }

  final buffer = StringBuffer();
  if (needsIntParse) {
    buffer
      ..writeln('int _parseIntEnv(String? value, {required int fallback}) {')
      ..writeln('  if (value == null || value.trim().isEmpty) {')
      ..writeln('    return fallback;')
      ..writeln('  }')
      ..writeln('  return int.tryParse(value.trim()) ?? fallback;')
      ..writeln('}')
      ..writeln();
  }

  if (needsBoolParse) {
    buffer
      ..writeln('bool _parseBoolEnv(String? value, {required bool fallback}) {')
      ..writeln('  if (value == null || value.trim().isEmpty) {')
      ..writeln('    return fallback;')
      ..writeln('  }')
      ..writeln('  final normalized = value.trim().toLowerCase();')
      ..writeln("  if (normalized == '1' ||")
      ..writeln("      normalized == 'true' ||")
      ..writeln("      normalized == 'yes' ||")
      ..writeln("      normalized == 'on' ||")
      ..writeln("      normalized == 'require') {")
      ..writeln('    return true;')
      ..writeln('  }')
      ..writeln("  if (normalized == '0' ||")
      ..writeln("      normalized == 'false' ||")
      ..writeln("      normalized == 'no' ||")
      ..writeln("      normalized == 'off' ||")
      ..writeln("      normalized == 'disable') {")
      ..writeln('    return false;')
      ..writeln('  }')
      ..writeln('  return fallback;')
      ..writeln('}')
      ..writeln();
  }

  return buffer.toString().trimRight();
}

OrmProjectConfig _defaultOrmProjectConfig(String packageName, Directory root) {
  final env = OrmedEnvironment.fromDirectory(root);
  final template = defaultOrmYaml(packageName);
  final expanded = env.interpolate(template);
  final yaml = loadYaml(expanded) as YamlMap;
  return OrmProjectConfig.fromYaml(yaml);
}

String _buildDataSourceOptionsSwitch({
  required OrmProjectConfig config,
  required String packageName,
}) {
  final selectedConnectionLine =
      "  final selectedConnection = (connection ?? defaultDataSourceConnection).trim();";
  if (config.connections.length == 1) {
    final entry = config.connections.entries.first;
    final connectionName = _dartStringLiteral(entry.key);
    final caseBody = _buildConnectionDataSourceOptionsBuilder(
      driverConfig: entry.value.driver,
      connectionName: entry.key,
      packageName: packageName,
      isDefaultConnection: entry.key == config.activeConnectionName,
    );
    final buffer = StringBuffer()
      ..writeln(selectedConnectionLine)
      ..writeln("  if (selectedConnection != '$connectionName') {")
      ..writeln('    throw ArgumentError.value(')
      ..writeln('      selectedConnection,')
      ..writeln("      'connection',")
      ..writeln(
        "      'Generated scaffold has a single datasource connection: $connectionName',",
      )
      ..writeln('    );')
      ..writeln('  }');
    for (final line in caseBody.split('\n')) {
      if (line.trim().isEmpty) {
        buffer.writeln('');
      } else {
        buffer.writeln('  $line');
      }
    }
    return buffer.toString().trimRight();
  }

  final buffer = StringBuffer()
    ..writeln(selectedConnectionLine)
    ..writeln('  switch (selectedConnection) {');

  for (final entry in config.connections.entries) {
    final connectionName = _dartStringLiteral(entry.key);
    final caseBody = _buildConnectionDataSourceOptionsBuilder(
      driverConfig: entry.value.driver,
      connectionName: entry.key,
      packageName: packageName,
      isDefaultConnection: entry.key == config.activeConnectionName,
    );

    buffer.writeln("    case '$connectionName':");
    for (final line in caseBody.split('\n')) {
      if (line.trim().isEmpty) {
        buffer.writeln('');
      } else {
        buffer.writeln('      $line');
      }
    }
  }

  final supported = config.connections.keys
      .map((name) => _dartStringLiteral(name))
      .join(', ');

  buffer
    ..writeln('    default:')
    ..writeln('      throw ArgumentError.value(')
    ..writeln("        selectedConnection,")
    ..writeln("        'connection',")
    ..writeln(
      "        'Unknown generated datasource connection. Expected one of: $supported',",
    )
    ..writeln('      );')
    ..writeln('  }');

  return buffer.toString().trimRight();
}

String _buildConnectionDataSourceOptionsBuilder({
  required DriverConfig driverConfig,
  required String connectionName,
  required String packageName,
  required bool isDefaultConnection,
}) {
  final driver = driverConfig.type.trim().toLowerCase();
  final safeConnectionName = _dartStringLiteral(connectionName);
  final scopedPathKey = dbConnectionEnvKey(connectionName, 'PATH');
  switch (driver) {
    case 'sqlite':
      final defaultPath =
          driverConfig.option('database') ?? 'database/$packageName.sqlite';
      final pathExpr =
          "${_envLookupExpression(scopedKeys: [scopedPathKey], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_PATH'])} ?? '${_dartStringLiteral(defaultPath)}'";
      return "final path = $pathExpr;\n"
          "return registry.sqliteFileDataSourceOptions(path: path, name: '$safeConnectionName');";
    case 'd1':
      final defaultAccountId = _firstDriverOption(driverConfig, const [
        'accountId',
        'account_id',
      ]);
      final defaultDatabaseId = _firstDriverOption(driverConfig, const [
        'databaseId',
        'database_id',
      ]);
      final defaultApiToken = _firstDriverOption(driverConfig, const [
        'apiToken',
        'api_token',
        'token',
      ]);
      final defaultBaseUrl =
          _firstDriverOption(driverConfig, const ['baseUrl', 'base_url']) ??
          'https://api.cloudflare.com/client/v4';
      final defaultMaxAttempts = _firstDriverIntOption(driverConfig, const [
        'maxAttempts',
        'max_attempts',
        'retryAttempts',
      ], fallback: 5);
      final defaultRequestTimeoutMs = _firstDriverIntOption(
        driverConfig,
        const ['requestTimeoutMs', 'request_timeout_ms', 'timeoutMs'],
        fallback: 30000,
      );
      final defaultRetryBaseDelayMs = _firstDriverIntOption(
        driverConfig,
        const ['retryBaseDelayMs', 'retry_base_delay_ms'],
        fallback: 250,
      );
      final defaultRetryMaxDelayMs = _firstDriverIntOption(driverConfig, const [
        'retryMaxDelayMs',
        'retry_max_delay_ms',
      ], fallback: 3000);
      final defaultDebugLog = _firstDriverBoolOption(driverConfig, const [
        'debugLog',
        'debug_log',
        'debug',
      ], fallback: false);
      final accountExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'D1_ACCOUNT_ID'), dbConnectionEnvKey(connectionName, 'CF_ACCOUNT_ID')], isDefaultConnection: isDefaultConnection, globalKeys: const ['D1_ACCOUNT_ID', 'CF_ACCOUNT_ID', 'DB_D1_ACCOUNT_ID'])} ?? ${_nullableDartStringLiteral(defaultAccountId)}";
      final databaseExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'D1_DATABASE_ID')], isDefaultConnection: isDefaultConnection, globalKeys: const ['D1_DATABASE_ID', 'DB_D1_DATABASE_ID'])} ?? ${_nullableDartStringLiteral(defaultDatabaseId)}";
      final tokenExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'D1_API_TOKEN'), dbConnectionEnvKey(connectionName, 'D1_SECRET')], isDefaultConnection: isDefaultConnection, globalKeys: const ['D1_API_TOKEN', 'D1_SECRET', 'DB_D1_API_TOKEN'])} ?? ${_nullableDartStringLiteral(defaultApiToken)}";
      final baseUrlExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'D1_BASE_URL')], isDefaultConnection: isDefaultConnection, globalKeys: const ['D1_BASE_URL', 'DB_D1_BASE_URL'])} ?? '${_dartStringLiteral(defaultBaseUrl)}'";
      final maxAttemptsExpr = _envLookupExpression(
        scopedKeys: [dbConnectionEnvKey(connectionName, 'D1_RETRY_ATTEMPTS')],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['D1_RETRY_ATTEMPTS', 'DB_D1_RETRY_ATTEMPTS'],
      );
      final timeoutExpr = _envLookupExpression(
        scopedKeys: [
          dbConnectionEnvKey(connectionName, 'D1_REQUEST_TIMEOUT_MS'),
        ],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['D1_REQUEST_TIMEOUT_MS', 'DB_D1_REQUEST_TIMEOUT_MS'],
      );
      final retryBaseExpr = _envLookupExpression(
        scopedKeys: [
          dbConnectionEnvKey(connectionName, 'D1_RETRY_BASE_DELAY_MS'),
        ],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const [
          'D1_RETRY_BASE_DELAY_MS',
          'DB_D1_RETRY_BASE_DELAY_MS',
        ],
      );
      final retryMaxExpr = _envLookupExpression(
        scopedKeys: [
          dbConnectionEnvKey(connectionName, 'D1_RETRY_MAX_DELAY_MS'),
        ],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['D1_RETRY_MAX_DELAY_MS', 'DB_D1_RETRY_MAX_DELAY_MS'],
      );
      final debugExpr = _envLookupExpression(
        scopedKeys: [dbConnectionEnvKey(connectionName, 'D1_DEBUG_LOG')],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['D1_DEBUG_LOG', 'DB_D1_DEBUG_LOG'],
      );
      return "final accountId = $accountExpr;\n"
          "final databaseId = $databaseExpr;\n"
          "final apiToken = $tokenExpr;\n"
          "if (accountId == null || accountId.trim().isEmpty || databaseId == null || databaseId.trim().isEmpty || apiToken == null || apiToken.trim().isEmpty) {\n"
          "  throw ArgumentError('Missing D1 credentials for connection \"$safeConnectionName\". Configure scoped DB_* vars for this connection or set driver defaults in config.');\n"
          "}\n"
          "final maxAttempts = _parseIntEnv($maxAttemptsExpr, fallback: $defaultMaxAttempts);\n"
          "final requestTimeoutMs = _parseIntEnv($timeoutExpr, fallback: $defaultRequestTimeoutMs);\n"
          "final retryBaseDelayMs = _parseIntEnv($retryBaseExpr, fallback: $defaultRetryBaseDelayMs);\n"
          "final retryMaxDelayMs = _parseIntEnv($retryMaxExpr, fallback: $defaultRetryMaxDelayMs);\n"
          "final debugLog = _parseBoolEnv($debugExpr, fallback: ${defaultDebugLog ? 'true' : 'false'});\n"
          "return registry.d1DataSourceOptions(\n"
          "  name: '$safeConnectionName',\n"
          "  accountId: accountId.trim(),\n"
          "  databaseId: databaseId.trim(),\n"
          "  apiToken: apiToken.trim(),\n"
          "  baseUrl: $baseUrlExpr,\n"
          "  maxAttempts: maxAttempts,\n"
          "  requestTimeoutMs: requestTimeoutMs,\n"
          "  retryBaseDelayMs: retryBaseDelayMs,\n"
          "  retryMaxDelayMs: retryMaxDelayMs,\n"
          "  debugLog: debugLog,\n"
          ");";
    case 'postgres':
    case 'postgresql':
      final defaultUrl = _firstDriverOption(driverConfig, const [
        'url',
        'database_url',
      ]);
      final defaultHost =
          _firstDriverOption(driverConfig, const ['host']) ?? 'localhost';
      final defaultPort = _firstDriverIntOption(driverConfig, const [
        'port',
      ], fallback: 5432);
      final defaultDatabase =
          _firstDriverOption(driverConfig, const ['database']) ?? 'postgres';
      final defaultUsername =
          _firstDriverOption(driverConfig, const ['username']) ?? 'postgres';
      final defaultPassword = _firstDriverOption(driverConfig, const [
        'password',
      ]);
      final defaultSslMode =
          _firstDriverOption(driverConfig, const ['sslmode']) ?? 'disable';
      final defaultTimezone =
          _firstDriverOption(driverConfig, const ['timezone']) ?? 'UTC';
      final defaultAppName = _firstDriverOption(driverConfig, const [
        'applicationName',
        'application_name',
      ]);
      final urlExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'URL')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_URL', 'DATABASE_URL'])} ?? ${_nullableDartStringLiteral(defaultUrl)}";
      final hostExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'HOST')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_HOST'])} ?? '${_dartStringLiteral(defaultHost)}'";
      final portExpr = _envLookupExpression(
        scopedKeys: [dbConnectionEnvKey(connectionName, 'PORT')],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['DB_PORT'],
      );
      final databaseExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'NAME')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_NAME'])} ?? '${_dartStringLiteral(defaultDatabase)}'";
      final usernameExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'USER')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_USER'])} ?? '${_dartStringLiteral(defaultUsername)}'";
      final passwordExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'PASSWORD')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_PASSWORD'])} ?? ${_nullableDartStringLiteral(defaultPassword)}";
      final sslModeExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'SSLMODE')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_SSLMODE'])} ?? '${_dartStringLiteral(defaultSslMode)}'";
      final timezoneExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'TIMEZONE')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_TIMEZONE'])} ?? '${_dartStringLiteral(defaultTimezone)}'";
      final appNameExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'APP_NAME')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_APP_NAME'])} ?? ${_nullableDartStringLiteral(defaultAppName)}";
      return "final url = $urlExpr;\n"
          "final host = $hostExpr;\n"
          "final port = _parseIntEnv($portExpr, fallback: $defaultPort);\n"
          "final database = $databaseExpr;\n"
          "final username = $usernameExpr;\n"
          "final password = $passwordExpr;\n"
          "final sslmode = $sslModeExpr;\n"
          "final timezone = $timezoneExpr;\n"
          "final appName = $appNameExpr;\n"
          "final connectionEnv = <String, String>{\n"
          "  ...env.values,\n"
          "  'DB_URL': url ?? '',\n"
          "  'DATABASE_URL': '',\n"
          "  'DB_HOST': host,\n"
          "  'DB_PORT': port.toString(),\n"
          "  'DB_NAME': database,\n"
          "  'DB_USER': username,\n"
          "  'DB_PASSWORD': password ?? '',\n"
          "  'DB_SSLMODE': sslmode,\n"
          "  'DB_TIMEZONE': timezone,\n"
          "  'DB_APP_NAME': appName ?? '',\n"
          "};\n"
          "return registry.postgresDataSourceOptionsFromEnv(\n"
          "  name: '$safeConnectionName',\n"
          "  environment: connectionEnv,\n"
          ");";
    case 'mysql':
      final defaultUrl = _firstDriverOption(driverConfig, const [
        'url',
        'database_url',
      ]);
      final defaultHost =
          _firstDriverOption(driverConfig, const ['host']) ?? '127.0.0.1';
      final defaultPort = _firstDriverIntOption(driverConfig, const [
        'port',
      ], fallback: 3306);
      final defaultDatabase =
          _firstDriverOption(driverConfig, const ['database']) ?? 'mysql';
      final defaultUsername =
          _firstDriverOption(driverConfig, const ['username']) ?? 'root';
      final defaultPassword = _firstDriverOption(driverConfig, const [
        'password',
      ]);
      final defaultSecure = _firstDriverBoolOption(driverConfig, const [
        'ssl',
        'sslmode',
      ], fallback: false);
      final defaultTimezone =
          _firstDriverOption(driverConfig, const ['timezone']) ?? '+00:00';
      final defaultCharset =
          _firstDriverOption(driverConfig, const ['charset']) ?? 'utf8mb4';
      final defaultCollation = _firstDriverOption(driverConfig, const [
        'collation',
      ]);
      final defaultSqlMode = _firstDriverOption(driverConfig, const [
        'sqlMode',
        'sql_mode',
      ]);
      final urlExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'URL')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_URL', 'DATABASE_URL'])} ?? ${_nullableDartStringLiteral(defaultUrl)}";
      final hostExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'HOST')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_HOST'])} ?? '${_dartStringLiteral(defaultHost)}'";
      final portExpr = _envLookupExpression(
        scopedKeys: [dbConnectionEnvKey(connectionName, 'PORT')],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['DB_PORT'],
      );
      final databaseExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'NAME')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_NAME'])} ?? '${_dartStringLiteral(defaultDatabase)}'";
      final usernameExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'USER')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_USER'])} ?? '${_dartStringLiteral(defaultUsername)}'";
      final passwordExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'PASSWORD')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_PASSWORD'])} ?? ${_nullableDartStringLiteral(defaultPassword)}";
      final secureExpr = _envLookupExpression(
        scopedKeys: [dbConnectionEnvKey(connectionName, 'SSLMODE')],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['DB_SSLMODE'],
      );
      final timezoneExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'TIMEZONE')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_TIMEZONE'])} ?? '${_dartStringLiteral(defaultTimezone)}'";
      final charsetExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'CHARSET')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_CHARSET'])} ?? '${_dartStringLiteral(defaultCharset)}'";
      final collationExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'COLLATION')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_COLLATION'])} ?? ${_nullableDartStringLiteral(defaultCollation)}";
      final sqlModeExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'SQL_MODE')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_SQL_MODE'])} ?? ${_nullableDartStringLiteral(defaultSqlMode)}";
      return "final url = $urlExpr;\n"
          "final host = $hostExpr;\n"
          "final port = _parseIntEnv($portExpr, fallback: $defaultPort);\n"
          "final database = $databaseExpr;\n"
          "final username = $usernameExpr;\n"
          "final password = $passwordExpr;\n"
          "final secure = _parseBoolEnv($secureExpr, fallback: ${defaultSecure ? 'true' : 'false'});\n"
          "final timezone = $timezoneExpr;\n"
          "final charset = $charsetExpr;\n"
          "final collation = $collationExpr;\n"
          "final sqlMode = $sqlModeExpr;\n"
          "final connectionEnv = <String, String>{\n"
          "  ...env.values,\n"
          "  'DB_URL': url ?? '',\n"
          "  'DATABASE_URL': '',\n"
          "  'DB_HOST': host,\n"
          "  'DB_PORT': port.toString(),\n"
          "  'DB_NAME': database,\n"
          "  'DB_USER': username,\n"
          "  'DB_PASSWORD': password ?? '',\n"
          "  'DB_SSLMODE': secure ? 'require' : 'disable',\n"
          "  'DB_TIMEZONE': timezone,\n"
          "  'DB_CHARSET': charset,\n"
          "  'DB_COLLATION': collation ?? '',\n"
          "  'DB_SQL_MODE': sqlMode ?? '',\n"
          "};\n"
          "return registry.mySqlDataSourceOptionsFromEnv(\n"
          "  name: '$safeConnectionName',\n"
          "  environment: connectionEnv,\n"
          ");";
    case 'mariadb':
      final defaultHost =
          _firstDriverOption(driverConfig, const ['host']) ?? '127.0.0.1';
      final defaultPort = _firstDriverIntOption(driverConfig, const [
        'port',
      ], fallback: 3306);
      final defaultDatabase =
          _firstDriverOption(driverConfig, const ['database']) ?? 'mysql';
      final defaultUsername =
          _firstDriverOption(driverConfig, const ['username']) ?? 'root';
      final defaultPassword = _firstDriverOption(driverConfig, const [
        'password',
      ]);
      final defaultSecure = _firstDriverBoolOption(driverConfig, const [
        'ssl',
        'sslmode',
      ], fallback: false);
      final defaultTimezone =
          _firstDriverOption(driverConfig, const ['timezone']) ?? '+00:00';
      final hostExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'HOST')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_HOST'])} ?? '${_dartStringLiteral(defaultHost)}'";
      final portExpr = _envLookupExpression(
        scopedKeys: [dbConnectionEnvKey(connectionName, 'PORT')],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['DB_PORT'],
      );
      final databaseExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'NAME')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_NAME'])} ?? '${_dartStringLiteral(defaultDatabase)}'";
      final usernameExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'USER')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_USER'])} ?? '${_dartStringLiteral(defaultUsername)}'";
      final passwordExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'PASSWORD')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_PASSWORD'])} ?? ${_nullableDartStringLiteral(defaultPassword)}";
      final secureExpr = _envLookupExpression(
        scopedKeys: [dbConnectionEnvKey(connectionName, 'SSLMODE')],
        isDefaultConnection: isDefaultConnection,
        globalKeys: const ['DB_SSLMODE'],
      );
      final timezoneExpr =
          "${_envLookupExpression(scopedKeys: [dbConnectionEnvKey(connectionName, 'TIMEZONE')], isDefaultConnection: isDefaultConnection, globalKeys: const ['DB_TIMEZONE'])} ?? '${_dartStringLiteral(defaultTimezone)}'";
      return "return registry.mariaDbDataSourceOptions(\n"
          "  name: '$safeConnectionName',\n"
          "  host: $hostExpr,\n"
          "  port: _parseIntEnv($portExpr, fallback: $defaultPort),\n"
          "  database: $databaseExpr,\n"
          "  username: $usernameExpr,\n"
          "  password: $passwordExpr,\n"
          "  secure: _parseBoolEnv($secureExpr, fallback: ${defaultSecure ? 'true' : 'false'}),\n"
          "  timezone: $timezoneExpr,\n"
          ");";
    default:
      final normalized = _dartStringLiteral(driverConfig.type);
      return "throw UnsupportedError('Unsupported driver type for scaffolded datasource config: $normalized');";
  }
}

String _buildPerConnectionOptionsHelpers(OrmProjectConfig config) {
  final buffer = StringBuffer();
  final used = <String>{};
  for (final connection in config.connections.keys) {
    final suffix = _connectionSuffix(connection, used: used);
    final safeConnection = _dartStringLiteral(connection);
    buffer
      ..writeln('/// Convenience helper for "$safeConnection" connection.')
      ..writeln('DataSourceOptions build${suffix}DataSourceOptions() {')
      ..writeln(
        "  return buildDataSourceOptions(connection: '$safeConnection');",
      )
      ..writeln('}')
      ..writeln('');
  }
  return buffer.toString().trimRight();
}

String _buildPerConnectionDataSourceHelpers(OrmProjectConfig config) {
  final buffer = StringBuffer();
  final used = <String>{};
  for (final connection in config.connections.keys) {
    final suffix = _connectionSuffix(connection, used: used);
    final safeConnection = _dartStringLiteral(connection);
    buffer
      ..writeln('/// Convenience helper for "$safeConnection" connection.')
      ..writeln(
        'DataSource create${suffix}DataSource({DataSourceOptions? options}) {',
      )
      ..writeln(
        '  return DataSource(options ?? build${suffix}DataSourceOptions());',
      )
      ..writeln('}')
      ..writeln('');
  }
  return buffer.toString().trimRight();
}

String _buildPerConnectionTestConfigHelpers(OrmProjectConfig config) {
  final buffer = StringBuffer();
  final used = <String>{};
  for (final connection in config.connections.keys) {
    final suffix = _connectionSuffix(connection, used: used);
    final safeConnection = _dartStringLiteral(connection);
    final variablePrefix = _lowerCamelCase(suffix);
    buffer
      ..writeln('/// Convenience test config for "$safeConnection" connection.')
      ..writeln(
        'final OrmedTestConfig ${variablePrefix}TestConfig = testConfig(connection: \'$safeConnection\');',
      )
      ..writeln('');
  }
  return buffer.toString().trimRight();
}

String _buildPerConnectionTestConnectionHelpers(OrmProjectConfig config) {
  final buffer = StringBuffer();
  final used = <String>{};
  for (final connection in config.connections.keys) {
    final suffix = _connectionSuffix(connection, used: used);
    final safeConnection = _dartStringLiteral(connection);
    buffer
      ..writeln('/// Convenience test connection for "$safeConnection".')
      ..writeln('OrmConnection ${_lowerCamelCase(suffix)}TestConnection() {')
      ..writeln("  return testConnection(connection: '$safeConnection');")
      ..writeln('}')
      ..writeln('');
  }
  return buffer.toString().trimRight();
}

String _connectionSuffix(String connectionName, {required Set<String> used}) {
  final normalized = splitConnectionNameParts(connectionName)
      .map(
        (part) =>
            part.substring(0, 1).toUpperCase() +
            part.substring(1).toLowerCase(),
      )
      .join();

  var suffix = normalized.isEmpty ? 'Default' : normalized;
  if (RegExp(r'^[0-9]').hasMatch(suffix)) {
    suffix = 'Conn$suffix';
  }

  var candidate = suffix;
  var index = 2;
  while (used.contains(candidate)) {
    candidate = '$suffix$index';
    index++;
  }
  used.add(candidate);
  return candidate;
}

String _envLookupExpression({
  required List<String> scopedKeys,
  required bool isDefaultConnection,
  List<String> globalKeys = const [],
}) {
  final keys = <String>[...scopedKeys, if (isDefaultConnection) ...globalKeys];
  final seen = <String>{};
  final unique = <String>[
    for (final key in keys)
      if (key.trim().isNotEmpty && seen.add(key.trim())) key.trim(),
  ];
  if (unique.isEmpty) {
    return 'null';
  }
  final literalKeys = unique
      .map((key) => "'${_dartStringLiteral(key)}'")
      .join(', ');
  return 'env.firstNonEmpty([$literalKeys])';
}

String? _firstDriverOption(DriverConfig driverConfig, List<String> keys) {
  for (final key in keys) {
    final value = driverConfig.option(key);
    if (value == null) continue;
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

int _firstDriverIntOption(
  DriverConfig driverConfig,
  List<String> keys, {
  required int fallback,
}) {
  final raw = _firstDriverOption(driverConfig, keys);
  if (raw == null) return fallback;
  return int.tryParse(raw) ?? fallback;
}

bool _firstDriverBoolOption(
  DriverConfig driverConfig,
  List<String> keys, {
  required bool fallback,
}) {
  final raw = _firstDriverOption(driverConfig, keys);
  if (raw == null) return fallback;
  final normalized = raw.toLowerCase();
  if (normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'on' ||
      normalized == 'require') {
    return true;
  }
  if (normalized == '0' ||
      normalized == 'false' ||
      normalized == 'no' ||
      normalized == 'off' ||
      normalized == 'disable') {
    return false;
  }
  return fallback;
}

String _nullableDartStringLiteral(String? value) {
  if (value == null) return 'null';
  return "'${_dartStringLiteral(value)}'";
}

String _lowerCamelCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value.substring(0, 1).toLowerCase() + value.substring(1);
}

String _dartStringLiteral(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

const String _defaultSeederTemplate = '''
import 'package:ormed/ormed.dart';

/// Root seeder executed by `orm seed` and `orm migrate --seed`.
class AppDatabaseSeeder extends DatabaseSeeder {
  AppDatabaseSeeder(super.connection);

  @override
  Future<void> run() async {
    // TODO: add seed logic here
    // Examples:
    // await seed<User>([
    //   {'name': 'Admin User', 'email': 'admin@example.com'},
    // ]);
    //
    // Or call other seeders:
    // await call([UserSeeder.new, PostSeeder.new]);
  }
}
''';

void _writeFile({
  required File file,
  required String content,
  required String label,
  required bool force,
  required _ArtifactTracker tracker,
  bool interactive = false,
}) {
  tracker.note(label, file.path);
  file.parent.createSync(recursive: true);
  if (file.existsSync()) {
    if (force) {
      file.writeAsStringSync(content);
      cliIO.writeln(
        '${cliIO.style.foreground(Colors.warning).render('↻')} Recreated $label at ${tracker.relative(file.path)}',
      );
    } else {
      cliIO.writeln(
        '${cliIO.style.foreground(Colors.muted).render('○')} $label already exists ${cliIO.style.foreground(Colors.muted).render('(skipped)')}',
      );
    }
    return;
  }
  file.writeAsStringSync(content);
  cliIO.writeln(
    '${cliIO.style.foreground(Colors.success).render('✓')} Created $label at ${tracker.relative(file.path)}',
  );
}

void _ensureDirectory(Directory dir, String label, _ArtifactTracker tracker) {
  tracker.note(label, dir.path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    cliIO.writeln(
      '${cliIO.style.foreground(Colors.success).render('✓')} Created $label at ${tracker.relative(dir.path)}',
    );
  } else {
    cliIO.writeln(
      '${cliIO.style.foreground(Colors.muted).render('○')} $label already exists',
    );
  }
}

class _ArtifactTracker {
  _ArtifactTracker(this.root);

  final Directory root;
  final Map<String, String> paths = <String, String>{};

  void note(String label, String path) {
    paths[label] = path;
  }

  String relative(String path) => p.relative(path, from: root.path);
}

// --- Helpers for populating existing migrations/seeders ---

bool _hasDartFiles(Directory dir) {
  if (!dir.existsSync()) return false;
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .any((f) => f.path.endsWith('.dart'));
}

Future<void> _populateExisting({
  required Console io,
  required Directory root,
  required OrmProjectConfig config,
  required String packageName,
  required Directory? migrationsDir,
  required Directory? seedersDir,
  required File? registryFile,
  required File? seedRegistryFile,
  required bool includeMigrations,
  required bool includeSeeders,
}) async {
  io.section('Populating registries from existing files');

  if (includeMigrations) {
    final migrationsDirResolved = migrationsDir;
    final registryFileResolved = registryFile;
    if (migrationsDirResolved == null || registryFileResolved == null) {
      throw StateError('Missing migrations registry context for population.');
    }

    // Migrations: gather files like migrations/m_*.dart and rebuild registry
    final migrationFiles =
        migrationsDirResolved
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => f.path != registryFileResolved.path)
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    // Build migration registry content skeleton by importing and registering
    final migrationImports = <String>[];
    final migrationEntries = <String>[];
    for (final f in migrationFiles) {
      final rel = p.relative(
        f.path,
        from: p.dirname(registryFileResolved.path),
      );
      final importPath = rel.replaceAll('\\', '/');
      // Guess class name from filename, keep a conservative fallback
      final base = p.basenameWithoutExtension(f.path);
      // Expected pattern: m_YYYY..._name.dart => class CreateUsersTable or similar
      // We cannot reliably infer class – we import and leave a TODO entry
      migrationImports.add("import '$importPath';");
      migrationEntries.add("  // TODO: Add entry for $base (imported above)");
    }

    final registryContent = [
      "import 'dart:convert';",
      "",
      "import 'package:ormed/migrations.dart';",
      "",
      ...migrationImports,
      "",
      "final List<MigrationEntry> _entries = [",
      ...migrationEntries,
      "];",
      "",
      "/// Build migration descriptors sorted by timestamp.",
      "List<MigrationDescriptor> buildMigrations() =>",
      "    MigrationEntry.buildDescriptors(_entries);",
      "",
      "MigrationEntry? _findEntry(String rawId) {",
      "  for (final entry in _entries) {",
      "    if (entry.id.toString() == rawId) return entry;",
      "  }",
      "  return null;",
      "}",
      "",
      "void main(List<String> args) {",
      "  if (args.contains('--dump-json')) {",
      "    final payload = buildMigrations().map((m) => m.toJson()).toList();",
      "    print(jsonEncode(payload));",
      "    return;",
      "  }",
      "",
      "  final planIndex = args.indexOf('--plan-json');",
      "  if (planIndex != -1) {",
      "    final id = args[planIndex + 1];",
      "    final entry = _findEntry(id);",
      "    if (entry == null) {",
      "      throw StateError('Unknown migration id ' + id + '.');",
      "    }",
      "    final directionName = args[args.indexOf('--direction') + 1];",
      "    final direction = MigrationDirection.values.byName(directionName);",
      "    final snapshotIndex = args.indexOf('--schema-snapshot');",
      "    SchemaSnapshot? snapshot;",
      "    if (snapshotIndex != -1) {",
      "      final decoded = utf8.decode(base64.decode(args[snapshotIndex + 1]));",
      "      final payload = jsonDecode(decoded) as Map<String, Object?>;",
      "      snapshot = SchemaSnapshot.fromJson(payload);",
      "    }",
      "    final plan = entry.migration.plan(direction, snapshot: snapshot);",
      "    print(jsonEncode(plan.toJson()));",
      "  }",
      "}",
    ].join('\n');

    if (migrationFiles.isNotEmpty) {
      registryFileResolved.writeAsStringSync(registryContent);
      io.success(
        'Populated migrations registry with ${migrationFiles.length} imports (manual entry TODOs left).',
      );
    } else {
      io.writeln(io.style.muted('No migration files found.'));
    }
  }

  if (includeSeeders) {
    final seedersDirResolved = seedersDir;
    final seedRegistryFileResolved = seedRegistryFile;
    if (seedersDirResolved == null || seedRegistryFileResolved == null) {
      throw StateError('Missing seed registry context for population.');
    }

    // Seeders: gather files in seeders dir
    final seederFiles =
        seedersDirResolved
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => p.basename(f.path) != 'database_seeder.dart')
            .where((f) => f.path != seedRegistryFileResolved.path)
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    // Build seed registry
    final seedImports = <String>[];
    final seedRegistrations = <String>[];
    for (final f in seederFiles) {
      final rel = p.relative(
        f.path,
        from: p.dirname(seedRegistryFileResolved.path),
      );
      final importPath = rel.replaceAll('\\', '/');
      final base = p.basenameWithoutExtension(f.path);
      seedImports.add("import '$importPath';");
      seedRegistrations.add("  // TODO: Register seeder for $base");
    }

    final seedRegistryContent = [
      "import 'package:ormed_cli/runtime.dart';",
      "import 'package:ormed/ormed.dart';",
      "import 'package:$packageName/src/database/orm_registry.g.dart' as g;",
      "",
      ...seedImports,
      "",
      "/// Registered seeders for this project.",
      "final List<SeederRegistration> seeders = <SeederRegistration>[",
      ...seedRegistrations,
      "];",
      "",
      "/// Run project seeders on the given connection.",
      "Future<void> runProjectSeeds(",
      "  OrmConnection connection, {",
      "  List<String>? names,",
      "  bool pretend = false,",
      "}) async {",
      "  g.bootstrapOrm(registry: connection.context.registry);",
      "  await SeederRunner().run(",
      "    connection: connection,",
      "    seeders: seeders,",
      "    names: names,",
      "    pretend: pretend,",
      "  );",
      "}",
      "",
      "Future<void> main(List<String> args) => runSeedRegistryEntrypoint(",
      "      args: args,",
      "      seeds: seeders,",
      "      beforeRun: (connection) =>",
      "          g.bootstrapOrm(registry: connection.context.registry),",
      "    );",
    ].join('\n');

    if (seederFiles.isNotEmpty) {
      seedRegistryFileResolved.writeAsStringSync(seedRegistryContent);
      io.success(
        'Populated seed registry with ${seederFiles.length} imports (manual registration TODOs left).',
      );
    } else {
      io.writeln(io.style.muted('No seeder files found.'));
    }
  }
}
