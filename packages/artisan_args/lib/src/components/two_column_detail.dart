import '../style/artisan_style.dart';
import 'base.dart';

/// A two-column detail component with dot fill.
///
/// ```dart
/// TwoColumnDetailComponent(
///   left: 'Status',
///   right: 'OK',
/// ).renderln(context);
/// ```
class TwoColumnDetailComponent extends CliComponent {
  const TwoColumnDetailComponent({
    required this.left,
    required this.right,
    this.fillChar = '.',
    this.indent = 2,
  });

  final String left;
  final String right;
  final String fillChar;
  final int indent;

  @override
  RenderResult build(ComponentContext context) {
    final leftLen = ArtisanStyle.visibleLength(left);
    final rightLen = ArtisanStyle.visibleLength(right);
    final available = context.terminalWidth - indent - leftLen - rightLen - 2;
    final fill = available > 0 ? ' ${fillChar * available} ' : ' ';

    return RenderResult(
      output: '${' ' * indent}$left$fill$right',
      lineCount: 1,
    );
  }
}
