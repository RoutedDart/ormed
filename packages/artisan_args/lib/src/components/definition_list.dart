import 'base.dart';

/// A definition list component (term: description pairs).
///
/// ```dart
/// DefinitionListComponent(
///   items: {
///     'Name': 'artisan_args',
///     'Version': '1.0.0',
///   },
/// ).renderln(context);
/// ```
class DefinitionListComponent extends CliComponent {
  const DefinitionListComponent({
    required this.items,
    this.separator = ':',
    this.indent = 2,
  });

  final Map<String, String> items;
  final String separator;
  final int indent;

  @override
  RenderResult build(ComponentContext context) {
    if (items.isEmpty) return RenderResult.empty;

    final buffer = StringBuffer();
    final maxKeyLen = items.keys
        .map((k) => k.length)
        .reduce((a, b) => a > b ? a : b);

    var first = true;
    for (final entry in items.entries) {
      if (!first) buffer.writeln();
      first = false;

      final key = entry.key.padRight(maxKeyLen);
      buffer.write(
        '${' ' * indent}${context.style.emphasize(key)}$separator ${entry.value}',
      );
    }

    return RenderResult(output: buffer.toString(), lineCount: items.length);
  }
}
