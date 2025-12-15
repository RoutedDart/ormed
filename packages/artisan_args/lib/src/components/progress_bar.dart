import 'base.dart';

/// A progress bar component.
///
/// For static rendering (shows current state):
/// ```dart
/// ProgressBarComponent(current: 50, total: 100).renderln(context);
/// ```
///
/// For interactive use with iteration:
/// ```dart
/// await ProgressBarComponent.iterate(
///   items: myList,
///   context: context,
///   onItem: (item) async {
///     await process(item);
///   },
/// );
/// ```
class ProgressBarComponent extends CliComponent {
  const ProgressBarComponent({
    required this.current,
    required this.total,
    this.width = 40,
    this.fillChar = '=',
    this.emptyChar = ' ',
    this.showPercentage = true,
    this.showCount = true,
  });

  final int current;
  final int total;
  final int width;
  final String fillChar;
  final String emptyChar;
  final bool showPercentage;
  final bool showCount;

  @override
  RenderResult build(ComponentContext context) {
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final filled = (progress * width).round();
    final empty = width - filled;

    final bar = '[${fillChar * filled}${emptyChar * empty}]';
    final parts = <String>[bar];

    if (showCount) {
      parts.add(context.newStyle().dim().render('$current/$total'));
    }
    if (showPercentage) {
      parts.add(context.newStyle().dim().render('$pct%'));
    }

    return RenderResult(output: parts.join(' '), lineCount: 1);
  }

  /// Iterates over items with a progress bar.
  static Future<void> iterate<T>({
    required Iterable<T> items,
    required ComponentContext context,
    required Future<void> Function(T item) onItem,
    int? width,
  }) async {
    final list = items.toList();
    final total = list.length;
    final barWidth = width ?? 40;

    context.hideCursor();

    try {
      for (var i = 0; i < total; i++) {
        context.clearLine();
        ProgressBarComponent(
          current: i,
          total: total,
          width: barWidth,
        ).render(context);

        await onItem(list[i]);
      }

      // Show completed state
      context.clearLine();
      ProgressBarComponent(
        current: total,
        total: total,
        width: barWidth,
      ).renderln(context);
    } finally {
      context.showCursor();
    }
  }
}

/// A stateful progress bar that can be advanced manually.
///
/// ```dart
/// final bar = StatefulProgressBar(max: 100);
/// bar.start(context);
/// for (var i = 0; i < 100; i++) {
///   bar.advance(context);
/// }
/// bar.finish(context);
/// ```
class StatefulProgressBar {
  StatefulProgressBar({
    required this.max,
    this.width = 40,
    this.fillChar = '=',
    this.emptyChar = ' ',
  });

  final int max;
  final int width;
  final String fillChar;
  final String emptyChar;

  int _current = 0;
  bool _started = false;

  int get current => _current;
  bool get isStarted => _started;

  void setMax(int newMax) {
    // Can't change max on this implementation, create a new one
  }

  void start(ComponentContext context) {
    _started = true;
    _current = 0;
    context.hideCursor();
    _render(context);
  }

  void advance(ComponentContext context, [int step = 1]) {
    if (!_started) start(context);
    _current += step;
    if (max > 0 && _current > max) _current = max;
    _render(context);
  }

  void finish(ComponentContext context) {
    if (!_started) return;
    if (max > 0) _current = max;
    _render(context, done: true);
    context.showCursor();
  }

  void _render(ComponentContext context, {bool done = false}) {
    final progress = max > 0 ? (_current / max).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final filled = (progress * width).round();
    final empty = width - filled;

    final bar = '[${fillChar * filled}${emptyChar * empty}]';
    final label = max <= 0 ? '$_current' : '$_current/$max';
    final line =
        '$bar ${context.newStyle().dim().render(label)} ${context.newStyle().dim().render('$pct%')}';

    context.clearLine();
    context.write(line);
    if (done) context.writeln();
  }
}
