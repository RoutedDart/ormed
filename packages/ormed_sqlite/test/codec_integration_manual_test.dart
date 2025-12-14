import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('Codec Integration Check', () {
    setUpAll(() {
      SqliteDriverAdapter.registerCodecs();
    });

    test('bool codec is registered and works', () {
      final registry = ValueCodecRegistry.instance.forDriver('sqlite');

      final decoded = registry.decodeByKey<bool>('bool', 1);
      expect(decoded, equals(true));
      expect(decoded.runtimeType, equals(bool));
    });

    test('DateTime codec is registered and works', () {
      final registry = ValueCodecRegistry.instance.forDriver('sqlite');

      final decoded = registry.decodeByKey<DateTime>(
        'DateTime',
        '2024-01-01T00:00:00.000Z',
      );
      expect(decoded, isA<DateTime>());
      expect(decoded?.year, equals(2024));
    });

    test('TypeMapper is registered', () {
      final mapper = TypeMapperRegistry.get('sqlite');
      expect(mapper, isNotNull);
      expect(mapper?.driverName, equals('sqlite'));
    });

    test('TypeMapper provides correct SQL types', () {
      final mapper = TypeMapperRegistry.get('sqlite')!;

      expect(mapper.dartTypeToSql(DateTime), equals('TEXT'));
      expect(mapper.dartTypeToSql(bool), equals('INTEGER'));
      expect(mapper.dartTypeToSql(int), equals('INTEGER'));
      expect(mapper.dartTypeToSql(String), equals('TEXT'));
    });

    test('TypeMapper provides correct codecs', () {
      final mapper = TypeMapperRegistry.get('sqlite')!;

      final boolCodec = mapper.getCodecForDartType(bool);
      expect(boolCodec, isNotNull);
      expect(boolCodec?.decode(1), equals(true));
      expect(boolCodec?.encode(true), equals(1));

      final dateTimeCodec = mapper.getCodecForDartType(DateTime);
      expect(dateTimeCodec, isNotNull);
      final testDate = DateTime.utc(2024, 1, 1);
      final encoded = dateTimeCodec?.encode(testDate) as String?;
      expect(encoded, contains('2024-01-01'));
    });
  });
}
