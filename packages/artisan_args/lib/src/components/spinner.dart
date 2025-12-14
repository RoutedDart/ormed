import 'dart:async';

import 'base.dart';

/// Spinner animation frame presets.
class SpinnerFrames {
  SpinnerFrames._();

  /// Braille dots spinner (default).
  static const dots = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  /// Line spinner.
  static const line = ['-', '\\', '|', '/'];

  /// Growing dots.
  static const growDots = ['.  ', '.. ', '...', ' ..', '  .', '   '];

  /// Circle quarters.
  static const circle = ['◐', '◓', '◑', '◒'];

  /// Arc spinner.
  static const arc = ['◜', '◠', '◝', '◞', '◡', '◟'];

  /// Box bounce.
  static const bounce = ['⠁', '⠂', '⠄', '⠂'];

  /// Arrows.
  static const arrows = ['←', '↖', '↑', '↗', '→', '↘', '↓', '↙'];

  /// Clock faces.
  static const clock = [
    '🕐',
    '🕑',
    '🕒',
    '🕓',
    '🕔',
    '🕕',
    '🕖',
    '🕗',
    '🕘',
    '🕙',
    '🕚',
    '🕛',
  ];

  /// Simple dots.
  static const simpleDots = ['   ', '.  ', '.. ', '...'];
}

/// A spinner component for showing async progress.
///
/// ```dart
/// await SpinnerComponent(
///   message: 'Loading...',
///   task: () async {
///     await fetchData();
///   },
/// ).interact(context);
/// ```
class SpinnerComponent extends InteractiveComponent<void> {
  SpinnerComponent({
    required this.message,
    required this.task,
    this.frames = SpinnerFrames.dots,
    this.interval = const Duration(milliseconds: 80),
    this.successMessage,
    this.successIcon = '✓',
    this.failureMessage,
    this.failureIcon = '✗',
  });

  final String message;
  final Future<void> Function() task;
  final List<String> frames;
  final Duration interval;
  final String? successMessage;
  final String successIcon;
  final String? failureMessage;
  final String failureIcon;

  @override
  RenderResult build(ComponentContext context) {
    final frame = context.style.info(frames.first);
    return RenderResult(output: '$frame $message', lineCount: 1);
  }

  @override
  Future<void> interact(ComponentContext context) async {
    var frameIndex = 0;
    var running = true;

    context.hideCursor();

    final timer = Timer.periodic(interval, (_) {
      if (!running) return;
      context.clearLine();
      final frame = context.style.info(frames[frameIndex]);
      context.write('$frame $message');
      frameIndex = (frameIndex + 1) % frames.length;
    });

    try {
      await task();
      running = false;
      timer.cancel();
      context.clearLine();
      final successText = successMessage ?? message;
      context.writeln('${context.style.success(successIcon)} $successText');
    } catch (e) {
      running = false;
      timer.cancel();
      context.clearLine();
      final failText = failureMessage ?? message;
      context.writeln('${context.style.error(failureIcon)} $failText');
      rethrow;
    } finally {
      context.showCursor();
    }
  }
}

/// A stateful spinner that can be started, updated, and stopped manually.
///
/// ```dart
/// final spinner = StatefulSpinner(message: 'Loading...');
/// spinner.start(context);
/// await doWork();
/// spinner.success(context, 'Done!');
/// ```
class StatefulSpinner {
  StatefulSpinner({
    required this.message,
    this.frames = SpinnerFrames.dots,
    this.interval = const Duration(milliseconds: 80),
    this.successIcon = '✓',
    this.errorIcon = '✗',
    this.warnIcon = '⚠',
  });

  final String message;
  final List<String> frames;
  final Duration interval;
  final String successIcon;
  final String errorIcon;
  final String warnIcon;

  Timer? _timer;
  int _frameIndex = 0;
  bool _running = false;

  bool get isRunning => _running;

  void start(ComponentContext context) {
    if (_running) return;
    _running = true;
    _frameIndex = 0;

    context.hideCursor();
    _render(context);

    _timer = Timer.periodic(interval, (_) {
      _frameIndex = (_frameIndex + 1) % frames.length;
      _render(context);
    });
  }

  void success(ComponentContext context, [String? msg]) {
    _stop(context, successIcon, msg ?? message, context.style.success);
  }

  void error(ComponentContext context, [String? msg]) {
    _stop(context, errorIcon, msg ?? message, context.style.error);
  }

  void warn(ComponentContext context, [String? msg]) {
    _stop(context, warnIcon, msg ?? message, context.style.warning);
  }

  void info(ComponentContext context, [String? msg]) {
    _stop(context, 'ℹ', msg ?? message, context.style.info);
  }

  void stop(ComponentContext context, [String? msg]) {
    _stop(context, ' ', msg ?? message, (s) => s);
  }

  void update(ComponentContext context, String newMessage) {
    if (!_running) return;
    context.clearLine();
    context.write('${context.style.info(frames[_frameIndex])} $newMessage');
  }

  void _stop(
    ComponentContext context,
    String icon,
    String msg,
    String Function(String) iconStyle,
  ) {
    _timer?.cancel();
    _timer = null;
    _running = false;

    context.clearLine();
    context.writeln('${iconStyle(icon)} $msg');
    context.showCursor();
  }

  void _render(ComponentContext context) {
    context.clearLine();
    context.write('${context.style.info(frames[_frameIndex])} $message');
  }
}

/// Helper function to run a task with a spinner.
///
/// ```dart
/// final result = await withSpinner(
///   message: 'Loading...',
///   context: context,
///   task: () async {
///     return await fetchData();
///   },
/// );
/// ```
Future<T> withSpinner<T>({
  required String message,
  required ComponentContext context,
  required Future<T> Function() task,
  List<String> frames = SpinnerFrames.dots,
  Duration interval = const Duration(milliseconds: 80),
  String? successMessage,
  String? failureMessage,
}) async {
  final spinner = StatefulSpinner(
    message: message,
    frames: frames,
    interval: interval,
  );

  spinner.start(context);

  try {
    final result = await task();
    spinner.success(context, successMessage ?? message);
    return result;
  } catch (e) {
    spinner.error(context, failureMessage ?? message);
    rethrow;
  }
}
