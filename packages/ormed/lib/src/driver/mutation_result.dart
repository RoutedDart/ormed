/// Result information produced by [MutationPlan] execution.
class MutationResult {
  const MutationResult({required this.affectedRows, this.returnedRows});

  final int affectedRows;
  final List<Map<String, Object?>>? returnedRows;
}
