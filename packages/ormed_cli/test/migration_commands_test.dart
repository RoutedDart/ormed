import 'dart:io';

import 'package:args/command_runner.dart';
import '../lib/src/commands.dart';
import '../lib/src/commands/shared.dart';
import 'package:ormed/ormed.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'models/cli_user.dart';

void main() {
  group('migration commands', () {
    late Directory repoRoot;
    late Directory scratchDir;
    late String dbPath;
    late File ormConfig;
    late String configArg;
    late CommandRunner<void> runner;

    setUp(() async {
      repoRoot = Directory.current;
      final scratchParent = Directory(
        p.join(repoRoot.path, '.dart_tool', 'ormed_cli_tests'),
      );
      if (!scratchParent.existsSync()) {
        scratchParent.createSync(recursive: true);
      }
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          'case_${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);
      dbPath = p.join(scratchDir.path, 'test.sqlite');
      runner = CommandRunner<void>('orm', 'Routed ORM CLI')
        ..addCommand(InitCommand())
        ..addCommand(MakeCommand())
        ..addCommand(ApplyCommand())
        ..addCommand(RollbackCommand())
        ..addCommand(StatusCommand())
        ..addCommand(SeedCommand())
        ..addCommand(SchemaDescribeCommand());
      ormConfig = File(p.join(scratchDir.path, 'orm.yaml'))
        ..writeAsStringSync(
          _ormYaml(
            databasePath: p.relative(dbPath, from: repoRoot.path),
            migrationsDir: p.relative(
              p.join(scratchDir.path, 'migrations'),
              from: repoRoot.path,
            ),
            registryPath: p.relative(
              p.join(scratchDir.path, 'migrations.dart'),
              from: repoRoot.path,
            ),
            seedsDir: p.relative(
              p.join(scratchDir.path, 'seeds'),
              from: repoRoot.path,
            ),
            seedsRegistry: p.relative(
              p.join(scratchDir.path, 'seeders.dart'),
              from: repoRoot.path,
            ),
            schemaDumpPath: p.relative(
              p.join(scratchDir.path, 'schema_dump.sql'),
              from: repoRoot.path,
            ),
          ),
        );
      configArg = p.relative(ormConfig.path, from: repoRoot.path);
      _writeMigrationFiles(scratchDir);
      _writeSeedFiles(scratchDir);
    });

    tearDown(() async {
      if (ormConfig.existsSync()) {
        ormConfig.deleteSync();
      }
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
    });

    test('apply, status, rollback execute migrations end-to-end', () async {
      final config = loadOrmProjectConfig(ormConfig);
      final connectionName = connectionNameForConfig(repoRoot, config);

      await runner.run(['apply', '--config', configArg]);
      expect(
        ConnectionManager.defaultManager.isRegistered(connectionName),
        isFalse,
      );

      await _expectTableExists(repoRoot, ormConfig, 'users');
      await _expectLedgerCount(repoRoot, ormConfig, 1);

      await runner.run(['status', '--config', configArg]);
      expect(
        ConnectionManager.defaultManager.isRegistered(connectionName),
        isFalse,
      );

      await runner.run(['rollback', '--config', configArg]);
      await _expectTableAbsent(repoRoot, ormConfig, 'users');
      await _expectLedgerCount(repoRoot, ormConfig, 0);
      expect(
        ConnectionManager.defaultManager.isRegistered(connectionName),
        isFalse,
      );
    });

    test('auto-detects orm.yaml from nested directories', () async {
      final previousCwd = Directory.current;
      final nested = _locateOrmCliPackage(repoRoot);
      expect(nested.existsSync(), isTrue);

      final nestedConfig = File(p.join(nested.path, 'orm.yaml'))
        ..writeAsStringSync(
          _ormYaml(
            databasePath: p.relative(dbPath, from: nested.path),
            migrationsDir: p.relative(
              p.join(scratchDir.path, 'migrations'),
              from: nested.path,
            ),
            registryPath: p.relative(
              p.join(scratchDir.path, 'migrations.dart'),
              from: nested.path,
            ),
            seedsDir: p.relative(
              p.join(scratchDir.path, 'seeds'),
              from: nested.path,
            ),
            seedsRegistry: p.relative(
              p.join(scratchDir.path, 'seeders.dart'),
              from: nested.path,
            ),
          ),
        );

      Directory.current = nested;
      try {
        await runner.run(['apply']);
        await runner.run(['rollback']);
      } finally {
        Directory.current = previousCwd;
        if (nestedConfig.existsSync()) {
          nestedConfig.deleteSync();
        }
      }
    });

    test('seed command runs registry script', () async {
      final logFile = File(p.join(scratchDir.path, 'seed.log'));
      if (logFile.existsSync()) {
        logFile.deleteSync();
      }
      await runner.run([
        'seed',
        '--config',
        configArg,
        '--class',
        'TestSeeder',
      ]);
      expect(logFile.existsSync(), isTrue);
      expect(logFile.readAsStringSync(), contains('TestSeeder'));
    });

    test('load multi-tenant orm.yaml and select connection', () {
      final multiConfig = File(p.join(scratchDir.path, 'orm.multi.yaml'))
        ..writeAsStringSync(
          _multiTenantOrmYaml(
            defaultDatabasePath: p.relative(dbPath, from: repoRoot.path),
            analyticsDatabasePath: p.relative(
              p.join(scratchDir.path, 'analytics.sqlite'),
              from: repoRoot.path,
            ),
            migrationsDir: p.relative(
              p.join(scratchDir.path, 'migrations'),
              from: repoRoot.path,
            ),
            registryPath: p.relative(
              p.join(scratchDir.path, 'migrations.dart'),
              from: repoRoot.path,
            ),
            seedsDir: p.relative(
              p.join(scratchDir.path, 'seeds'),
              from: repoRoot.path,
            ),
            seedsRegistry: p.relative(
              p.join(scratchDir.path, 'seeders.dart'),
              from: repoRoot.path,
            ),
          ),
        );

      final config = loadOrmProjectConfig(multiConfig);
      expect(config.connections.keys, containsAll(['default', 'analytics']));
      expect(config.connectionName, 'default');

      final analytics = config.withConnection('analytics');
      expect(analytics.connectionName, 'analytics');
      expect(
        analytics.driver.option('database'),
        equals(
          p.relative(
            p.join(scratchDir.path, 'analytics.sqlite'),
            from: repoRoot.path,
          ),
        ),
      );
    });

    test('apply --seed executes default seeder', () async {
      final logFile = File(p.join(scratchDir.path, 'seed.log'));
      if (logFile.existsSync()) {
        logFile.deleteSync();
      }
      await runner.run(['apply', '--config', configArg, '--seed']);
      expect(logFile.existsSync(), isTrue);
      expect(logFile.readAsStringSync(), contains('TestSeeder'));
    });

    test('apply --pretend preserves schema and ledger state', () async {
      await runner.run(['apply', '--config', configArg, '--pretend']);
      await _expectLedgerCount(repoRoot, ormConfig, 0);
      await _expectTableAbsent(repoRoot, ormConfig, 'users');
    });

    test('apply loads schema dump before running migrations', () async {
      final schemaDump = File(p.join(scratchDir.path, 'schema_dump.sql'));
      schemaDump.writeAsStringSync('CREATE TABLE baseline (id INTEGER);\n');
      await runner.run([
        'apply',
        '--config',
        configArg,
        '--schema-path',
        p.relative(schemaDump.path, from: repoRoot.path),
      ]);
      await _expectTableExists(repoRoot, ormConfig, 'baseline');
    });

    test('rollback --pretend preserves schema and ledger', () async {
      await runner.run(['apply', '--config', configArg]);
      await runner.run(['rollback', '--config', configArg, '--pretend']);
      await _expectLedgerCount(repoRoot, ormConfig, 1);
      await _expectTableExists(repoRoot, ormConfig, 'users');
    });

    test(
      'status --pending exits with failure when migrations remain',
      () async {
        exitCode = 0;
        await runner.run(['status', '--config', configArg, '--pending']);
        expect(exitCode, 1);
        exitCode = 0;
      },
    );

    test('schema describe refreshes schema dump', () async {
      final schemaDump = File(p.join(scratchDir.path, 'schema_dump.sql'));
      schemaDump.writeAsStringSync('');
      await runner.run(['apply', '--config', configArg]);
      await runner.run(['schema:describe', '--config', configArg]);
      final contents = schemaDump.readAsStringSync();
      expect(contents, contains('CREATE TABLE IF NOT EXISTS "users"'));
    });

    test('apply reuses schema dump produced by schema:describe', () async {
      final schemaDump = File(p.join(scratchDir.path, 'schema_dump.sql'));
      schemaDump.writeAsStringSync('');
      await runner.run(['apply', '--config', configArg]);
      await runner.run(['schema:describe', '--config', configArg]);
      final contents = schemaDump.readAsStringSync();
      expect(contents, contains('CREATE TABLE IF NOT EXISTS "users"'));

      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }

      await runner.run(['apply', '--config', configArg]);
      await _expectTableExists(repoRoot, ormConfig, 'users');
      await _expectLedgerCount(repoRoot, ormConfig, 1);
    });
  });
}

