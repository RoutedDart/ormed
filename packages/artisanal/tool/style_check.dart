import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';

void main() {
  final s = Style().foreground(const AnsiColor(1));
  print(s.render('test'));
}
