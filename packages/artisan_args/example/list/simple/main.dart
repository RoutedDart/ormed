/// Simple list example - ported from lipgloss/examples/list/simple
///
/// Demonstrates basic nested list creation with different enumerators.
import 'package:artisan_args/artisan_args.dart';

void main() {
  final l = LipList.create([
    'A',
    'B',
    'C',
    LipList.create([
      'D',
      'E',
      'F',
    ]).enumerator(ListEnumerators.roman),
    'G',
  ]);

  print(l);
}
