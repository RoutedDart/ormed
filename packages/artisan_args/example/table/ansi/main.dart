/// ANSI table example - ported from lipgloss/examples/table/ansi
///
/// Demonstrates a simple table with styled cell values.
import 'package:artisan_args/artisan_args.dart';

void main() {
  final s = Style().foreground(AnsiColor(240));

  final t = Table()
      .row(['Bubble Tea', s.render('Milky')])
      .row(['Milk Tea', s.render('Also milky')])
      .row(['Actual milk', s.render('Milky as well')]);

  print(t.render());
}
