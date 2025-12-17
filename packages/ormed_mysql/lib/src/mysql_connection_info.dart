/// Connection URL parsing helpers for MySQL / MariaDB.
library;

/// Parsed connection components from a `mysql://` or `mariadb://` URL.
///
/// This is intentionally small and reusable: it focuses on the pieces commonly
/// required for adapters, test harnesses, and tools:
/// host/port/database/credentials plus TLS intent.
class MySqlConnectionInfo {
  MySqlConnectionInfo({
    required this.scheme,
    required this.host,
    required this.port,
    required this.database,
    this.username,
    this.password,
    required this.secure,
  });

  /// URL scheme (e.g. `mysql`, `mariadb`, `mysqls`, `mariadbs`, `mysql+ssl`).
  ///
  /// The scheme is preserved from the input URL when available, but can also be
  /// overridden when reconstructing a URL via [toUrl].
  final String scheme;

  final String host;
  final int port;
  final String database;
  final String? username;
  final String? password;

  /// Whether TLS should be used for the connection.
  ///
  /// Resolution order:
  /// 1) If the URL contains `?ssl=...` or `?secure=...`, those explicitly win.
  /// 2) Otherwise, if the scheme implies TLS (`mysqls`, `mariadbs`, `+ssl`), it
  ///    enables TLS.
  /// 3) Otherwise, it falls back to [secureByDefault] passed to [fromUrl].
  final bool secure;

  /// Parse a `mysql://` / `mariadb://` URL into connection components.
  ///
  /// [secureByDefault] is only used when the URL does not explicitly specify
  /// `ssl`/`secure` and the scheme does not imply TLS.
  factory MySqlConnectionInfo.fromUrl(
    String url, {
    bool secureByDefault = false,
  }) {
    final uri = Uri.parse(url);

    final host = uri.host.isEmpty ? 'localhost' : uri.host;
    final port = uri.hasPort ? uri.port : 3306;
    final database =
        uri.pathSegments.isNotEmpty && uri.pathSegments.first.isNotEmpty
        ? uri.pathSegments.first
        : 'mysql';

    String? username;
    String? password;
    if (uri.userInfo.isNotEmpty) {
      final parts = uri.userInfo.split(':');
      username = Uri.decodeComponent(parts.first);
      if (parts.length > 1) {
        password = Uri.decodeComponent(parts.sublist(1).join(':'));
      }
    }

    var secure = secureByDefault || _schemeRequiresTls(uri.scheme);

    // Explicit query params win over defaults / scheme.
    final sslParam = uri.queryParameters['ssl'];
    final secureParam = uri.queryParameters['secure'];
    final explicit = sslParam ?? secureParam;
    if (explicit != null) {
      secure = _parseBool(explicit) ?? secure;
    }

    return MySqlConnectionInfo(
      scheme: uri.scheme.isEmpty ? 'mysql' : uri.scheme,
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      secure: secure,
    );
  }

  /// Reconstruct the URL, optionally overriding selected parts.
  String toUrl({String? database, bool? secure, String? scheme}) {
    final db = database ?? this.database;
    final useSsl = secure ?? this.secure;
    final effectiveScheme = scheme ?? this.scheme;
    final auth = username != null
        ? (password != null ? '$username:$password@' : '$username@')
        : '';
    final sslQuery = useSsl ? '?secure=true' : '';
    return '$effectiveScheme://$auth$host:$port/$db$sslQuery';
  }
}

/// Convenience wrapper for MariaDB-specific URLs.
///
/// This is equivalent to using [MySqlConnectionInfo] with a `mariadb://...`
/// URL, but is handy for naming and intent in apps/tests.
class MariaDbConnectionInfo extends MySqlConnectionInfo {
  MariaDbConnectionInfo({
    required super.host,
    required super.port,
    required super.database,
    super.username,
    super.password,
    required super.secure,
  }) : super(scheme: 'mariadb');

  factory MariaDbConnectionInfo.fromUrl(
    String url, {
    bool secureByDefault = false,
  }) {
    final parsed = MySqlConnectionInfo.fromUrl(
      url,
      secureByDefault: secureByDefault,
    );
    return MariaDbConnectionInfo(
      host: parsed.host,
      port: parsed.port,
      database: parsed.database,
      username: parsed.username,
      password: parsed.password,
      secure: parsed.secure,
    );
  }
}

bool _schemeRequiresTls(String scheme) {
  final normalized = scheme.toLowerCase();
  if (normalized.contains('+ssl')) return true;
  return normalized == 'mysqls' || normalized == 'mariadbs';
}

bool? _parseBool(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
