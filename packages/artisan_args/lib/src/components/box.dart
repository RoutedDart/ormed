import '../style/artisan_style.dart';
import 'base.dart';

/// A key-value pair component with dot fill.
class KeyValue extends CliComponent {
  const KeyValue({
    required this.key,
    required this.value,
    this.fillChar = '.',
    this.width,
  });

  final String key;
  final String value;
  final String fillChar;
  final int? width;

  @override
  RenderResult build(ComponentContext context) {
    final totalWidth = width ?? context.terminalWidth;
    final keyLen = ArtisanStyle.visibleLength(key);
    final valueLen = ArtisanStyle.visibleLength(value);
    final fillLen = totalWidth - keyLen - valueLen - 2;
    final fill = fillLen > 0 ? ' ${fillChar * fillLen} ' : ' ';

    return RenderResult(output: '$key$fill$value', lineCount: 1);
  }
}

/// A boxed message component.
class Box extends CliComponent {
  const Box({
    required this.content,
    this.title,
    this.borderStyle = BorderStyle.rounded,
    this.padding = 1,
  });

  final String content;
  final String? title;
  final BorderStyle borderStyle;
  final int padding;

  @override
  RenderResult build(ComponentContext context) {
    final chars = borderStyle.chars;
    final lines = content.split('\n');
    final maxLen = lines
        .map((l) => ArtisanStyle.visibleLength(l))
        .reduce((a, b) => a > b ? a : b);
    final innerWidth = maxLen + (padding * 2);

    final buffer = StringBuffer();

    // Top border
    if (title != null) {
      final titlePart = '${chars.horizontal} $title ';
      final remaining = innerWidth - titlePart.length;
      buffer.writeln(
        '${chars.topLeft}$titlePart${chars.horizontal * remaining}${chars.topRight}',
      );
    } else {
      buffer.writeln(
        '${chars.topLeft}${chars.horizontal * innerWidth}${chars.topRight}',
      );
    }

    // Content
    final pad = ' ' * padding;
    for (final line in lines) {
      final lineLen = ArtisanStyle.visibleLength(line);
      final rightPad = ' ' * (maxLen - lineLen);
      buffer.writeln(
        '${chars.vertical}$pad$line$rightPad$pad${chars.vertical}',
      );
    }

    // Bottom border
    buffer.write(
      '${chars.bottomLeft}${chars.horizontal * innerWidth}${chars.bottomRight}',
    );

    return RenderResult(output: buffer.toString(), lineCount: lines.length + 2);
  }
}

/// Border styles for boxes.
enum BorderStyle {
  rounded,
  single,
  double,
  heavy,
  ascii;

  ComponentBoxChars get chars => switch (this) {
    BorderStyle.rounded => ComponentBoxChars.rounded,
    BorderStyle.single => ComponentBoxChars.single,
    BorderStyle.double => ComponentBoxChars.double,
    BorderStyle.heavy => ComponentBoxChars.heavy,
    BorderStyle.ascii => ComponentBoxChars.ascii,
  };
}

/// Box drawing characters for component system.
class ComponentBoxChars {
  const ComponentBoxChars({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.horizontal,
    required this.vertical,
  });

  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;
  final String horizontal;
  final String vertical;

  static const rounded = ComponentBoxChars(
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
    horizontal: '─',
    vertical: '│',
  );

  static const single = ComponentBoxChars(
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
    horizontal: '─',
    vertical: '│',
  );

  static const double = ComponentBoxChars(
    topLeft: '╔',
    topRight: '╗',
    bottomLeft: '╚',
    bottomRight: '╝',
    horizontal: '═',
    vertical: '║',
  );

  static const heavy = ComponentBoxChars(
    topLeft: '┏',
    topRight: '┓',
    bottomLeft: '┗',
    bottomRight: '┛',
    horizontal: '━',
    vertical: '┃',
  );

  static const ascii = ComponentBoxChars(
    topLeft: '+',
    topRight: '+',
    bottomLeft: '+',
    bottomRight: '+',
    horizontal: '-',
    vertical: '|',
  );
}
