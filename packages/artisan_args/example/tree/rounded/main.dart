/// Rounded tree example - ported from lipgloss/examples/tree/rounded
///
/// Demonstrates tree with rounded enumerator and custom styles.
import 'package:artisan_args/artisan_args.dart';

void main() {
  final itemStyle = Style().marginRight(1);
  final enumeratorStyle = Style().foreground(AnsiColor(8)).marginRight(1);

  final t = Tree()
      .root('Groceries')
      .child(
        Tree().root('Fruits').children([
          'Blood Orange',
          'Papaya',
          'Dragonfruit',
          'Yuzu',
        ]),
      )
      .child(
        Tree().root('Items').children([
          'Cat Food',
          'Nutella',
          'Powdered Sugar',
        ]),
      )
      .child(Tree().root('Veggies').children(['Leek', 'Artichoke']))
      .fileStyle(itemStyle)
      .branchStyle(enumeratorStyle)
      .enumerator(TreeEnumerator.rounded);

  print(t);
}
