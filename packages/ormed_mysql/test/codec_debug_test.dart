import 'package:test/test.dart';
import 'package:ormed_mysql/src/mysql_codecs.dart';
import 'package:carbonized/carbonized.dart';

void main() {
  group('MySQL DateTime Codec Debug', () {
    late MySqlDateTimeCodec codec;
    late MySqlCarbonCodec carbonCodec;

    setUp(() {
      codec = MySqlDateTimeCodec();
      carbonCodec = MySqlCarbonCodec();
    });

    test('DateTime codec encode', () {
      final now = DateTime(2025, 12, 9, 14, 30, 45, 123, 456);
      final encoded = codec.encode(now);
      print('DateTime encoded: $encoded');
      expect(encoded, isA<String>());
    });

    test('DateTime codec decode from String', () {
      final dateStr = '2025-12-09 14:30:45.123456';
      final decoded = codec.decode(dateStr);
      print('String decoded: $decoded');
      expect(decoded, isA<DateTime>());
    });

    test('DateTime codec decode from DateTime', () {
      final now = DateTime.utc(2025, 12, 9, 14, 30, 45, 123, 456);
      final decoded = codec.decode(now);
      print('DateTime decoded: $decoded');
      expect(
        decoded?.isAtSameMomentAs(now) ?? false,
        isTrue,
        reason: 'Decoded value should represent the same instant (UTC-safe)',
      );
    });

    test('Carbon codec decode from String', () {
      final dateStr = '2025-12-09 14:30:45.123456';
      final decoded = carbonCodec.decode(dateStr);
      print('String decoded to Carbon: $decoded (${decoded?.microsecond} μs)');
      expect(decoded, isA<Carbon>());
    });

    test('Carbon codec decode from DateTime', () {
      final now = DateTime.utc(2025, 12, 9, 14, 30, 45, 123, 456);
      final decoded = carbonCodec.decode(now);
      print(
        'DateTime decoded to Carbon: $decoded (${decoded?.microsecond} μs)',
      );
      expect(decoded, isA<Carbon>());
      expect(
        decoded?.dateTime.toUtc().microsecondsSinceEpoch,
        equals(now.microsecondsSinceEpoch),
        reason: 'Carbon decode should preserve the exact instant',
      );
    });

    test('Round-trip DateTime codec', () {
      final original = DateTime(2025, 12, 9, 14, 30, 45, 123, 456);
      final encoded = codec.encode(original);
      final decoded = codec.decode(encoded);
      print('Original: $original (${original.microsecond} μs)');
      print('Encoded: $encoded');
      print('Decoded: $decoded (${decoded?.microsecond} μs)');
      expect(decoded?.microsecond, equals(original.microsecond));
    });

    test('Round-trip Carbon codec via DateTime', () {
      final dt = DateTime.utc(2025, 12, 9, 14, 30, 45, 123, 456);
      final asCarbon = Carbon.createFromDateTime(dt);
      final encoded = carbonCodec.encode(asCarbon as Carbon);
      final decoded = carbonCodec.decode(encoded);
      print('Original DateTime: $dt (${dt.microsecond} μs)');
      print('Encoded: $encoded');
      print('Decoded Carbon: $decoded (${decoded?.microsecond} μs)');
      expect(
        decoded?.dateTime.toUtc().microsecondsSinceEpoch,
        equals(dt.microsecondsSinceEpoch),
        reason: 'Round-trip should preserve microsecond precision and instant',
      );
    });
  });
}
