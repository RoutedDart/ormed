/// Background tree example - ported from lipgloss/examples/tree/background
///
/// Demonstrates tree with background colors on items and enumerators.
import 'package:artisan_args/artisan_args.dart';

void main() {
  final enumeratorStyle = Style().background(AnsiColor(0)).padding(0, 1);

  final headerItemStyle = Style()
      .background(BasicColor('#ee6ff8'))
      .foreground(BasicColor('#ecfe65'))
      .bold()
      .padding(0, 1);

  final itemStyle = headerItemStyle.copy().background(AnsiColor(0));

  final t = Tree()
      .root('# Table of Contents')
      .rootStyle(itemStyle)
      .fileStyle(itemStyle)
      .directoryStyle(itemStyle)
      .branchStyle(enumeratorStyle)
      .child(
        Tree().root('## Chapter 1').child('Chapter 1.1').child('Chapter 1.2'),
      )
      .child(
        Tree().root('## Chapter 2').child('Chapter 2.1').child('Chapter 2.2'),
      );

  print(t.render());
}
