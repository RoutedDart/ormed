import '../style/artisan_style.dart';

typedef ProgressWriteRaw = void Function(String text);

/// A progress bar for displaying task progress in the terminal.
///
/// ```dart
/// final bar = ArtisanProgressBar(
///   style: style,
///   outRaw: stdout.write,
///   terminalWidth: 80,
///   max: 100,
/// );
/// bar.start();
/// for (var i = 0; i < 100; i++) {
///   bar.advance();
/// }
/// bar.finish();
/// ```
class ArtisanProgressBar {
  ArtisanProgressBar({
    required this.style,
    required ProgressWriteRaw outRaw,
    required this.terminalWidth,
    required int max,
  }) : _outRaw = outRaw,
       _max = max;

  final ArtisanStyle style;
  final ProgressWriteRaw _outRaw;
  final int terminalWidth;

  int _max;
  int _current = 0;
  bool _started = false;

  /// Updates the maximum value of the progress bar.
  void setMax(int max) {
    _max = max;
  }

  /// Starts rendering the progress bar.
  void start() {
    _started = true;
    _render();
  }

  /// Advances the progress bar by [step] units.
  void advance([int step = 1]) {
    if (!_started) start();
    _current += step;
    if (_max > 0 && _current > _max) _current = _max;
    _render();
  }

  /// Finishes the progress bar and moves to a new line.
  void finish() {
    if (!_started) return;
    if (_max > 0) _current = _max;
    _render(done: true);
  }

  void _render({bool done = false}) {
    final max = _max;
    final current = _current;
    final pct = max <= 0 ? 0 : ((current / max) * 100).clamp(0, 100).round();

    final barWidth = (terminalWidth - 20).clamp(10, 80);
    final filled = max <= 0
        ? 0
        : ((current / max) * barWidth).clamp(0, barWidth).round();
    final empty = barWidth - filled;
    final bar = '[${'=' * filled}${' ' * empty}]';
    final label = max <= 0 ? '$current' : '$current/$max';
    final line = '$bar ${style.muted(label)} ${style.muted('$pct%')}';
    _outRaw('\r$line${done ? '\n' : ''}');
  }
}
