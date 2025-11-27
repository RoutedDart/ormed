import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaDiffer', () {
    late SchemaSnapshot snapshot;

    setUp(() {
      snapshot = SchemaSnapshot(
        schemas: const [],
        tables: const [SchemaTable(name: 'users')],
        views: const [],
        columns: const [
          SchemaColumn(name: 'id', dataType: 'integer', tableName: 'users'),
          SchemaColumn(name: 'email', dataType: 'text', tableName: 'users'),
        ],
        indexes: const [
          SchemaIndex(
            name: 'users_email_index',
            columns: ['email'],
            tableName: 'users',
          ),
        ],
        foreignKeys: const [],
      );
    });

    test('warns when creating an existing table', () {
      final builder = SchemaBuilder()
        ..create('users', (table) {
          table.increments('id');
        });

      final plan = builder.build();
      final diff = SchemaDiffer().diff(plan: plan, snapshot: snapshot);

      expect(diff.entries, hasLength(1));
      final entry = diff.entries.single;
      expect(entry.action, SchemaDiffAction.createTable);
      expect(entry.severity, SchemaDiffSeverity.warning);
      expect(entry.description, contains('users'));
    });

    test('detects column/index changes on alter table', () {
      final builder = SchemaBuilder()
        ..table('users', (table) {
          table.string('nickname');
          table.dropColumn('email');
          table.renameColumn('id', 'user_id');
          table.index(['nickname'], name: 'users_nick_index');
          table.dropIndex('users_email_index');
        });

      final plan = builder.build();
      final diff = SchemaDiffer().diff(plan: plan, snapshot: snapshot);

      expect(
        diff.entries.map((e) => e.action),
        containsAll(<SchemaDiffAction>[
          SchemaDiffAction.addColumn,
          SchemaDiffAction.dropColumn,
          SchemaDiffAction.renameColumn,
          SchemaDiffAction.addIndex,
          SchemaDiffAction.dropIndex,
        ]),
      );
      final dropColumn = diff.entries.firstWhere(
        (entry) => entry.action == SchemaDiffAction.dropColumn,
      );
      expect(dropColumn.severity, SchemaDiffSeverity.info);
    });
  });
}
