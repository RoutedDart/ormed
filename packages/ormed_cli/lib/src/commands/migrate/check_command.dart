import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed/migrations.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class MigrationCheckCommand extends Command<void> {
  MigrationCheckCommand() {
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
      );
  }

  @override
  String get name => 'migrations:check';

  @override
  String get description =>
      'Validate migrations.dart entries for id format, duplicates, and order.';

  @override
  Future<void> run() async {
    final configArg = argResults?['config'] as String?;
    final overridePath = argResults?['path'] as String?;
    final realPath = argResults?['realpath'] == true;

    final resolved = resolveOrmProjectConfig(configPath: configArg);
    final root = resolved.root;
    final config = resolved.config;
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }
    final registryPath = overridePath == null
        ? resolvePath(root, config.migrations.registry)
        : (realPath || p.isAbsolute(overridePath)
              ? p.normalize(overridePath)
              : resolvePath(root, overridePath));

    final registry = File(registryPath);
    if (!registry.existsSync()) {
      usageException('Migration registry not found: $registryPath');
    }

    final content = registry.readAsStringSync();
    final ids = _extractMigrationIds(content);
    final issues = _validateMigrationIds(ids);

    cliIO.section('Migration registry check');
    cliIO.components.horizontalTable({
      'Registry': p.relative(registryPath, from: root.path),
      'Entries': ids.length.toString(),
    });

    if (issues.isEmpty) {
      cliIO.success('No issues found.');
      return;
    }

    cliIO.error('Found ${issues.length} issue(s):');
    for (final issue in issues) {
      cliIO.writeln('  - $issue');
    }
    exitCode = 1;
  }
}

List<String> _extractMigrationIds(String source) {
  final matches = <_MigrationIdMatch>[];
  final namedPattern = RegExp(r"MigrationEntry\.named\(\s*'([^']+)'");
  final parsedPattern = RegExp(r"id:\s*MigrationId\.parse\(\s*'([^']+)'\s*\)");

  for (final match in namedPattern.allMatches(source)) {
    final id = match.group(1);
    if (id != null) {
      matches.add(_MigrationIdMatch(match.start, id));
    }
  }
  for (final match in parsedPattern.allMatches(source)) {
    final id = match.group(1);
    if (id != null) {
      matches.add(_MigrationIdMatch(match.start, id));
    }
  }

  matches.sort((a, b) => a.start.compareTo(b.start));
  return matches.map((m) => m.id).toList(growable: false);
}

List<String> _validateMigrationIds(List<String> ids) {
  final issues = <String>[];
  if (ids.isEmpty) {
    issues.add('No migration entries found.');
    return issues;
  }

  final seen = <String>{};
  final parsedIds = <_ParsedMigrationId>[];
  for (final id in ids) {
    if (!seen.add(id)) {
      issues.add('Duplicate migration id: $id');
      continue;
    }

    try {
      final parsed = MigrationId.parse(id);
      parsedIds.add(_ParsedMigrationId(raw: id, timestamp: parsed.timestamp));
    } on FormatException catch (error) {
      issues.add('Invalid migration id "$id": ${error.message}');
    }
  }

  for (var i = 1; i < parsedIds.length; i++) {
    final previous = parsedIds[i - 1];
    final current = parsedIds[i];
    if (current.timestamp.isBefore(previous.timestamp)) {
      issues.add(
        'Out-of-order migrations: ${previous.raw} appears before ${current.raw}.',
      );
    }
  }

  return issues;
}

class _MigrationIdMatch {
  const _MigrationIdMatch(this.start, this.id);

  final int start;
  final String id;
}

class _ParsedMigrationId {
  const _ParsedMigrationId({required this.raw, required this.timestamp});

  final String raw;
  final DateTime timestamp;
}
