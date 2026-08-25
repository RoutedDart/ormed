library;

import 'package:ormed/ormed.dart';

import 'd1_adapter.dart';
import 'd1_binding.dart';
import 'd1_transport.dart';

/// Ergonomic Cloudflare D1 helpers for bootstrapping [DataSource] instances.
extension D1DataSourceRegistryExtensions on ModelRegistry {
  /// Builds [DataSourceOptions] over a native Cloudflare D1 binding.
  DataSourceOptions d1DataSourceOptionsFromBinding({
    required D1DatabaseBinding binding,
    String name = 'default',
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String? database,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) {
    return DataSourceOptions(
      name: name,
      driver: D1DriverAdapter.fromBinding(
        config: DatabaseConfig(
          driver: 'd1',
          options: <String, Object?>{
            ...?(database == null
                ? null
                : <String, Object?>{'database': database}),
          },
        ),
        binding: binding,
        extensions: driverExtensions,
      ),
      registry: this,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      database: database,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
    );
  }

  /// Builds a [DataSource] over a native Cloudflare D1 binding.
  DataSource d1DataSourceFromBinding({
    required D1DatabaseBinding binding,
    String name = 'default',
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String? database,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
  }) => DataSource(
    d1DataSourceOptionsFromBinding(
      binding: binding,
      name: name,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      database: database,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
      driverExtensions: driverExtensions,
    ),
  );

  /// Builds [DataSourceOptions] over an application-owned D1 HTTP endpoint.
  ///
  /// The endpoint is suitable for browser and Worker clients. Authentication
  /// belongs in [headers] or in the endpoint's session/cookie policy; this
  /// helper never requires or embeds a Cloudflare API token.
  DataSourceOptions d1DataSourceOptionsFromEndpoint({
    required Uri endpoint,
    Uri? batchEndpoint,
    Map<String, String> headers = const <String, String>{},
    String name = 'default',
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String? database,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    int maxAttempts = 4,
    int requestTimeoutMs = 30000,
    int retryBaseDelayMs = 250,
    int retryMaxDelayMs = 3000,
    bool debugLog = false,
    D1Transport? transport,
  }) {
    final options = <String, Object?>{
      'endpoint': endpoint.toString(),
      if (batchEndpoint != null) 'batchEndpoint': batchEndpoint.toString(),
      if (headers.isNotEmpty) 'headers': headers,
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
      database: database,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
    );
  }

  /// Builds a [DataSource] over an application-owned D1 HTTP endpoint.
  DataSource d1DataSourceFromEndpoint({
    required Uri endpoint,
    Uri? batchEndpoint,
    Map<String, String> headers = const <String, String>{},
    String name = 'default',
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String? database,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    int maxAttempts = 4,
    int requestTimeoutMs = 30000,
    int retryBaseDelayMs = 250,
    int retryMaxDelayMs = 3000,
    bool debugLog = false,
    D1Transport? transport,
  }) => DataSource(
    d1DataSourceOptionsFromEndpoint(
      endpoint: endpoint,
      batchEndpoint: batchEndpoint,
      headers: headers,
      name: name,
      scopeRegistry: scopeRegistry,
      codecs: codecs,
      logging: logging,
      database: database,
      tablePrefix: tablePrefix,
      defaultSchema: defaultSchema,
      carbonTimezone: carbonTimezone,
      carbonLocale: carbonLocale,
      enableNamedTimezones: enableNamedTimezones,
      driverExtensions: driverExtensions,
      maxAttempts: maxAttempts,
      requestTimeoutMs: requestTimeoutMs,
      retryBaseDelayMs: retryBaseDelayMs,
      retryMaxDelayMs: retryMaxDelayMs,
      debugLog: debugLog,
      transport: transport,
    ),
  );

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
  /// - `D1_ACCOUNT_ID` or `CF_ACCOUNT_ID` (also accepts `DB_D1_ACCOUNT_ID`)
  /// - `D1_DATABASE_ID` (also accepts `DB_D1_DATABASE_ID`)
  /// - `D1_API_TOKEN` or `D1_SECRET` (also accepts `DB_D1_API_TOKEN`)
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
    final accountId = env.firstNonEmpty([
      'D1_ACCOUNT_ID',
      'CF_ACCOUNT_ID',
      'DB_D1_ACCOUNT_ID',
    ]);
    final databaseId = env.firstNonEmpty([
      'D1_DATABASE_ID',
      'DB_D1_DATABASE_ID',
    ]);
    final apiToken = env.firstNonEmpty([
      'D1_API_TOKEN',
      'D1_SECRET',
      'DB_D1_API_TOKEN',
    ]);
    final baseUrl =
        env.firstNonEmpty(['D1_BASE_URL', 'DB_D1_BASE_URL']) ??
        'https://api.cloudflare.com/client/v4';
    final maxAttempts = _intFromEnv(
      env,
      keys: const ['D1_RETRY_ATTEMPTS', 'DB_D1_RETRY_ATTEMPTS'],
      fallback: 5,
    );
    final requestTimeoutMs = _intFromEnv(
      env,
      keys: const ['D1_REQUEST_TIMEOUT_MS', 'DB_D1_REQUEST_TIMEOUT_MS'],
      fallback: 30000,
    );
    final retryBaseDelayMs = _intFromEnv(
      env,
      keys: const ['D1_RETRY_BASE_DELAY_MS', 'DB_D1_RETRY_BASE_DELAY_MS'],
      fallback: 250,
    );
    final retryMaxDelayMs = _intFromEnv(
      env,
      keys: const ['D1_RETRY_MAX_DELAY_MS', 'DB_D1_RETRY_MAX_DELAY_MS'],
      fallback: 3000,
    );
    final debugLog = _boolFromEnv(
      env,
      keys: const ['D1_DEBUG_LOG', 'DB_D1_DEBUG_LOG'],
      fallback: false,
    );
    final missing = <String>[
      if (accountId == null)
        'D1_ACCOUNT_ID or CF_ACCOUNT_ID or DB_D1_ACCOUNT_ID',
      if (databaseId == null) 'D1_DATABASE_ID or DB_D1_DATABASE_ID',
      if (apiToken == null) 'D1_API_TOKEN or D1_SECRET or DB_D1_API_TOKEN',
    ];
    if (missing.isNotEmpty) {
      throw ArgumentError('Missing required env vars: ${missing.join(', ')}');
    }

    return d1DataSourceOptions(
      accountId: accountId!,
      databaseId: databaseId!,
      apiToken: apiToken!,
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

int _intFromEnv(
  OrmedEnvironment env, {
  required List<String> keys,
  required int fallback,
}) {
  for (final key in keys) {
    final raw = env.value(key);
    if (raw == null) continue;
    final parsed = int.tryParse(raw.trim());
    if (parsed != null) return parsed;
  }
  return fallback;
}

bool _boolFromEnv(
  OrmedEnvironment env, {
  required List<String> keys,
  required bool fallback,
}) {
  for (final key in keys) {
    final raw = env.value(key);
    if (raw == null) continue;
    final normalized = raw.trim().toLowerCase();
    if (normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on') {
      return true;
    }
    if (normalized == '0' ||
        normalized == 'false' ||
        normalized == 'no' ||
        normalized == 'off') {
      return false;
    }
  }
  return fallback;
}
