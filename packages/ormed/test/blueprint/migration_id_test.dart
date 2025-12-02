import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('MigrationId', () {
    group('parse() - new format (m_YYYYMMDDHHMMSS_slug)', () {
      test('parses new format with m_ prefix', () {
        final id = MigrationId.parse('m_20251130100953_create_users_table');

        expect(id.timestamp, DateTime.utc(2025, 11, 30, 10, 9, 53));
        expect(id.slug, 'create_users_table');
      });

      test('parses new format without m_ prefix', () {
        final id = MigrationId.parse('20251130100953_create_users_table');

        expect(id.timestamp, DateTime.utc(2025, 11, 30, 10, 9, 53));
        expect(id.slug, 'create_users_table');
      });

      test('handles slug with multiple underscores', () {
        final id = MigrationId.parse(
          'm_20251201090000_add_email_verified_at_column',
        );

        expect(id.timestamp, DateTime.utc(2025, 12, 1, 9, 0, 0));
        expect(id.slug, 'add_email_verified_at_column');
      });
    });

    group(
      'parse() - old format (YYYY_MM_DD_HHMMSS_slug) for backward compatibility',
      () {
        test('parses old format', () {
          final id = MigrationId.parse('2025_11_30_100953_create_users_table');

          expect(id.timestamp, DateTime.utc(2025, 11, 30, 10, 9, 53));
          expect(id.slug, 'create_users_table');
        });

        test('handles old format with multiple underscores in slug', () {
          final id = MigrationId.parse(
            '2025_12_01_090000_add_email_verified_at',
          );

          expect(id.timestamp, DateTime.utc(2025, 12, 1, 9, 0, 0));
          expect(id.slug, 'add_email_verified_at');
        });
      },
    );

    group('toFileName()', () {
      test('generates filename in new format', () {
        final timestamp = DateTime.utc(2025, 11, 30, 10, 9, 53);
        final id = MigrationId(timestamp, 'create_users_table');

        expect(id.toFileName(), 'm_20251130100953_create_users_table');
      });

      test('preserves slug with multiple underscores', () {
        final timestamp = DateTime.utc(2025, 12, 1, 9, 0, 0);
        final id = MigrationId(timestamp, 'add_email_verified_at_column');

        expect(
          id.toFileName(),
          'm_20251201090000_add_email_verified_at_column',
        );
      });
    });

    group('format consistency', () {
      test('new format -> toFileName() round-trips correctly', () {
        const original = 'm_20251130100953_create_users_table';
        final parsed = MigrationId.parse(original);
        final generated = parsed.toFileName();

        expect(generated, original);
      });

      test('old format -> toFileName() converts to new format', () {
        const original = '2025_11_30_100953_create_users_table';
        final parsed = MigrationId.parse(original);
        final generated = parsed.toFileName();

        expect(generated, 'm_20251130100953_create_users_table');
      });

      test('both formats parse to same MigrationId', () {
        final newFormat = MigrationId.parse(
          'm_20251130100953_create_users_table',
        );
        final oldFormat = MigrationId.parse(
          '2025_11_30_100953_create_users_table',
        );

        expect(newFormat, oldFormat);
        expect(newFormat.timestamp, oldFormat.timestamp);
        expect(newFormat.slug, oldFormat.slug);
      });
    });

    group('sorting and comparison', () {
      test('migrations sort by timestamp correctly', () {
        final ids = [
          MigrationId.parse('m_20251202120000_third'),
          MigrationId.parse('m_20251201090000_second'),
          MigrationId.parse('m_20251130100953_first'),
        ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        expect(ids[0].slug, 'first');
        expect(ids[1].slug, 'second');
        expect(ids[2].slug, 'third');
      });

      test('equality works correctly', () {
        final id1 = MigrationId.parse('m_20251130100953_create_users_table');
        final id2 = MigrationId.parse('m_20251130100953_create_users_table');
        final id3 = MigrationId.parse('m_20251130100954_create_users_table');

        expect(id1, id2);
        expect(id1, isNot(id3));
      });
    });

    group('error handling', () {
      test('throws on invalid new format', () {
        expect(
          () => MigrationId.parse('m_202511_create_users'),
          throwsFormatException,
        );
      });

      test('throws on invalid old format', () {
        expect(
          () => MigrationId.parse('2025_11_create_users'),
          throwsFormatException,
        );
      });

      test('handles edge case timestamps', () {
        // Dart DateTime wraps out-of-range values, so this is valid
        final id = MigrationId.parse('m_20259999123456_edge_case');
        // Just verify it doesn't crash
        expect(id.slug, 'edge_case');
      });
    });
  });
}
