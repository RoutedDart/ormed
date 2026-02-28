import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:ormed_cli/src/commands/base/shared.dart' show defaultOrmYaml;
import 'package:ormed_cli/src/commands/base/init_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('init command', () {
    late Directory scratchParent;
    late Directory scratchDir;

    setUp(() {
      scratchParent = Directory(
        p.join(Directory.systemTemp.path, 'ormed_cli_tests'),
      );
      if (!scratchParent.existsSync()) {
        scratchParent.createSync(recursive: true);
      }
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          'init_${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);

      // Minimal pubspec so findProjectRoot() works from scratchDir
      File(p.join(scratchDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  ormed: any
  ormed_sqlite: any
dev_dependencies:
  ormed_cli: any
  build_runner: any
''');
    });

    tearDown(() {
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    Future<void> runInit(
      List<String> args, {
      String Function()? readLine,
      void Function(int code)? setExitCode,
    }) async {
      final cmd = InitCommand();
      cmd.workingDirectory = scratchDir;

      final runner = CommandRunner<void>(
        'ormed',
        'ORM CLI',
        ansi: false,
        readLine: readLine,
        setExitCode: setExitCode,
      )..addCommand(cmd);
      await runner.run(args);
    }

    test('scaffolds default files and directories', () async {
      await runInit(['init', '--no-interaction', '--skip-build']);

      final ormYaml = File(p.join(scratchDir.path, 'ormed.yaml'));
      expect(ormYaml.existsSync(), isFalse);
      final envExample = File(p.join(scratchDir.path, '.env.example'));
      expect(envExample.existsSync(), isTrue);

      final migrationsDir = Directory(
        p.join(scratchDir.path, 'lib/src/database/migrations'),
      );
      final migrationsReg = File(
        p.join(scratchDir.path, 'lib/src/database/migrations.dart'),
      );
      expect(migrationsDir.existsSync(), isTrue);
      expect(migrationsReg.existsSync(), isTrue);

      final seedersDir = Directory(
        p.join(scratchDir.path, 'lib/src/database/seeders'),
      );
      final seedersReg = File(
        p.join(scratchDir.path, 'lib/src/database/seeders.dart'),
      );
      final defaultSeeder = File(
        p.join(seedersDir.path, 'database_seeder.dart'),
      );
      expect(seedersDir.existsSync(), isTrue);
      expect(seedersReg.existsSync(), isTrue);
      expect(defaultSeeder.existsSync(), isTrue);

      final schemaDump = File(p.join(scratchDir.path, 'database/schema.sql'));
      expect(schemaDump.parent.existsSync(), isTrue);

      final datasourceFile = File(
        p.join(scratchDir.path, 'lib/src/database/datasource.dart'),
      );
      final databaseConfigFile = File(
        p.join(scratchDir.path, 'lib/src/database/config.dart'),
      );
      final testHelperFile = File(
        p.join(scratchDir.path, 'lib/test/helpers/ormed_test_helper.dart'),
      );
      expect(datasourceFile.existsSync(), isTrue);
      expect(databaseConfigFile.existsSync(), isTrue);
      expect(testHelperFile.existsSync(), isTrue);
      expect(
        datasourceFile.readAsStringSync(),
        contains('options ?? buildDataSourceOptions(connection: connection)'),
      );
      expect(
        datasourceFile.readAsStringSync(),
        contains('Map<String, DataSource> createDataSources'),
      );
      expect(
        datasourceFile.readAsStringSync(),
        contains('createDefaultDataSource'),
      );
      expect(
        databaseConfigFile.readAsStringSync(),
        contains(
          'final env = OrmedEnvironment.fromDirectory(Directory.current);',
        ),
      );
      expect(
        databaseConfigFile.readAsStringSync(),
        contains('buildAllDataSourceOptions()'),
      );
      expect(
        databaseConfigFile.readAsStringSync(),
        contains('buildDefaultDataSourceOptions'),
      );
      final helperText = testHelperFile.readAsStringSync();
      expect(
        helperText,
        contains("import 'package:test_project/src/database/config.dart';"),
      );
      expect(
        helperText,
        contains("import 'package:test_project/src/database/datasource.dart';"),
      );
      expect(helperText, contains('final OrmedTestConfig defaultTestConfig'));
      expect(helperText, contains('OrmConnection defaultTestConnection()'));
      expect(helperText, isNot(contains('analyticsTestConfig')));
      expect(helperText, isNot(contains('SqliteDriverAdapter.inMemory()')));
    });

    test('scaffolds datasource config for multiple connections', () async {
      File(p.join(scratchDir.path, 'ormed.yaml')).writeAsStringSync('''
default_connection: primary
connections:
  primary:
    driver:
      type: sqlite
      options:
        database: database/primary.sqlite
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema
  analytics:
    driver:
      type: sqlite
      options:
        database: database/analytics.sqlite
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema
''');

      await runInit([
        'init',
        '--only=datasource',
        '--no-interaction',
        '--skip-build',
      ]);

      final datasourceFile = File(
        p.join(scratchDir.path, 'lib/src/database/datasource.dart'),
      );
      final configFile = File(
        p.join(scratchDir.path, 'lib/src/database/config.dart'),
      );
      final datasourceText = datasourceFile.readAsStringSync();
      final configText = configFile.readAsStringSync();

      expect(
        datasourceText,
        contains('buildDataSourceOptions(connection: connection)'),
      );
      expect(datasourceText, contains('createDataSources'));
      expect(datasourceText, contains('createPrimaryDataSource'));
      expect(datasourceText, contains('createAnalyticsDataSource'));

      expect(
        configText,
        contains("const String defaultDataSourceConnection = 'primary';"),
      );
      expect(configText, contains("'primary'"));
      expect(configText, contains("'analytics'"));
      expect(configText, contains("case 'primary':"));
      expect(configText, contains("case 'analytics':"));
      expect(configText, contains('buildAllDataSourceOptions()'));
      expect(configText, contains('buildPrimaryDataSourceOptions'));
      expect(configText, contains('buildAnalyticsDataSourceOptions'));
    });

    test('scaffolds test helper derived from configured connections', () async {
      File(p.join(scratchDir.path, 'ormed.yaml')).writeAsStringSync('''
default_connection: primary
connections:
  primary:
    driver:
      type: sqlite
      options:
        database: database/primary.sqlite
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema
  analytics:
    driver:
      type: sqlite
      options:
        database: database/analytics.sqlite
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema
''');

      await runInit([
        'init',
        '--only=tests',
        '--no-interaction',
        '--skip-build',
      ]);

      final helperFile = File(
        p.join(scratchDir.path, 'lib/test/helpers/ormed_test_helper.dart'),
      );
      expect(helperFile.existsSync(), isTrue);
      final helperText = helperFile.readAsStringSync();

      expect(
        helperText,
        contains("import 'package:test_project/src/database/config.dart';"),
      );
      expect(
        helperText,
        contains("import 'package:test_project/src/database/datasource.dart';"),
      );
      expect(helperText, contains('final OrmedTestConfig primaryTestConfig'));
      expect(helperText, contains('final OrmedTestConfig analyticsTestConfig'));
      expect(helperText, contains('OrmConnection primaryTestConnection()'));
      expect(helperText, contains('OrmConnection analyticsTestConnection()'));
      expect(helperText, isNot(contains('SqliteDriverAdapter.inMemory()')));
    });

    test('--populate-existing scans and populates registries', () async {
      // Create some pre-existing artifacts that init should import.
      final migrationsDir = Directory(
        p.join(scratchDir.path, 'lib/src/database/migrations'),
      )..createSync(recursive: true);
      final seedersDir = Directory(
        p.join(scratchDir.path, 'lib/src/database/seeders'),
      )..createSync(recursive: true);

      final migA = File(
        p.join(migrationsDir.path, 'm_20240101000000_create_alpha.dart'),
      )..writeAsStringSync('class CreateAlpha extends Migration {}');
      final migB =
          File(
              p.join(
                migrationsDir.path,
                'subdir',
                'm_20240102000000_create_beta.dart',
              ),
            )
            ..createSync(recursive: true)
            ..writeAsStringSync('class CreateBeta extends Migration {}');

      final seederA = File(p.join(seedersDir.path, 'demo_seeder.dart'))
        ..writeAsStringSync('class DemoSeeder {}');

      await runInit([
        'init',
        '--no-interaction',
        '--populate-existing',
        '--skip-build',
      ]);

      final migrationsReg = File(
        p.join(scratchDir.path, 'lib/src/database/migrations.dart'),
      );
      final seedersReg = File(
        p.join(scratchDir.path, 'lib/src/database/seeders.dart'),
      );
      expect(migrationsReg.existsSync(), isTrue);
      expect(seedersReg.existsSync(), isTrue);

      final regText = migrationsReg.readAsStringSync();
      // Should import using path relative to migrations.dart location.
      expect(
        regText,
        contains("import 'migrations/${p.basename(migA.path)}';"),
      );
      expect(
        regText,
        contains("import 'migrations/subdir/${p.basename(migB.path)}';"),
      );
      // Should place TODO entries for manual mapping.
      expect(
        regText,
        contains('TODO: Add entry for m_20240101000000_create_alpha'),
      );
      expect(
        regText,
        contains('TODO: Add entry for m_20240102000000_create_beta'),
      );

      final seedText = seedersReg.readAsStringSync();
      expect(
        seedText,
        contains("import 'seeders/${p.basename(seederA.path)}';"),
      );
      expect(seedText, contains('final List<SeederRegistration> seeders'));
      expect(seedText, contains('TODO: Register seeder for demo_seeder'));
      // Ensure helper function exists
      expect(seedText, contains('runProjectSeeds'));
    });

    test(
      'prompts to populate registries when artifacts exist (interactive yes)',
      () async {
        // Create artifacts before running init, but do not pass --populate-existing.
        final migrationsDir = Directory(
          p.join(scratchDir.path, 'lib/src/database/migrations'),
        )..createSync(recursive: true);
        final seedersDir = Directory(
          p.join(scratchDir.path, 'lib/src/database/seeders'),
        )..createSync(recursive: true);

        final migA = File(
          p.join(migrationsDir.path, 'm_20240103000000_create_gamma.dart'),
        )..writeAsStringSync('class CreateGamma extends Migration {}');
        final seederA = File(p.join(seedersDir.path, 'alpha_seeder.dart'))
          ..writeAsStringSync('class AlphaSeeder {}');

        // Simulate answering "y" to the populate prompt.
        var answered = false;
        String readLine() {
          if (!answered) {
            answered = true;
            return 'y';
          }
          return '';
        }

        await runInit(['init', '--skip-build'], readLine: readLine);

        final migrationsReg = File(
          p.join(scratchDir.path, 'lib/src/database/migrations.dart'),
        );
        final seedersReg = File(
          p.join(scratchDir.path, 'lib/src/database/seeders.dart'),
        );
        final regText = migrationsReg.readAsStringSync();
        final seedText = seedersReg.readAsStringSync();

        expect(
          regText,
          contains("import 'migrations/${p.basename(migA.path)}';"),
        );
        expect(
          regText,
          contains('TODO: Add entry for m_20240103000000_create_gamma'),
        );
        expect(
          seedText,
          contains("import 'seeders/${p.basename(seederA.path)}';"),
        );
        expect(seedText, contains('TODO: Register seeder for alpha_seeder'));
      },
    );

    test('interactive "no" does not populate registries', () async {
      // Pre-create artifacts, then answer 'n' to prompt.
      final migDir = Directory(
        p.join(scratchDir.path, 'lib/src/database/migrations'),
      )..createSync(recursive: true);
      final seedDir = Directory(
        p.join(scratchDir.path, 'lib/src/database/seeders'),
      )..createSync(recursive: true);

      File(
        p.join(migDir.path, 'm_20240104000000_create_delta.dart'),
      ).writeAsStringSync('class CreateDelta extends Migration {}');
      File(
        p.join(seedDir.path, 'delta_seeder.dart'),
      ).writeAsStringSync('class DeltaSeeder {}');

      String readLine() => 'n';
      await runInit(['init', '--skip-build'], readLine: readLine);

      final migrationsReg = File(
        p.join(scratchDir.path, 'lib/src/database/migrations.dart'),
      );
      final regText = migrationsReg.readAsStringSync();
      // Should still be initial template with markers present (no population).
      expect(regText, contains('// <ORM-MIGRATION-IMPORTS>'));
      expect(regText, contains('// </ORM-MIGRATION-IMPORTS>'));
      expect(regText, contains('// <ORM-MIGRATION-REGISTRY>'));
      expect(regText, contains('// </ORM-MIGRATION-REGISTRY>'));
      // And should not include our test artifact import.
      expect(regText, isNot(contains('m_20240104000000_create_delta.dart')));

      final seedersReg = File(
        p.join(scratchDir.path, 'lib/src/database/seeders.dart'),
      );
      final seedText = seedersReg.readAsStringSync();
      expect(seedText, contains('// <ORM-SEED-IMPORTS>'));
      expect(seedText, contains('// </ORM-SEED-IMPORTS>'));
      expect(seedText, contains('// <ORM-SEED-REGISTRY>'));
      expect(seedText, contains('// </ORM-SEED-REGISTRY>'));
      expect(seedText, isNot(contains('delta_seeder.dart')));
    });

    test('--force overwrites existing registry files', () async {
      // First run to scaffold.
      await runInit(['init', '--no-interaction', '--skip-build']);

      final migrationsReg = File(
        p.join(scratchDir.path, 'lib/src/database/migrations.dart'),
      );
      final seedersReg = File(
        p.join(scratchDir.path, 'lib/src/database/seeders.dart'),
      );

      // Corrupt/replace with sentinel content.
      migrationsReg.writeAsStringSync('// SENTINEL: MIGRATIONS');
      seedersReg.writeAsStringSync('// SENTINEL: SEEDERS');

      // Re-run with --force should overwrite to a clean state.
      await runInit(['init', '--no-interaction', '--force', '--skip-build']);

      final regText = migrationsReg.readAsStringSync();
      final seedText = seedersReg.readAsStringSync();

      // Overwrite removed old content
      expect(regText, isNot(contains('SENTINEL')));
      expect(seedText, isNot(contains('SENTINEL')));

      // Migrations registry should be a valid scaffold (may be template or repopulated)
      expect(
        regText.contains('// <ORM-MIGRATION-IMPORTS>') ||
            regText.contains("final List<MigrationEntry> _entries = ["),
        isTrue,
        reason: 'Expected migrations registry to be scaffolded',
      );

      // Seeders registry should be in a usable state (template or repopulated)
      expect(
        seedText.contains('// <ORM-SEED-IMPORTS>') ||
            seedText.contains("import 'seeders/database_seeder.dart';"),
        isTrue,
        reason: 'Expected seeders registry to be scaffolded or repopulated',
      );
    });

    test(
      'errors when registry path collides with directory (malformed ormed.yaml)',
      () async {
        // Write an ormed.yaml where registry paths equal their directories.
        File(p.join(scratchDir.path, 'ormed.yaml')).writeAsStringSync('''
driver:
  type: sqlite
  options:
    database: database.sqlite
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations
  ledger_table: orm_migrations
  schema_dump: database/schema.sql
seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders
''');

        // Seed directories exist already.
        Directory(
          p.join(scratchDir.path, 'lib/src/database/migrations'),
        ).createSync(recursive: true);
        Directory(
          p.join(scratchDir.path, 'lib/src/database/seeders'),
        ).createSync(recursive: true);

        // Running init should attempt to write files to those registry paths and fail.
        await expectLater(
          runInit(['init', '--no-interaction', '--skip-build']),
          throwsA(isA<FileSystemException>()),
        );
      },
    );

    test('--only=datasource scaffolds only datasource', () async {
      await runInit([
        'init',
        '--only=datasource',
        '--no-interaction',
        '--skip-build',
      ]);

      final datasourceFile = File(
        p.join(scratchDir.path, 'lib/src/database/datasource.dart'),
      );
      expect(datasourceFile.existsSync(), isTrue);
      final datasourceConfigFile = File(
        p.join(scratchDir.path, 'lib/src/database/config.dart'),
      );
      expect(datasourceConfigFile.existsSync(), isTrue);

      final migrationsReg = File(
        p.join(scratchDir.path, 'lib/src/database/migrations.dart'),
      );
      final seedersReg = File(
        p.join(scratchDir.path, 'lib/src/database/seeders.dart'),
      );
      expect(migrationsReg.existsSync(), isFalse);
      expect(seedersReg.existsSync(), isFalse);
    });

    test('--only=migrations --only=seeders skips datasource', () async {
      File(
        p.join(scratchDir.path, 'ormed.yaml'),
      ).writeAsStringSync(defaultOrmYaml('test_project'));

      await runInit([
        'init',
        '--only=migrations',
        '--only=seeders',
        '--no-interaction',
        '--skip-build',
      ]);

      final migrationsReg = File(
        p.join(scratchDir.path, 'lib/src/database/migrations.dart'),
      );
      final seedersReg = File(
        p.join(scratchDir.path, 'lib/src/database/seeders.dart'),
      );
      expect(migrationsReg.existsSync(), isTrue);
      expect(seedersReg.existsSync(), isTrue);

      final datasourceFile = File(
        p.join(scratchDir.path, 'lib/src/database/datasource.dart'),
      );
      expect(datasourceFile.existsSync(), isFalse);
    });

    test('--only=migrations works without ormed.yaml', () async {
      await runInit(['init', '--only=migrations', '--skip-build']);
      final migrationsReg = File(
        p.join(scratchDir.path, 'lib/src/database/migrations.dart'),
      );
      expect(migrationsReg.existsSync(), isTrue);
    });

    test(
      'does not prompt for dependencies when packages already declared',
      () async {
        File(p.join(scratchDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
dev_dependencies:
  ormed_cli: any
  build_runner: any
dependency_overrides:
  ormed: any
  ormed_sqlite: any
''');

        var promptCount = 0;
        String readLine() {
          promptCount++;
          return 'n';
        }

        await runInit(['init', '--skip-build'], readLine: readLine);

        expect(promptCount, equals(0));
      },
    );

    test('--with-analyzer writes analyzer plugin config', () async {
      await runInit([
        'init',
        '--no-interaction',
        '--skip-build',
        '--with-analyzer',
      ]);

      final options = File(p.join(scratchDir.path, 'analysis_options.yaml'));
      expect(options.existsSync(), isTrue);
      final text = options.readAsStringSync();
      expect(text, contains('plugins:'));
      expect(text, contains('- ormed'));
    });
  });
}
