import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:ormed_cli/src/commands/migrate/check_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MigrationCheckCommand', () {
    late Directory repoRoot;
    late Directory scratchDir;
    late File ormConfig;
    late File registryFile;
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
          'check_case_${DateTime.now().microsecondsSinceEpoch}',
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

      runner = CommandRunner<void>('ormed', 'ORM CLI')
        ..addCommand(MigrationCheckCommand());
      Directory.current = scratchDir;
      exitCode = 0;
    });

    tearDown(() async {
      Directory.current = repoRoot;
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    Future<void> runCheck() async {
      await runner.run([
        'migrations:check',
        '--config',
        p.relative(ormConfig.path, from: Directory.current.path),
      ]);
    }

    test('passes for ordered unique migration ids', () async {
      registryFile.writeAsStringSync('''
import 'package:ormed/migrations.dart';

final List<MigrationEntry> _entries = [
  MigrationEntry.named('m_20260227094500_create_users', const CreateUsers()),
  MigrationEntry.named('m_20260227094600_create_posts', const CreatePosts()),
];
''');

      await expectLater(runCheck(), completes);
    });

    test(
      'sets non-zero exit code for duplicate and out-of-order ids',
      () async {
        registryFile.writeAsStringSync('''
import 'package:ormed/migrations.dart';

final List<MigrationEntry> _entries = [
  MigrationEntry.named('m_20260227094600_create_posts', const CreatePosts()),
  MigrationEntry.named('m_20260227094500_create_users', const CreateUsers()),
  MigrationEntry.named('m_20260227094500_create_users', const CreateUsersAgain()),
];
''');

        await expectLater(runCheck(), completes);
        expect(exitCode, 1);
      },
    );
  });
}
