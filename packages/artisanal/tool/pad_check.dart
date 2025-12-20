import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/ranges.dart' as ranges;

void main() {
  final hs = Style().foreground(const AnsiColor(1));
  final styled = ranges.styleRanges('test line', [ranges.StyleRange(0, 4, hs)]);
  final padded = Style().width(20).height(24).render(styled);
  print('styled=' + styled);
  print('padded=' + padded);
}
