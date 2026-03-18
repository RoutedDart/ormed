import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class MySqlBuiltinTypesRecord extends Model<MySqlBuiltinTypesRecord> {
  const MySqlBuiltinTypesRecord({
    this.id,
    required this.active,
    required this.amount,
    required this.timeValue,
    required this.dateValue,
    required this.dateTimeValue,
    required this.timestampValue,
    required this.uuidValue,
    required this.tags,
    required this.document,
    required this.payload,
    this.bitValue,
    this.geometry,
  });

  final int? id;
  final bool active;
  final Decimal amount;
  final Duration timeValue;
  final DateTime dateValue;
  final DateTime dateTimeValue;
  final DateTime timestampValue;
  final UuidValue uuidValue;
  final Set<String> tags;
  final Map<String, Object?> document;
  final Uint8List payload;
  final MySqlBitString? bitValue;
  final MySqlGeometry? geometry;
}

final class $MySqlBuiltinTypesRecord extends MySqlBuiltinTypesRecord
    with ModelAttributes {
  const $MySqlBuiltinTypesRecord({
    super.id,
    required super.active,
    required super.amount,
    required super.timeValue,
    required super.dateValue,
    required super.dateTimeValue,
    required super.timestampValue,
    required super.uuidValue,
    required super.tags,
    required super.document,
    required super.payload,
    super.bitValue,
    super.geometry,
  });
}

