import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed_cli/src/commands/base/shared.dart'
    show
        importsMarkerEnd,
        importsMarkerStart,
        initialRegistryTemplate,
        registryMarkerEnd,
        registryMarkerStart;
import 'package:ormed_cli/src/commands/migrate/makemigrations_command.dart';
import 'package:ormed_cli/src/commands/migrate/sync_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MigrationSyncCommand', () {
    late Directory repoRoot;
    late Directory scratchDir;
    late File ormConfig;
    late File registryFile;
    late Directory migrationsDir;
    late CommandRunner<void> runner;

    setUp(() async {
      repoRoot = Directory.current;
      final scratchParent = Directory(
        p.join(Directory.systemTemp.path, 'ormed_cli_tests'),
      );
      if (!scratchParent.existsSync()) {
        scratchParent.createSync(recursive: true);
      }
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          'sync_case_${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);

      ormConfig = File(p.join(scratchDir.path, 'ormed.yaml'))
        ..writeAsStringSync('''
driver:
  type: sqlite
  options:
    database: database.sqlite
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
  ledger_table: orm_migrations
  schema_dump: database/schema.sql
''');

      File(p.join(scratchDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

      registryFile = File(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations.dart'),
      );
      registryFile.parent.createSync(recursive: true);
      registryFile.writeAsStringSync(initialRegistryTemplate);

      migrationsDir = Directory(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations'),
      )..createSync(recursive: true);

      runner = CommandRunner<void>('ormed', 'ORM CLI')
        ..addCommand(MigrationSyncCommand())
        ..addCommand(MakeMigrationsCommand());
      Directory.current = scratchDir;
      exitCode = 0;
    });

    tearDown(() async {
      Directory.current = repoRoot;
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    Future<void> runSync([List<String> args = const []]) async {
      await runner.run([
        'migrations:sync',
        ...args,
        '--config',
        p.relative(ormConfig.path, from: Directory.current.path),
      ]);
    }

    Future<void> runMakeMigrations([List<String> args = const []]) async {
      await runner.run([
        'makemigrations',
        ...args,
        '--config',
        p.relative(ormConfig.path, from: Directory.current.path),
      ]);
    }

    Future<void> runSyncWithoutConfig([List<String> args = const []]) async {
      await runner.run(['migrations:sync', ...args]);
    }

    test('adds missing imports and entries for dart/sql migrations', () async {
      final existingDart =
          File(p.join(migrationsDir.path, 'm_20260227094500_create_users.dart'))
            ..writeAsStringSync('''
import 'package:ormed/migrations.dart';

class CreateUsers extends Migration {
  const CreateUsers();
  @override
  void up(SchemaBuilder schema) {}
  @override
  void down(SchemaBuilder schema) {}
}
''');

      final newDart =
          File(p.join(migrationsDir.path, 'm_20260227094600_create_posts.dart'))
            ..writeAsStringSync('''
import 'package:ormed/migrations.dart';

class CreatePosts extends Migration {
  const CreatePosts();
  @override
  void up(SchemaBuilder schema) {}
  @override
  void down(SchemaBuilder schema) {}
}
''');

      final sqlDir = Directory(
        p.join(migrationsDir.path, 'm_20260227094700_create_posts_index'),
      )..createSync(recursive: true);
      File(p.join(sqlDir.path, 'up.sql')).writeAsStringSync('-- up');
      File(p.join(sqlDir.path, 'down.sql')).writeAsStringSync('-- down');

      var content = registryFile.readAsStringSync();
      content = content.replaceFirst(
        '$importsMarkerStart\n$importsMarkerEnd',
        "$importsMarkerStart\nimport 'migrations/${p.basename(existingDart.path)}';\n$importsMarkerEnd",
      );
      content = content.replaceFirst(
        '$registryMarkerStart\n  $registryMarkerEnd',
        """$registryMarkerStart
  MigrationEntry.named(
    'm_20260227094500_create_users',
    const CreateUsers(),
  ),
  $registryMarkerEnd""",
      );
      registryFile.writeAsStringSync(content);

      await runSync();

      final synced = registryFile.readAsStringSync();
      expect(
        RegExp(r"'m_20260227094500_create_users'").allMatches(synced).length,
        equals(1),
      );
      expect(
        synced,
        contains("import 'migrations/${p.basename(newDart.path)}';"),
      );
      expect(synced, contains("'m_20260227094600_create_posts'"));
      expect(synced, contains("'m_20260227094700_create_posts_index'"));
      expect(synced, contains('SqlFileMigration('));
    });

    test('dry-run does not write registry', () async {
      File(
        p.join(migrationsDir.path, 'm_20260227094600_create_posts.dart'),
      ).writeAsStringSync('''
import 'package:ormed/migrations.dart';

class CreatePosts extends Migration {
  const CreatePosts();
  @override
  void up(SchemaBuilder schema) {}
  @override
  void down(SchemaBuilder schema) {}
}
''');

      final before = registryFile.readAsStringSync();
      await runSync(['--dry-run']);
      final after = registryFile.readAsStringSync();
      expect(after, equals(before));
    });

    test('makemigrations alias syncs missing entries', () async {
      File(
        p.join(migrationsDir.path, 'm_20260227094600_create_posts.dart'),
      ).writeAsStringSync('''
import 'package:ormed/migrations.dart';

class CreatePosts extends Migration {
  const CreatePosts();
  @override
  void up(SchemaBuilder schema) {}
  @override
  void down(SchemaBuilder schema) {}
}
''');

      await runMakeMigrations();

      final synced = registryFile.readAsStringSync();
      expect(synced, contains("'m_20260227094600_create_posts'"));
    });

    test('returns usage error when markers are missing', () async {
      registryFile.writeAsStringSync('// registry without markers');
      await runSync();
      expect(exitCode, 64);
    });

    test('works without ormed.yaml using convention defaults', () async {
      ormConfig.deleteSync();
      File(
        p.join(migrationsDir.path, 'm_20260227094600_create_posts.dart'),
      ).writeAsStringSync('''
import 'package:ormed/migrations.dart';

class CreatePosts extends Migration {
  const CreatePosts();
  @override
  void up(SchemaBuilder schema) {}
  @override
  void down(SchemaBuilder schema) {}
}
''');

      await runSyncWithoutConfig();
      final synced = registryFile.readAsStringSync();
      expect(synced, contains("'m_20260227094600_create_posts'"));
    });
  });
}
