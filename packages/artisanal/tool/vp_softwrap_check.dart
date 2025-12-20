import 'package:artisanal/src/tui/bubbles/viewport.dart';

void main() {
  final content = 'This is a very long line that should be wrapped by the viewport.';
  final vp = ViewportModel(width: 20, height: 5, softWrap: true).setContent(content);
  print(vp.view());
}
