import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed_cli/src/commands/base/shared.dart';
import 'package:ormed_cli/src/commands/migrate/makemigrations_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MakeMigrationsCommand', () {
    late Directory repoRoot;
    late Directory scratchDir;
    late File ormConfig;
    late ModelSchemaLoader previousLoader;

    setUp(() async {
      repoRoot = Directory.current;
      final scratchParent = Directory(
        p.join(Directory.systemTemp.path, 'ormed_cli_tests'),
      )..createSync(recursive: true);
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          'makemigrations_${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);

      File(p.join(scratchDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

      ormConfig = File(p.join(scratchDir.path, 'ormed.yaml'))
        ..writeAsStringSync('''
driver:
  type: sqlite
  options:
    database: database/test.sqlite
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
  ledger_table: orm_migrations
  schema_dump: database/schema.sql
''');

      final registryFile = File(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations.dart'),
      );
      registryFile.parent.createSync(recursive: true);
      registryFile.writeAsStringSync(initialRegistryTemplate);

      final ormRegistry = File(
        p.join(
          scratchDir.path,
          'lib',
          'src',
          'database',
          'orm_registry.g.dart',
        ),
      );
      ormRegistry.parent.createSync(recursive: true);
      ormRegistry.writeAsStringSync('// test placeholder');

      previousLoader = modelSchemaLoader;
      modelSchemaLoader = _FakeModelSchemaLoader(const [
        ModelSchemaTable(
          modelName: 'User',
          tableName: 'users',
          schema: null,
          columns: [
            ModelSchemaColumn(
              name: 'id',
              columnName: 'id',
              resolvedType: 'int',
              columnType: null,
              isNullable: false,
              isPrimaryKey: true,
              isUnique: false,
              isIndexed: false,
              autoIncrement: true,
            ),
            ModelSchemaColumn(
              name: 'email',
              columnName: 'email',
              resolvedType: 'String',
              columnType: null,
              isNullable: false,
              isPrimaryKey: false,
              isUnique: true,
              isIndexed: true,
              autoIncrement: false,
            ),
          ],
        ),
      ]);

      Directory.current = scratchDir;
    });

    tearDown(() async {
      modelSchemaLoader = previousLoader;
      Directory.current = repoRoot;
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    test('generates migration from model diff and syncs registry', () async {
      final runner = CommandRunner<void>('ormed', 'ORM CLI')
        ..addCommand(MakeMigrationsCommand());

      await runner.run([
        'makemigrations',
        '--config',
        p.relative(ormConfig.path, from: Directory.current.path),
      ]);

      final migrationsDir = Directory(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations'),
      );
      final created = migrationsDir.listSync().whereType<File>().singleWhere(
        (f) => p.basename(f.path).endsWith('.dart'),
      );
      final migrationId = p.basenameWithoutExtension(created.path);
      final migrationText = created.readAsStringSync();
      expect(migrationText, contains("schema.create('users'"));
      expect(migrationText, contains("table.column('id'"));
      expect(migrationText, contains("table.column('email'"));

      final registryText = File(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations.dart'),
      ).readAsStringSync();
      expect(registryText, contains("'$migrationId'"));
    });
  });
}

class _FakeModelSchemaLoader implements ModelSchemaLoader {
  const _FakeModelSchemaLoader(this.tables);

  final List<ModelSchemaTable> tables;

  @override
  Future<List<ModelSchemaTable>> load({
    required Directory root,
    required String packageName,
    required String ormRegistryPath,
  }) async {
    return tables;
  }
}
