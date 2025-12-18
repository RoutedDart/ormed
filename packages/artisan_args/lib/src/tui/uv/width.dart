/// Upstream: `third_party/ultraviolet/styled.go` uses `ansi.GraphemeWidth` and
/// `ansi.WcWidth`. For now, this is a minimal wcwidth-like approximation.
///
/// Note: This is intentionally minimal-first. The Ultraviolet parity tests we
/// port initially mostly cover ASCII + common wide (CJK/emoji) characters.
import '../../unicode/grapheme.dart' as uni;

enum WidthMethod { grapheme, wcwidth }

extension WidthMethodX on WidthMethod {
  int stringWidth(String s) {
    var width = 0;
    // Count display width per grapheme cluster to avoid double-counting
    // multi-codepoint clusters (e.g. ZWJ emoji sequences).
    for (final g in uni.graphemes(s)) {
      width += runeWidth(uni.firstCodePoint(g));
    }
    return width;
  }
}

int runeWidth(int rune) {
  // Control characters and null
  if (rune < 32 || (rune >= 0x7F && rune < 0xA0)) {
    return 0;
  }

  // Zero-width (very small subset).
  if (rune == 0x200B || // ZWSP
      rune == 0x200C || // ZWNJ
      rune == 0x200D || // ZWJ
      rune == 0xFEFF) {
    // BOM
    return 0;
  }

  // Wide characters (CJK + emoji range subset).
  if ((rune >= 0x1100 && rune <= 0x115F) || // Hangul Jamo
      (rune >= 0x2E80 && rune <= 0x9FFF) || // CJK
      (rune >= 0xAC00 && rune <= 0xD7A3) || // Hangul Syllables
      (rune >= 0xF900 && rune <= 0xFAFF) || // CJK Compatibility
      (rune >= 0xFE10 && rune <= 0xFE1F) || // Vertical Forms
      (rune >= 0xFE30 && rune <= 0xFE6F) || // CJK Compatibility Forms
      (rune >= 0xFF00 && rune <= 0xFF60) || // Fullwidth ASCII
      (rune >= 0xFFE0 && rune <= 0xFFE6) || // Fullwidth symbols
      (rune >= 0x20000 && rune <= 0x3FFFF) || // CJK Extensions
      (rune >= 0x1F300 && rune <= 0x1F9FF)) {
    return 2;
  }

  return 1;
}
