import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';

void runDriverOverrideTests() {
  ormedGroup('driver overrides', (dataSource) {
    test('model definition exposes driver-specific override metadata', () {
      final definition = DriverOverrideEntryOrmDefinition.definition;
      final payload = definition.fieldByName('payload');
      expect(payload, isNotNull);

      final field = payload!;
      expect(field.columnTypeForDriver('postgres'), equals('jsonb'));
      expect(
        field.codecTypeForDriver('postgres'),
        equals('PostgresPayloadCodec'),
      );

      expect(field.columnTypeForDriver('sqlite'), equals('TEXT'));
      expect(field.codecTypeForDriver('sqlite'), equals('SqlitePayloadCodec'));

      expect(field.columnTypeForDriver('mysql'), equals('JSON'));
      expect(
        field.codecTypeForDriver('mariadb'),
        equals('MariaDbPayloadCodec'),
      );

      // Keys are normalized before lookup.
      expect(field.columnTypeForDriver(' Postgres '), equals('jsonb'));
      expect(
        field.codecTypeForDriver(' SQLITE '),
        equals('SqlitePayloadCodec'),
      );
    });

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
        if (driverName.contains('sqlite') || driverName.contains('d1')) {
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
