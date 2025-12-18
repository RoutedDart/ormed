/// Rune utilities for sanitizing text input in TUI applications.
///
/// This provides helpers for Bubble widgets that process key input containing
/// runes. It handles control characters, newlines, and tabs.
library;

import '../../unicode/grapheme.dart' as uni;

/// Function type for sanitizing rune lists.
typedef RuneSanitizer = List<int> Function(List<int> runes);

/// Options for configuring the sanitizer behavior.
class SanitizerOptions {
  /// Creates sanitizer options.
  SanitizerOptions({
    this.tabReplacement = '    ',
    this.newlineReplacement = '\n',
  });

  /// String to replace tabs with.
  final String tabReplacement;

  /// String to replace newlines with.
  final String newlineReplacement;
}

/// Creates a rune sanitizer with the given options.
///
/// The sanitizer removes control characters from runes and optionally
/// replaces newline/carriage return/tabs by specified strings.
///
/// Example:
/// ```dart
/// import 'package:artisan_args/src/unicode/grapheme.dart' as uni;
///
/// final sanitizer = createSanitizer(SanitizerOptions(
///   tabReplacement: ' ',
///   newlineReplacement: ' ',
/// ));
/// final clean = sanitizer(uni.codePoints('hello\tworld'));
/// ```
RuneSanitizer createSanitizer([SanitizerOptions? options]) {
  final opts = options ?? SanitizerOptions();
  final tabRunes = uni.codePoints(opts.tabReplacement);
  final newlineRunes = uni.codePoints(opts.newlineReplacement);

  return (List<int> runes) {
    final result = <int>[];

    for (final r in runes) {
      if (r == 0xFFFD) {
        // Unicode replacement character - skip invalid runes
        continue;
      } else if (r == 0x0D || r == 0x0A) {
        // Carriage return or newline
        result.addAll(newlineRunes);
      } else if (r == 0x09) {
        // Tab
        result.addAll(tabRunes);
      } else if (_isControl(r)) {
        // Other control characters - skip
        continue;
      } else {
        // Keep the character
        result.add(r);
      }
    }

    return result;
  };
}

/// Checks if a rune is a control character.
bool _isControl(int rune) {
  // C0 controls (0x00-0x1F) except for allowed ones
  if (rune >= 0x00 && rune <= 0x1F) {
    return true;
  }
  // C1 controls (0x7F-0x9F)
  if (rune >= 0x7F && rune <= 0x9F) {
    return true;
  }
  return false;
}

/// Calculates the display width of a string, accounting for wide characters.
///
/// This is useful for terminal rendering where some characters (like CJK)
/// take up two columns.
int stringWidth(String s) {
  var width = 0;
  for (final g in uni.graphemes(s)) {
    width += runeWidth(uni.firstCodePoint(g));
  }
  return width;
}

/// Calculates the display width of a single rune.
///
/// Returns 2 for wide characters (CJK, etc.), 0 for zero-width characters,
/// and 1 for normal characters.
int runeWidth(int rune) {
  // Zero-width characters
  if (rune == 0x200B || // Zero-width space
      rune == 0x200C || // Zero-width non-joiner
      rune == 0x200D || // Zero-width joiner
      rune == 0xFEFF) {
    // BOM
    return 0;
  }

  // Wide characters (simplified - in practice you'd use a proper table)
  // CJK Unified Ideographs
  if ((rune >= 0x4E00 && rune <= 0x9FFF) ||
      // CJK Extension A
      (rune >= 0x3400 && rune <= 0x4DBF) ||
      // Full-width ASCII variants
      (rune >= 0xFF00 && rune <= 0xFF60) ||
      // Full-width punctuation
      (rune >= 0xFFE0 && rune <= 0xFFE6) ||
      // Hangul
      (rune >= 0xAC00 && rune <= 0xD7A3) ||
      // Hiragana
      (rune >= 0x3040 && rune <= 0x309F) ||
      // Katakana
      (rune >= 0x30A0 && rune <= 0x30FF)) {
    return 2;
  }

  return 1;
}

/// Truncates a string to fit within the given width.
///
/// If the string is longer than [width], it is truncated and [tail] is
/// appended (if there's room).
String truncate(String s, int width, [String tail = '']) {
  if (width <= 0) return '';

  final fullWidth = stringWidth(s);
  if (fullWidth <= width) return s;

  final tailWidth = stringWidth(tail);
  final targetWidth = (width - tailWidth).clamp(0, width);

  var currentWidth = 0;
  final result = StringBuffer();

  for (final g in uni.graphemes(s)) {
    final w = runeWidth(uni.firstCodePoint(g));
    if (currentWidth + w > targetWidth) break;
    currentWidth += w;
    result.write(g);
  }

  if (tail.isNotEmpty && currentWidth < width) {
    result.write(tail);
  }

  return result.toString();
}

/// Gets the first grapheme cluster from a string.
///
/// Returns a record with the first grapheme and the remaining string.
/// For simplicity, this treats each rune as a grapheme cluster.
/// A proper implementation would use Unicode grapheme cluster breaking rules.
({String first, String rest}) firstGraphemeCluster(String s) {
  if (s.isEmpty) {
    return (first: '', rest: '');
  }

  final it = uni.graphemes(s).iterator;
  if (!it.moveNext()) return (first: '', rest: '');
  final first = it.current;
  final rest = s.substring(first.length);
  return (first: first, rest: rest);
}
