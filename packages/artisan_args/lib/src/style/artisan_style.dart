/// ANSI styling utilities for console output.
///
/// Provides methods for colorizing and formatting text in terminals
/// that support ANSI escape sequences.
///
/// ```dart
/// final style = ArtisanStyle(ansi: true);
/// print(style.success('Done!'));     // Green text
/// print(style.error('Failed!'));     // Red text
/// print(style.warning('Warning!'));  // Yellow text
/// ```
class ArtisanStyle {
  /// Creates a new style instance.
  ///
  /// Set [ansi] to `true` to enable ANSI escape sequences, or `false`
  /// to return plain text.
  ArtisanStyle({required bool ansi}) : _ansi = ansi;

  final bool _ansi;

  /// Whether ANSI styling is enabled.
  bool get enabled => _ansi;

  static final _ansiRegex = RegExp(r'\x1B\[[0-9;]*m');

  /// Strips all ANSI escape sequences from [input].
  static String stripAnsi(String input) => input.replaceAll(_ansiRegex, '');

  /// Returns the visible length of [input], ignoring ANSI sequences.
  static int visibleLength(String input) => stripAnsi(input).length;

  /// Formats [text] as a heading (bold yellow).
  String heading(String text) => _wrap(text, '1;33');

  /// Formats [text] as a command name (green).
  String command(String text) => _wrap(text, '32');

  /// Formats [text] as an option (green).
  String option(String text) => _wrap(text, '32');

  /// Formats [text] as muted/dimmed (gray).
  String muted(String text) => _wrap(text, '90');

  /// Formats [text] as a success message (bold green).
  String success(String text) => _wrap(text, '1;32');

  /// Formats [text] as a warning message (bold yellow).
  String warning(String text) => _wrap(text, '1;33');

  /// Formats [text] as an info message (bold blue).
  String info(String text) => _wrap(text, '1;34');

  /// Formats [text] as an error message (red).
  String error(String text) => _wrap(text, '31');

  /// Formats [text] as emphasized (bold).
  String emphasize(String text) => _wrap(text, '1');

  /// Formats option usage text, highlighting option names.
  String formatOptionsUsage(String usage) {
    if (!_ansi) return usage;

    final lines = usage.split('\n');
    final styled = <String>[];
    for (final line in lines) {
      if (line.trim().isEmpty) {
        styled.add(line);
        continue;
      }

      final match = RegExp(r'^(\s*)(.*)$').firstMatch(line);
      if (match == null) {
        styled.add(line);
        continue;
      }

      final indent = match.group(1) ?? '';
      final rest = match.group(2) ?? '';
      final split = RegExp(r'\s{2,}').firstMatch(rest);
      if (split == null) {
        styled.add(line);
        continue;
      }

      final left = rest.substring(0, split.start).trimRight();
      final spacing = rest.substring(split.start, split.end);
      final right = rest.substring(split.end);
      styled.add('$indent${option(left)}$spacing$right');
    }

    return styled.join('\n');
  }

  String _wrap(String text, String sgr) {
    if (!_ansi) return text;
    return '\x1B[${sgr}m$text\x1B[0m';
  }
}
