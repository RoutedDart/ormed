import 'base.dart';

/// A tree structure component.
///
/// ```dart
/// TreeComponent(
///   data: {
///     'src': {
///       'lib': ['main.dart', 'utils.dart'],
///       'test': ['main_test.dart'],
///     },
///     'pubspec.yaml': null,
///   },
/// ).renderln(context);
/// ```
class TreeComponent extends CliComponent {
  const TreeComponent({
    required this.data,
    this.showRoot = false,
    this.rootLabel = '.',
  });

  final Map<String, dynamic> data;
  final bool showRoot;
  final String rootLabel;

  static const _pipe = '│';
  static const _tee = '├';
  static const _elbow = '└';
  static const _dash = '──';

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    final nodeFn = context.style.info;
    final leafFn = (String s) => s;

    if (showRoot) {
      buffer.writeln(nodeFn(rootLabel));
    }

    _renderNode(buffer, data, '', true, nodeFn, leafFn);

    final output = buffer.toString().trimRight();
    final lineCount = output.split('\n').length;

    return RenderResult(output: output, lineCount: lineCount);
  }

  void _renderNode(
    StringBuffer buffer,
    dynamic node,
    String prefix,
    bool isLast,
    String Function(String) nodeFn,
    String Function(String) leafFn,
  ) {
    if (node is Map<String, dynamic>) {
      final entries = node.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLastEntry = i == entries.length - 1;
        final connector = isLastEntry ? _elbow : _tee;

        if (entry.value is Map || entry.value is List) {
          buffer.writeln('$prefix$connector$_dash ${nodeFn(entry.key)}');
          final newPrefix = prefix + (isLastEntry ? '    ' : '$_pipe   ');
          _renderNode(
            buffer,
            entry.value,
            newPrefix,
            isLastEntry,
            nodeFn,
            leafFn,
          );
        } else {
          buffer.writeln('$prefix$connector$_dash ${leafFn(entry.key)}');
        }
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        final item = node[i];
        final isLastItem = i == node.length - 1;
        final connector = isLastItem ? _elbow : _tee;

        if (item is Map || item is List) {
          _renderNode(buffer, item, prefix, isLastItem, nodeFn, leafFn);
        } else {
          buffer.writeln('$prefix$connector$_dash ${leafFn(item.toString())}');
        }
      }
    }
  }
}
