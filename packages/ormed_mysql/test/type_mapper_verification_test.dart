import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:uuid/uuid_value.dart';

void main() {
  group('MySQL TypeMapper Verification', () {
    late MysqlTypeMapper mapper;

    setUpAll(() {
      MySqlDriverAdapter.registerCodecs();
      mapper = TypeMapperRegistry.get('mysql')! as MysqlTypeMapper;
    });

    test('TypeMapper is registered for mysql', () {
      expect(TypeMapperRegistry.has('mysql'), isTrue);
      expect(mapper.driverName, equals('mysql'));
    });

    test('TypeMapper is registered for mariadb', () {
      expect(TypeMapperRegistry.has('mariadb'), isTrue);
      final mariadbMapper = TypeMapperRegistry.get('mariadb');
      expect(mariadbMapper, isNotNull);
      expect(
        mariadbMapper?.driverName,
        equals('mysql'),
      ); // Same mapper instance
    });

    test('bool → TINYINT with codec', () {
      expect(mapper.dartTypeToSql(bool), equals('TINYINT'));

      final codec = mapper.getCodecForDartType(bool);
      expect(codec, isNotNull);
      expect(codec?.encode(true), equals(1));
      expect(codec?.encode(false), equals(0));
      expect(codec?.decode(1), equals(true));
      expect(codec?.decode(0), equals(false));
    });

    test('DateTime → DATETIME with codec', () {
      expect(mapper.dartTypeToSql(DateTime), equals('DATETIME'));

      final codec = mapper.getCodecForDartType(DateTime);
      expect(codec, isNotNull);

      // MySQL returns DateTime as String sometimes, codec should handle it
      final testDate = DateTime.utc(2024, 1, 1);
      final encoded = codec?.encode(testDate);
      expect(encoded, isA<String>());

      // Decode from string (typical MySQL behavior)
      final decoded = codec?.decode('2024-01-01 00:00:00');
      expect(decoded, isA<DateTime>());
    });

    test('Duration → TIME with codec', () {
      expect(mapper.dartTypeToSql(Duration), equals('TIME'));

      final codec = mapper.getCodecForDartType(Duration);
      expect(codec, isNotNull);

      final encoded = codec?.encode(const Duration(hours: 1, minutes: 2));
      expect(encoded, equals('01:02:00'));

      final decoded = codec?.decode('12:34:56.123456');
      expect(
        decoded,
        equals(
          const Duration(
            hours: 12,
            minutes: 34,
            seconds: 56,
            microseconds: 123456,
          ),
        ),
      );
    });

    test('Decimal → DECIMAL with codec', () {
      expect(mapper.dartTypeToSql(Decimal), equals('DECIMAL'));

      final codec = mapper.getCodecForDartType(Decimal);
      expect(codec, isNotNull);

      final value = Decimal.parse('123.4500');
      final encoded = codec?.encode(value);
      expect(encoded, isA<String>());
      expect(Decimal.parse(encoded as String), equals(value));

      final decoded = codec?.decode('123.4500');
      expect(decoded, equals(value));
    });

    test('UuidValue → CHAR(36) with codec', () {
      expect(mapper.dartTypeToSql(UuidValue), equals('CHAR(36)'));

      final codec = mapper.getCodecForDartType(UuidValue);
      expect(codec, isNotNull);

      final uuid = UuidValue.fromString('00000000-0000-0000-0000-000000000000');
      final encoded = codec?.encode(uuid);
      expect(encoded, equals('00000000-0000-0000-0000-000000000000'));

      final decoded = codec?.decode('00000000-0000-0000-0000-000000000000');
      expect(decoded, equals(uuid));
    });

    test('All basic type mappings', () {
      expect(mapper.dartTypeToSql(int), equals('INT'));
      expect(mapper.dartTypeToSql(double), equals('DOUBLE'));
      expect(mapper.dartTypeToSql(String), equals('VARCHAR'));
      expect(mapper.dartTypeToSql(bool), equals('TINYINT'));
      expect(mapper.dartTypeToSql(DateTime), equals('DATETIME'));
      expect(mapper.dartTypeToSql(Duration), equals('TIME'));
      expect(mapper.dartTypeToSql(Decimal), equals('DECIMAL'));
    });

    test('Reverse SQL → Dart mappings', () {
      expect(mapper.sqlTypeToDart('INT'), equals(int));
      expect(mapper.sqlTypeToDart('INTEGER'), equals(int));
      expect(mapper.sqlTypeToDart('DOUBLE'), equals(double));
      expect(mapper.sqlTypeToDart('DECIMAL'), equals(Decimal));
      expect(mapper.sqlTypeToDart('NUMERIC'), equals(Decimal));
      expect(mapper.sqlTypeToDart('VARCHAR'), equals(String));
      expect(mapper.sqlTypeToDart('TEXT'), equals(String));
      expect(
        mapper.sqlTypeToDart('TINYINT'),
        equals(int),
      ); // Without (1), it's int
      expect(mapper.sqlTypeToDart('DATETIME'), equals(DateTime));
      expect(mapper.sqlTypeToDart('TIMESTAMP'), equals(DateTime));
      expect(mapper.sqlTypeToDart('TIME'), equals(Duration));
      expect(mapper.sqlTypeToDart('BLOB'), equals(List<int>));
    });

    test('TINYINT handling', () {
      // In MySQL TypeMapper, TINYINT is normalized to INT
      // The bool codec is selected by Dart type, not SQL type
      expect(mapper.sqlTypeToDart('TINYINT'), equals(int));
      expect(mapper.sqlTypeToDart('TINYINT(1)'), equals(int));
      expect(mapper.sqlTypeToDart('TINYINT(2)'), equals(int));

      // The bool codec is associated with bool Dart type
      expect(mapper.dartTypeToSql(bool), equals('TINYINT'));
    });

    test('SQL type normalization', () {
      expect(mapper.normalizeSqlType('varchar(255)'), equals('VARCHAR'));
      expect(mapper.normalizeSqlType('INT'), equals('INT'));
      expect(mapper.normalizeSqlType('int'), equals('INT'));

      // All integer types normalize to INT
      expect(mapper.normalizeSqlType('BIGINT'), equals('INT'));
      expect(mapper.normalizeSqlType('TINYINT'), equals('INT'));
      expect(mapper.normalizeSqlType('SMALLINT'), equals('INT'));

      // Decimal types normalize to DECIMAL
      expect(mapper.normalizeSqlType('numeric(18,6)'), equals('DECIMAL'));
      expect(mapper.normalizeSqlType('decimal(18,6)'), equals('DECIMAL'));

      // TIME stays TIME
      expect(mapper.normalizeSqlType('time(6)'), equals('TIME'));
    });

    test('SQL type aliases', () {
      expect(mapper.sqlTypeToDart('INTEGER'), equals(int));
      expect(mapper.sqlTypeToDart('SMALLINT'), equals(int));
      expect(mapper.sqlTypeToDart('BIGINT'), equals(int));
      expect(mapper.sqlTypeToDart('CHAR'), equals(String));
      expect(mapper.sqlTypeToDart('TEXT'), equals(String));
      expect(mapper.sqlTypeToDart('FLOAT'), equals(double));
      expect(mapper.sqlTypeToDart('DATE'), equals(DateTime));
      expect(mapper.sqlTypeToDart('TIME'), equals(Duration));
    });

    test('Has multiple type mappings', () {
      expect(mapper.typeMappings.length, greaterThan(5));
    });

    test('Codec for JSON type', () {
      final codec = mapper.getCodecForDartType(Map);
      expect(codec, isNotNull);

      final testMap = {
        'key': 'value',
        'nested': {'inner': 'data'},
      };
      final encoded = codec?.encode(testMap);
      expect(encoded, isA<String>());
      expect(encoded, contains('key'));

      final decoded = codec?.decode(encoded);
      expect(decoded, isA<Map>());
      expect((decoded as Map)['key'], equals('value'));
      expect((decoded['nested'] as Map)['inner'], equals('data'));
    });

    test('Supports UNSIGNED modifier', () {
      // MySQL supports UNSIGNED for all types (returns true)
      expect(mapper.supportsUnsigned('INT'), isTrue);
      expect(mapper.supportsUnsigned('BIGINT'), isTrue);
      expect(mapper.supportsUnsigned('TINYINT'), isTrue);
      expect(mapper.supportsUnsigned('VARCHAR'), isTrue); // MySQL allows it
    });

    test('Supports isSqlTypeSupported', () {
      expect(mapper.isSqlTypeSupported('INT'), isTrue);
      expect(mapper.isSqlTypeSupported('VARCHAR'), isTrue);
      expect(mapper.isSqlTypeSupported('TINYINT'), isTrue);
      expect(mapper.isSqlTypeSupported('DATETIME'), isTrue);
      expect(mapper.isSqlTypeSupported('BLOB'), isTrue);
    });

    test('Bool codec accessed by Dart type', () {
      // MySQL TypeMapper associates bool codec with bool Dart type
      final codec = mapper.getCodecForDartType(bool);
      expect(codec, isNotNull);

      // Should encode bool → int
      expect(codec?.encode(true), equals(1));
      expect(codec?.encode(false), equals(0));

      // Should decode int → bool
      expect(codec?.decode(1), equals(true));
      expect(codec?.decode(0), equals(false));
    });
  });
}
