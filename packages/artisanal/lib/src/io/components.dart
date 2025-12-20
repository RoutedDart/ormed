import 'dart:async';

import '../style/color.dart';
import '../style/style.dart';
import '../tui/bubbles/components/alert.dart' show Alert, AlertDisplayStyle;
import '../tui/bubbles/components/base.dart' show RenderConfig, DisplayComponent;
import '../tui/bubbles/components/list.dart' show BulletList;
import '../tui/bubbles/components/table.dart' show HorizontalTableComponent;
import '../tui/bubbles/components/titled_block.dart' show TitledBlockComponent;
import '../tui/bubbles/components/two_column_detail.dart'
    show TwoColumnDetailComponent, TwoColumnDetailList;
import '../tui/bubbles/components/styled_block.dart' show CommentComponent;
import '../tui/bubbles/components/exception.dart' show ExceptionComponent;
import '../tui/bubbles/components/text.dart' show Rule;
import 'console.dart';

/// Higher-level console UI components (Laravel-style).
///
/// Access via `io.components`.
///
/// ```dart
/// io.components.task('Running migrations', run: () async {
///   return TaskResult.success;
/// });
/// io.components.twoColumnDetail('Name', 'Value');
/// io.components.bulletList(['Item 1', 'Item 2']);
/// io.components.alert('Important!');
/// io.components.spin('Loading...', run: () async { ... });
/// ```
class Components {
  /// Creates a components helper for the given I/O instance.
  Components({required this.io});

  /// The I/O instance to use for output.
  final Console io;

  /// The style configuration.
  Style get style => io.style;

  RenderConfig get _renderConfig => io.renderConfig;

  /// Helper to apply muted styling.
  String muted(String text) => style.foreground(Colors.muted).render(text);

  void _writeComponent(DisplayComponent component) {
    final output = component.render();
    if (output.isEmpty) return;
    for (final line in output.split('\n')) {
      io.writeln(line);
    }
  }

  /// Displays a task with dotted fill and DONE/FAIL/SKIPPED status.
  Future<TaskResult> task(
    String description, {
    FutureOr<TaskResult> Function()? run,
  }) => io.task(description, run: run);

  /// Displays two columns aligned with proper spacing.
  void twoColumnDetail(String first, [String? second]) {
    _writeComponent(
      TwoColumnDetailComponent(
        left: first,
        right: second ?? '',
        renderConfig: _renderConfig,
      ),
    );
  }

  /// Displays a bulleted list of items.
  void bulletList(Iterable<Object> items) {
    final bullet = _renderConfig
        .configureStyle(Style().foreground(Colors.muted))
        .render('•');
    _writeComponent(
      BulletList(
        items: items.map((e) => e.toString()).toList(),
        bullet: bullet,
        indent: 2,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Displays a boxed alert message.
  void alert(Object message) {
    _writeComponent(
      Alert(renderConfig: _renderConfig)
        ..warning()
        ..displayStyle(AlertDisplayStyle.block)
        ..message(message.toString())
        ..width(_renderConfig.terminalWidth),
    );
    io.newLine();
  }

  /// Displays an info block with a header.
  void info(String title, Object message) {
    _writeComponent(
      TitledBlockComponent.info(
        title: title,
        message: message,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Displays a success block with a header.
  void success(String title, Object message) {
    _writeComponent(
      TitledBlockComponent.success(
        title: title,
        message: message,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Displays a warning block with a header.
  void warn(String title, Object message) {
    _writeComponent(
      TitledBlockComponent.warning(
        title: title,
        message: message,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Displays an error block with a header.
  void error(String title, Object message) {
    _writeComponent(
      TitledBlockComponent.error(
        title: title,
        message: message,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Renders a definition list (term/definition pairs).
  void definitionList(Map<String, Object?> definitions) {
    if (definitions.isEmpty) return;

    _writeComponent(
      TwoColumnDetailList(renderConfig: _renderConfig)
        ..width(_renderConfig.terminalWidth)
        ..fillChar('.')
        ..fillStyle(Style().dim())
        ..rows(definitions.map((k, v) => MapEntry(k, v?.toString() ?? ''))),
    );
    io.newLine();
  }

  /// Displays a line separator.
  void line([int width = 0]) {
    final w = width > 0 ? width : (io.terminalWidth * 0.6).round();
    io.writeln(muted('-' * w));
  }

  /// Displays a horizontal rule with optional centered text.
  void rule([String? text]) {
    final width = io.terminalWidth - 4;
    final cfg = RenderConfig(
      terminalWidth: width,
      colorProfile: _renderConfig.colorProfile,
      hasDarkBackground: _renderConfig.hasDarkBackground,
    );
    final line = Rule(text: text, renderConfig: cfg).render();
    io.writeln(muted(line));
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
        style.foreground(Colors.success).render('✓') +
            muted(' ${_formatDuration(watch.elapsed)}'),
      );
      return result;
    } catch (_) {
      watch.stop();
      io.writeln(
        style.foreground(Colors.error).render('✗') +
            muted(' ${_formatDuration(watch.elapsed)}'),
      );
      rethrow;
    }
  }

  /// Displays a comment (dimmed text with // prefix).
  void comment(Object message) {
    _writeComponent(
      CommentComponent(text: message, renderConfig: _renderConfig),
    );
  }

  /// Displays a horizontal table (row-as-headers layout).
  void horizontalTable(Map<String, Object?> data) {
    _writeComponent(
      HorizontalTableComponent(
        data: data,
        padding: 2,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Renders an exception with pretty formatting.
  void renderException(Object exception, [StackTrace? stackTrace]) {
    io.newLine();
    _writeComponent(
      ExceptionComponent(
        exception: exception,
        stackTrace: stackTrace,
        maxStackFrames: 10,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }
}

String _formatDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  if (ms < 1000) return '${ms}ms';
  final seconds = ms / 1000;
  return '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s';
}
