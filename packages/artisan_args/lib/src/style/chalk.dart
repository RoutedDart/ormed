import 'package:chalkdart/chalk.dart';

/// Extended ANSI styling utilities using chalkdart.
///
/// Provides advanced color support including:
/// - 256 colors
/// - True color (RGB)
/// - Color keywords
/// - Gradients
///
/// ```dart
/// final chalk = ArtisanChalk();
/// print(chalk.success('Done!'));
/// print(chalk.rgb(255, 128, 0, 'Orange text'));
/// print(chalk.gradient(['#ff0000', '#00ff00'], 'Gradient text'));
/// ```
class ArtisanChalk {
  ArtisanChalk({bool? enabled}) : _enabled = enabled ?? true, _chalk = Chalk();

  final bool _enabled;
  final Chalk _chalk;

  /// Whether color output is enabled.
  bool get enabled => _enabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Semantic Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Success styling (green).
  String success(String text) => _enabled ? _chalk.green.bold(text) : text;

  /// Error styling (red).
  String error(String text) => _enabled ? _chalk.red(text) : text;

  /// Warning styling (yellow).
  String warning(String text) => _enabled ? _chalk.yellow.bold(text) : text;

  /// Info styling (blue).
  String info(String text) => _enabled ? _chalk.blue.bold(text) : text;

  /// Muted styling (gray).
  String muted(String text) => _enabled ? _chalk.gray(text) : text;

  /// Heading styling (bold yellow).
  String heading(String text) => _enabled ? _chalk.yellow.bold(text) : text;

  /// Command styling (green).
  String command(String text) => _enabled ? _chalk.green(text) : text;

  /// Emphasis styling (bold).
  String emphasis(String text) => _enabled ? _chalk.bold(text) : text;

  /// Highlight styling (inverted).
  String highlight(String text) => _enabled ? _chalk.inverse(text) : text;

  // ─────────────────────────────────────────────────────────────────────────────
  // Basic Colors
  // ─────────────────────────────────────────────────────────────────────────────

  String black(String text) => _enabled ? _chalk.black(text) : text;
  String red(String text) => _enabled ? _chalk.red(text) : text;
  String green(String text) => _enabled ? _chalk.green(text) : text;
  String yellow(String text) => _enabled ? _chalk.yellow(text) : text;
  String blue(String text) => _enabled ? _chalk.blue(text) : text;
  String magenta(String text) => _enabled ? _chalk.magenta(text) : text;
  String cyan(String text) => _enabled ? _chalk.cyan(text) : text;
  String white(String text) => _enabled ? _chalk.white(text) : text;

  // Bright variants
  String brightBlack(String text) => _enabled ? _chalk.brightBlack(text) : text;
  String brightRed(String text) => _enabled ? _chalk.brightRed(text) : text;
  String brightGreen(String text) => _enabled ? _chalk.brightGreen(text) : text;
  String brightYellow(String text) =>
      _enabled ? _chalk.brightYellow(text) : text;
  String brightBlue(String text) => _enabled ? _chalk.brightBlue(text) : text;
  String brightMagenta(String text) =>
      _enabled ? _chalk.brightMagenta(text) : text;
  String brightCyan(String text) => _enabled ? _chalk.brightCyan(text) : text;
  String brightWhite(String text) => _enabled ? _chalk.brightWhite(text) : text;

  // ─────────────────────────────────────────────────────────────────────────────
  // Styles
  // ─────────────────────────────────────────────────────────────────────────────

  String bold(String text) => _enabled ? _chalk.bold(text) : text;
  String dim(String text) => _enabled ? _chalk.dim(text) : text;
  String italic(String text) => _enabled ? _chalk.italic(text) : text;
  String underline(String text) => _enabled ? _chalk.underline(text) : text;
  String inverse(String text) => _enabled ? _chalk.inverse(text) : text;
  String strikethrough(String text) =>
      _enabled ? _chalk.strikethrough(text) : text;

  // ─────────────────────────────────────────────────────────────────────────────
  // Advanced Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Applies RGB color to text.
  String rgb(int r, int g, int b, String text) {
    if (!_enabled) return text;
    return _chalk.rgb(r, g, b)(text);
  }

  /// Applies RGB background color to text.
  String bgRgb(int r, int g, int b, String text) {
    if (!_enabled) return text;
    return _chalk.bgRgb(r, g, b)(text);
  }

  /// Applies hex color to text.
  String hex(String hexColor, String text) {
    if (!_enabled) return text;
    return _chalk.hex(hexColor)(text);
  }

  /// Applies hex background color to text.
  String bgHex(String hexColor, String text) {
    if (!_enabled) return text;
    return _chalk.bgHex(hexColor)(text);
  }

  /// Applies a keyword color (CSS color names).
  String keyword(String colorName, String text) {
    if (!_enabled) return text;
    return _chalk.keyword(colorName)(text);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Utilities
  // ─────────────────────────────────────────────────────────────────────────────

  /// Strips ANSI codes from text.
  static String strip(String text) {
    // Remove ANSI escape sequences
    return text.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
  }

  /// Returns the visible length of text (ignoring ANSI codes).
  static int visibleLength(String text) => strip(text).length;
}

/// Common color presets.
class ColorPresets {
  ColorPresets._();

  // Status colors
  static const success = '#22c55e';
  static const error = '#ef4444';
  static const warning = '#f59e0b';
  static const info = '#3b82f6';

  // Accent colors
  static const purple = '#a855f7';
  static const pink = '#ec4899';
  static const orange = '#f97316';
  static const teal = '#14b8a6';

  // Neutral colors
  static const gray50 = '#f9fafb';
  static const gray100 = '#f3f4f6';
  static const gray200 = '#e5e7eb';
  static const gray300 = '#d1d5db';
  static const gray400 = '#9ca3af';
  static const gray500 = '#6b7280';
  static const gray600 = '#4b5563';
  static const gray700 = '#374151';
  static const gray800 = '#1f2937';
  static const gray900 = '#111827';
}
