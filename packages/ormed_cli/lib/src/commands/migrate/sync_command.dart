import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed/migrations.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class MigrationSyncCommand extends Command<void> {
  MigrationSyncCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help:
            'Path to ormed.yaml (optional; convention defaults are used when omitted).',
      )
      ..addOption(
        'path',
        help:
            'Override migration registry file path (relative to project root unless --realpath is set).',
      )
      ..addFlag(
        'realpath',
        negatable: false,
        help: 'Treat --path as an absolute path.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Preview changes without writing migrations.dart.',
      );
  }

  @override
  String get name => 'migrations:sync';

  @override
  String get description =>
      'Scan migration files and register missing imports/entries.';

  @override
  Future<void> run() async {
    final configArg = argResults?['config'] as String?;
    final overridePath = argResults?['path'] as String?;
    final realPath = argResults?['realpath'] == true;
    final dryRun = argResults?['dry-run'] == true;

    final resolved = resolveOrmProjectConfig(configPath: configArg);
    final projectRoot = resolved.root;
    final config = resolved.config;
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }
    final registryPath = resolveRegistryFilePath(
      projectRoot,
      config,
      override: overridePath,
      realPath: realPath,
    );
    final registryFile = File(registryPath);
    if (!registryFile.existsSync()) {
      usageException('Migration registry not found: $registryPath');
    }

    var content = registryFile.readAsStringSync();
    if (!content.contains(importsMarkerStart) ||
        !content.contains(importsMarkerEnd) ||
        !content.contains(registryMarkerStart) ||
        !content.contains(registryMarkerEnd)) {
      usageException(
        'Registry markers are missing in ${p.relative(registryPath, from: projectRoot.path)}.\n'
        'Run `ormed init --force --only=migrations` or update migrations.dart to include marker blocks.',
      );
    }

    final migrationsDirPath = resolvePath(
      projectRoot,
      config.migrations.directory,
    );
    final migrationsDir = Directory(migrationsDirPath);
    if (!migrationsDir.existsSync()) {
      usageException(
        'Migrations directory not found: ${p.relative(migrationsDirPath, from: projectRoot.path)}',
      );
    }

    final registryDir = p.dirname(registryPath);
    final existingImports = _extractImports(content);
    final existingIds = _extractMigrationIds(content);
    final warnings = <String>[];
    final scanned = _scanMigrationCandidates(
      migrationsDir: migrationsDir,
      registryDir: registryDir,
      warnings: warnings,
    );

    final importsToAdd = <String>[];
    final entriesToAdd = <String>[];
    final seenIds = <String>{...existingIds};
    final seenImports = <String>{...existingImports};
    for (final candidate in scanned) {
      final importLine = candidate.importLine;
      if (importLine != null && seenImports.add(importLine)) {
        importsToAdd.add(importLine);
      }
      if (seenIds.add(candidate.id)) {
        entriesToAdd.add(candidate.entryLine);
      }
    }

    cliIO.section('Migration registry sync');
    cliIO.components.horizontalTable({
      'Registry': p.relative(registryPath, from: projectRoot.path),
      'Scanned': scanned.length.toString(),
      'Imports to add': importsToAdd.length.toString(),
      'Entries to add': entriesToAdd.length.toString(),
      if (dryRun) 'Mode': 'dry-run',
    });

    for (final warning in warnings) {
      cliIO.warn(warning);
    }

    if (importsToAdd.isEmpty && entriesToAdd.isEmpty) {
      cliIO.info('No changes needed.');
      return;
    }

    if (dryRun) {
      if (importsToAdd.isNotEmpty) {
        cliIO.newLine();
        cliIO.section('Imports');
        for (final line in importsToAdd) {
          cliIO.writeln(line);
        }
      }
      if (entriesToAdd.isNotEmpty) {
        cliIO.newLine();
        cliIO.section('Entries');
        for (final line in entriesToAdd) {
          cliIO.writeln(line);
        }
      }
      return;
    }

    for (final line in importsToAdd) {
      content = insertBetweenMarkers(
        content,
        importsMarkerStart,
        importsMarkerEnd,
        line,
        indent: '',
      );
    }
    for (final line in entriesToAdd) {
      content = insertBetweenMarkers(
        content,
        registryMarkerStart,
        registryMarkerEnd,
        line,
        indent: '  ',
      );
    }
    registryFile.writeAsStringSync(content);
    cliIO.success(
      'Synchronized migrations registry (+${importsToAdd.length} imports, +${entriesToAdd.length} entries).',
    );
  }
}

