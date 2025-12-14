import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  group('PostgreSQL TypeMapper Verification', () {
    late PostgresTypeMapper mapper;

    setUpAll(() {
      PostgresDriverAdapter.registerCodecs();
      mapper = TypeMapperRegistry.get('postgres')! as PostgresTypeMapper;
    });

    test('TypeMapper is registered', () {
      expect(TypeMapperRegistry.has('postgres'), isTrue);
      expect(mapper.driverName, equals('postgres'));
    });

    test('bool → BOOLEAN', () {
      expect(mapper.dartTypeToSql(bool), equals('BOOLEAN'));
    });

    test('DateTime → TIMESTAMP', () {
      expect(mapper.dartTypeToSql(DateTime), equals('TIMESTAMP'));
    });

    test('All basic type mappings', () {
      expect(mapper.dartTypeToSql(int), equals('INTEGER'));
      expect(mapper.dartTypeToSql(double), equals('DOUBLE PRECISION'));
      expect(mapper.dartTypeToSql(String), equals('TEXT'));
      expect(mapper.dartTypeToSql(bool), equals('BOOLEAN'));
      expect(mapper.dartTypeToSql(DateTime), equals('TIMESTAMP'));
    });

    test('Reverse SQL → Dart mappings', () {
      expect(mapper.sqlTypeToDart('INTEGER'), equals(int));
      expect(mapper.sqlTypeToDart('REAL'), equals(double));
      expect(mapper.sqlTypeToDart('TEXT'), equals(String));
      expect(mapper.sqlTypeToDart('BOOLEAN'), equals(bool));
      expect(mapper.sqlTypeToDart('TIMESTAMP'), equals(DateTime));
      expect(mapper.sqlTypeToDart('BYTEA'), equals(List<int>));
    });

    test('SQL type normalization', () {
      expect(mapper.normalizeSqlType('varchar(255)'), equals('TEXT'));
      expect(mapper.normalizeSqlType('INTEGER'), equals('INTEGER'));
      expect(mapper.normalizeSqlType('int'), equals('INTEGER'));
      expect(mapper.normalizeSqlType('BIGINT'), equals('INTEGER'));
      expect(
        mapper.normalizeSqlType('TIMESTAMP WITH TIME ZONE'),
        equals('TIMESTAMP'),
      );
      expect(mapper.normalizeSqlType('DOUBLE'), equals('DOUBLE'));
      expect(mapper.normalizeSqlType('REAL'), equals('DOUBLE PRECISION'));
    });

    test('SQL type aliases', () {
      expect(mapper.sqlTypeToDart('INT'), equals(int));
      expect(mapper.sqlTypeToDart('INT4'), equals(int));
      expect(mapper.sqlTypeToDart('BIGINT'), equals(int));
      expect(mapper.sqlTypeToDart('SMALLINT'), equals(int));
      expect(mapper.sqlTypeToDart('VARCHAR'), equals(String));
      expect(mapper.sqlTypeToDart('CHAR'), equals(String));
      expect(mapper.sqlTypeToDart('BOOL'), equals(bool));
      expect(mapper.sqlTypeToDart('TIMESTAMPTZ'), equals(DateTime));
    });

    test('Has multiple type mappings', () {
      expect(mapper.typeMappings.length, greaterThan(5));
    });

    test('Codec for JSON type', () {
      final codec = mapper.getCodecForDartType(Map);
      expect(codec, isNotNull);

      final testMap = {'key': 'value'};
      final encoded = codec?.encode(testMap);
      expect(encoded, isA<String>());
      expect(encoded, contains('key'));

      final decoded = codec?.decode(encoded);
      expect(decoded, isA<Map>());
      expect((decoded as Map)['key'], equals('value'));
    });

    test('Supports isSqlTypeSupported', () {
      expect(mapper.isSqlTypeSupported('INTEGER'), isTrue);
      expect(mapper.isSqlTypeSupported('TEXT'), isTrue);
      expect(mapper.isSqlTypeSupported('BOOLEAN'), isTrue);
      expect(mapper.isSqlTypeSupported('TIMESTAMP'), isTrue);
      expect(mapper.isSqlTypeSupported('BYTEA'), isTrue);
    });
  });
}