Directory _locateOrmCliPackage(Directory start) {
  final normalized = Directory(p.normalize(start.absolute.path));
  if (_isOrmCliPackage(normalized)) {
    return normalized;
  }

  var cursor = normalized;
  while (true) {
    final candidate = Directory(
      p.join(cursor.path, 'packages', 'orm', 'ormed_cli'),
    );
    if (_isOrmCliPackage(candidate)) {
      return candidate;
    }
    final parent = cursor.parent;
    if (parent.path == cursor.path) {
      throw StateError(
        'Unable to locate packages/orm/ormed_cli relative to ${start.path}',
      );
    }
    cursor = parent;
  }
}

bool _isOrmCliPackage(Directory directory) {
  final pubspec = File(p.join(directory.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    return false;
  }
  final contents = pubspec.readAsStringSync();
  return RegExp(r'^name:\s+ormed_cli\b', multiLine: true).hasMatch(contents);
}

String _ormYaml({
  required String databasePath,
  required String migrationsDir,
  required String registryPath,
  required String seedsDir,
  required String seedsRegistry,
  String schemaDumpPath = 'database/schema.sql',
}) =>
    '''
driver:
  type: sqlite
  options:
    database: $databasePath
migrations:
  directory: $migrationsDir
  registry: $registryPath
  schema_dump: $schemaDumpPath
  ledger_table: orm_migrations
seeds:
  directory: $seedsDir
  registry: $seedsRegistry
  default_class: TestSeeder
''';

String _multiTenantOrmYaml({
  required String defaultDatabasePath,
  required String analyticsDatabasePath,
  required String migrationsDir,
  required String registryPath,
  required String seedsDir,
  required String seedsRegistry,
  String schemaDumpPath = 'database/schema.sql',
}) =>
    '''
default_connection: default
connections:
  default:
    driver:
      type: sqlite
      options:
        database: $defaultDatabasePath
    migrations:
      directory: $migrationsDir
      registry: $registryPath
      ledger_table: orm_migrations
      schema_dump: $schemaDumpPath
    seeds:
      directory: $seedsDir
      registry: $seedsRegistry
      default_class: TestSeeder
  analytics:
    driver:
      type: sqlite
      options:
        database: $analyticsDatabasePath
    migrations:
      directory: $migrationsDir
      registry: $registryPath
      ledger_table: orm_migrations
      schema_dump: $schemaDumpPath
    seeds:
      directory: $seedsDir
      registry: $seedsRegistry
      default_class: TestSeeder
''';

void _writeMigrationFiles(Directory scratchDir) {
  final migrationsDir = Directory(p.join(scratchDir.path, 'migrations'))
    ..createSync(recursive: true);
  final migrationFile = File(p.join(migrationsDir.path, 'create_users.dart'))
    ..writeAsStringSync(_migrationLibrary);
  File(p.join(scratchDir.path, 'migrations.dart')).writeAsStringSync(
    _registryLibrary(p.relative(migrationFile.path, from: scratchDir.path)),
  );
}

void _writeSeedFiles(Directory scratchDir) {
  final seedsDir = Directory(p.join(scratchDir.path, 'seeds'))
    ..createSync(recursive: true);
  File(
    p.join(seedsDir.path, 'test_seeder.dart'),
  ).writeAsStringSync('class TestSeeder {}\n');
  File(
    p.join(scratchDir.path, 'seeders.dart'),
  ).writeAsStringSync(_seedRegistryLibrary);
}

Future<void> _expectTableExists(
  Directory repoRoot,
  File ormConfig,
  String table,
) async {
  final config = loadOrmProjectConfig(ormConfig);
  final handle = await createConnection(repoRoot, config);
  try {
    await handle.use((connection) async {
      _registerCliModels(connection);
      final driver = connection.driver;
      expect(driver, isA<SchemaDriver>());
      final snapshot = await SchemaSnapshot.capture(driver as SchemaDriver);
      final exists = snapshot.tables.any((t) => t.name == table);
      expect(exists, isTrue, reason: 'Expected table $table to exist.');
    });
  } finally {
    await handle.dispose();
  }
}

Future<void> _expectTableAbsent(
  Directory repoRoot,
  File ormConfig,
  String table,
) async {
  final config = loadOrmProjectConfig(ormConfig);
  final handle = await createConnection(repoRoot, config);
  try {
    await handle.use((connection) async {
      _registerCliModels(connection);
      final driver = connection.driver;
      expect(driver, isA<SchemaDriver>());
      final snapshot = await SchemaSnapshot.capture(driver as SchemaDriver);
      final exists = snapshot.tables.any((t) => t.name == table);
      expect(exists, isFalse, reason: 'Expected table $table to be dropped.');
    });
  } finally {
    await handle.dispose();
  }
}

Future<void> _expectLedgerCount(
  Directory repoRoot,
  File ormConfig,
  int expected,
) async {
  final config = loadOrmProjectConfig(ormConfig);
  final handle = await createConnection(repoRoot, config);
  try {
    final ledger = SqlMigrationLedger.managed(
      connectionName: handle.name,
      manager: handle.manager,
      tableName: config.migrations.ledgerTable,
    );
    await handle.use((_) async {
      final applied = await ledger.readApplied();
      expect(applied.length, expected);
    });
  } finally {
    await handle.dispose();
  }
}

void _registerCliModels(OrmConnection connection) {
  connection.context.registry.register(CliUserOrmDefinition.definition);
}

const _migrationLibrary = '''
import 'package:ormed/migrations.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.increments('id');
      table.string('email');
      table.boolean('active').defaultValue(true);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
''';

String _registryLibrary(String migrationImportPath) =>
    '''
import 'dart:convert';

import 'package:ormed/migrations.dart';
import '$migrationImportPath';

class _MigrationEntry {
  const _MigrationEntry({required this.id, required this.migration});

  final MigrationId id;
  final Migration migration;
}

final List<_MigrationEntry> _entries = [
  _MigrationEntry(
    id: MigrationId.parse('2024_01_01_000000_create_users_table'),
    migration: const CreateUsersTable(),
  ),
];

List<MigrationDescriptor> buildMigrations() =>
    List.unmodifiable(_entries.map(
      (entry) => MigrationDescriptor.fromMigration(
        id: entry.id,
        migration: entry.migration,
      ),
    ));

_MigrationEntry? _findEntry(String rawId) {
  for (final entry in _entries) {
    if (entry.id.toString() == rawId) return entry;
  }
  return null;
}

void main(List<String> args) {
  if (args.contains('--dump-json')) {
    final payload = buildMigrations().map((m) => m.toJson()).toList();
    print(jsonEncode(payload));
    return;
  }

  final planIndex = args.indexOf('--plan-json');
  if (planIndex != -1) {
    final id = args[planIndex + 1];
    final entry = _findEntry(id);
    if (entry == null) {
      throw StateError('Unknown migration id \$id.');
    }
    final directionName = args[args.indexOf('--direction') + 1];
    final direction = MigrationDirection.values.byName(directionName);
    final snapshotIndex = args.indexOf('--schema-snapshot');
    SchemaSnapshot? snapshot;
    if (snapshotIndex != -1) {
      final decoded =
          utf8.decode(base64.decode(args[snapshotIndex + 1]));
      final payload = jsonDecode(decoded) as Map<String, Object?>;
      snapshot = SchemaSnapshot.fromJson(payload);
    }
    final plan = entry.migration.plan(direction, snapshot: snapshot);
    print(jsonEncode(plan.toJson()));
  }
}
''';

const _seedRegistryLibrary = r'''
import 'dart:io';

import 'package:ormed_cli/runtime.dart';
import 'package:ormed/ormed.dart';

final List<SeederRegistration> _seeders = [
  SeederRegistration(
    name: 'TestSeeder',
    factory: TestSeeder.new,
  ),
];

class TestSeeder extends Seeder {
  TestSeeder(SeedContext context) : super(context);

  @override
  Future<void> run() async {
    final scriptDir = File(Platform.script.toFilePath()).parent;
    final log = File('${scriptDir.path}/seed.log');
    log.writeAsStringSync('TestSeeder\n', mode: FileMode.append, flush: true);
  }
}

Future<void> runProjectSeeds(
  OrmConnection connection, {
  List<String>? names,
  bool pretend = false,
}) => runSeedRegistryOnConnection(
      connection,
      _seeders,
      names: names,
      pretend: pretend,
    );

Future<void> main(List<String> args) =>
    runSeedRegistryEntrypoint(args: args, seeds: _seeders);
''';
