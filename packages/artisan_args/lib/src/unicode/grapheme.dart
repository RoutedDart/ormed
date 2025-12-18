import 'package:characters/characters.dart';

/// Returns a lazy grapheme-cluster iterable.
Iterable<String> graphemes(String s) => s.characters;

/// Decodes a Dart String (UTF-16) into Unicode scalar values (code points).
///
/// This intentionally avoids `String.runes` so callers can stay consistent on
/// grapheme-cluster APIs while still accessing code points when needed.
List<int> codePoints(String s) {
  final units = s.codeUnits;
  if (units.isEmpty) return const [];

  final out = <int>[];
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDBFF && i + 1 < units.length) {
      final u2 = units[i + 1];
      if (u2 >= 0xDC00 && u2 <= 0xDFFF) {
        // surrogate pair
        final high = u - 0xD800;
        final low = u2 - 0xDC00;
        out.add(0x10000 + ((high << 10) | low));
        i++;
        continue;
      }
    }
    out.add(u);
  }
  return out;
}

int firstCodePoint(String s) {
  final cps = codePoints(s);
  return cps.isEmpty ? 0 : cps.first;
}

bool isSingleCodePoint(String s) => codePoints(s).length == 1;
