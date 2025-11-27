library;

import 'package:ormed/ormed.dart';

/// Helper to apply a [SchemaPlan] to a [SchemaDriver].
Future<void> applySchemaPlan(SchemaDriver driver, SchemaPlan plan) async {
  await driver.applySchemaPlan(plan);
}

/// Helper to build a [SchemaPlan] from a list of [ModelDefinition]s.
SchemaPlan buildSchemaPlan(List<ModelDefinition> definitions) {
  final mutations = <SchemaMutation>[];
  for (final definition in definitions) {
    final snapshot = ModelTableSnapshot.fromDefinition(definition);
    mutations.add(SchemaMutation.createTable(snapshot.toCreateBlueprint()));
  }
  return SchemaPlan(mutations: mutations);
}

/// Applies schema for a list of [ModelDefinition]s to the given [SchemaDriver].

Future<void> applyModelSchemas(
  SchemaDriver driver,
  List<ModelDefinition> definitions,
) async {
  final plan = buildSchemaPlan(definitions);

  await applySchemaPlan(driver, plan);
}
