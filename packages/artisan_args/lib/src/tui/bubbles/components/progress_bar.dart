import 'dart:async';

import '../../cmd.dart';
import '../../component.dart';
import '../../msg.dart';
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
class ProgressBarComponent extends DisplayComponent {
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
  @Deprecated(
    'UV-unsafe during a running TUI (direct terminal writes). '
    'Prefer hosting a ProgressBarModel and driving it via progressIterateCmd / ProgressBarSetMsg.',
  )
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

// ─────────────────────────────────────────────────────────────────────────────
// TUI-first model + messages (UV-safe)
// ─────────────────────────────────────────────────────────────────────────────

int _lastProgressBarId = 0;
int _nextProgressBarId() => ++_lastProgressBarId;

sealed class ProgressBarMsg extends Msg {
  const ProgressBarMsg({required this.id});
  final int id;
}

final class ProgressBarSetMsg extends ProgressBarMsg {
  const ProgressBarSetMsg({
    required super.id,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;
}

final class ProgressBarAdvanceMsg extends ProgressBarMsg {
  const ProgressBarAdvanceMsg({required super.id, this.step = 1});
  final int step;
}

final class ProgressBarIterateDoneMsg extends ProgressBarMsg {
  const ProgressBarIterateDoneMsg({required super.id});
}

final class ProgressBarIterateErrorMsg extends ProgressBarMsg {
  const ProgressBarIterateErrorMsg({
    required super.id,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}

/// A UV-safe progress bar model that can be hosted inside a parent [Model].
///
/// This model **does not write to the terminal**. It only renders via [view()].
///
/// Drive it using:
/// - [ProgressBarSetMsg] / [ProgressBarAdvanceMsg], or
/// - [progressIterateCmd] for a turn-key stream command.
final class ProgressBarModel extends ViewComponent {
  ProgressBarModel({
    int? id,
    this.current = 0,
    this.total = 0,
    this.width = 40,
    this.fillChar = '=',
    this.emptyChar = ' ',
    this.showPercentage = true,
    this.showCount = true,
    this.renderConfig = const RenderConfig(),
  }) : id = id ?? _nextProgressBarId();

  final int id;
  final int current;
  final int total;
  final int width;
  final String fillChar;
  final String emptyChar;
  final bool showPercentage;
  final bool showCount;
  final RenderConfig renderConfig;

  ProgressBarModel copyWith({
    int? current,
    int? total,
    int? width,
    String? fillChar,
    String? emptyChar,
    bool? showPercentage,
    bool? showCount,
    RenderConfig? renderConfig,
  }) {
    return ProgressBarModel(
      id: id,
      current: current ?? this.current,
      total: total ?? this.total,
      width: width ?? this.width,
      fillChar: fillChar ?? this.fillChar,
      emptyChar: emptyChar ?? this.emptyChar,
      showPercentage: showPercentage ?? this.showPercentage,
      showCount: showCount ?? this.showCount,
      renderConfig: renderConfig ?? this.renderConfig,
    );
  }

  @override
  Cmd? init() => null;

  @override
  (ViewComponent, Cmd?) update(Msg msg) {
    return switch (msg) {
      ProgressBarSetMsg(:final id, :final current, :final total)
          when id == this.id =>
        (copyWith(current: current, total: total), null),
      ProgressBarAdvanceMsg(:final id, :final step) when id == this.id =>
        (
          copyWith(
            current:
                total > 0 ? (current + step).clamp(0, total) : current + step,
          ),
          null,
        ),
      _ => (this, null),
    };
  }

  @override
  String view() {
    return ProgressBarComponent(
      current: current,
      total: total,
      width: width,
      fillChar: fillChar,
      emptyChar: emptyChar,
      showPercentage: showPercentage,
      showCount: showCount,
      renderConfig: renderConfig,
    ).render();
  }
}

/// Produces a UV-safe [StreamCmd] that runs [onItem] for each element and emits
/// progress updates for a hosted [ProgressBarModel].
///
/// The returned command emits:
/// - an initial [ProgressBarSetMsg] (0/total)
/// - a [ProgressBarSetMsg] after each item completes (n/total)
/// - [ProgressBarIterateDoneMsg] when finished
/// - [ProgressBarIterateErrorMsg] on failure (and then completes)
StreamCmd<Msg> progressIterateCmd<T>({
  required int id,
  required Iterable<T> items,
  required Future<void> Function(T item) onItem,
}) {
  final list = items.toList(growable: false);
  final total = list.length;

  Stream<Msg> stream() async* {
    yield ProgressBarSetMsg(id: id, current: 0, total: total);
    try {
      for (var i = 0; i < total; i++) {
        await onItem(list[i]);
        yield ProgressBarSetMsg(id: id, current: i + 1, total: total);
      }
      yield ProgressBarIterateDoneMsg(id: id);
    } catch (e, st) {
      yield ProgressBarIterateErrorMsg(id: id, error: e, stackTrace: st);
    }
  }

  return Cmd.listen<Msg>(stream(), onData: (m) => m);
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
@Deprecated(
  'CLI-only utility (direct terminal writes). Prefer ProgressBarModel inside a TUI.',
)
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
