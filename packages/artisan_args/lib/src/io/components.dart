import 'dart:async';

import '../style/artisan_style.dart';
import 'artisan_io.dart';

/// Higher-level console UI components (Laravel-style).
///
/// Access via `io.components`.
///
/// ```dart
/// io.components.task('Running migrations', run: () async {
///   return ArtisanTaskResult.success;
/// });
/// io.components.twoColumnDetail('Name', 'Value');
/// io.components.bulletList(['Item 1', 'Item 2']);
/// io.components.alert('Important!');
/// io.components.spin('Loading...', run: () async { ... });
/// ```
class ArtisanComponents {
  /// Creates a components helper for the given I/O instance.
  ArtisanComponents({required this.io});

  /// The I/O instance to use for output.
  final ArtisanIO io;

  /// The style configuration.
  ArtisanStyle get style => io.style;

  /// Displays a task with dotted fill and DONE/FAIL/SKIPPED status.
  Future<ArtisanTaskResult> task(
    String description, {
    FutureOr<ArtisanTaskResult> Function()? run,
  }) => io.task(description, run: run);

  /// Displays two columns aligned with proper spacing.
  void twoColumnDetail(String first, [String? second]) =>
      io.twoColumnDetail(first, second);

  /// Displays a bulleted list of items.
  void bulletList(Iterable<Object> items) {
    for (final item in items) {
      io.writeln('  ${style.muted('•')} $item');
    }
    io.newLine();
  }

  /// Displays a boxed alert message.
  void alert(Object message) => io.alert(message);

  /// Displays an info block with a header.
  void info(String title, Object message) {
    _titledBlock(title, message, style.info);
  }

  /// Displays a success block with a header.
  void success(String title, Object message) {
    _titledBlock(title, message, style.success);
  }

  /// Displays a warning block with a header.
  void warn(String title, Object message) {
    _titledBlock(title, message, style.warning);
  }

  /// Displays an error block with a header.
  void error(String title, Object message) {
    _titledBlock(title, message, style.error);
  }

  /// Renders a definition list (term/definition pairs).
  void definitionList(Map<String, Object?> definitions) {
    if (definitions.isEmpty) return;

    final termWidth = definitions.keys
        .map((k) => ArtisanStyle.visibleLength(k))
        .fold<int>(0, (m, v) => v > m ? v : m);

    final maxWidth = io.terminalWidth;
    final dotWidth = (maxWidth ~/ 3).clamp(4, 20);

    for (final entry in definitions.entries) {
      final term = entry.key;
      final value = entry.value?.toString() ?? '';
      final termLen = ArtisanStyle.visibleLength(term);
      final dots = dotWidth - (termLen - termWidth).abs();
      final dotStr = style.muted(' ${'.' * dots.clamp(2, dotWidth)} ');
      io.writeln('  $term$dotStr$value');
    }
    io.newLine();
  }

  /// Displays a line separator.
  void line([int width = 0]) {
    final w = width > 0 ? width : (io.terminalWidth * 0.6).round();
    io.writeln(style.muted('-' * w));
  }

  /// Displays a horizontal rule with optional centered text.
  void rule([String? text]) {
    final width = io.terminalWidth - 4;
    if (text == null || text.isEmpty) {
      io.writeln(style.muted('─' * width));
    } else {
      final textLen = ArtisanStyle.visibleLength(text);
      final side = ((width - textLen - 2) / 2).floor();
      final left = '─' * side.clamp(0, width);
      final right = '─' * (width - side - textLen - 2).clamp(0, width);
      io.writeln(style.muted(left) + ' $text ' + style.muted(right));
    }
    io.newLine();
  }

  /// Runs a callback while displaying a processing indicator.
  Future<R> spin<R>(
    String message, {
    required FutureOr<R> Function() run,
  }) async {
    io.write('$message ');
    final watch = Stopwatch()..start();
    try {
      final result = await run();
      watch.stop();
      io.writeln(
        style.success('✓') + style.muted(' ${_formatDuration(watch.elapsed)}'),
      );
      return result;
    } catch (_) {
      watch.stop();
      io.writeln(
        style.error('✗') + style.muted(' ${_formatDuration(watch.elapsed)}'),
      );
      rethrow;
    }
  }

  /// Displays a comment (dimmed text with // prefix).
  void comment(Object message) {
    final lines = message is Iterable
        ? message.map((e) => e.toString()).toList()
        : message.toString().split('\n');
    for (final line in lines) {
      io.writeln(style.muted('// $line'));
    }
  }

  /// Displays a horizontal table (row-as-headers layout).
  void horizontalTable(Map<String, Object?> data) {
    if (data.isEmpty) return;

    final maxKeyWidth = data.keys
        .map((k) => ArtisanStyle.visibleLength(k))
        .fold<int>(0, (m, v) => v > m ? v : m);

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value?.toString() ?? '';
      final padding = maxKeyWidth - ArtisanStyle.visibleLength(key);
      io.writeln('  ${style.info(key)}${' ' * padding}  │  $value');
    }
    io.newLine();
  }

  /// Renders an exception with pretty formatting.
  void renderException(Object exception, [StackTrace? stackTrace]) {
    final exceptionType = exception.runtimeType.toString();
    final message = exception.toString();

    io.newLine();
    io.writeln(style.error('  $exceptionType  '));
    io.newLine();

    // Exception message
    final messageLines = message.split('\n');
    for (final line in messageLines) {
      io.writeln('  ${style.warning(line)}');
    }

    // Stack trace
    if (stackTrace != null) {
      io.newLine();
      io.writeln(style.muted('  Stack trace:'));
      io.newLine();

      final lines = stackTrace.toString().split('\n');
      var frameCount = 0;
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (frameCount >= 10) {
          io.writeln(style.muted('  ... and more frames'));
          break;
        }

        // Parse and format stack frame
        final match = RegExp(r'#(\d+)\s+(\S+)\s+\((.+)\)').firstMatch(line);
        if (match != null) {
          final number = match.group(1)!.padLeft(2);
          final member = match.group(2)!;
          final location = match.group(3)!;

          io.writeln('  ${style.muted(number)}  ${style.info(member)}');
          io.writeln('      ${style.muted(location)}');
          frameCount++;
        }
      }
    }
    io.newLine();
  }

  void _titledBlock(
    String title,
    Object message,
    String Function(String) titleStyle,
  ) {
    io.writeln(titleStyle('  $title  '));
    final lines = message is Iterable
        ? message.map((e) => e.toString()).toList()
        : message.toString().split('\n');
    for (final line in lines) {
      io.writeln('  $line');
    }
    io.newLine();
  }
}

String _formatDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  if (ms < 1000) return '${ms}ms';
  final seconds = ms / 1000;
  return '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s';
}
