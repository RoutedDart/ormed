import 'dart:io' as io;

import '../style/artisan_style.dart';

/// The result of rendering a CLI component.
class RenderResult {
  const RenderResult({this.output = '', this.lineCount = 0});

  /// The rendered output string.
  final String output;

  /// Number of lines rendered (for cleanup).
  final int lineCount;

  /// Empty result.
  static const empty = RenderResult();
}

/// Context provided to CLI components during rendering/interaction.
class ComponentContext {
  ComponentContext({
    required this.style,
    required this.stdout,
    required this.stdin,
    this.terminalWidth = 80,
  });

  final ArtisanStyle style;
  final io.Stdout stdout;
  final io.Stdin stdin;
  final int terminalWidth;

  /// Write text to stdout.
  void write(String text) => stdout.write(text);

  /// Write a line to stdout.
  void writeln([String text = '']) => stdout.writeln(text);

  /// Clear the current line.
  void clearLine() => stdout.write('\x1B[2K\r');

  /// Move cursor up n lines.
  void cursorUp([int n = 1]) => stdout.write('\x1B[${n}A');

  /// Move cursor down n lines.
  void cursorDown([int n = 1]) => stdout.write('\x1B[${n}B');

  /// Clear n lines above cursor.
  void clearLines(int n) {
    for (var i = 0; i < n; i++) {
      stdout.write('\x1B[2K'); // Clear line
      if (i < n - 1) stdout.write('\x1B[1A'); // Move up
    }
    stdout.write('\r');
  }

  /// Hide cursor.
  void hideCursor() => stdout.write('\x1B[?25l');

  /// Show cursor.
  void showCursor() => stdout.write('\x1B[?25h');

  /// Create a child context with modified properties.
  ComponentContext copyWith({
    ArtisanStyle? style,
    io.Stdout? stdout,
    io.Stdin? stdin,
    int? terminalWidth,
  }) {
    return ComponentContext(
      style: style ?? this.style,
      stdout: stdout ?? this.stdout,
      stdin: stdin ?? this.stdin,
      terminalWidth: terminalWidth ?? this.terminalWidth,
    );
  }
}

/// Base class for all CLI components.
///
/// All components implement [build] to return their rendered output.
///
/// Example:
/// ```dart
/// class MyBanner extends CliComponent {
///   final String title;
///   MyBanner(this.title);
///
///   @override
///   RenderResult build(ComponentContext context) {
///     return RenderResult(
///       output: context.style.heading(title),
///       lineCount: 1,
///     );
///   }
/// }
///
/// // Usage
/// MyBanner('Hello').render(context);
/// ```
abstract class CliComponent {
  const CliComponent();

  /// Builds and returns the rendered output.
  RenderResult build(ComponentContext context);

  /// Renders the component to stdout.
  void render(ComponentContext context) {
    final result = build(context);
    if (result.output.isNotEmpty) {
      context.write(result.output);
    }
  }

  /// Renders the component followed by a newline.
  void renderln(ComponentContext context) {
    final result = build(context);
    if (result.output.isNotEmpty) {
      context.writeln(result.output);
    } else {
      context.writeln();
    }
  }
}

/// Base class for interactive CLI components that return a value.
///
/// Interactive components use [build] for their visual representation
/// and [interact] for handling user input.
///
/// Example:
/// ```dart
/// class MyPrompt extends InteractiveComponent<String> {
///   final String question;
///   MyPrompt(this.question);
///
///   @override
///   RenderResult build(ComponentContext context) {
///     return RenderResult(
///       output: '${context.style.info("?")} $question: ',
///       lineCount: 1,
///     );
///   }
///
///   @override
///   Future<String?> interact(ComponentContext context) async {
///     render(context); // Show the prompt
///     return context.stdin.readLineSync();
///   }
/// }
///
/// // Usage
/// final result = await MyPrompt('Name').interact(context);
/// ```
abstract class InteractiveComponent<T> extends CliComponent {
  const InteractiveComponent();

  /// Handles user interaction and returns the result.
  ///
  /// This method should call [render] or [build] as needed,
  /// then handle user input and return the result.
  ///
  /// Returns null if the interaction was cancelled.
  Future<T?> interact(ComponentContext context);

  /// Alias for [interact] for backwards compatibility.
  Future<T?> run(ComponentContext context) => interact(context);
}
