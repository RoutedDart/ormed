/// Makeup tree example - ported from lipgloss/examples/tree/makeup
///
/// Demonstrates a tree with nested items and rounded enumerators.
import 'package:artisan_args/artisan_args.dart';

void main() {
  final enumeratorStyle = Style().foreground(AnsiColor(63)).marginRight(1);
  final rootStyle = Style().foreground(AnsiColor(35));
  final itemStyle = Style().foreground(AnsiColor(212));

  final t = Tree()
      .root('⁜ Makeup')
      .child('Glossier')
      .child('Fenty Beauty')
      .child(Tree()
          .child('Gloss Bomb Universal Lip Luminizer')
          .child('Hot Cheeks Velour Blushlighter'))
      .child('Nyx')
      .child('Mac')
      .child('Milk')
      .enumerator(TreeEnumerator.rounded)
      .branchStyle(enumeratorStyle)
      .rootStyle(rootStyle)
      .fileStyle(itemStyle)
      .directoryStyle(itemStyle);

  print(t.render());
}
