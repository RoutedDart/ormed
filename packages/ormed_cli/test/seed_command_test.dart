import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed_cli/src/commands/db/seed_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('SeedCommand', () {
    late Directory repoRoot;
    late Directory scratchDir;

    setUp(() {
      repoRoot = Directory.current;
      final scratchParent = Directory(
        p.join(Directory.systemTemp.path, 'ormed_cli_tests'),
      )..createSync(recursive: true);
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          'seed_case_${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);

      File(p.join(scratchDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
''');
      Directory.current = scratchDir;
    });

    tearDown(() {
      Directory.current = repoRoot;
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    Future<void> runSeed(List<String> args) async {
      final runner = CommandRunner<void>('ormed', 'ORM CLI')
        ..addCommand(SeedCommand());
      await runner.run(['seed', ...args]);
    }

    test('bootstraps missing seed scaffold and returns cleanly', () async {
      await runSeed(const <String>[]);

      expect(
        File(p.join(scratchDir.path, 'lib/src/database/seeders.dart'))
            .existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(
            scratchDir.path,
            'lib/src/database/seeders/database_seeder.dart',
          ),
        ).existsSync(),
        isTrue,
      );
    });
  });
}
