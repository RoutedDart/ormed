enum FullTextMode { natural, boolean, phrase, websearch }

class FullTextWhere {
  FullTextWhere({
    required List<String> columns,
    required this.value,
    this.language,
    this.mode = FullTextMode.natural,
    this.expanded = false,
  }) : columns = List.unmodifiable(columns);

  final List<String> columns;
  final Object value;
  final String? language;
  final FullTextMode mode;
  final bool expanded;
}
