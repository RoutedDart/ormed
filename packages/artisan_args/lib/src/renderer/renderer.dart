/// Renderer abstraction for terminal output.
///
/// Provides an interface for rendering styled content to different outputs,
/// with color profile detection and background detection.
///
/// ```dart
/// // Use the default terminal renderer
/// final renderer = TerminalRenderer();
/// print(renderer.colorProfile); // ColorProfile.trueColor
///
/// // Use a string renderer for testing
/// final testRenderer = StringRenderer();
/// style.render('Hello', renderer: testRenderer);
/// print(testRenderer.output);
/// ```
library;

import 'dart:io';

import '../style/color.dart';

export '../style/color.dart' show ColorProfile;

/// Abstract interface for rendering styled output.
///
/// Implementations handle writing to different outputs (terminal, string buffer)
/// and provide information about the target's color capabilities.
abstract class Renderer {
  /// The color profile of the output target.
  ColorProfile get colorProfile;

  /// Whether the output target has a dark background.
  ///
  /// Used by [AdaptiveColor] to select appropriate color variants.
  bool get hasDarkBackground;

  /// Writes text to the output without a trailing newline.
  void write(String text);

  /// Writes text to the output followed by a newline.
  void writeln([String text = '']);
}

/// A renderer that outputs to a terminal.
///
/// Automatically detects the terminal's color capabilities from
/// environment variables.
class TerminalRenderer implements Renderer {
  /// Creates a terminal renderer.
  ///
  /// If [output] is not provided, defaults to [stdout].
  /// If [forceProfile] is provided, uses that instead of auto-detection.
  /// If [forceDarkBackground] is provided, uses that instead of auto-detection.
  TerminalRenderer({
    IOSink? output,
    ColorProfile? forceProfile,
    bool? forceDarkBackground,
  }) : _output = output ?? stdout,
       _forceProfile = forceProfile,
       _forceDarkBackground = forceDarkBackground;

  final IOSink _output;
  final ColorProfile? _forceProfile;
  final bool? _forceDarkBackground;

  ColorProfile? _cachedProfile;
  bool? _cachedDarkBackground;

  @override
  ColorProfile get colorProfile {
    if (_forceProfile != null) return _forceProfile;
    return _cachedProfile ??= _detectColorProfile();
  }

  @override
  bool get hasDarkBackground {
    if (_forceDarkBackground != null) return _forceDarkBackground;
    return _cachedDarkBackground ??= _detectDarkBackground();
  }

  @override
  void write(String text) => _output.write(text);

  @override
  void writeln([String text = '']) => _output.writeln(text);

  /// Detects the color profile from environment variables.
  ///
  /// Checks:
  /// - `NO_COLOR` - If set, returns [ColorProfile.ascii]
  /// - `COLORTERM` - If 'truecolor' or '24bit', returns [ColorProfile.trueColor]
  /// - `TERM` - If contains '256color', returns [ColorProfile.ansi256]
  /// - `TERM` - If set, returns [ColorProfile.ansi]
  /// - Otherwise, returns [ColorProfile.ascii]
  static ColorProfile _detectColorProfile() {
    final env = Platform.environment;

    // NO_COLOR standard: https://no-color.org/
    if (env.containsKey('NO_COLOR')) {
      return ColorProfile.ascii;
    }

    // Check for true color support
    final colorTerm = env['COLORTERM']?.toLowerCase() ?? '';
    if (colorTerm.contains('truecolor') || colorTerm.contains('24bit')) {
      return ColorProfile.trueColor;
    }

    // Check TERM for color capabilities
    final term = env['TERM']?.toLowerCase() ?? '';

    // Check for 256-color support
    if (term.contains('256color') ||
        term.contains('256-color') ||
        term == 'xterm-256') {
      return ColorProfile.ansi256;
    }

    // Common terminals that support 256 colors
    if (term.contains('xterm') ||
        term.contains('screen') ||
        term.contains('tmux') ||
        term.contains('vt100') ||
        term.contains('linux') ||
        term.contains('rxvt') ||
        term.contains('konsole') ||
        term.contains('gnome') ||
        term.contains('alacritty') ||
        term.contains('kitty') ||
        term.contains('iterm')) {
      // Modern terminals typically support 256 colors minimum
      return ColorProfile.ansi256;
    }

    // Check for basic color support
    if (term.isNotEmpty && term != 'dumb') {
      return ColorProfile.ansi;
    }

    // Windows terminal detection
    if (Platform.isWindows) {
      final wtSession = env['WT_SESSION'];
      if (wtSession != null && wtSession.isNotEmpty) {
        // Windows Terminal supports true color
        return ColorProfile.trueColor;
      }

      // Check if running in ConEmu or similar
      final conEmu = env['ConEmuANSI'];
      if (conEmu == 'ON') {
        return ColorProfile.trueColor;
      }

      // Modern Windows 10+ console supports ANSI
      return ColorProfile.ansi256;
    }

    return ColorProfile.ascii;
  }

