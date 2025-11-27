enum IndexHintType { use, force, ignore }

class IndexHint {
  IndexHint(this.type, List<String> indexes)
    : indexes = List.unmodifiable(indexes);

  final IndexHintType type;
  final List<String> indexes;
}
