import 'package:artisanal/src/tui/bubbles/viewport.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';

void main() {
  final hs = Style().foreground(const AnsiColor(1));
  print('render(test)=' + hs.render('test'));
  final vp = ViewportModel(width: 20, highlightStyle: hs)
      .setContent('test line')
      .setHighlights([[0, 4]]);
  print('vp.highlightStyle.render(test)=' + vp.highlightStyle.render('test'));
  print(vp.view());
}