List<String> _extractImports(String source) {
  final pattern = RegExp(r"import\s+'([^']+)';");
  return {
    for (final match in pattern.allMatches(source))
      "import '${match.group(1)}';",
  }.toList(growable: false);
}

Set<String> _extractMigrationIds(String source) {
  final ids = <String>{};
  final namedPattern = RegExp(r"MigrationEntry\.named\(\s*'([^']+)'");
  final parsedPattern = RegExp(r"id:\s*MigrationId\.parse\(\s*'([^']+)'\s*\)");

  for (final match in namedPattern.allMatches(source)) {
    final id = match.group(1);
    if (id != null) ids.add(id);
  }
  for (final match in parsedPattern.allMatches(source)) {
    final id = match.group(1);
    if (id != null) ids.add(id);
  }
  return ids;
}

List<_MigrationCandidate> _scanMigrationCandidates({
  required Directory migrationsDir,
  required String registryDir,
  required List<String> warnings,
}) {
  final candidatesById = <String, _MigrationCandidate>{};

  final entities = migrationsDir.listSync(recursive: true)
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final candidate = _buildDartCandidate(
        file: entity,
        registryDir: registryDir,
        warnings: warnings,
      );
      if (candidate == null) continue;
      candidatesById.putIfAbsent(candidate.id, () => candidate);
      continue;
    }
    if (entity is Directory) {
      final candidate = _buildSqlCandidate(
        dir: entity,
        registryDir: registryDir,
        warnings: warnings,
      );
      if (candidate == null) continue;
      candidatesById.putIfAbsent(candidate.id, () => candidate);
    }
  }

  final result = candidatesById.values.toList(growable: false)
    ..sort((a, b) => a.id.compareTo(b.id));
  return result;
}

_MigrationCandidate? _buildDartCandidate({
  required File file,
  required String registryDir,
  required List<String> warnings,
}) {
  final migrationId = p.basenameWithoutExtension(file.path);
  try {
    MigrationId.parse(migrationId);
  } on FormatException {
    return null;
  }

  final content = file.readAsStringSync();
  final classMatches = RegExp(
    r'class\s+([A-Za-z_][A-Za-z0-9_]*)\s+extends\s+Migration\b',
  ).allMatches(content).toList();
  if (classMatches.isEmpty) {
    warnings.add(
      'Skipping ${p.basename(file.path)}: no `class ... extends Migration` found.',
    );
    return null;
  }
  final className = classMatches.first.group(1)!;
  final hasConstCtor = RegExp(
    'const\\s+$className\\s*\\(',
    multiLine: true,
  ).hasMatch(content);

  final importPath = p
      .relative(file.path, from: registryDir)
      .replaceAll(r'\', '/');
  final ctor = hasConstCtor ? 'const $className()' : '$className()';
  return _MigrationCandidate(
    id: migrationId,
    importLine: "import '$importPath';",
    entryLine:
        '''MigrationEntry.named(
    '$migrationId',
    $ctor,
  ),''',
  );
}

_MigrationCandidate? _buildSqlCandidate({
  required Directory dir,
  required String registryDir,
  required List<String> warnings,
}) {
  final migrationId = p.basename(dir.path);
  try {
    MigrationId.parse(migrationId);
  } on FormatException {
    return null;
  }

  final up = File(p.join(dir.path, 'up.sql'));
  final down = File(p.join(dir.path, 'down.sql'));
  if (!up.existsSync() || !down.existsSync()) {
    warnings.add(
      'Skipping ${p.basename(dir.path)}: expected up.sql and down.sql.',
    );
    return null;
  }

  final relativeDir = p
      .relative(dir.path, from: registryDir)
      .replaceAll(r'\', '/');
  return _MigrationCandidate(
    id: migrationId,
    importLine: null,
    entryLine:
        '''MigrationEntry.named(
    '$migrationId',
    SqlFileMigration(
      upPath: '$relativeDir/up.sql',
      downPath: '$relativeDir/down.sql',
    ),
  ),''',
  );
}

class _MigrationCandidate {
  const _MigrationCandidate({
    required this.id,
    required this.importLine,
    required this.entryLine,
  });

  final String id;
  final String? importLine;
  final String entryLine;
}
