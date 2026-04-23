library;

Map<String, Object?> sqliteSessionOptions(Map<String, Object?> options) {
  return _mapFrom(options['session']);
}

Set<String> sqliteSessionAllowlist(Map<String, Object?> options) {
  final raw =
      options['sessionAllowlist'] ??
      options['session_allowlist'] ??
      options['sessionAllowList'];
  return _stringListFrom(
    raw,
  ).map((entry) => entry.trim()).where((entry) => entry.isNotEmpty).toSet();
}

List<String> sqliteInitStatements(Map<String, Object?> options) {
  return _stringListFrom(options['init']);
}

void validateSqliteSessionKey(
  String key,
  Set<String> allowlist, {
  required String driverName,
}) {
  if (!_sessionKeyPattern.hasMatch(key)) {
    throw ArgumentError.value(
      key,
      'session',
      'Invalid $driverName session option key.',
    );
  }
  if (allowlist.isNotEmpty && !allowlist.contains(key)) {
    throw ArgumentError.value(
      key,
      'session',
      'Session option "$key" is not allowlisted for $driverName.',
    );
  }
}

String sqlitePragmaValue(Object? value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? 'ON' : 'OFF';
  if (value is num) return value.toString();
  return _quote(value.toString());
}

Map<String, Object?> _mapFrom(Object? value) {
  if (value == null) return const {};
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry(key.toString(), v));
  }
  return const {};
}

List<String> _stringListFrom(Object? value) {
  if (value == null) return const [];
  if (value is List<String>) return List<String>.from(value);
  if (value is List) {
    return value.map((entry) => entry.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return [value];
  }
  return const [];
}

final RegExp _sessionKeyPattern = RegExp(
  r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$',
);

String _quote(String value) => '\'${value.replaceAll('\'', "''")}\'';
