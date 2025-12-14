import 'base.dart';

/// A bullet list component.
class BulletList extends CliComponent {
  const BulletList({required this.items, this.bullet = '•', this.indent = 2});

  final List<String> items;
  final String bullet;
  final int indent;

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    final prefix = ' ' * indent;

    for (var i = 0; i < items.length; i++) {
      buffer.write('$prefix$bullet ${items[i]}');
      if (i < items.length - 1) buffer.writeln();
    }

    return RenderResult(output: buffer.toString(), lineCount: items.length);
  }
}

/// A numbered list component.
class NumberedList extends CliComponent {
  const NumberedList({required this.items, this.indent = 2, this.startAt = 1});

  final List<String> items;
  final int indent;
  final int startAt;

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    final prefix = ' ' * indent;
    final maxNumWidth = (startAt + items.length - 1).toString().length;

    for (var i = 0; i < items.length; i++) {
      final num = (startAt + i).toString().padLeft(maxNumWidth);
      buffer.write('$prefix$num. ${items[i]}');
      if (i < items.length - 1) buffer.writeln();
    }

    return RenderResult(output: buffer.toString(), lineCount: items.length);
  }
}
