/// Simple tree example - ported from lipgloss/examples/tree/simple
///
/// Demonstrates basic tree creation with nested children.
import 'package:artisan_args/artisan_args.dart';

void main() {
  final t = Tree()
      .root('.')
      .child('macOS')
      .child(
        Tree()
            .root('Linux')
            .child('NixOS')
            .child('Arch Linux (btw)')
            .child('Void Linux'),
      )
      .child(
        Tree().root('BSD').child('FreeBSD').child('OpenBSD'),
      );

  print(t);
}
