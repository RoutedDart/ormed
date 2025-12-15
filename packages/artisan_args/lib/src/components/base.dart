import 'dart:io' as io;

import '../renderer/renderer.dart';
import '../style/style.dart';

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
    required this.stdout,
    required this.stdin,
    this.terminalWidth = 80,
    Renderer? renderer,
  }) : _renderer = renderer;

  final io.Stdout stdout;
  final io.Stdin stdin;
  final int terminalWidth;

  /// The renderer for styled output.
  final Renderer? _renderer;

  /// Gets the renderer, using the default if none was provided.
  Renderer get renderer => _renderer ?? defaultRenderer;

  /// The color profile from the renderer.
  ColorProfile get colorProfile => renderer.colorProfile;

  /// Whether the terminal has a dark background.
  bool get hasDarkBackground => renderer.hasDarkBackground;

  /// Creates a new Style pre-configured with the context's color profile.
  ///
  /// ```dart
  /// final myStyle = context.newStyle()
  ///     .bold()
  ///     .foreground(Colors.green);
  /// ```
  Style newStyle() => Style()
    ..colorProfile = colorProfile
    ..hasDarkBackground = hasDarkBackground;

  /// Write text to stdout.
  void write(String text) => stdout.write(text);

  /// Write a line to stdout.
  void writeln([String text = '']) => stdout.writeln(text);

  /// Render styled text directly to stdout.
  ///
  /// ```dart
  /// context.renderStyled(
  ///   'Hello World',
  ///   context.newStyle().bold().foreground(Colors.green),
  /// );
  /// ```
  void renderStyled(String text, Style style) {
    write(style.render(text));
  }

  /// Render styled text with a newline.
  void renderStyledln(String text, Style style) {
    writeln(style.render(text));
  }

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
    io.Stdout? stdout,
    io.Stdin? stdin,
    int? terminalWidth,
    Renderer? renderer,
  }) {
    return ComponentContext(
      stdout: stdout ?? this.stdout,
      stdin: stdin ?? this.stdin,
      terminalWidth: terminalWidth ?? this.terminalWidth,
      renderer: renderer ?? _renderer,
    );
  }

  /// Creates a context with a specific color profile.
  ///
  /// Useful for forcing ASCII-only output or testing with specific profiles.
  ComponentContext withColorProfile(ColorProfile profile) {
    return copyWith(
      renderer: StringRenderer(
        colorProfile: profile,
        hasDarkBackground: hasDarkBackground,
      ),
    );
  }

  /// Creates a context configured for ASCII-only output.
  ComponentContext get asciiOnly => withColorProfile(ColorProfile.ascii);

  /// Creates a context configured for ANSI-256 colors.
  ComponentContext get ansi256 => withColorProfile(ColorProfile.ansi256);

  /// Creates a context configured for true color output.
  ComponentContext get trueColor => withColorProfile(ColorProfile.trueColor);
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

/// Mixin that provides fluent style support for components.
///
/// Components that mix this in can accept a [Style] for rendering
/// and will automatically use the context's color profile.
mixin StyledComponent {
  /// Applies the given style to text using the context's color profile.
  String applyStyle(ComponentContext context, String text, Style? style) {
    if (style == null) return text;

    style
      ..colorProfile = context.colorProfile
      ..hasDarkBackground = context.hasDarkBackground;

    return style.render(text);
  }

  /// Creates a preconfigured style from the context.
  Style styleFrom(ComponentContext context) => context.newStyle();
}

/// Abstract base for fluent component builders.
///
/// Provides common rendering configuration for components that
/// use the new Style system.
abstract class FluentComponent<T extends FluentComponent<T>> {
  ColorProfile _colorProfile = ColorProfile.trueColor;
  bool _hasDarkBackground = true;

  /// Gets the current color profile.
  ColorProfile get currentColorProfile => _colorProfile;

  /// Gets whether the terminal has a dark background.
  bool get currentHasDarkBackground => _hasDarkBackground;

  /// Sets the color profile for rendering.
  T colorProfile(ColorProfile profile) {
    _colorProfile = profile;
    return this as T;
  }

  /// Sets whether the terminal has a dark background.
  T darkBackground(bool value) {
    _hasDarkBackground = value;
    return this as T;
  }

  /// Configures this component from a context.
  T fromContext(ComponentContext context) {
    _colorProfile = context.colorProfile;
    _hasDarkBackground = context.hasDarkBackground;
    return this as T;
  }

  /// Applies the current color profile to a style.
  Style configureStyle(Style style) {
    return style
      ..colorProfile = _colorProfile
      ..hasDarkBackground = _hasDarkBackground;
  }

  /// Renders the component to a string.
  String render();

  /// Returns the number of lines in the rendered output.
  int get lineCount;

  @override
  String toString() => render();
}
