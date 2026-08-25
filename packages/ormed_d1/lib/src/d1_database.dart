import 'package:ormed/ormed.dart';

import 'd1_binding.dart';
import 'd1_data_source_options.dart';
import 'd1_transport.dart';

/// High-level Cloudflare D1 connection helpers that do not require generated code.
class D1Database {
  D1Database._();

  /// Opens a D1 database using explicit credentials.
  static Future<OrmDatabase> connect({
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
    ModelRegistry? registry,
    ScopeRegistry? scopeRegistry,
    Map<String, ValueCodec<dynamic>> codecs = const {},
    bool logging = false,
    String tablePrefix = '',
    String? defaultSchema,
    String carbonTimezone = 'UTC',
    String carbonLocale = 'en_US',
    bool enableNamedTimezones = false,
    List<DriverExtension> driverExtensions = const [],
    List<QueryInterceptor> interceptors = const [],
    D1Transport? transport,
  }) {
    final models = registry ?? ModelRegistry();
    final options = models.d1DataSourceOptions(
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
    );
    return OrmDatabase.fromDataSource(
      DataSource(options.copyWith(interceptors: interceptors)),
    );
  }

  /// Opens a D1 database from a native Worker binding.
  static Future<OrmDatabase> fromBinding({
    required D1DatabaseBinding binding,
    String name = 'default',
    ModelRegistry? registry,
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
    List<QueryInterceptor> interceptors = const [],
  }) {
    final models = registry ?? ModelRegistry();
    final options = models.d1DataSourceOptionsFromBinding(
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
    );
    return OrmDatabase.fromDataSource(
      DataSource(options.copyWith(interceptors: interceptors)),
    );
  }

  /// Opens a database through an application-owned D1 HTTP endpoint.
  ///
  /// Use this from browsers or any host that cannot access a native D1
  /// binding. The endpoint is responsible for authenticating the caller and
  /// executing D1 inside the Worker; do not put a Cloudflare API token in a
  /// browser application.
  static Future<OrmDatabase> fromEndpoint({
    required Uri endpoint,
    Uri? batchEndpoint,
    Map<String, String> headers = const <String, String>{},
    String name = 'default',
    ModelRegistry? registry,
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
    List<QueryInterceptor> interceptors = const [],
    D1Transport? transport,
  }) {
    final models = registry ?? ModelRegistry();
    final options = models.d1DataSourceOptionsFromEndpoint(
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
    );
    return OrmDatabase.fromDataSource(
      DataSource(options.copyWith(interceptors: interceptors)),
    );
  }
}
