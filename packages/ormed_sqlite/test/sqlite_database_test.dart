import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteDatabase', () {
    test('connects and runs raw queries without generated code', () async {
      final interceptor = RecordingInterceptor();
      final db = await SqliteDatabase.connect(interceptors: [interceptor]);
      addTearDown(db.close);

      expect(db.isOpen, isTrue);
      expect(db.registry.allDefinitions, isEmpty);

      await db.executeRaw(
        'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
      );
      await db.executeRaw('INSERT INTO users (id, name) VALUES (?, ?)', [
        1,
        'Alice',
      ]);

      final rows = await db.queryRaw('SELECT id, name FROM users');
      expect(rows, hasLength(1));
      expect(rows.single['id'], 1);
      expect(rows.single['name'], 'Alice');

      expect(
        interceptor.contexts.map((context) => context.operationName),
        containsAll(<String>['RAW']),
      );

      final statements = <ExecutingStatement>[];
      final queryEvents = <QueryEvent>[];
      final completed = <QueryExecuted>[];
      db.beforeExecuting(statements.add);
      db.onQuery(queryEvents.add);
      db.listen(completed.add);

      final matchingUsers = await db
          .table('users')
          .whereEquals('name', 'Alice')
          .orderBy('name')
          .limit(10)
          .get();
      expect(matchingUsers, hasLength(1));
      expect(matchingUsers.single['name'], 'Alice');
      expect(statements, hasLength(1));
      expect(statements.single.sql, contains('SELECT'));
      expect(queryEvents, hasLength(1));
      expect(queryEvents.single.succeeded, isTrue);
      expect(completed, hasLength(1));

      final created = await db.table('users').create({
        'id': 3,
        'name': 'Carol',
      });
      expect(created, containsPair('id', 3));
      expect(created, containsPair('name', 'Carol'));

      final createdRows = await db
          .table('users')
          .whereEquals('name', 'Carol')
          .get();
      expect(createdRows, hasLength(1));
      expect(createdRows.single, containsPair('id', 3));

      final selectContext = interceptor.contexts.last;
      expect(selectContext.operationName, 'SELECT');
      expect(selectContext.collectionName, 'users');
      expect(selectContext.sql, contains('SELECT'));

      interceptor.clear();
      await db.transaction(() async {
        await db.executeRaw('INSERT INTO users (id, name) VALUES (?, ?)', [
          2,
          'Bob',
        ]);
      });
      final transactionContext = interceptor.contexts.firstWhere(
        (context) => context.operationName == 'TRANSACTION',
      );
      final rawInTransaction = interceptor.contexts.firstWhere(
        (context) =>
            context.operationName == 'RAW' && context.sql.startsWith('INSERT'),
      );
      expect(transactionContext.transactionId, isNotNull);
      expect(rawInTransaction.transactionId, transactionContext.transactionId);
    });

    test(
      'supports schema plans and manual migrations without codegen',
      () async {
        final interceptor = RecordingInterceptor();
        final db = await SqliteDatabase.connect(interceptors: [interceptor]);
        addTearDown(db.close);

        await db.executeSchema((schema) {
          schema.create('users', (table) {
            table.increments('id');
            table.string('name');
          });
        });
        expect(
          interceptor.contexts.map((context) => context.operationName),
          contains('SCHEMA'),
        );

        final migration = MigrationEntry.named(
          'm_20260824000000_create_audit_entries',
          const CreateAuditEntries(),
        );
        final first = await db.migrate([migration]);
        final second = await db.migrate([migration]);

        expect(first.actions, hasLength(1));
        expect(second.actions, isEmpty);
        expect(
          interceptor.contexts.where(
            (context) => context.operationName == 'SCHEMA',
          ),
          isNotEmpty,
        );

        final tables = await db.queryRaw(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        );
        expect(
          tables.map((row) => row['name']),
          containsAll(<Object>['users', 'audit_entries', 'orm_migrations']),
        );
      },
    );
  });
}

class RecordingInterceptor extends QueryInterceptor {
  final contexts = <QueryExecutionContext>[];

  void clear() => contexts.clear();

  @override
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  ) async {
    contexts.add(context);
    return next();
  }
}

class CreateAuditEntries extends Migration {
  const CreateAuditEntries();

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('audit_entries', (table) {
      table.increments('id');
      table.text('event');
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('audit_entries', ifExists: true);
  }
}
