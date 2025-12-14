import 'base.dart';

/// A component that composes multiple child components.
class CompositeComponent extends CliComponent {
  const CompositeComponent({required this.children});

  final List<CliComponent> children;

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    var totalLines = 0;

    for (final child in children) {
      final result = child.build(context);
      buffer.write(result.output);
      totalLines += result.lineCount;
    }

    return RenderResult(output: buffer.toString(), lineCount: totalLines);
  }
}

/// A component that renders with a newline after each child.
class ColumnComponent extends CliComponent {
  const ColumnComponent({required this.children, this.spacing = 0});

  final List<CliComponent> children;
  final int spacing;

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    var totalLines = 0;

    for (var i = 0; i < children.length; i++) {
      final result = children[i].build(context);
      buffer.writeln(result.output);
      totalLines += result.lineCount + 1;

      // Add spacing between children
      for (var s = 0; s < spacing; s++) {
        buffer.writeln();
        totalLines++;
      }
    }

    return RenderResult(output: buffer.toString(), lineCount: totalLines);
  }
}

/// A component that renders children horizontally with a separator.
class RowComponent extends CliComponent {
  const RowComponent({required this.children, this.separator = ' '});

  final List<CliComponent> children;
  final String separator;

  @override
  RenderResult build(ComponentContext context) {
    final outputs = <String>[];
    var maxLines = 0;

    for (final child in children) {
      final result = child.build(context);
      outputs.add(result.output);
      if (result.lineCount > maxLines) maxLines = result.lineCount;
    }

    return RenderResult(output: outputs.join(separator), lineCount: maxLines);
  }
}
