/// Loads `orm.yaml` into portable project configuration metadata.
library;

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'orm_project_config.dart';

/// Loads [OrmProjectConfig] from [file].
///
/// Throws when the file is missing so callers can instruct users to run
/// `orm init`.
OrmProjectConfig loadOrmProjectConfig(File file) {
  if (!file.existsSync()) {
    throw StateError('Missing orm.yaml at ${file.path}. Run `orm init` first.');
  }
  final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
  return OrmProjectConfig.fromYaml(yaml);
}
