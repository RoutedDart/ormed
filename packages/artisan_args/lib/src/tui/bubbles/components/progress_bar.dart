import 'base.dart';
import '../../../terminal/terminal.dart' show Terminal;
import '../../../style/style.dart';

/// A progress bar component.
///
/// For static rendering (shows current state):
/// ```dart
/// print(ProgressBarComponent(current: 50, total: 100).render());
/// ```
///
/// For interactive use with iteration:
/// ```dart
/// await ProgressBarComponent.iterate(
///   items: myList,
///   terminal: terminal,
///   onItem: (item) async {
///     await process(item);
///   },
/// );
/// ```
class ProgressBarComponent extends ViewComponent {
  const ProgressBarComponent({
    required this.current,
    required this.total,
    this.width = 40,
    this.fillChar = '=',
    this.emptyChar = ' ',
    this.showPercentage = true,
    this.showCount = true,
    this.renderConfig = const RenderConfig(),
  });

  final int current;
  final int total;
  final int width;
  final String fillChar;
  final String emptyChar;
  final bool showPercentage;
  final bool showCount;
  final RenderConfig renderConfig;

  @override
  String render() {
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final filled = (progress * width).round();
    final empty = width - filled;

    final bar = '[${fillChar * filled}${emptyChar * empty}]';
    final parts = <String>[bar];
    final dim = renderConfig.configureStyle(Style().dim());

    if (showCount) {
      parts.add(dim.render('$current/$total'));
    }
    if (showPercentage) {
      parts.add(dim.render('$pct%'));
    }

    return parts.join(' ');
  }

  /// Iterates over items with a progress bar.
  static Future<void> iterate<T>({
    required Iterable<T> items,
    required Terminal terminal,
    required Future<void> Function(T item) onItem,
    RenderConfig renderConfig = const RenderConfig(),
    int? width,
  }) async {
    final list = items.toList();
    final total = list.length;
    final barWidth = width ?? 40;

    terminal.hideCursor();

    try {
      for (var i = 0; i < total; i++) {
        terminal.clearLine();
        final view = ProgressBarComponent(
          current: i,
          total: total,
          width: barWidth,
          renderConfig: renderConfig,
        ).render();
        terminal.write(view);

        await onItem(list[i]);
      }

      // Show completed state
      terminal.clearLine();
      final view = ProgressBarComponent(
        current: total,
        total: total,
        width: barWidth,
        renderConfig: renderConfig,
      ).render();
      terminal.write(view);
      terminal.writeln();
    } finally {
      terminal.showCursor();
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

  void start(
    Terminal terminal, {
    RenderConfig renderConfig = const RenderConfig(),
  }) {
    _started = true;
    _current = 0;
    terminal.hideCursor();
    _render(terminal, renderConfig: renderConfig);
  }

  void advance(
    Terminal terminal, {
    int step = 1,
    RenderConfig renderConfig = const RenderConfig(),
  }) {
    if (!_started) start(terminal, renderConfig: renderConfig);
    _current += step;
    if (max > 0 && _current > max) _current = max;
    _render(terminal, renderConfig: renderConfig);
  }

  void finish(
    Terminal terminal, {
    RenderConfig renderConfig = const RenderConfig(),
  }) {
    if (!_started) return;
    if (max > 0) _current = max;
    _render(terminal, renderConfig: renderConfig, done: true);
    terminal.showCursor();
  }

  void _render(
    Terminal terminal, {
    required RenderConfig renderConfig,
    bool done = false,
  }) {
    final progress = max > 0 ? (_current / max).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final filled = (progress * width).round();
    final empty = width - filled;

    final bar = '[${fillChar * filled}${emptyChar * empty}]';
    final label = max <= 0 ? '$_current' : '$_current/$max';
    final dim = renderConfig.configureStyle(Style().dim());
    final line = '$bar ${dim.render(label)} ${dim.render('$pct%')}';

    terminal.clearLine();
    terminal.write(line);
    if (done) terminal.writeln();
  }
}
