/// Styled tree example - demonstrates per-subtree styling.
///
/// This is a port of the Go lipgloss example: examples/tree/styles/main.go
library;

import 'package:artisan_args/artisan_args.dart';

void main() {
  final purple = Style().foreground(AnsiColor(99)).marginRight(1);
  final pink = Style().foreground(AnsiColor(212)).marginRight(1);

  final t = Tree()
      .child('Glossier')
      .child("Claire's Boutique")
      .child(
        Tree()
            .root('Nyx')
            .child('Lip Gloss')
            .child('Foundation')
            .enumeratorStyle(pink)
            .indenterStyle(pink),
      )
      .child('Mac')
      .child('Milk')
      .enumeratorStyle(purple)
      .indenterStyle(purple);

  print(t.render());
}
