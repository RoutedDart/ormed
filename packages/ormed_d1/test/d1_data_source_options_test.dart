import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';
import 'package:test/test.dart';

void main() {
  group('D1DataSourceRegistryExtensions', () {
    test('builds options from explicit credentials', () {
      final registry = ModelRegistry();

      final options = registry.d1DataSourceOptions(
        accountId: 'acct-1',
        databaseId: 'db-1',
        apiToken: 'token-1',
        maxAttempts: 7,
        debugLog: true,
      );

      expect(options.registry, same(registry));
      expect(options.database, equals('db-1'));
      expect(options.driver, isA<D1DriverAdapter>());

      final driver = options.driver as D1DriverAdapter;
      expect(driver.options['accountId'], equals('acct-1'));
      expect(driver.options['databaseId'], equals('db-1'));
      expect(driver.options['apiToken'], equals('token-1'));
      expect(driver.options['maxAttempts'], equals(7));
      expect(driver.options['debugLog'], isTrue);
    });

    test('builds options from environment map', () {
      final registry = ModelRegistry();

      final options = registry.d1DataSourceOptionsFromEnv(
        environment: const {
          'CF_ACCOUNT_ID': 'acct-env',
          'D1_DATABASE_ID': 'db-env',
          'D1_SECRET': 'token-env',
          'D1_DEBUG_LOG': '1',
          'D1_RETRY_ATTEMPTS': '9',
        },
      );

      final driver = options.driver as D1DriverAdapter;
      expect(driver.options['accountId'], equals('acct-env'));
      expect(driver.options['databaseId'], equals('db-env'));
      expect(driver.options['apiToken'], equals('token-env'));
      expect(driver.options['maxAttempts'], equals(9));
      expect(driver.options['debugLog'], isTrue);
    });

    test('accepts DB_D1_* scaffolded environment variable names', () {
      final registry = ModelRegistry();

      final options = registry.d1DataSourceOptionsFromEnv(
        environment: const {
          'DB_D1_ACCOUNT_ID': 'acct-db',
          'DB_D1_DATABASE_ID': 'db-db',
          'DB_D1_API_TOKEN': 'token-db',
          'DB_D1_BASE_URL': 'https://api.example.invalid/client/v4',
          'DB_D1_RETRY_ATTEMPTS': '7',
          'DB_D1_REQUEST_TIMEOUT_MS': '12000',
          'DB_D1_RETRY_BASE_DELAY_MS': '100',
          'DB_D1_RETRY_MAX_DELAY_MS': '1400',
          'DB_D1_DEBUG_LOG': 'true',
        },
      );

      final driver = options.driver as D1DriverAdapter;
      expect(driver.options['accountId'], equals('acct-db'));
      expect(driver.options['databaseId'], equals('db-db'));
      expect(driver.options['apiToken'], equals('token-db'));
      expect(
        driver.options['baseUrl'],
        equals('https://api.example.invalid/client/v4'),
      );
      expect(driver.options['maxAttempts'], equals(7));
      expect(driver.options['requestTimeoutMs'], equals(12000));
      expect(driver.options['retryBaseDelayMs'], equals(100));
      expect(driver.options['retryMaxDelayMs'], equals(1400));
      expect(driver.options['debugLog'], isTrue);
    });

    test('throws helpful error when required env vars are missing', () {
      final registry = ModelRegistry();
      expect(
        () => registry.d1DataSourceOptionsFromEnv(
          environment: const <String, String>{},
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('D1_DATABASE_ID'),
          ),
        ),
      );
    });
  });
}
