import '../style/artisan_style.dart';

/// Box drawing characters for panels and borders.
class BoxChars {
  BoxChars._();

  /// Single line box characters.
  static const single = BoxCharSet(
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
    horizontal: '─',
    vertical: '│',
    leftT: '├',
    rightT: '┤',
    topT: '┬',
    bottomT: '┴',
    cross: '┼',
  );

  /// Double line box characters.
  static const double = BoxCharSet(
    topLeft: '╔',
    topRight: '╗',
    bottomLeft: '╚',
    bottomRight: '╝',
    horizontal: '═',
    vertical: '║',
    leftT: '╠',
    rightT: '╣',
    topT: '╦',
    bottomT: '╩',
    cross: '╬',
  );

  /// Rounded box characters.
  static const rounded = BoxCharSet(
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
    horizontal: '─',
    vertical: '│',
    leftT: '├',
    rightT: '┤',
    topT: '┬',
    bottomT: '┴',
    cross: '┼',
  );

  /// Heavy/bold box characters.
  static const heavy = BoxCharSet(
    topLeft: '┏',
    topRight: '┓',
    bottomLeft: '┗',
    bottomRight: '┛',
    horizontal: '━',
    vertical: '┃',
    leftT: '┣',
    rightT: '┫',
    topT: '┳',
    bottomT: '┻',
    cross: '╋',
  );

  /// ASCII-only box characters.
  static const ascii = BoxCharSet(
    topLeft: '+',
    topRight: '+',
    bottomLeft: '+',
    bottomRight: '+',
    horizontal: '-',
    vertical: '|',
    leftT: '+',
    rightT: '+',
    topT: '+',
    bottomT: '+',
    cross: '+',
  );
}

/// A set of box drawing characters.
class BoxCharSet {
  const BoxCharSet({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.horizontal,
    required this.vertical,
    required this.leftT,
    required this.rightT,
    required this.topT,
    required this.bottomT,
    required this.cross,
  });

  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;
  final String horizontal;
  final String vertical;
  final String leftT;
  final String rightT;
  final String topT;
  final String bottomT;
  final String cross;
}

/// Alignment for panel content.
enum PanelAlign { left, center, right }

/// Renders a boxed panel with optional title.
///
/// ```dart
/// final panel = Panel(
///   style: style,
///   terminalWidth: 80,
/// );
/// print(panel.render(
///   content: 'Hello, World!',
///   title: 'Greeting',
/// ));
/// ```
class Panel {
  Panel({
    required this.style,
    required this.terminalWidth,
    this.chars = BoxChars.rounded,
    this.padding = 1,
  });

  final ArtisanStyle style;
  final int terminalWidth;
  final BoxCharSet chars;
  final int padding;

