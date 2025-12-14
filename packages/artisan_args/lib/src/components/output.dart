import '../style/artisan_style.dart';
import 'base.dart';

/// Box drawing characters for panels and borders.
class PanelBoxChars {
  PanelBoxChars._();

  static const single = PanelBoxCharSet(
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

  static const double = PanelBoxCharSet(
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

  static const rounded = PanelBoxCharSet(
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

  static const heavy = PanelBoxCharSet(
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

  static const ascii = PanelBoxCharSet(
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
class PanelBoxCharSet {
  const PanelBoxCharSet({
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
    final titleWidth =
        title != null ? ArtisanStyle.visibleLength(title!) + 4 : 0;
    final minWidth = [contentWidth, titleWidth, 10].reduce((a, b) => a > b ? a : b);
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
    final cols = columnCount ??
        ((context.terminalWidth - indent) ~/ (maxItemWidth + gutter))
            .clamp(1, items.length);

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

/// A tree structure component.
///
/// ```dart
/// TreeComponent(
///   data: {
///     'src': {
///       'lib': ['main.dart', 'utils.dart'],
///       'test': ['main_test.dart'],
///     },
///     'pubspec.yaml': null,
///   },
/// ).renderln(context);
/// ```
class TreeComponent extends CliComponent {
  const TreeComponent({
    required this.data,
    this.showRoot = false,
    this.rootLabel = '.',
  });

  final Map<String, dynamic> data;
  final bool showRoot;
  final String rootLabel;

  static const _pipe = '│';
  static const _tee = '├';
  static const _elbow = '└';
  static const _dash = '──';

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    final nodeFn = context.style.info;
    final leafFn = (String s) => s;

    if (showRoot) {
      buffer.writeln(nodeFn(rootLabel));
    }

    _renderNode(buffer, data, '', true, nodeFn, leafFn);

    final output = buffer.toString().trimRight();
    final lineCount = output.split('\n').length;

    return RenderResult(output: output, lineCount: lineCount);
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
    final maxKeyLen =
        items.keys.map((k) => k.length).reduce((a, b) => a > b ? a : b);

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

/// A two-column detail component with dot fill.
///
/// ```dart
/// TwoColumnDetailComponent(
///   left: 'Status',
///   right: 'OK',
/// ).renderln(context);
/// ```
class TwoColumnDetailComponent extends CliComponent {
  const TwoColumnDetailComponent({
    required this.left,
    required this.right,
    this.fillChar = '.',
    this.indent = 2,
  });

  final String left;
  final String right;
  final String fillChar;
  final int indent;

  @override
  RenderResult build(ComponentContext context) {
    final leftLen = ArtisanStyle.visibleLength(left);
    final rightLen = ArtisanStyle.visibleLength(right);
    final available = context.terminalWidth - indent - leftLen - rightLen - 2;
    final fill = available > 0 ? ' ${fillChar * available} ' : ' ';

    return RenderResult(
      output: '${' ' * indent}$left$fill$right',
      lineCount: 1,
    );
  }
}

/// A task status component (Laravel-style).
///
/// ```dart
/// TaskComponent(
///   description: 'Running migrations',
///   status: TaskStatus.success,
/// ).renderln(context);
/// ```
class TaskComponent extends CliComponent {
  const TaskComponent({
    required this.description,
    required this.status,
    this.fillChar = '.',
    this.indent = 2,
  });

  final String description;
  final TaskStatus status;
  final String fillChar;
  final int indent;

  @override
  RenderResult build(ComponentContext context) {
    final statusText = switch (status) {
      TaskStatus.success => context.style.success('DONE'),
      TaskStatus.failure => context.style.error('FAIL'),
      TaskStatus.skipped => context.style.warning('SKIP'),
      TaskStatus.running => context.style.info('...'),
    };

    final descLen = ArtisanStyle.visibleLength(description);
    final statusLen = 4; // DONE/FAIL/SKIP
    final available = context.terminalWidth - indent - descLen - statusLen - 2;
    final fill = available > 0 ? ' ${fillChar * available} ' : ' ';

    return RenderResult(
      output: '${' ' * indent}$description$fill$statusText',
      lineCount: 1,
    );
  }
}

/// Task status values.
enum TaskStatus { success, failure, skipped, running }

/// An alert/notice block component.
///
/// ```dart
/// AlertComponent(
///   message: 'This is important!',
///   type: AlertType.warning,
/// ).renderln(context);
/// ```
class AlertComponent extends CliComponent {
  const AlertComponent({
    required this.message,
    this.type = AlertType.info,
  });

  final String message;
  final AlertType type;

  @override
  RenderResult build(ComponentContext context) {
    final (prefix, styleFn) = switch (type) {
      AlertType.info => ('[INFO]', context.style.info),
      AlertType.success => ('[OK]', context.style.success),
      AlertType.warning => ('[WARN]', context.style.warning),
      AlertType.error => ('[ERROR]', context.style.error),
      AlertType.note => ('[NOTE]', context.style.muted),
    };

    return RenderResult(
      output: '${styleFn(prefix)} $message',
      lineCount: 1,
    );
  }
}

/// Alert types.
enum AlertType { info, success, warning, error, note }

