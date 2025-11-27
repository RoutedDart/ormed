class JsonUpdateClause {
  const JsonUpdateClause({
    required this.column,
    required this.path,
    required this.value,
    this.patch = false,
  });

  final String column;
  final String path;
  final Object? value;
  final bool patch;
}
