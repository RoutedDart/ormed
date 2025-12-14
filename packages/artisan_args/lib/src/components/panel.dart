import '../style/artisan_style.dart';
import 'base.dart';
import 'panel_chars.dart';

/// Alignment for panel content.
enum PanelAlignment { left, center, right }

/// A boxed panel component with optional title.
///
/// ```dart
/// PanelComponent(
///   content: 'Hello, World!',
///   title: 'Greeting',
/// ).renderln(context);
/// ```
class PanelComponent extends CliComponent {
  const PanelComponent({
    required this.content,
    this.title,
    this.titleAlign = PanelAlignment.left,
    this.contentAlign = PanelAlignment.left,
    this.chars = PanelBoxChars.rounded,
    this.padding = 1,
    this.width,
  });

  final Object content;
  final String? title;
  final PanelAlignment titleAlign;
  final PanelAlignment contentAlign;
  final PanelBoxCharSet chars;
  final int padding;
  final int? width;

  @override
  RenderResult build(ComponentContext context) {
    final lines = _normalizeLines(content);
    final border = context.style.muted;
    final titleFn = context.style.heading;

    // Calculate width
    final contentWidth = lines
        .map((l) => ArtisanStyle.visibleLength(l))
        .fold<int>(0, (m, v) => v > m ? v : m);
    final titleWidth = title != null
        ? ArtisanStyle.visibleLength(title!) + 4
        : 0;
    final minWidth = [
      contentWidth,
      titleWidth,
      10,
    ].reduce((a, b) => a > b ? a : b);
    final boxWidth = (width ?? minWidth + padding * 2 + 2).clamp(
      minWidth + padding * 2 + 2,
      context.terminalWidth,
    );
    final innerWidth = boxWidth - 2;

    final buffer = StringBuffer();
    final pad = ' ' * padding;

    // Top border with optional title
    if (title != null) {
      final styledTitle = ' ${titleFn(title!)} ';
      final titleLen = ArtisanStyle.visibleLength(styledTitle);
      final remainingWidth = innerWidth - titleLen;

      String topLine;
      switch (titleAlign) {
        case PanelAlignment.left:
          final rightFill = chars.horizontal * (remainingWidth - 1);
          topLine =
              '${chars.topLeft}${chars.horizontal}$styledTitle$rightFill${chars.topRight}';
        case PanelAlignment.center:
          final leftFill = chars.horizontal * (remainingWidth ~/ 2);
          final rightFill =
              chars.horizontal * (remainingWidth - remainingWidth ~/ 2);
          topLine =
              '${chars.topLeft}$leftFill$styledTitle$rightFill${chars.topRight}';
        case PanelAlignment.right:
          final leftFill = chars.horizontal * (remainingWidth - 1);
          topLine =
              '${chars.topLeft}$leftFill$styledTitle${chars.horizontal}${chars.topRight}';
      }
      buffer.writeln(border(topLine));
    } else {
      buffer.writeln(
        border(
          '${chars.topLeft}${chars.horizontal * innerWidth}${chars.topRight}',
        ),
      );
    }

    // Content lines
    for (final line in lines) {
      final visible = ArtisanStyle.visibleLength(line);
      final available = innerWidth - padding * 2;
      final fill = available - visible;

      String paddedLine;
      switch (contentAlign) {
        case PanelAlignment.left:
          paddedLine = '$pad$line${' ' * (fill > 0 ? fill : 0)}$pad';
        case PanelAlignment.center:
          final leftPad = ' ' * (fill ~/ 2);
          final rightPad = ' ' * (fill - fill ~/ 2);
          paddedLine = '$pad$leftPad$line$rightPad$pad';
        case PanelAlignment.right:
          paddedLine = '$pad${' ' * (fill > 0 ? fill : 0)}$line$pad';
      }

      buffer.writeln(
        '${border(chars.vertical)}$paddedLine${border(chars.vertical)}',
      );
    }

    // Bottom border
    buffer.write(
      border(
        '${chars.bottomLeft}${chars.horizontal * innerWidth}${chars.bottomRight}',
      ),
    );

    return RenderResult(output: buffer.toString(), lineCount: lines.length + 2);
  }

  List<String> _normalizeLines(Object content) {
    if (content is Iterable) {
      return content.map((e) => e.toString()).toList();
    }
    return content.toString().split('\n');
  }
}
