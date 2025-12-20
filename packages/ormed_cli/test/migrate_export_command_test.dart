import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_cli/src/commands/migrate/export_command.dart';
import 'package:ormed_cli/src/commands/migrate/migrate_command.dart';
import 'package:ormed_cli/src/commands/base/shared.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class TestMigrationEntry {
  final MigrationId id;
  final Migration migration;
  TestMigrationEntry(this.id, this.migration);
}

class TestMigrationRegistryLoader implements MigrationRegistryLoader {
  List<TestMigrationEntry> entries = [];

  @override
  Future<List<MigrationDescriptor>> load(
    Directory root,
    OrmProjectConfig config, {
    String? registryPath,
  }) async {
    return entries
        .map(
          (e) => MigrationDescriptor.fromMigration(
            id: e.id,
            migration: e.migration,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<SchemaPlan> buildPlan({
    required Directory root,
    required OrmProjectConfig config,
    required MigrationId id,
    required MigrationDirection direction,
    required SchemaSnapshot snapshot,
    String? registryPath,
  }) async {
    final entry = entries.firstWhere((e) => e.id == id);
    return entry.migration.plan(direction, snapshot: snapshot);
  }
}

void main() {
  group('migrate export (sql)', () {
    late Directory repoRoot;
    late Directory scratchDir;
    late File ormConfig;
    late String dbPath;
    late MigrationRegistryLoader previousLoader;
    late TestMigrationRegistryLoader loader;

    setUp(() async {
      repoRoot = Directory.current;
      final scratchParent = Directory(
        p.join(repoRoot.path, '.dart_tool', 'ormed_cli_tests'),
      );
      scratchParent.createSync(recursive: true);
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          'export_${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);

      dbPath = p.join(scratchDir.path, 'test.sqlite');
      ormConfig = File(p.join(scratchDir.path, 'orm.yaml'))
        ..writeAsStringSync('''
driver:
  type: sqlite
  options:
    database: ${p.basename(dbPath)}
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

      Directory.current = scratchDir;

      previousLoader = migrationRegistryLoader;
      loader = TestMigrationRegistryLoader()
        ..entries = [
          TestMigrationEntry(
            MigrationId.parse('m_20250101000000_create_demo'),
            _DemoMigration(),
          ),
        ];
      migrationRegistryLoader = loader;
    });

    tearDown(() async {
      migrationRegistryLoader = previousLoader;
      final manager = ConnectionManager.instance;
      for (final name in manager.registeredConnectionNames) {
        await manager.unregister(name);
      }
      Directory.current = repoRoot;
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    Future<void> runOrm(List<String> args) async {
      final runner = CommandRunner<void>('orm', 'ORM CLI')
        ..addCommand(ApplyCommand())
        ..addCommand(ExportCommand());
      await runner.run([
        ...args,
        '--config',
        p.relative(ormConfig.path, from: Directory.current.path),
      ]);
    }

    test(
      'migrate:export writes up.sql and down.sql without applying',
      () async {
        final outDir = Directory(p.join(scratchDir.path, 'sql_out'));
        await runOrm(['migrate:export', '--out', outDir.path, '--all']);

        final migrationFolder = Directory(
          p.join(outDir.path, 'm_20250101000000_create_demo'),
        );
        expect(migrationFolder.existsSync(), isTrue);
        final upSql = File(
          p.join(migrationFolder.path, 'up.sql'),
        ).readAsStringSync();
        final downSql = File(
          p.join(migrationFolder.path, 'down.sql'),
        ).readAsStringSync();
        expect(upSql, contains('CREATE TABLE'));
        expect(downSql, contains('DROP TABLE'));

        // Ensure the migration was not applied.
        final handle = await createConnection(
          scratchDir,
          loadOrmProjectConfig(ormConfig),
        );
        try {
          await handle.use((connection) async {
            final driver = connection.driver as SchemaDriver;
            expect(await SchemaInspector(driver).hasTable('demo'), isFalse);
          });
        } finally {
          await handle.dispose();
        }
      },
    );

    test(
      'migrate --pretend --write-sql writes files without applying',
      () async {
        final outDir = Directory(p.join(scratchDir.path, 'sql_preview_out'));
        await runOrm([
          'migrate',
          '--pretend',
          '--write-sql',
          '--sql-out',
          outDir.path,
        ]);

        final migrationFolder = Directory(
          p.join(outDir.path, 'm_20250101000000_create_demo'),
        );
        expect(migrationFolder.existsSync(), isTrue);
        expect(
          File(p.join(migrationFolder.path, 'up.sql')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(migrationFolder.path, 'down.sql')).existsSync(),
          isTrue,
        );
      },
    );
  });
}

class _DemoMigration extends Migration {
  @override
  void down(SchemaBuilder schema) {
    schema.raw('DROP TABLE demo;');
  }

  @override
  void up(SchemaBuilder schema) {
    schema.raw('CREATE TABLE demo (id INTEGER PRIMARY KEY);');
  }
}
