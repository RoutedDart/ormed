import 'package:ormed/src/driver/compiler/plan_compiler.dart';
import 'package:ormed/src/driver/mutation/mutation_plan.dart';
import 'package:ormed/src/driver/statement/sql_statement_payload.dart'
    show SqlStatementPayload;
import 'package:ormed/src/driver/statement/statement_preview.dart';
import 'package:ormed/src/query/query_plan.dart';

class FallbackPlanCompiler implements PlanCompiler {
  const FallbackPlanCompiler();

  @override
  StatementPreview compileMutation(MutationPlan plan) =>
      const StatementPreview(payload: SqlStatementPayload(sql: '<fallback>'));

  @override
  StatementPreview compileSelect(QueryPlan plan) =>
      const StatementPreview(payload: SqlStatementPayload(sql: '<fallback>'));
}

PlanCompiler fallbackPlanCompiler() => const FallbackPlanCompiler();
