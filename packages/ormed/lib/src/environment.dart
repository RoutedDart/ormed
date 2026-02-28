/// Environment helpers shared across Ormed runtime and driver packages.
library;

import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;

class OrmedEnvironment {
  OrmedEnvironment([Map<String, String>? values])
    : _values = Map.unmodifiable(
        Map<String, String>.from(values ?? Platform.environment),
      );

  factory OrmedEnvironment.fromDirectory(
    Directory directory, {
    bool includePlatformEnvironment = true,
    bool quiet = true,
  }) {
    final env = dotenv.DotEnv(
      includePlatformEnvironment: includePlatformEnvironment,
      quiet: quiet,
    );
    final candidate = File('${directory.path}/.env');
    env.load(candidate.existsSync() ? [candidate.path] : const <String>[]);
    // ignore: invalid_use_of_visible_for_testing_member
    return OrmedEnvironment(Map<String, String>.from(env.map));
  }

  final Map<String, String> _values;

  Map<String, String> get values => Map<String, String>.from(_values);

  String? value(String key) => firstNonEmpty([key]);

  String? firstNonEmpty(Iterable<String> keys) {
    for (final key in keys) {
      final value = _values[key];
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  String string(String key, {required String fallback}) {
    final value = _values[key];
    if (value == null) return fallback;
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  int intValue(String key, {required int fallback}) {
    final value = _values[key];
    if (value == null) return fallback;
    return int.tryParse(value.trim()) ?? fallback;
  }

  bool boolValue(String key, {required bool fallback}) {
    final value = _values[key];
    if (value == null) return fallback;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return fallback;
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'no' ||
        normalized == 'off' ||
        normalized == 'disable' ||
        normalized == 'disabled') {
      return false;
    }
    return true;
  }

  bool firstBool(Iterable<String> keys, {required bool fallback}) {
    for (final key in keys) {
      final value = _values[key];
      if (value == null) continue;
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      return boolValue(key, fallback: fallback);
    }
    return fallback;
  }

  String require(String key, {String? message}) {
    final resolved = value(key);
    if (resolved == null) {
      throw ArgumentError(message ?? 'Missing required env var: $key');
    }
    return resolved;
  }

  String requireAny(Iterable<String> keys, {String? message}) {
    final resolved = firstNonEmpty(keys);
    if (resolved == null) {
      final missing = keys.join(' or ');
      throw ArgumentError(message ?? 'Missing required env vars: $missing');
    }
    return resolved;
  }

  String interpolate(String input) {
    return _interpolate(input, resolvingKeys: <String>{});
  }

  String _interpolate(String input, {required Set<String> resolvingKeys}) {
    if (!input.contains(r'${')) {
      return input;
    }

    final buffer = StringBuffer();
    var cursor = 0;
    while (cursor < input.length) {
      final start = input.indexOf(r'${', cursor);
      if (start == -1) {
        buffer.write(input.substring(cursor));
        break;
      }

      buffer.write(input.substring(cursor, start));
      final end = _findPlaceholderEnd(input, start + 2);
      if (end == -1) {
        buffer.write(input.substring(start));
        break;
      }

      final token = input.substring(start + 2, end);
      buffer.write(_resolvePlaceholder(token, resolvingKeys: resolvingKeys));
      cursor = end + 1;
    }

    return buffer.toString();
  }

  String _resolvePlaceholder(
    String token, {
    required Set<String> resolvingKeys,
  }) {
    final separatorIndex = token.indexOf(':-');
    if (separatorIndex == -1) {
      final key = token.trim();
      return _resolveVariable(key, resolvingKeys: resolvingKeys) ?? '';
    }

    final key = token.substring(0, separatorIndex).trim();
    final fallbackRaw = token.substring(separatorIndex + 2);
    final value = _resolveVariable(key, resolvingKeys: resolvingKeys);
    if (value == null || value.trim().isEmpty) {
      return _interpolate(fallbackRaw, resolvingKeys: resolvingKeys);
    }
    return value;
  }

  String? _resolveVariable(String key, {required Set<String> resolvingKeys}) {
    if (key.isEmpty) return null;
    final raw = _values[key];
    if (raw == null) return null;
    if (resolvingKeys.contains(key)) {
      return null;
    }

    resolvingKeys.add(key);
    final resolved = _interpolate(raw, resolvingKeys: resolvingKeys);
    resolvingKeys.remove(key);
    return resolved;
  }

  int _findPlaceholderEnd(String input, int fromIndex) {
    var nestedDepth = 0;
    for (var i = fromIndex; i < input.length; i++) {
      final current = input.codeUnitAt(i);
      if (current == 0x24 /* $ */ &&
          i + 1 < input.length &&
          input.codeUnitAt(i + 1) == 0x7B /* { */ ) {
        nestedDepth++;
        i++;
        continue;
      }
      if (current == 0x7D /* } */ ) {
        if (nestedDepth == 0) {
          return i;
        }
        nestedDepth--;
      }
    }
    return -1;
  }
}
