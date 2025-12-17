/// Roman numerals list example - ported from lipgloss/examples/list/roman
///
/// Demonstrates list with Roman numeral enumerator and custom styles.
import 'package:artisan_args/artisan_args.dart';

void main() {
  final enumeratorStyle = Style().foreground(AnsiColor(99)).marginRight(1);
  final itemStyle = Style().foreground(AnsiColor(255)).marginRight(1);

  final l =
      LipList.create(['Glossier', "Claire's Boutique", 'Nyx', 'Mac', 'Milk'])
          .enumerator(ListEnumerators.roman)
          .enumeratorStyle(enumeratorStyle)
          .itemStyle(itemStyle);

  print(l);
}
