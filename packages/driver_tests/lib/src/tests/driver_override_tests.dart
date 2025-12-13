import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';

void runDriverOverrideTests() {
  ormedGroup('driver overrides', (dataSource) {
    test(
      'repository encodes payload using driver-specific codec',
      () async {
        final ds = dataSource;
        final repo = ds.context.repository<DriverOverrideEntry>();
        const entry = DriverOverrideEntry(id: 1, payload: {'mode': 'dark'});
        await repo.insert(entry);

        final rows = await ds.connection.driver.queryRaw(
          'SELECT payload FROM driver_override_entries WHERE id = 1',
        );
        final value = rows.single['payload'];
        final driverName = ds.options.driver.metadata.name.toLowerCase();
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

        final fetched = await ds.context
            .query<DriverOverrideEntry>()
            .whereEquals('id', 1)
            .firstOrFail();
        expect(fetched.payload['mode'], equals('dark'));
      },
      skip: !dataSource.options.driver.metadata.supportsCapability(
        DriverCapability.rawSQL,
      ),
    );
  });
}
