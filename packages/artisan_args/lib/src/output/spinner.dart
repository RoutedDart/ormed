import 'dart:async';
import 'dart:io' as io;

import '../style/artisan_style.dart';

/// Spinner animation frames.
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

/// Configuration for the animated spinner.
class SpinnerConfig {
  const SpinnerConfig({
    this.frames = SpinnerFrames.dots,
    this.interval = const Duration(milliseconds: 80),
    this.successIcon = '✓',
    this.errorIcon = '✗',
    this.warnIcon = '⚠',
  });

  /// Animation frames.
  final List<String> frames;

  /// Interval between frames.
  final Duration interval;

  /// Icon shown on success.
  final String successIcon;

  /// Icon shown on error.
  final String errorIcon;

  /// Icon shown on warning.
  final String warnIcon;
}

/// An animated terminal spinner.
///
/// ```dart
/// final spinner = Spinner(
///   message: 'Loading...',
///   style: style,
///   stdout: io.stdout,
/// );
/// spinner.start();
/// await doWork();
/// spinner.success('Done!');
/// ```
class Spinner {
  Spinner({
    required this.message,
    required this.style,
    required io.Stdout stdout,
    this.config = const SpinnerConfig(),
  }) : _stdout = stdout;

  /// The message to display.
  final String message;

  /// The style configuration.
  final ArtisanStyle style;

  /// The spinner configuration.
  final SpinnerConfig config;

  final io.Stdout _stdout;

  Timer? _timer;
  int _frameIndex = 0;
  bool _running = false;

  /// Whether the spinner is currently running.
  bool get isRunning => _running;

  /// Starts the spinner animation.
  void start() {
    if (_running) return;
    _running = true;
    _frameIndex = 0;

    _hideCursor();
    _render();

    _timer = Timer.periodic(config.interval, (_) {
      _frameIndex = (_frameIndex + 1) % config.frames.length;
      _render();
    });
  }

  /// Stops the spinner and shows a success message.
  void success([String? message]) {
    _stop(config.successIcon, message ?? this.message, style.success);
  }

  /// Stops the spinner and shows an error message.
  void error([String? message]) {
    _stop(config.errorIcon, message ?? this.message, style.error);
  }

  /// Stops the spinner and shows a warning message.
  void warn([String? message]) {
    _stop(config.warnIcon, message ?? this.message, style.warning);
  }

  /// Stops the spinner and shows an info message.
  void info([String? message]) {
    _stop('ℹ', message ?? this.message, style.info);
  }

  /// Stops the spinner without a status icon.
  void stop([String? message]) {
    _stop(' ', message ?? this.message, (s) => s);
  }

  /// Updates the spinner message while running.
  void update(String newMessage) {
    if (!_running) return;
    _clearLine();
    _stdout.write('${style.info(config.frames[_frameIndex])} $newMessage');
  }

  void _stop(String icon, String message, String Function(String) iconStyle) {
    _timer?.cancel();
    _timer = null;
    _running = false;

    _clearLine();
    _stdout.writeln('${iconStyle(icon)} $message');
    _showCursor();
  }

  void _render() {
    _clearLine();
    _stdout.write('${style.info(config.frames[_frameIndex])} $message');
  }

  void _clearLine() {
    _stdout.write('\r\x1B[K');
  }

  void _hideCursor() {
    _stdout.write('\x1B[?25l');
  }

  void _showCursor() {
    _stdout.write('\x1B[?25h');
  }
}

/// Runs a callback with an animated spinner.
///
/// ```dart
/// final result = await withSpinner(
///   message: 'Processing...',
///   style: style,
///   stdout: io.stdout,
///   run: () async {
///     await processData();
///     return 'Done!';
///   },
/// );
/// ```
Future<T> withSpinner<T>({
  required String message,
  required ArtisanStyle style,
  required io.Stdout stdout,
  required FutureOr<T> Function() run,
  SpinnerConfig config = const SpinnerConfig(),
  String? successMessage,
  String? errorMessage,
}) async {
  final spinner = Spinner(
    message: message,
    style: style,
    stdout: stdout,
    config: config,
  );

  spinner.start();

  try {
    final result = await run();
    spinner.success(successMessage);
    return result;
  } catch (e) {
    spinner.error(errorMessage ?? 'Failed: $e');
    rethrow;
  }
}
