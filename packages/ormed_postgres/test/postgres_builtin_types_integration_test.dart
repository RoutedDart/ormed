import 'dart:io';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/migrations.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class BuiltinTypesRecord extends Model<BuiltinTypesRecord> {
  const BuiltinTypesRecord({
    this.id,
    required this.active,
    required this.smallintValue,
    required this.integerValue,
    required this.bigintValue,
    required this.realValue,
    required this.doubleValue,
    required this.charValue,
    required this.varcharValue,
    required this.textValue,
    required this.bitValue,
    required this.varbitValue,
    required this.moneyValue,
    required this.pointValue,
    required this.lineValue,
    required this.lsegValue,
    required this.boxValue,
    required this.pathValue,
    required this.polygonValue,
    required this.circleValue,
    required this.dateValue,
    required this.timeValue,
    required this.timetzValue,
    required this.timestampValue,
    required this.timestamptzValue,
    required this.pgLsnValue,
    required this.pgSnapshotValue,
    required this.txidSnapshotValue,
    required this.xmlValue,
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
  final bool active;
  final int smallintValue;
  final int integerValue;
  final int bigintValue;
  final double realValue;
  final double doubleValue;
  final String charValue;
  final String varcharValue;
  final String textValue;
  final PgBitString bitValue;
  final PgBitString varbitValue;
  final PgMoney moneyValue;
  final Point pointValue;
  final Line lineValue;
  final LineSegment lsegValue;
  final Box boxValue;
  final Path pathValue;
  final Polygon polygonValue;
  final Circle circleValue;
  final DateTime dateValue;
  final Time timeValue;
  final PgTimeTz timetzValue;
  final DateTime timestampValue;
  final DateTime timestamptzValue;
  final LSN pgLsnValue;
  final PgSnapshot pgSnapshotValue;
  final PgSnapshot txidSnapshotValue;
  final String xmlValue;
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

final class $BuiltinTypesRecord extends BuiltinTypesRecord
    with ModelAttributes {
  const $BuiltinTypesRecord({
    super.id,
    required super.active,
    required super.smallintValue,
    required super.integerValue,
    required super.bigintValue,
    required super.realValue,
    required super.doubleValue,
    required super.charValue,
    required super.varcharValue,
    required super.textValue,
    required super.bitValue,
    required super.varbitValue,
    required super.moneyValue,
    required super.pointValue,
    required super.lineValue,
    required super.lsegValue,
    required super.boxValue,
    required super.pathValue,
    required super.polygonValue,
    required super.circleValue,
    required super.dateValue,
    required super.timeValue,
    required super.timetzValue,
    required super.timestampValue,
    required super.timestamptzValue,
    required super.pgLsnValue,
    required super.pgSnapshotValue,
    required super.txidSnapshotValue,
    required super.xmlValue,
    required super.uuidValue,
    required super.uuidValues,
    required super.amount,
    required super.duration,
    required super.document,
    required super.query,
    required super.intRange,
    required super.dateRange,
    required super.timeRange,
    required super.ip,
    required super.subnet,
    required super.mac,
    required super.payload,
  });
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
          name: 'active',
          columnName: 'active',
          dartType: 'bool',
          resolvedType: 'bool',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'smallintValue',
          columnName: 'smallint_value',
          dartType: 'int',
          resolvedType: 'int',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'integerValue',
          columnName: 'integer_value',
          dartType: 'int',
          resolvedType: 'int',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'bigintValue',
          columnName: 'bigint_value',
          dartType: 'int',
          resolvedType: 'int',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'realValue',
          columnName: 'real_value',
          dartType: 'double',
          resolvedType: 'double',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'doubleValue',
          columnName: 'double_value',
          dartType: 'double',
          resolvedType: 'double',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'charValue',
          columnName: 'char_value',
          dartType: 'String',
          resolvedType: 'String',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'varcharValue',
          columnName: 'varchar_value',
          dartType: 'String',
          resolvedType: 'String',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'textValue',
          columnName: 'text_value',
          dartType: 'String',
          resolvedType: 'String',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'bitValue',
          columnName: 'bit_value',
          dartType: 'PgBitString',
          resolvedType: 'PgBitString',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'varbitValue',
          columnName: 'varbit_value',
          dartType: 'PgBitString',
          resolvedType: 'PgBitString',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'moneyValue',
          columnName: 'money_value',
          dartType: 'PgMoney',
          resolvedType: 'PgMoney',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'pointValue',
          columnName: 'point_value',
          dartType: 'Point',
          resolvedType: 'Point',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'lineValue',
          columnName: 'line_value',
          dartType: 'Line',
          resolvedType: 'Line',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'lsegValue',
          columnName: 'lseg_value',
          dartType: 'LineSegment',
          resolvedType: 'LineSegment',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'boxValue',
          columnName: 'box_value',
          dartType: 'Box',
          resolvedType: 'Box',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'pathValue',
          columnName: 'path_value',
          dartType: 'Path',
          resolvedType: 'Path',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'polygonValue',
          columnName: 'polygon_value',
          dartType: 'Polygon',
          resolvedType: 'Polygon',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'circleValue',
          columnName: 'circle_value',
          dartType: 'Circle',
          resolvedType: 'Circle',
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
          name: 'timeValue',
          columnName: 'time_value',
          dartType: 'Time',
          resolvedType: 'Time',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'timetzValue',
          columnName: 'timetz_value',
          dartType: 'PgTimeTz',
          resolvedType: 'PgTimeTz',
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
          name: 'timestamptzValue',
          columnName: 'timestamptz_value',
          dartType: 'DateTime',
          resolvedType: 'DateTime',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'pgLsnValue',
          columnName: 'pg_lsn_value',
          dartType: 'LSN',
          resolvedType: 'LSN',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'pgSnapshotValue',
          columnName: 'pg_snapshot_value',
          dartType: 'PgSnapshot',
          resolvedType: 'PgSnapshot',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'txidSnapshotValue',
          columnName: 'txid_snapshot_value',
          dartType: 'PgSnapshot',
          resolvedType: 'PgSnapshot',
          isNullable: false,
        ),
        FieldDefinition(
          name: 'xmlValue',
          columnName: 'xml_value',
          dartType: 'String',
          resolvedType: 'String',
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
      'active': model.active,
      'smallint_value': model.smallintValue,
      'integer_value': model.integerValue,
      'bigint_value': model.bigintValue,
      'real_value': model.realValue,
      'double_value': model.doubleValue,
      'char_value': model.charValue,
      'varchar_value': model.varcharValue,
      'text_value': model.textValue,
      'bit_value': registry.encodeByKey('PgBitString', model.bitValue),
      'varbit_value': registry.encodeByKey('PgBitString', model.varbitValue),
      'money_value': registry.encodeByKey('PgMoney', model.moneyValue),
      'point_value': registry.encodeByKey('Point', model.pointValue),
      'line_value': registry.encodeByKey('Line', model.lineValue),
      'lseg_value': registry.encodeByKey('LineSegment', model.lsegValue),
      'box_value': registry.encodeByKey('Box', model.boxValue),
      'path_value': registry.encodeByKey('Path', model.pathValue),
      'polygon_value': registry.encodeByKey('Polygon', model.polygonValue),
      'circle_value': registry.encodeByKey('Circle', model.circleValue),
      'date_value': TypedValue<DateTime>(Type.date, model.dateValue.toUtc()),
      'time_value': registry.encodeByKey('Time', model.timeValue),
      'timetz_value': registry.encodeByKey('PgTimeTz', model.timetzValue),
      'timestamp_value': TypedValue<DateTime>(
        Type.timestamp,
        model.timestampValue.toUtc(),
      ),
      'timestamptz_value': TypedValue<DateTime>(
        Type.timestampTz,
        model.timestamptzValue.toUtc(),
      ),
      'pg_lsn_value': registry.encodeByKey('LSN', model.pgLsnValue),
      'pg_snapshot_value': registry.encodeByKey(
        'PgSnapshot',
        model.pgSnapshotValue,
      ),
      'txid_snapshot_value': registry.encodeByKey(
        'PgSnapshot',
        model.txidSnapshotValue,
      ),
      'xml_value': model.xmlValue,
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
      active: data['active'] as bool,
      smallintValue: (data['smallint_value'] as num).toInt(),
      integerValue: (data['integer_value'] as num).toInt(),
      bigintValue: (data['bigint_value'] as num).toInt(),
      realValue: (data['real_value'] as num).toDouble(),
      doubleValue: (data['double_value'] as num).toDouble(),
      charValue: data['char_value'] as String,
      varcharValue: data['varchar_value'] as String,
      textValue: data['text_value'] as String,
      bitValue: registry.decodeByKey<PgBitString>(
        'PgBitString',
        data['bit_value'],
      )!,
      varbitValue: registry.decodeByKey<PgBitString>(
        'PgBitString',
        data['varbit_value'],
      )!,
      moneyValue: registry.decodeByKey<PgMoney>(
        'PgMoney',
        data['money_value'],
      )!,
      pointValue: registry.decodeByKey<Point>('Point', data['point_value'])!,
      lineValue: registry.decodeByKey<Line>('Line', data['line_value'])!,
      lsegValue: registry.decodeByKey<LineSegment>(
        'LineSegment',
        data['lseg_value'],
      )!,
      boxValue: registry.decodeByKey<Box>('Box', data['box_value'])!,
      pathValue: registry.decodeByKey<Path>('Path', data['path_value'])!,
      polygonValue: registry.decodeByKey<Polygon>(
        'Polygon',
        data['polygon_value'],
      )!,
      circleValue: registry.decodeByKey<Circle>(
        'Circle',
        data['circle_value'],
      )!,
      dateValue: data['date_value'] as DateTime,
      timeValue: registry.decodeByKey<Time>('Time', data['time_value'])!,
      timetzValue: registry.decodeByKey<PgTimeTz>(
        'PgTimeTz',
        data['timetz_value'],
      )!,
      timestampValue: data['timestamp_value'] as DateTime,
      timestamptzValue: data['timestamptz_value'] as DateTime,
      pgLsnValue: registry.decodeByKey<LSN>('LSN', data['pg_lsn_value'])!,
      pgSnapshotValue: registry.decodeByKey<PgSnapshot>(
        'PgSnapshot',
        data['pg_snapshot_value'],
      )!,
      txidSnapshotValue: registry.decodeByKey<PgSnapshot>(
        'PgSnapshot',
        data['txid_snapshot_value'],
      )!,
      xmlValue: data['xml_value'] as String,
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
      table.boolean('active');
      table.smallInteger('smallint_value');
      table.integer('integer_value');
      table.bigInteger('bigint_value');
      table.float('real_value');
      table.double('double_value');
      table.column('char_value', const ColumnType.custom('character(8)'));
      table.string('varchar_value', length: 32);
      table.text('text_value');
      table.bit('bit_value', length: 8);
      table.varbit('varbit_value');
      table.money('money_value');
      table.point('point_value');
      table.line('line_value');
      table.lseg('lseg_value');
      table.box('box_value');
      table.path('path_value');
      table.polygon('polygon_value');
      table.circle('circle_value');
      table.date('date_value');
      table.time('time_value');
      table.timeTz('timetz_value');
      table.dateTime('timestamp_value');
      table.dateTimeTz('timestamptz_value');
      table.pgLsn('pg_lsn_value');
      table.pgSnapshot('pg_snapshot_value');
      table.txidSnapshot('txid_snapshot_value');
      table.xml('xml_value');
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
      final active = true;
      final smallintValue = 12;
      final integerValue = 42;
      final bigintValue = 9007199254740991;
      final realValue = 3.25;
      final doubleValue = 9007199254740.991;
      final charValue = 'CHARTEST';
      final varcharValue = 'Hello';
      final textValue = 'A longer piece of text';
      final bitValue = PgBitString.parse('10101010');
      final varbitValue = PgBitString.parse('101');
      final moneyValue = const PgMoney.fromCents(1234);
      final pointValue = const Point(1.5, 2.5);
      final lineValue = Line(1, 2, 3);
      final lsegValue = LineSegment(const Point(0, 0), const Point(1, 1));
      final boxValue = Box(const Point(2, 2), const Point(1, 1));
      final pathValue = Path(const [Point(0, 0), Point(1, 1)], open: true);
      final polygonValue = Polygon(const [
        Point(0, 0),
        Point(0, 1),
        Point(1, 1),
      ]);
      final circleValue = Circle(const Point(0, 0), 5);
      final dateValue = DateTime.utc(2024, 1, 2);
      final timeValue = Time(1, 2, 3, 0, 400000);
      final timetzValue = PgTimeTz(
        time: Time(1, 2, 3),
        offset: const Duration(hours: 4),
      );
      final timestampValue = DateTime.utc(2024, 1, 2, 3, 4, 5);
      final timestamptzValue = DateTime.utc(2024, 1, 2, 3, 4, 6);
      final pgLsnValue = LSN.fromString('0/10');
      final pgSnapshotValue = const PgSnapshot(xmin: 1, xmax: 10, xip: [2, 3]);
      final txidSnapshotValue = const PgSnapshot(
        xmin: 11,
        xmax: 20,
        xip: [12, 13],
      );
      final xmlValue = '<root>hi</root>';

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
        $BuiltinTypesRecord(
          active: active,
          smallintValue: smallintValue,
          integerValue: integerValue,
          bigintValue: bigintValue,
          realValue: realValue,
          doubleValue: doubleValue,
          charValue: charValue,
          varcharValue: varcharValue,
          textValue: textValue,
          bitValue: bitValue,
          varbitValue: varbitValue,
          moneyValue: moneyValue,
          pointValue: pointValue,
          lineValue: lineValue,
          lsegValue: lsegValue,
          boxValue: boxValue,
          pathValue: pathValue,
          polygonValue: polygonValue,
          circleValue: circleValue,
          dateValue: dateValue,
          timeValue: timeValue,
          timetzValue: timetzValue,
          timestampValue: timestampValue,
          timestamptzValue: timestamptzValue,
          pgLsnValue: pgLsnValue,
          pgSnapshotValue: pgSnapshotValue,
          txidSnapshotValue: txidSnapshotValue,
          xmlValue: xmlValue,
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
      expect(created.active, equals(active));
      expect(created.smallintValue, equals(smallintValue));
      expect(created.integerValue, equals(integerValue));
      expect(created.bigintValue, equals(bigintValue));
      expect(created.realValue, equals(realValue));
      expect(created.doubleValue, equals(doubleValue));
      expect(created.charValue, equals(charValue));
      expect(created.varcharValue, equals(varcharValue));
      expect(created.textValue, equals(textValue));
      expect(created.bitValue, equals(bitValue));
      expect(created.varbitValue, equals(varbitValue));
      expect(created.moneyValue, equals(moneyValue));
      expect(created.pointValue, equals(pointValue));
      expect(created.lineValue, equals(lineValue));
      expect(created.lsegValue, equals(lsegValue));
      expect(created.boxValue, equals(boxValue));
      expect(created.pathValue, equals(pathValue));
      expect(created.polygonValue, equals(polygonValue));
      expect(created.circleValue, equals(circleValue));
      expect(created.dateValue, equals(dateValue));
      expect(created.timeValue, equals(timeValue));
      expect(created.timetzValue, equals(timetzValue));
      expect(created.timestampValue, equals(timestampValue));
      expect(created.timestamptzValue, equals(timestamptzValue));
      expect(created.pgLsnValue, equals(pgLsnValue));
      expect(created.pgSnapshotValue, equals(pgSnapshotValue));
      expect(created.txidSnapshotValue, equals(txidSnapshotValue));
      expect(created.xmlValue, equals(xmlValue));
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
      expect(fetched!.active, equals(active));
      expect(fetched.smallintValue, equals(smallintValue));
      expect(fetched.integerValue, equals(integerValue));
      expect(fetched.bigintValue, equals(bigintValue));
      expect(fetched.realValue, equals(realValue));
      expect(fetched.doubleValue, equals(doubleValue));
      expect(fetched.charValue, equals(charValue));
      expect(fetched.varcharValue, equals(varcharValue));
      expect(fetched.textValue, equals(textValue));
      expect(fetched.bitValue, equals(bitValue));
      expect(fetched.varbitValue, equals(varbitValue));
      expect(fetched.moneyValue, equals(moneyValue));
      expect(fetched.pointValue, equals(pointValue));
      expect(fetched.lineValue, equals(lineValue));
      expect(fetched.lsegValue, equals(lsegValue));
      expect(fetched.boxValue, equals(boxValue));
      expect(fetched.pathValue, equals(pathValue));
      expect(fetched.polygonValue, equals(polygonValue));
      expect(fetched.circleValue, equals(circleValue));
      expect(fetched.dateValue, equals(dateValue));
      expect(fetched.timeValue, equals(timeValue));
      expect(fetched.timetzValue, equals(timetzValue));
      expect(fetched.timestampValue, equals(timestampValue));
      expect(fetched.timestamptzValue, equals(timestamptzValue));
      expect(fetched.pgLsnValue, equals(pgLsnValue));
      expect(fetched.pgSnapshotValue, equals(pgSnapshotValue));
      expect(fetched.txidSnapshotValue, equals(txidSnapshotValue));
      expect(fetched.xmlValue, equals(xmlValue));
      expect(fetched.uuidValue, equals(uuid));
      expect(fetched.uuidValues, equals(uuidValues));
      expect(fetched.amount, equals(amount));
      expect(fetched.duration, equals(interval));
      expect(fetched.ip, equals(ip));
      expect(fetched.payload, equals(payload));
    });
  }, config: config);
}
