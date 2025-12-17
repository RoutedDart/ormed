import 'dart:io';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/migrations.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class BuiltinTypesRecord extends Model<BuiltinTypesRecord> {
  const BuiltinTypesRecord({
    this.id,
    required this.uuidValue,
    required this.uuidValues,
    required this.amount,
    required this.duration,
    required this.document,
    required this.query,
    required this.intRange,
    required this.dateRange,
    required this.timeRange,
    required this.ip,
    required this.subnet,
    required this.mac,
    required this.payload,
  });

  final int? id;
  final UuidValue uuidValue;
  final List<UuidValue> uuidValues;
  final Decimal amount;
  final Interval duration;
  final TsVector document;
  final TsQuery query;
  final IntRange intRange;
  final DateRange dateRange;
  final DateTimeRange timeRange;
  final PgInet ip;
  final PgCidr subnet;
  final PgMacAddress mac;
  final Uint8List payload;
}

final ModelDefinition<BuiltinTypesRecord> _builtinTypesDefinition =
    ModelDefinition<BuiltinTypesRecord>(
      modelName: 'BuiltinTypesRecord',
      tableName: 'postgres_builtin_types',
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
          name: 'uuidValue',
          columnName: 'uuid_value',
          dartType: 'UuidValue',
          resolvedType: 'UuidValue',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'uuidValues',
          columnName: 'uuid_values',
          dartType: 'List<UuidValue>',
          resolvedType: 'List<UuidValue>',
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
          name: 'duration',
          columnName: 'duration',
          dartType: 'Interval',
          resolvedType: 'Interval',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'document',
          columnName: 'document',
          dartType: 'TsVector',
          resolvedType: 'TsVector',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'query',
          columnName: 'query',
          dartType: 'TsQuery',
          resolvedType: 'TsQuery',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'intRange',
          columnName: 'int_range',
          dartType: 'IntRange',
          resolvedType: 'IntRange',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'dateRange',
          columnName: 'date_range',
          dartType: 'DateRange',
          resolvedType: 'DateRange',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'timeRange',
          columnName: 'time_range',
          dartType: 'DateTimeRange',
          resolvedType: 'DateTimeRange',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'ip',
          columnName: 'ip',
          dartType: 'PgInet',
          resolvedType: 'PgInet',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'subnet',
          columnName: 'subnet',
          dartType: 'PgCidr',
          resolvedType: 'PgCidr',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'mac',
          columnName: 'mac',
          dartType: 'PgMacAddress',
          resolvedType: 'PgMacAddress',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'payload',
          columnName: 'payload',
          dartType: 'Uint8List',
          resolvedType: 'Uint8List',
          isNullable: false,
        ),
      ],
      codec: const _BuiltinTypesRecordCodec(),
    );

final class _BuiltinTypesRecordCodec extends ModelCodec<BuiltinTypesRecord> {
  const _BuiltinTypesRecordCodec();

  @override
  Map<String, Object?> encode(
    BuiltinTypesRecord model,
    ValueCodecRegistry registry,
  ) {
    return <String, Object?>{
      'id': model.id,
      'uuid_value': registry.encodeByKey('UuidValue', model.uuidValue),
      'uuid_values': registry.encodeByKey('List<UuidValue>', model.uuidValues),
      'amount': registry.encodeByKey('Decimal', model.amount),
      'duration': registry.encodeByKey('Interval', model.duration),
      'document': registry.encodeByKey('TsVector', model.document),
      'query': registry.encodeByKey('TsQuery', model.query),
      'int_range': registry.encodeByKey('IntRange', model.intRange),
      'date_range': registry.encodeByKey('DateRange', model.dateRange),
      'time_range': registry.encodeByKey('DateTimeRange', model.timeRange),
      'ip': registry.encodeByKey('PgInet', model.ip),
      'subnet': registry.encodeByKey('PgCidr', model.subnet),
      'mac': registry.encodeByKey('PgMacAddress', model.mac),
      'payload': registry.encodeByKey('Uint8List', model.payload),
    };
  }

  @override
  BuiltinTypesRecord decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    return BuiltinTypesRecord(
      id: data['id'] as int?,
      uuidValue: registry.decodeByKey<UuidValue>(
        'UuidValue',
        data['uuid_value'],
      )!,
      uuidValues: registry.decodeByKey<List<UuidValue>>(
        'List<UuidValue>',
        data['uuid_values'],
      )!,
      amount: registry.decodeByKey<Decimal>('Decimal', data['amount'])!,
      duration: registry.decodeByKey<Interval>('Interval', data['duration'])!,
      document: registry.decodeByKey<TsVector>('TsVector', data['document'])!,
      query: registry.decodeByKey<TsQuery>('TsQuery', data['query'])!,
      intRange: registry.decodeByKey<IntRange>('IntRange', data['int_range'])!,
      dateRange: registry.decodeByKey<DateRange>(
        'DateRange',
        data['date_range'],
      )!,
      timeRange: registry.decodeByKey<DateTimeRange>(
        'DateTimeRange',
        data['time_range'],
      )!,
      ip: registry.decodeByKey<PgInet>('PgInet', data['ip'])!,
      subnet: registry.decodeByKey<PgCidr>('PgCidr', data['subnet'])!,
      mac: registry.decodeByKey<PgMacAddress>('PgMacAddress', data['mac'])!,
      payload: registry.decodeByKey<Uint8List>('Uint8List', data['payload'])!,
    );
  }
}