final class _MySqlBuiltinTypesCodec
    extends ModelCodec<MySqlBuiltinTypesRecord> {
  const _MySqlBuiltinTypesCodec();

  @override
  Map<String, Object?> encode(
    MySqlBuiltinTypesRecord model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': model.id,
      'active': registry.encodeByKey('bool', model.active),
      'amount': registry.encodeByKey('Decimal', model.amount),
      'time_value': registry.encodeByKey('Duration', model.timeValue),
      'date_value': registry.encodeByKey('DateTime', model.dateValue),
      'datetime_value': registry.encodeByKey('DateTime', model.dateTimeValue),
      'timestamp_value': registry.encodeByKey('DateTime', model.timestampValue),
      'uuid_value': registry.encodeByKey('UuidValue', model.uuidValue),
      'tags': registry.encodeByKey('Set<String>', model.tags),
      'document': registry.encodeByKey('Map<String, Object?>', model.document),
      'payload': model.payload,
      'bit_value': registry.encodeByKey('MySqlBitString', model.bitValue),
      'geom': registry.encodeByKey('MySqlGeometry', model.geometry),
    };
  }

  @override
  MySqlBuiltinTypesRecord decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    return MySqlBuiltinTypesRecord(
      id: (data['id'] as num?)?.toInt(),
      active: registry.decodeByKey<bool>('bool', data['active']) ?? false,
      amount:
          registry.decodeByKey<Decimal>('Decimal', data['amount']) ??
          Decimal.zero,
      timeValue:
          registry.decodeByKey<Duration>('Duration', data['time_value']) ??
          Duration.zero,
      dateValue:
          registry.decodeByKey<DateTime>('DateTime', data['date_value']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      dateTimeValue:
          registry.decodeByKey<DateTime>('DateTime', data['datetime_value']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      timestampValue:
          registry.decodeByKey<DateTime>('DateTime', data['timestamp_value']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      uuidValue:
          registry.decodeByKey<UuidValue>('UuidValue', data['uuid_value']) ??
          UuidValue.fromString('00000000-0000-0000-0000-000000000000'),
      tags:
          registry.decodeByKey<Set<String>>('Set<String>', data['tags']) ??
          <String>{},
      document:
          registry.decodeByKey<Map<String, Object?>>(
            'Map<String, Object?>',
            data['document'],
          ) ??
          const <String, Object?>{},
      payload: (data['payload'] as Uint8List?) ?? Uint8List(0),
      bitValue: registry.decodeByKey<MySqlBitString>(
        'MySqlBitString',
        data['bit_value'],
      ),
      geometry: registry.decodeByKey<MySqlGeometry>(
        'MySqlGeometry',
        data['geom'],
      ),
    );
  }
}

final ModelDefinition<MySqlBuiltinTypesRecord> _builtinTypesDefinition =
    ModelDefinition<MySqlBuiltinTypesRecord>(
      modelName: 'MySqlBuiltinTypesRecord',
      tableName: 'mysql_builtin_types',
      fields: const [
        FieldDefinition(
          name: 'id',
          columnName: 'id',
          dartType: 'int?',
          resolvedType: 'int?',
          isPrimaryKey: true,
          autoIncrement: true,
          isNullable: true,
        ),
        FieldDefinition(
          name: 'active',
          columnName: 'active',
          dartType: 'bool',
          resolvedType: 'bool',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'amount',
          columnName: 'amount',
          dartType: 'Decimal',
          resolvedType: 'Decimal',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'timeValue',
          columnName: 'time_value',
          dartType: 'Duration',
          resolvedType: 'Duration',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'dateValue',
          columnName: 'date_value',
          dartType: 'DateTime',
          resolvedType: 'DateTime',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'dateTimeValue',
          columnName: 'datetime_value',
          dartType: 'DateTime',
          resolvedType: 'DateTime',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'timestampValue',
          columnName: 'timestamp_value',
          dartType: 'DateTime',
          resolvedType: 'DateTime',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'uuidValue',
          columnName: 'uuid_value',
          dartType: 'UuidValue',
          resolvedType: 'UuidValue',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'tags',
          columnName: 'tags',
          dartType: 'Set<String>',
          resolvedType: 'Set<String>',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'document',
          columnName: 'document',
          dartType: 'Map<String, Object?>',
          resolvedType: 'Map<String, Object?>',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'payload',
          columnName: 'payload',
          dartType: 'Uint8List',
          resolvedType: 'Uint8List',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'bitValue',
          columnName: 'bit_value',
          dartType: 'MySqlBitString?',
          resolvedType: 'MySqlBitString?',
          isNullable: true,
        ),
        FieldDefinition(
          name: 'geometry',
          columnName: 'geom',
          dartType: 'MySqlGeometry?',
          resolvedType: 'MySqlGeometry?',
          isNullable: true,
        ),
      ],
      codec: _MySqlBuiltinTypesCodec(),
    );

class _CreateMysqlBuiltinTypesTable extends Migration {
  const _CreateMysqlBuiltinTypesTable();

  MigrationId get id =>
      MigrationId(DateTime.utc(2025, 1, 1, 0, 0, 2), 'mysql_builtin_types');

  @override
  void up(SchemaBuilder schema) {
    schema.create('mysql_builtin_types', (table) {
      table.id();
      table.boolean('active');
      table.decimal('amount', precision: 18, scale: 6);
      table.column(
        'time_value',
        const ColumnType(ColumnTypeName.time, precision: 6),
      );
      table.date('date_value');
      table.dateTime('datetime_value', precision: 6);
      table.timestamp('timestamp_value', timezoneAware: true, precision: 6);
      table.uuid('uuid_value');
      table.set('tags', ['alpha', 'beta', 'gamma']);
      table.json('document');
      table.binary('payload');
      table.column('bit_value', const ColumnType.custom('BIT(4)')).nullable();
      table.geometry('geom').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('mysql_builtin_types', ifExists: true, cascade: true);
  }
}

Future<void> main() async {
  final url =
      OrmedEnvironment().firstNonEmpty(['MYSQL_URL']) ??
      'mysql://root:secret@localhost:6605/orm_test';

  MySqlDriverAdapter.registerCodecs();

  final registry = ModelRegistry()
    ..register<MySqlBuiltinTypesRecord>(_builtinTypesDefinition);

  final adapter = MySqlDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mysql', options: {'url': url, 'ssl': true}),
  );

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'mysql_builtin_types_base',
      driver: adapter,
      entities: [_builtinTypesDefinition],
      registry: registry,
    ),
  );
  await dataSource.init();

  final config = setUpOrmed(
    dataSource: dataSource,
    migrationDescriptors: [
      MigrationDescriptor.fromMigration(
        id: const _CreateMysqlBuiltinTypesTable().id,
        migration: const _CreateMysqlBuiltinTypesTable(),
      ),
    ],
    strategy: DatabaseIsolationStrategy.recreate,
    adapterFactory: (_) => MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: {'url': url, 'ssl': true},
      ),
    ),
  );

  tearDownAll(() async {
    await dataSource.dispose();
  });

  ormedGroup('MySQL built-in type hydration', (scopedDataSource) {
    test('round-trips core builtins via repository', () async {
      final amount = Decimal.parse('123.450000');
      final timeValue = const Duration(
        hours: 12,
        minutes: 34,
        seconds: 56,
        microseconds: 123456,
      );
      final dateValue = DateTime.utc(2024, 1, 2);
      final dateTimeValue = DateTime.utc(2024, 1, 2, 3, 4, 5, 123, 456);
      final timestampValue = DateTime.utc(2024, 1, 2, 3, 4, 6, 234, 567);
      final uuidValue = UuidValue.fromString(const Uuid().v4());
      final tags = <String>{'alpha', 'beta'};
      final document = <String, Object?>{'hello': 'world', 'count': 1};
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);

      final created = await scopedDataSource
          .repo<MySqlBuiltinTypesRecord>()
          .insert(
            $MySqlBuiltinTypesRecord(
              active: true,
              amount: amount,
              timeValue: timeValue,
              dateValue: dateValue,
              dateTimeValue: dateTimeValue,
              timestampValue: timestampValue,
              uuidValue: uuidValue,
              tags: tags,
              document: document,
              payload: payload,
            ),
          );

      expect(created.id, isNotNull);
      expect(created.amount, equals(amount));
      expect(created.timeValue, equals(timeValue));
      expect(created.uuidValue, equals(uuidValue));
      expect(created.tags, equals(tags));
      expect(created.document, equals(document));
      expect(created.payload, equals(payload));
      expect(created.bitValue, isNull);
      expect(created.geometry, isNull);

      final fetched = await scopedDataSource.context
          .query<MySqlBuiltinTypesRecord>()
          .whereEquals('id', created.id)
          .first();

      expect(fetched, isNotNull);
      expect(fetched!.amount, equals(amount));
      expect(fetched.timeValue, equals(timeValue));
      expect(fetched.uuidValue, equals(uuidValue));
      expect(fetched.tags, equals(tags));
      expect(fetched.document, equals(document));
      expect(fetched.payload, equals(payload));
    });

    test('decodes BIT and GEOMETRY values', () async {
      final payload = Uint8List.fromList([10, 20, 30]);
      final uuidValue = UuidValue.fromString(const Uuid().v4());

      await scopedDataSource.connection.driver.executeRaw(
        'INSERT INTO mysql_builtin_types (active, amount, time_value, date_value, datetime_value, timestamp_value, uuid_value, tags, document, payload, bit_value, geom) '
        "VALUES (1, '1.000000', '00:00:01.000001', '2024-01-02', '2024-01-02 03:04:05.000000', '2024-01-02 03:04:06.000000', ?, 'alpha,beta', '{\"ok\":true}', ?, b'1010', ST_GeomFromText(?))",
        [uuidValue.toString(), payload, 'POINT(1 2)'],
      );

      final fetched = await scopedDataSource.context
          .query<MySqlBuiltinTypesRecord>()
          .orderBy('id', descending: true)
          .first();
      expect(fetched, isNotNull);
      expect(fetched!.bitValue, isNotNull);
      expect(fetched.bitValue!.bytes, equals(Uint8List.fromList([10])));
      expect(fetched.geometry, isNotNull);
      expect(fetched.geometry!.bytes, isNotEmpty);
    });
  }, config: config);
}
