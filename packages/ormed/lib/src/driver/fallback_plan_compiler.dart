import 'package:ormed/src/driver/mutation_plan.dart';
import 'package:ormed/src/driver/plan_compiler.dart';
import 'package:ormed/src/driver/sql_statement_payload.dart'
    show SqlStatementPayload;
import 'package:ormed/src/driver/statement_preview.dart';
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