  /// Renders a panel with the given content.
  String render({
    required Object content,
    String? title,
    PanelAlign titleAlign = PanelAlign.left,
    PanelAlign contentAlign = PanelAlign.left,
    int? width,
    String Function(String)? borderStyle,
    String Function(String)? titleStyle,
    String Function(String)? contentStyle,
  }) {
    final lines = _normalizeLines(content);
    final border = borderStyle ?? style.muted;
    final titleFn = titleStyle ?? style.heading;
    final contentFn = contentStyle ?? ((s) => s);

    // Calculate width
    final contentWidth = lines
        .map((l) => ArtisanStyle.visibleLength(l))
        .fold<int>(0, (m, v) => v > m ? v : m);
    final titleWidth = title != null
        ? ArtisanStyle.visibleLength(title) + 4
        : 0;
    final minWidth = [
      contentWidth,
      titleWidth,
      10,
    ].reduce((a, b) => a > b ? a : b);
    final boxWidth = (width ?? minWidth + padding * 2 + 2).clamp(
      minWidth + padding * 2 + 2,
      terminalWidth,
    );
    final innerWidth = boxWidth - 2;

    final buffer = StringBuffer();
    final pad = ' ' * padding;

    // Top border with optional title
    if (title != null) {
      final styledTitle = ' ${titleFn(title)} ';
      final titleLen = ArtisanStyle.visibleLength(styledTitle);
      final remainingWidth = innerWidth - titleLen;

      String topLine;
      switch (titleAlign) {
        case PanelAlign.left:
          final rightFill = chars.horizontal * (remainingWidth - 1);
          topLine =
              '${chars.topLeft}${chars.horizontal}$styledTitle$rightFill${chars.topRight}';
        case PanelAlign.center:
          final leftFill = chars.horizontal * (remainingWidth ~/ 2);
          final rightFill =
              chars.horizontal * (remainingWidth - remainingWidth ~/ 2);
          topLine =
              '${chars.topLeft}$leftFill$styledTitle$rightFill${chars.topRight}';
        case PanelAlign.right:
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
        case PanelAlign.left:
          paddedLine =
              '$pad${contentFn(line)}${' ' * (fill > 0 ? fill : 0)}$pad';
        case PanelAlign.center:
          final leftPad = ' ' * (fill ~/ 2);
          final rightPad = ' ' * (fill - fill ~/ 2);
          paddedLine = '$pad$leftPad${contentFn(line)}$rightPad$pad';
        case PanelAlign.right:
          paddedLine =
              '$pad${' ' * (fill > 0 ? fill : 0)}${contentFn(line)}$pad';
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

    return buffer.toString();
  }

  List<String> _normalizeLines(Object content) {
    if (content is Iterable) {
      return content.map((e) => e.toString()).toList();
    }
    return content.toString().split('\n');
  }
}

/// Renders content in multiple columns.
///
/// ```dart
/// final columns = Columns(terminalWidth: 80);
/// print(columns.render(
///   items: ['Item 1', 'Item 2', 'Item 3', 'Item 4'],
///   columnCount: 2,
/// ));
/// ```
class Columns {
  Columns({required this.terminalWidth, this.gutter = 2});

  final int terminalWidth;
  final int gutter;

  /// Renders items in columns.
  String render({
    required List<String> items,
    int? columnCount,
    String Function(String)? itemStyle,
  }) {
    if (items.isEmpty) return '';

    final styleFn = itemStyle ?? ((s) => s);

    // Auto-calculate columns if not specified
    final maxItemWidth = items
        .map((i) => ArtisanStyle.visibleLength(i))
        .fold<int>(0, (m, v) => v > m ? v : m);
    final cols =
        columnCount ??
        ((terminalWidth - 2) ~/ (maxItemWidth + gutter)).clamp(1, items.length);

    final colWidth = (terminalWidth - 2 - (cols - 1) * gutter) ~/ cols;

    final buffer = StringBuffer();
    for (var i = 0; i < items.length; i += cols) {
      final row = <String>[];
      for (var j = 0; j < cols && i + j < items.length; j++) {
        final item = items[i + j];
        final visible = ArtisanStyle.visibleLength(item);
        final fill = colWidth - visible;
        row.add('${styleFn(item)}${' ' * (fill > 0 ? fill : 0)}');
      }
      buffer.writeln('  ${row.join(' ' * gutter)}');
    }

    return buffer.toString().trimRight();
  }
}

/// Renders a tree structure.
///
/// ```dart
/// final tree = Tree(style: style);
/// print(tree.render({
///   'src': {
///     'lib': ['main.dart', 'utils.dart'],
///     'test': ['main_test.dart'],
///   },
///   'pubspec.yaml': null,
/// }));
/// ```
class Tree {
  Tree({required this.style});

  final ArtisanStyle style;

  static const _pipe = '│';
  static const _tee = '├';
  static const _elbow = '└';
  static const _dash = '──';

  /// Renders a tree from a map structure.
  String render(
    Map<String, dynamic> data, {
    String Function(String)? nodeStyle,
    String Function(String)? leafStyle,
  }) {
    final buffer = StringBuffer();
    final nodeFn = nodeStyle ?? style.info;
    final leafFn = leafStyle ?? ((s) => s);

    _renderNode(buffer, data, '', true, nodeFn, leafFn);
    return buffer.toString().trimRight();
  }

  void _renderNode(
    StringBuffer buffer,
    dynamic node,
    String prefix,
    bool isLast,
    String Function(String) nodeFn,
    String Function(String) leafFn,
  ) {
    if (node is Map<String, dynamic>) {
      final entries = node.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLastEntry = i == entries.length - 1;
        final connector = isLastEntry ? _elbow : _tee;

        if (entry.value is Map || entry.value is List) {
          buffer.writeln('$prefix$connector$_dash ${nodeFn(entry.key)}');
          final newPrefix = prefix + (isLastEntry ? '    ' : '$_pipe   ');
          _renderNode(
            buffer,
            entry.value,
            newPrefix,
            isLastEntry,
            nodeFn,
            leafFn,
          );
        } else {
          buffer.writeln('$prefix$connector$_dash ${leafFn(entry.key)}');
        }
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        final item = node[i];
        final isLastItem = i == node.length - 1;
        final connector = isLastItem ? _elbow : _tee;

        if (item is Map || item is List) {
          _renderNode(buffer, item, prefix, isLastItem, nodeFn, leafFn);
        } else {
          buffer.writeln('$prefix$connector$_dash ${leafFn(item.toString())}');
        }
      }
    }
  }
}
