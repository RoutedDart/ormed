import 'dart:convert';

import 'package:test/test.dart';

import '../../models.dart';
import '../config.dart';
import '../harness/driver_test_harness.dart';

void runDriverOverrideTests({
  required DriverHarnessBuilder<DriverTestHarness> createHarness,
  required DriverTestConfig config,
}) {
  group('${config.driverName} driver overrides', () {
    test('repository encodes payload using driver-specific codec', () async {
      final harness = await createHarness();
      addTearDown(harness.dispose);

      final repo = harness.context.repository<DriverOverrideEntry>();
      const entry = DriverOverrideEntry(id: 1, payload: {'mode': 'dark'});
      await repo.insert(entry);

      final rows = await harness.adapter.queryRaw(
        'SELECT payload FROM settings WHERE id = 1',
      );
      final value = rows.single['payload'];
      final driverName = harness.adapter.metadata.name.toLowerCase();
      if (driverName.contains('sqlite')) {
        expect(value, isA<String>());
        expect(value, equals(jsonEncode(entry.payload)));
      } else if (driverName.contains('postgres')) {
        expect(value, isA<Map>());
        final decoded = (value as Map).cast<String, Object?>();
        expect(decoded['encoded_by'], equals('postgres'));
      } else {
        expect(value, isA<Map>());
        final decoded = (value as Map).cast<String, Object?>();
        expect(decoded['mode'], equals('dark'));
      }

      final fetched = await harness.context
          .query<DriverOverrideEntry>()
          .whereEquals('id', 1)
          .firstOrFail();
      expect(fetched.payload['mode'], equals('dark'));
    });
  });
}
