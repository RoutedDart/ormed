import 'package:meta/meta.dart';

/// Options for SQLite full text search indexes.
@immutable
class SqliteFullTextOptions {
  const SqliteFullTextOptions({this.tokenizer, this.prefixSizes = const []});

  final String? tokenizer;
  final List<int> prefixSizes;

  bool get hasOptions =>
      (tokenizer != null && tokenizer!.isNotEmpty) || prefixSizes.isNotEmpty;

  Map<String, Object?> toJson() => {
    if (tokenizer != null && tokenizer!.isNotEmpty) 'tokenizer': tokenizer,
    if (prefixSizes.isNotEmpty) 'prefixes': prefixSizes,
  };
}
