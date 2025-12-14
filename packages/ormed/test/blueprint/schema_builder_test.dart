import 'package:ormed/migrations.dart';
import 'package:ormed/src/model_definition.dart';
import 'package:ormed/src/value_codec.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaBuilder', () {
    test('captures create table blueprint with constraints', () {
      final builder = SchemaBuilder();

      builder.create('users', (table) {
        table.increments('id');
        table.string('name').nullable();
        table.string('email').unique();
        table.timestamp('created_at').useCurrentTimestamp();
      });

      final plan = builder.build(description: 'create-users');
      expect(plan.mutations, hasLength(1));

      final create = plan.mutations.first;
      expect(create.operation, SchemaMutationOperation.createTable);
      final blueprint = create.blueprint!;
      expect(blueprint.columns, hasLength(4));

      final idColumn = blueprint.columns.first;
      expect(idColumn.definition!.primaryKey, isTrue);
      expect(idColumn.definition!.autoIncrement, isTrue);

      final emailColumn = blueprint.columns.firstWhere(
        (column) => column.name == 'email',
      );
      expect(emailColumn.definition!.unique, isTrue);

      expect(plan.checksum(), hasLength(40));
    });

    test('captures alter table operations', () {
      final builder = SchemaBuilder();

      builder.table('users', (table) {
        table.string('nickname');
        table.dropColumn('legacy_email');
        table.renameColumn('phone', 'mobile');
        table.unique(['email'], name: 'users_email_unique');
        table.dropIndex('users_old_idx');
        table
            .string('display_name')
            .defaultValue('Guest')
            .change()
            .useCurrentOnUpdate();
      });

      final plan = builder.build();
      final alter = plan.mutations.single;
      expect(alter.operation, SchemaMutationOperation.alterTable);
      final blueprint = alter.blueprint!;

      expect(blueprint.columns.length, equals(3));
      expect(
        blueprint.columns
            .where((column) => column.kind == ColumnCommandKind.drop)
            .single
            .name,
        'legacy_email',
      );
      expect(blueprint.renamedColumns.single.from, 'phone');
      expect(blueprint.indexes.last.kind, IndexCommandKind.drop);
      final alteredColumn = blueprint.columns.firstWhere(
        (column) => column.name == 'display_name',
      );
      expect(alteredColumn.kind, ColumnCommandKind.alter);
      expect(alteredColumn.definition!.defaultValue?.value, 'Guest');
      expect(alteredColumn.definition!.useCurrentOnUpdate, isTrue);
    });

    test('captures advanced column helpers and implied indexes', () {
      final builder = SchemaBuilder();

      builder.create('libraries', (table) {
        table.useEngine('InnoDB');
        table.charset('utf8mb4');
        table.collation('utf8mb4_unicode_ci');
        table.setTableComment('Primary libraries table');

        table.string('code').unique().charset('utf8mb4');
        table.smallInteger('rating', unsigned: true).defaultValue(1);
        table.float('ratio', precision: 8, scale: 2);
        table.double('score', precision: 14, scale: 4);
        table
            .enum_('status', ['draft', 'published'])
            .defaultValue('draft')
            .after('code');
        table.jsonb('metadata');
        table.timestamps();
      });

      final mutation = builder.build().mutations.single;
      final blueprint = mutation.blueprint!;

      expect(blueprint.engine, 'InnoDB');
      expect(blueprint.tableCharset, 'utf8mb4');
      expect(blueprint.tableCollation, 'utf8mb4_unicode_ci');
      expect(blueprint.tableComment, 'Primary libraries table');

      final statusColumn = _columnDefinition(blueprint, 'status');
      expect(statusColumn?.allowedValues, equals(['draft', 'published']));
      expect(statusColumn?.afterColumn, 'code');

      final indexNames = blueprint.indexes
          .where((index) => index.kind == IndexCommandKind.add)
          .map((index) => index.definition?.name)
          .whereType<String>()
          .toList();
      expect(indexNames, contains('libraries_code_unique'));
    });

    test(
      'timestamps, soft deletes, and morphs helpers add expected columns',
      () {
        final builder = SchemaBuilder();

        builder.create('attachments', (table) {
          table.timestamps(useCurrent: true);
          table.softDeletes();
          table.morphs('attachable');
        });

        final columns = builder.build().mutations.single.blueprint!.columns;
        final names = columns.map((column) => column.name).toSet();
        expect(
          names,
          containsAll([
            'created_at',
            'updated_at',
            'deleted_at',
            'attachable_id',
            'attachable_type',
          ]),
        );
      },
    );

    test('provides snapshot helpers when configured', () {
      final snapshot = SchemaSnapshot(
        schemas: const [SchemaNamespace(name: 'main', isDefault: true)],
        tables: const [SchemaTable(name: 'users', schema: 'main')],
        views: const [],
        columns: const [
          SchemaColumn(name: 'id', dataType: 'INTEGER', tableName: 'users'),
          SchemaColumn(name: 'email', dataType: 'TEXT', tableName: 'users'),
        ],
        indexes: const [],
        foreignKeys: const [],
      );
      final builder = SchemaBuilder(snapshot: snapshot);

      expect(builder.hasSnapshot, isTrue);
      expect(builder.hasTable('users'), isTrue);
      expect(builder.hasColumn('users', 'email'), isTrue);
      expect(builder.columnType('users', 'email'), equals('TEXT'));
      expect(builder.tableListing(schemaQualified: false), contains('users'));
    });
  });

  test('migration descriptor computes deterministic checksum', () {
    final migration = _CreateUsersMigration();
    final descriptor = MigrationDescriptor.fromMigration(
      id: MigrationId.parse('2025_01_01_000000_create_users'),
      migration: migration,
    );

    expect(descriptor.up.mutations, isNotEmpty);
    expect(descriptor.down.mutations, isNotEmpty);
    expect(descriptor.checksum.length, 40);
  });

  test('model snapshot converts model definitions to blueprints', () {
    final definition = ModelDefinition<AdHocRow>(
      modelName: 'User',
      tableName: 'users',
      codec: const _FakeCodec(),
      fields: const [
        FieldDefinition(
          name: 'id',
          columnName: 'id',
          dartType: 'int',
          resolvedType: 'int',
          isPrimaryKey: true,
          isNullable: false,
          isUnique: true,
          isIndexed: true,
          autoIncrement: true,
        ),
        FieldDefinition(
          name: 'email',
          columnName: 'email',
          dartType: 'String',
          resolvedType: 'String',
          isPrimaryKey: false,
          isNullable: false,
          isUnique: true,
          isIndexed: true,
          autoIncrement: false,
        ),
      ],
    );

    final graph = ModelGraphSnapshot([definition]);
    final usersTable = graph.tableByName('users');
    expect(usersTable, isNotNull);

    final blueprint = usersTable!.toCreateBlueprint();
    expect(blueprint.columns, hasLength(2));
    final columnNames = blueprint.columns.map((c) => c.name).toList();
    expect(columnNames, containsAll(['id', 'email']));
  });
}

ColumnDefinition? _columnDefinition(TableBlueprint blueprint, String name) {
  return blueprint.columns
      .firstWhere((column) => column.name == name && column.definition != null)
      .definition;
}

class _CreateUsersMigration extends Migration {
  const _CreateUsersMigration();

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('users', ifExists: true, cascade: true);
  }

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('users', (table) {
      table.increments('id');
      table.string('name');
      table.string('email').unique();
    });
  }
}

class _FakeCodec extends ModelCodec<AdHocRow> {
  const _FakeCodec();

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) =>
      Map<String, Object?>.from(model);

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) =>
      AdHocRow(data);
}
