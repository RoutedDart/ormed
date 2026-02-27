import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed/migrations.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class MigrationEntryCommand extends Command<void> {
  MigrationEntryCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help:
            'Path to ormed.yaml (optional; convention defaults are used when omitted).',
      )
      ..addOption(
        'file',
        abbr: 'f',
        help: 'Path to migration Dart file or SQL migration directory.',
      );
  }

  @override
  String get name => 'migrations:entry';

  @override
  String get description =>
      'Print import/entry snippets for manual migrations.dart registration.';

  @override
  Future<void> run() async {
    final configArg = argResults?['config'] as String?;
    final fileOption = (argResults?['file'] as String?)?.trim();
    final restArg = argResults?.rest.isNotEmpty == true
        ? argResults!.rest.first.trim()
        : null;
    final targetArg = fileOption?.isNotEmpty == true ? fileOption : restArg;

    if (targetArg == null || targetArg.isEmpty) {
      usageException(
        'Provide a migration file/directory. Example: '
        'ormed migrations:entry lib/src/database/migrations/m_20260227094500_create_users.dart',
      );
    }

    final resolved = resolveOrmProjectConfig(configPath: configArg);
    final projectRoot = resolved.root;
    final config = resolved.config;
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }
    final registryPath = resolvePath(projectRoot, config.migrations.registry);
    final registryDir = p.dirname(registryPath);

    final targetPath = p.isAbsolute(targetArg)
        ? p.normalize(targetArg)
        : resolvePath(projectRoot, targetArg);
    final targetType = FileSystemEntity.typeSync(targetPath);
    if (targetType == FileSystemEntityType.notFound) {
      usageException('Path not found: $targetArg');
    }

    final snippet = switch (targetType) {
      FileSystemEntityType.file => _buildDartSnippet(
        migrationFilePath: targetPath,
        registryDir: registryDir,
      ),
      FileSystemEntityType.directory => _buildSqlSnippet(
        migrationDirectoryPath: targetPath,
        registryDir: registryDir,
      ),
      _ => throw UsageException('Unsupported path type: $targetArg', usage),
    };

    print('# Paste into ${p.relative(registryPath, from: projectRoot.path)}');
    if (snippet.importLine != null) {
      print(snippet.importLine!);
    }
    print(snippet.entryLine);
  }
}

_MigrationEntrySnippet _buildDartSnippet({
  required String migrationFilePath,
  required String registryDir,
}) {
  if (!migrationFilePath.endsWith('.dart')) {
    throw UsageException(
      'Dart migration file must end with .dart: $migrationFilePath',
      'ormed migrations:entry <path/to/migration.dart>',
    );
  }

  final file = File(migrationFilePath);
  final content = file.readAsStringSync();
  final classMatches = RegExp(
    r'class\s+([A-Za-z_][A-Za-z0-9_]*)\s+extends\s+Migration\b',
  ).allMatches(content).toList();
  if (classMatches.isEmpty) {
    throw UsageException(
      'No `class ... extends Migration` found in ${file.path}.',
      'ormed migrations:entry <path/to/migration.dart>',
    );
  }

  final className = classMatches.first.group(1)!;
  final hasConstCtor = RegExp(
    'const\\s+$className\\s*\\(',
    multiLine: true,
  ).hasMatch(content);

  final migrationId = p.basenameWithoutExtension(file.path);
  try {
    MigrationId.parse(migrationId);
  } on FormatException catch (error) {
    throw UsageException(
      'Invalid migration id from filename "$migrationId": ${error.message}',
      'Expected format: m_YYYYMMDDHHMMSS_slug.dart',
    );
  }

  final relativeImportPath = p
      .relative(file.path, from: registryDir)
      .replaceAll(r'\', '/');
  final ctor = hasConstCtor ? 'const $className()' : '$className()';
  return _MigrationEntrySnippet(
    importLine: "import '$relativeImportPath';",
    entryLine:
        '''MigrationEntry.named(
  '$migrationId',
  $ctor,
),''',
  );
}

_MigrationEntrySnippet _buildSqlSnippet({
  required String migrationDirectoryPath,
  required String registryDir,
}) {
  final dir = Directory(migrationDirectoryPath);
  final migrationId = p.basename(dir.path);
  try {
    MigrationId.parse(migrationId);
  } on FormatException catch (error) {
    throw UsageException(
      'Invalid migration id from directory "$migrationId": ${error.message}',
      'Expected format: m_YYYYMMDDHHMMSS_slug/',
    );
  }

  final relativeDir = p
      .relative(dir.path, from: registryDir)
      .replaceAll(r'\', '/');
  return _MigrationEntrySnippet(
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

class _MigrationEntrySnippet {
  const _MigrationEntrySnippet({this.importLine, required this.entryLine});

  final String? importLine;
  final String entryLine;
}
