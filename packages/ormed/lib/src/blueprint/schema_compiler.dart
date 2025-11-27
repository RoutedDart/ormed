import '../hook/query_builder_hook.dart';
import 'schema_driver.dart';
import 'schema_plan.dart';

/// Translates [SchemaPlan] objects into SQL statements using a dialect.
class SchemaPlanCompiler {
  SchemaPlanCompiler(this.dialect, {List<SchemaMutationHook>? hooks})
    : _hooks = hooks ?? const <SchemaMutationHook>[];

  final SchemaDialect dialect;
  final List<SchemaMutationHook> _hooks;

  SchemaPreview compile(SchemaPlan plan) {
    final statements = <SchemaStatement>[];
    for (final mutation in plan.mutations) {
      final hookStatements = _hookStatements(mutation);
      if (hookStatements != null) {
        statements.addAll(hookStatements);
        continue;
      }
      statements.addAll(dialect.compileMutation(mutation));
    }
    return SchemaPreview(List.unmodifiable(statements));
  }

  List<SchemaStatement>? _hookStatements(SchemaMutation mutation) {
    for (final hook in _hooks) {
      if (hook.handles(mutation)) {
        return hook.handle(mutation);
      }
    }
    return null;
  }
}

/// Dialects convert individual schema mutations into executable SQL.
abstract class SchemaDialect {
  const SchemaDialect();

  /// Identifier for the driver this dialect targets (e.g. `postgres`).
  String get driverName;

  List<SchemaStatement> compileMutation(SchemaMutation mutation);
}
