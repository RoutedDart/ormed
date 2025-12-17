import 'package:ormed/src/driver/mutation/mutation_plan.dart';
import 'package:ormed/src/driver/statement/statement_preview.dart';
import 'package:ormed/src/query/query_plan.dart';

/// Translates ORM plans into statement previews for a backend.
abstract class PlanCompiler {
  StatementPreview compileSelect(QueryPlan plan);

  StatementPreview compileMutation(MutationPlan plan);
}
