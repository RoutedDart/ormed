import 'package:ormed/src/driver/mutation_plan.dart' show MutationPlan;
import 'package:ormed/src/driver/plan_compiler.dart' show PlanCompiler;
import 'package:ormed/src/driver/statement_preview.dart' show StatementPreview;
import 'package:ormed/src/query/query_plan.dart';

class ClosurePlanCompiler implements PlanCompiler {
  const ClosurePlanCompiler({
    required StatementPreview Function(QueryPlan) compileSelect,
    required StatementPreview Function(MutationPlan) compileMutation,
  }) : _select = compileSelect,
       _mutation = compileMutation;

  final StatementPreview Function(QueryPlan) _select;
  final StatementPreview Function(MutationPlan) _mutation;

  @override
  StatementPreview compileMutation(MutationPlan plan) => _mutation(plan);

  @override
  StatementPreview compileSelect(QueryPlan plan) => _select(plan);
}