final class _CreateBuiltinTypesTable extends Migration {
  const _CreateBuiltinTypesTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('postgres_builtin_types', (table) {
      table.increments('id');
      table.uuid('uuid_value');
      table.uuidArray('uuid_values');
      table.decimal('amount', precision: 18, scale: 6);
      table.interval('duration');
      table.tsvector('document');
      table.tsquery('query');
      table.int4range('int_range');
      table.daterange('date_range');
      table.tstzrange('time_range');
      table.inet('ip');
      table.cidr('subnet');
      table.macaddr('mac');
      table.binary('payload');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('postgres_builtin_types', ifExists: true, cascade: true);
  }
}

Future<void> main() async {
  final url =
      Platform.environment['POSTGRES_URL'] ??
      'postgres://postgres:postgres@localhost:6543/orm_test';

  PostgresDriverAdapter.registerCodecs();

  final registry = ModelRegistry()
    ..register<BuiltinTypesRecord>(_builtinTypesDefinition);

  final adapter = PostgresDriverAdapter.custom(
    config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
  );

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'postgres_builtin_types_base',
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
        id: MigrationId(DateTime.utc(2025, 1, 1, 0, 0, 1), 'builtin_types'),
        migration: const _CreateBuiltinTypesTable(),
      ),
    ],
    strategy: DatabaseIsolationStrategy.recreate,
    adapterFactory: (_) => PostgresDriverAdapter.custom(
      config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
    ),
  );

  tearDownAll(() async {
    await dataSource.dispose();
  });

  ormedGroup('Postgres built-in type hydration', (scopedDataSource) {
    test('round-trips typed values via table() queries', () async {
      final uuid = UuidValue.fromString(const Uuid().v4());
      final uuidValues = [
        UuidValue.fromString(const Uuid().v4()),
        UuidValue.fromString(const Uuid().v4()),
      ];
      final amount = Decimal.parse('123.450000');
      final interval = Interval(months: 1, days: 2, microseconds: 3000000);
      final document = TsVector(
        words: [
          TsWord('hello'),
          TsWord('world', positions: [TsWordPos(1)]),
        ],
      );
      final query = TsQuery.word('hello');
      final intRange = IntRange(
        1,
        10,
        Bounds(Bound.inclusive, Bound.exclusive),
      );
      final dateRange = DateRange(
        DateTime.utc(2020, 1, 1),
        DateTime.utc(2020, 1, 10),
        Bounds(Bound.inclusive, Bound.exclusive),
      );
      final timeRange = DateTimeRange(
        DateTime.utc(2020, 1, 1),
        DateTime.utc(2020, 1, 2),
        Bounds(Bound.inclusive, Bound.exclusive),
      );
      final ip = PgInet('127.0.0.1');
      final subnet = PgCidr('192.168.0.0/24');
      final mac = PgMacAddress('08:00:2b:01:02:03');
      final payload = Uint8List.fromList([1, 2, 3, 4]);

      final repo = scopedDataSource.repo<BuiltinTypesRecord>();

      final created = await repo.insert(
        BuiltinTypesRecord(
          uuidValue: uuid,
          uuidValues: uuidValues,
          amount: amount,
          duration: interval,
          document: document,
          query: query,
          intRange: intRange,
          dateRange: dateRange,
          timeRange: timeRange,
          ip: ip,
          subnet: subnet,
          mac: mac,
          payload: payload,
        ),
      );

      expect(created.id, isNotNull);
      expect(created.uuidValue, equals(uuid));
      expect(created.uuidValues, equals(uuidValues));
      expect(created.amount, equals(amount));
      expect(created.duration, equals(interval));
      expect(created.document, isA<TsVector>());
      expect(created.query, isA<TsQuery>());
      expect(created.intRange, equals(intRange));
      expect(created.dateRange, equals(dateRange));
      expect(created.timeRange, equals(timeRange));
      expect(created.ip, equals(ip));
      expect(created.subnet, equals(subnet));
      expect(created.mac, equals(mac));
      expect(created.payload, equals(payload));

      final fetched = await scopedDataSource.context
          .query<BuiltinTypesRecord>()
          .whereEquals('id', created.id)
          .first();

      expect(fetched, isNotNull);
      expect(fetched!.uuidValue, equals(uuid));
      expect(fetched.uuidValues, equals(uuidValues));
      expect(fetched.amount, equals(amount));
      expect(fetched.duration, equals(interval));
      expect(fetched.ip, equals(ip));
      expect(fetched.payload, equals(payload));
    });
  }, config: config);
}
