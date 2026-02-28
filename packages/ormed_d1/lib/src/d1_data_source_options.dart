library;

import 'package:ormed/ormed.dart';

import 'd1_adapter.dart';
import 'd1_transport.dart';

/// Ergonomic Cloudflare D1 helpers for bootstrapping [DataSource] instances.
extension D1DataSourceRegistryExtensions on ModelRegistry {
  /// Builds [DataSourceOptions] for D1 using explicit credentials.
  DataSourceOptions d1DataSourceOptions({
    required String accountId,
    required String databaseId,
    required String apiToken,
    String baseUrl = 'https://api.cloudflare.com/client/v4',
    int maxAttempts = 5,
    int requestTimeoutMs = 30000,
    int retryBaseDelayMs = 250,
    int retryMaxDelayMs = 3000,
    bool debugLog = false,
    String name = 'default',
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    D1Transport? transport,
  }) {
    final options = <String, Object?>{
      'accountId': accountId,
      'databaseId': databaseId,
      'apiToken': apiToken,
      'baseUrl': baseUrl,
      'maxAttempts': maxAttempts,
      'requestTimeoutMs': requestTimeoutMs,
      'retryBaseDelayMs': retryBaseDelayMs,
      'retryMaxDelayMs': retryMaxDelayMs,
      'debugLog': debugLog,
    };
    return DataSourceOptions(
      name: name,
      driver: D1DriverAdapter.custom(
        config: DatabaseConfig(driver: 'd1', options: options),
        transport: transport,
        extensions: driverExtensions,
      ),
      registry: this,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      database: databaseId,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
    );
  }

  /// Builds [DataSourceOptions] for D1 using common environment variables.
  ///
  /// Required vars:
  /// - `D1_ACCOUNT_ID` or `CF_ACCOUNT_ID`
  /// - `D1_DATABASE_ID`
  /// - `D1_API_TOKEN` or `D1_SECRET`
  DataSourceOptions d1DataSourceOptionsFromEnv({
    String name = 'default',
    Map<String, String>? environment,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    D1Transport? transport,
  }) {
    final env = OrmedEnvironment(environment);
    final accountId = env.firstNonEmpty(['D1_ACCOUNT_ID', 'CF_ACCOUNT_ID']);
    final databaseId = env.value('D1_DATABASE_ID');
    final apiToken = env.firstNonEmpty(['D1_API_TOKEN', 'D1_SECRET']);
    final baseUrl = env.string(
      'D1_BASE_URL',
      fallback: 'https://api.cloudflare.com/client/v4',
    );
    final missing = <String>[
      if (accountId == null) 'D1_ACCOUNT_ID or CF_ACCOUNT_ID',
      if (databaseId == null) 'D1_DATABASE_ID',
      if (apiToken == null) 'D1_API_TOKEN or D1_SECRET',
    ];
    if (missing.isNotEmpty) {
      throw ArgumentError('Missing required env vars: ${missing.join(', ')}');
    }

    return d1DataSourceOptions(
      accountId: accountId!,
      databaseId: databaseId!,
      apiToken: apiToken!,
      baseUrl: baseUrl,
      maxAttempts: env.intValue('D1_RETRY_ATTEMPTS', fallback: 5),
      requestTimeoutMs: env.intValue('D1_REQUEST_TIMEOUT_MS', fallback: 30000),
      retryBaseDelayMs: env.intValue('D1_RETRY_BASE_DELAY_MS', fallback: 250),
      retryMaxDelayMs: env.intValue('D1_RETRY_MAX_DELAY_MS', fallback: 3000),
      debugLog: env.boolValue('D1_DEBUG_LOG', fallback: false),
      name: name,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
      driverExtensions: driverExtensions,
      transport: transport,
    );
  }

  /// Builds a D1 [DataSource] using explicit credentials.
  DataSource d1DataSource({
    required String accountId,
    required String databaseId,
    required String apiToken,
    String baseUrl = 'https://api.cloudflare.com/client/v4',
    int maxAttempts = 5,
    int requestTimeoutMs = 30000,
    int retryBaseDelayMs = 250,
    int retryMaxDelayMs = 3000,
    bool debugLog = false,
    String name = 'default',
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    D1Transport? transport,
  }) {
    return DataSource(
      d1DataSourceOptions(
        accountId: accountId,
        databaseId: databaseId,
        apiToken: apiToken,
        baseUrl: baseUrl,
        maxAttempts: maxAttempts,
        requestTimeoutMs: requestTimeoutMs,
        retryBaseDelayMs: retryBaseDelayMs,
        retryMaxDelayMs: retryMaxDelayMs,
        debugLog: debugLog,
        name: name,
        scopeRegistry: scopeRegistry,
        codecs: codecs,
        logging: logging,
        tablePrefix: tablePrefix,
        defaultSchema: defaultSchema,
        carbonTimezone: carbonTimezone,
        carbonLocale: carbonLocale,
        enableNamedTimezones: enableNamedTimezones,
        driverExtensions: driverExtensions,
        transport: transport,
      ),
    );
  }

  /// Builds a D1 [DataSource] from environment variables.
  DataSource d1DataSourceFromEnv({
    String name = 'default',
    Map<String, String>? environment,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    D1Transport? transport,
  }) {
    return DataSource(
      d1DataSourceOptionsFromEnv(
        name: name,
        environment: environment,
        scopeRegistry: scopeRegistry,
        codecs: codecs,
        logging: logging,
        tablePrefix: tablePrefix,
        defaultSchema: defaultSchema,
        carbonTimezone: carbonTimezone,
        carbonLocale: carbonLocale,
        enableNamedTimezones: enableNamedTimezones,
        driverExtensions: driverExtensions,
        transport: transport,
      ),
    );
  }
}
