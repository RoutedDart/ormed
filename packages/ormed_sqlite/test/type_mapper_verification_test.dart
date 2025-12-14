import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('SQLite TypeMapper Verification', () {
    late DriverTypeMapper mapper;

    setUpAll(() {
      SqliteDriverAdapter.registerCodecs();
      mapper = TypeMapperRegistry.get('sqlite')!;
    });

    test('TypeMapper is registered', () {
      expect(mapper, isNotNull);
      expect(mapper.driverName, 'sqlite');
    });

    test('bool → INTEGER with IntBoolCodec', () {
      final sqlType = mapper.dartTypeToSql(bool);
      expect(sqlType, 'INTEGER');

      final codec = mapper.getCodecForDartType(bool);
      expect(codec!.encode(true), 1);
      expect(codec.decode(1), true);
    });

    test('DateTime → TEXT with codec', () {
      final sqlType = mapper.dartTypeToSql(DateTime);
      expect(sqlType, 'TEXT');

      final codec = mapper.getCodecForDartType(DateTime);
      expect(codec, isNotNull);
    });

    test('All basic type mappings', () {
      expect(mapper.dartTypeToSql(int), 'INTEGER');
      expect(mapper.dartTypeToSql(String), 'TEXT');
      expect(mapper.dartTypeToSql(double), 'REAL');
    });

    test('Reverse SQL → Dart mappings', () {
      expect(mapper.sqlTypeToDart('INTEGER'), int);
      expect(mapper.sqlTypeToDart('TEXT'), String);
      expect(mapper.sqlTypeToDart('REAL'), double);
    });

    test('SQL type normalization', () {
      expect(mapper.normalizeSqlType('INTEGER'), 'INTEGER');
      expect(mapper.normalizeSqlType('integer'), 'INTEGER');
      expect(mapper.normalizeSqlType('TEXT(255)'), 'TEXT');
      expect(mapper.normalizeSqlType('TEXT NOT NULL'), 'TEXT');
    });

    test('Has multiple type mappings', () {
      expect(mapper.typeMappings.length, greaterThanOrEqualTo(5));
    });
  });
}
