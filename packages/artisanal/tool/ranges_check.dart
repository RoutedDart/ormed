import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/ranges.dart' as ranges;

void main() {
  final s = 'test line';
  final out = ranges.styleRanges(s, [
    ranges.StyleRange(0, 4, Style().foreground(const AnsiColor(1))),
  ]);
  print(out);
}
