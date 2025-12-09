import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

/// Tests for timezone-aware Carbon codec behavior.
/// 
/// These tests verify that:
/// 1. Carbon instances are decoded with the configured default timezone
/// 2. Encoding always stores in UTC (database consistency)
/// 3. Timezone conversions work correctly
void main() {
  group('Carbon Timezone Codecs', () {
    setUp(() {
      // Reset Carbon configuration before each test
      CarbonConfig.reset();
    });

    test('decodes to UTC by default', () {
      CarbonConfig.configure(defaultTimezone: 'UTC');

      const codec = SqliteCarbonInterfaceCodec();
      final decoded = codec.decode('2024-12-08T20:30:00.000Z');

      expect(decoded, isNotNull);
      expect(decoded!.isUtc, isTrue);
      expect(decoded.format('yyyy-MM-dd HH:mm'), '2024-12-08 20:30');
    });

    test('decodes to configured timezone with TimeMachine', () async {
      await CarbonConfig.configureWithTimeMachine(
        defaultTimezone: 'America/New_York',
      );

      const codec = SqliteCarbonInterfaceCodec();
      // 20:30 UTC = 15:30 EST (UTC-5)
      final decoded = codec.decode('2024-12-08T20:30:00.000Z');

      expect(decoded, isNotNull);
      // Decoded Carbon is presented in NY timezone
      expect(decoded!.format('yyyy-MM-dd HH:mm z'), contains('15:30'));
      expect(decoded.hour, 15); // Shows as 15 in NY timezone
      
      // The underlying DateTime is still UTC
      // When we explicitly convert to UTC view, it still shows the same time
      // because Carbon.tz() creates a view, not a conversion
      final utcView = decoded.tz('UTC');
      expect(utcView.format('HH:mm'), '20:30');
    });

    test('encoding always converts to UTC', () async {
      await CarbonConfig.configureWithTimeMachine(
        defaultTimezone: 'America/New_York',
      );

      const codec = SqliteCarbonInterfaceCodec();
      
      // Create a Carbon in NY timezone (3:30 PM local)
      final nyCarbon = CarbonConfig.createCarbon(
        dateTime: DateTime(2024, 12, 8, 15, 30),
      );

      // Encode should convert to UTC
      final encoded = codec.encode(nyCarbon);

      expect(encoded, isNotNull);
      expect(encoded, isA<String>());
      expect(encoded.toString(), endsWith('Z')); // UTC indicator
      
      // Parse and verify it's 20:30 UTC (15:30 NY + 5 hours)
      final parsed = DateTime.parse(encoded.toString());
      expect(parsed.hour, 20);
      expect(parsed.minute, 30);
    });

    test('round-trip preserves time in UTC', () {
      CarbonConfig.configure(defaultTimezone: 'UTC');

      const codec = SqliteCarbonInterfaceCodec();
      
      final original = CarbonConfig.createCarbon(
        dateTime: DateTime.utc(2024, 12, 8, 20, 30),
      );

      // Encode and decode
      final encoded = codec.encode(original);
      final decoded = codec.decode(encoded);

      expect(decoded!.year, original.year);
      expect(decoded.month, original.month);
      expect(decoded.day, original.day);
      expect(decoded.hour, original.hour);
      expect(decoded.minute, original.minute);
    });

    test('handles DateTime input', () {
      CarbonConfig.configure(defaultTimezone: 'UTC');

      const codec = SqliteCarbonInterfaceCodec();
      final dateTime = DateTime.utc(2024, 12, 8, 20, 30);
      final decoded = codec.decode(dateTime);

      expect(decoded, isNotNull);
      expect(decoded!.year, 2024);
      expect(decoded.month, 12);
      expect(decoded.day, 8);
      expect(decoded.hour, 20);
      expect(decoded.minute, 30);
    });

    test('handles Carbon input (no-op)', () {
      CarbonConfig.configure(defaultTimezone: 'UTC');

      const codec = SqliteCarbonCodec();
      final carbon = Carbon.now();
      final decoded = codec.decode(carbon);

      expect(decoded, same(carbon)); // Returns same instance
    });

    test('SqliteCarbonCodec returns Carbon type', () {
      CarbonConfig.configure(defaultTimezone: 'UTC');

      const codec = SqliteCarbonCodec();
      final decoded = codec.decode('2024-12-08T20:30:00.000Z');

      expect(decoded, isA<Carbon>());
    });

    test('SqliteCarbonInterfaceCodec returns CarbonInterface type', () {
      CarbonConfig.configure(defaultTimezone: 'UTC');

      const codec = SqliteCarbonInterfaceCodec();
      final decoded = codec.decode('2024-12-08T20:30:00.000Z');

      expect(decoded, isA<CarbonInterface>());
    });

    test('handles null values', () {
      const carbonCodec = SqliteCarbonCodec();
      const interfaceCodec = SqliteCarbonInterfaceCodec();

      expect(carbonCodec.encode(null), isNull);
      expect(carbonCodec.decode(null), isNull);
      expect(interfaceCodec.encode(null), isNull);
      expect(interfaceCodec.decode(null), isNull);
    });
  });
}
