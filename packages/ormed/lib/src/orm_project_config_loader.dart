/// Loads `orm.yaml` into portable project configuration metadata.
library;

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:meta/meta.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

import 'orm_project_config.dart';

/// Loads [OrmProjectConfig] from [file].
///
/// Throws when the file is missing so callers can instruct users to run
/// `orm init`.
OrmProjectConfig loadOrmProjectConfig(File file) {
  if (!file.existsSync()) {
    throw StateError('Missing orm.yaml at ${file.path}. Run `orm init` first.');
  }
  final parsed = loadYaml(file.readAsStringSync());
  final env = _loadEnv(file.parent);
  final expanded = _expandEnv(parsed, env);
  return OrmProjectConfig.fromMap(expanded as Map<String, Object?>);
}

/// Recursively expand `${VAR}` or `${VAR:-default}` placeholders inside a YAML
/// structure using [environment]. Strings without placeholders are returned
/// unchanged.
@visibleForTesting
Object? expandEnv(Object? value, Map<String, String> environment) =>
    _expandEnv(value, environment);

Map<String, String> _loadEnv(Directory directory) {
  final env = dotenv.DotEnv(includePlatformEnvironment: true, quiet: true);
  final candidate = File('${directory.path}/.env');
  env.load(candidate.existsSync() ? [candidate.path] : const <String>[]);
  // DotEnv exposes the merged map; ignore visibility lint because this is the
  // supported way to read loaded values.
  // ignore: invalid_use_of_visible_for_testing_member
  return Map<String, String>.from(env.map);
}

Object? _expandEnv(Object? value, Map<String, String> environment) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _expandEnv(entry.value, environment),
    };
  }
  if (value is Iterable) {
    return value.map((item) => _expandEnv(item, environment)).toList();
  }
  if (value is String) {
    return _expandString(value, environment);
  }
  return value;
}

final RegExp _envPattern = RegExp(r'\$\{([^}:]+)(:-([^}]*))?\}');

String _expandString(String input, Map<String, String> environment) {
  return input.replaceAllMapped(_envPattern, (match) {
    final key = match.group(1)!;
    final fallback = match.group(3);
    return environment[key] ?? (fallback ?? '');
  });
}
