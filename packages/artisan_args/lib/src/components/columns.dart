import '../style/artisan_style.dart';
import 'base.dart';

/// A multi-column layout component.
///
/// ```dart
/// ColumnsComponent(
///   items: ['Item 1', 'Item 2', 'Item 3', 'Item 4'],
///   columnCount: 2,
/// ).renderln(context);
/// ```
class ColumnsComponent extends CliComponent {
  const ColumnsComponent({
    required this.items,
    this.columnCount,
    this.gutter = 2,
    this.indent = 2,
  });

  final List<String> items;
  final int? columnCount;
  final int gutter;
  final int indent;

  @override
  RenderResult build(ComponentContext context) {
    if (items.isEmpty) return RenderResult.empty;

    // Auto-calculate columns if not specified
    final maxItemWidth = items
        .map((i) => ArtisanStyle.visibleLength(i))
        .fold<int>(0, (m, v) => v > m ? v : m);
    final cols =
        columnCount ??
        ((context.terminalWidth - indent) ~/ (maxItemWidth + gutter)).clamp(
          1,
          items.length,
        );

    final colWidth =
        (context.terminalWidth - indent - (cols - 1) * gutter) ~/ cols;

    final buffer = StringBuffer();
    var lineCount = 0;

    for (var i = 0; i < items.length; i += cols) {
      final row = <String>[];
      for (var j = 0; j < cols && i + j < items.length; j++) {
        final item = items[i + j];
        final visible = ArtisanStyle.visibleLength(item);
        final fill = colWidth - visible;
        row.add('$item${' ' * (fill > 0 ? fill : 0)}');
      }
      if (lineCount > 0) buffer.writeln();
      buffer.write('${' ' * indent}${row.join(' ' * gutter)}');
      lineCount++;
    }

    return RenderResult(output: buffer.toString(), lineCount: lineCount);
  }
}