  /// Detects whether the terminal has a dark background.
  ///
  /// This is a heuristic based on common terminal configurations.
  /// Most terminals default to dark backgrounds, so we default to true.
  static bool _detectDarkBackground() {
    final env = Platform.environment;

    // Check for explicit COLORFGBG variable (format: "fg;bg")
    final colorFgBg = env['COLORFGBG'];
    if (colorFgBg != null) {
      final parts = colorFgBg.split(';');
      if (parts.length >= 2) {
        final bg = int.tryParse(parts.last);
        if (bg != null) {
          // ANSI colors 0-6 and 8 are typically dark
          // Colors 7 and 15 are light (white)
          return bg != 7 && bg != 15;
        }
      }
    }

    // Check for macOS Terminal.app with light theme
    final termProgram = env['TERM_PROGRAM'];
    if (termProgram == 'Apple_Terminal') {
      // Apple Terminal defaults to light, but many users change it
      // Default to dark as it's more common in developer setups
      return true;
    }

    // Most terminals default to dark backgrounds
    return true;
  }

  @override
  String toString() =>
      'TerminalRenderer(colorProfile: $colorProfile, darkBackground: $hasDarkBackground)';
}

/// A renderer that captures output to a string buffer.
///
/// Useful for testing styled output without terminal dependency.
///
/// ```dart
/// final renderer = StringRenderer();
/// style.render('Hello');
/// renderer.writeln('Hello');
///
/// expect(renderer.output, contains('Hello'));
/// renderer.clear();
/// ```
class StringRenderer implements Renderer {
  /// Creates a string renderer with optional configuration.
  ///
  /// [colorProfile] defaults to [ColorProfile.trueColor] for testing.
  /// [hasDarkBackground] defaults to true.
  StringRenderer({ColorProfile? colorProfile, bool? hasDarkBackground})
    : colorProfile = colorProfile ?? ColorProfile.trueColor,
      hasDarkBackground = hasDarkBackground ?? true;

  final StringBuffer _buffer = StringBuffer();

  @override
  final ColorProfile colorProfile;

  @override
  final bool hasDarkBackground;

  @override
  void write(String text) => _buffer.write(text);

  @override
  void writeln([String text = '']) => _buffer.writeln(text);

  /// Gets the captured output.
  String get output => _buffer.toString();

  /// Gets the output and clears the buffer.
  String flush() {
    final result = _buffer.toString();
    _buffer.clear();
    return result;
  }

  /// Clears the captured output.
  void clear() => _buffer.clear();

  /// Whether the buffer is empty.
  bool get isEmpty => _buffer.isEmpty;

  /// Whether the buffer is not empty.
  bool get isNotEmpty => _buffer.isNotEmpty;

  /// The number of characters in the buffer.
  int get length => _buffer.length;

  @override
  String toString() =>
      'StringRenderer(colorProfile: $colorProfile, length: $length)';
}

/// A renderer that discards all output.
///
/// Useful for silencing output in quiet mode or benchmarking.
class NullRenderer implements Renderer {
  /// Creates a null renderer.
  const NullRenderer({
    this.colorProfile = ColorProfile.ascii,
    this.hasDarkBackground = true,
  });

  @override
  final ColorProfile colorProfile;

  @override
  final bool hasDarkBackground;

  @override
  void write(String text) {}

  @override
  void writeln([String text = '']) {}

  @override
  String toString() => 'NullRenderer()';
}

// ─────────────────────────────────────────────────────────────────────────────
// Global Default Renderer
// ─────────────────────────────────────────────────────────────────────────────

/// The default renderer used when none is specified.
///
/// This is lazily initialized to a [TerminalRenderer] on first access.
/// You can replace it with a custom renderer for testing or other purposes.
Renderer? _defaultRenderer;

/// Gets the default renderer.
///
/// Returns a [TerminalRenderer] if not explicitly set.
Renderer get defaultRenderer => _defaultRenderer ??= TerminalRenderer();

/// Sets the default renderer.
///
/// Pass `null` to reset to the default [TerminalRenderer].
set defaultRenderer(Renderer? renderer) {
  _defaultRenderer = renderer;
}

/// Resets the default renderer to a new [TerminalRenderer].
void resetDefaultRenderer() {
  _defaultRenderer = null;
}
