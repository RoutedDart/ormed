import 'dart:async';
import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:ormed_cli/src/commands/migrate/entry_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MigrationEntryCommand', () {
    late Directory repoRoot;
    late Directory scratchDir;
    late File ormConfig;
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
          'entry_case_${DateTime.now().microsecondsSinceEpoch}',
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

      final registryFile = File(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations.dart'),
      );
      registryFile.parent.createSync(recursive: true);
      registryFile.writeAsStringSync('// test registry');

      runner = CommandRunner<void>('ormed', 'ORM CLI')
        ..addCommand(MigrationEntryCommand());
      Directory.current = scratchDir;
    });

    tearDown(() async {
      Directory.current = repoRoot;
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    Future<String> runEntry(List<String> args) async {
      final lines = <String>[];
      await runZoned(
        () async {
          await runner.run([
            'migrations:entry',
            ...args,
            '--config',
            p.relative(ormConfig.path, from: Directory.current.path),
          ]);
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            lines.add(line);
          },
        ),
      );
      return lines.join('\n');
    }

    test('prints import and entry snippet for Dart migration file', () async {
      final migrationFile = File(
        p.join(
          scratchDir.path,
          'lib',
          'src',
          'database',
          'migrations',
          'm_20260227094500_create_users.dart',
        ),
      );
      migrationFile.parent.createSync(recursive: true);
      migrationFile.writeAsStringSync('''
import 'package:ormed/migrations.dart';

class CreateUsers extends Migration {
  const CreateUsers();

  @override
  void up(SchemaBuilder schema) {}

  @override
  void down(SchemaBuilder schema) {}
}
''');

      final out = await runEntry([
        p.relative(migrationFile.path, from: scratchDir.path),
      ]);

      expect(
        out,
        contains("import 'migrations/m_20260227094500_create_users.dart';"),
      );
      expect(out, contains("MigrationEntry.named("));
      expect(out, contains("'m_20260227094500_create_users'"));
      expect(out, contains('const CreateUsers(),'));
    });

    test(
      'prints SQL migration entry snippet for migration directory',
      () async {
        final sqlDir = Directory(
          p.join(
            scratchDir.path,
            'lib',
            'src',
            'database',
            'migrations',
            'm_20260227094600_create_users_sql',
          ),
        )..createSync(recursive: true);
        File(p.join(sqlDir.path, 'up.sql')).writeAsStringSync('-- up');
        File(p.join(sqlDir.path, 'down.sql')).writeAsStringSync('-- down');

        final out = await runEntry([
          p.relative(sqlDir.path, from: scratchDir.path),
        ]);

        expect(out, contains('MigrationEntry.named('));
        expect(out, contains("'m_20260227094600_create_users_sql'"));
        expect(out, contains('SqlFileMigration('));
        expect(
          out,
          contains(
            "upPath: 'migrations/m_20260227094600_create_users_sql/up.sql'",
          ),
        );
        expect(out, isNot(contains("import 'migrations/")));
      },
    );
  });
}
