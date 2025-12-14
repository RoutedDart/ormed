import '../style/artisan_style.dart';
import 'base.dart';

/// A styled block component (Symfony-style).
///
/// ```dart
/// StyledBlockComponent(
///   message: 'This is an important message!',
///   blockStyle: BlockStyleType.error,
/// ).renderln(context);
/// ```
class StyledBlockComponent extends CliComponent {
  const StyledBlockComponent({
    required this.message,
    this.blockStyle = BlockStyleType.info,
    this.prefix,
    this.large = false,
    this.padding = 1,
  });

  final Object message;
  final BlockStyleType blockStyle;
  final String? prefix;
  final bool large;
  final int padding;

  @override
  RenderResult build(ComponentContext context) {
    final lines = _normalizeLines(message);
    final buffer = StringBuffer();

    final blockColor = switch (blockStyle) {
      BlockStyleType.info => context.style.info,
      BlockStyleType.success => context.style.success,
      BlockStyleType.warning => context.style.warning,
      BlockStyleType.error => context.style.error,
      BlockStyleType.note => context.style.muted,
    };

    final prefixText =
        prefix ??
        switch (blockStyle) {
          BlockStyleType.info => '[INFO]',
          BlockStyleType.success => '[OK]',
          BlockStyleType.warning => '[WARNING]',
          BlockStyleType.error => '[ERROR]',
          BlockStyleType.note => '[NOTE]',
        };

    final pad = ' ' * padding;
    var lineCount = 0;

    if (large) {
      final maxWidth = lines
          .map((l) => ArtisanStyle.visibleLength(l))
          .fold<int>(0, (m, v) => v > m ? v : m);
      final blockWidth = (maxWidth + padding * 2 + prefixText.length + 2).clamp(
        40,
        context.terminalWidth - 4,
      );

      buffer.writeln();
      lineCount++;
      buffer.writeln(blockColor(' ' * blockWidth));
      lineCount++;
      buffer.writeln(
        blockColor(
          '$pad$prefixText${' ' * (blockWidth - prefixText.length - padding)}',
        ),
      );
      lineCount++;
      for (final line in lines) {
        final fill =
            blockWidth - ArtisanStyle.visibleLength(line) - padding * 2;
        buffer.writeln(
          blockColor('$pad$line${' ' * (fill > 0 ? fill : 0)}$pad'),
        );
        lineCount++;
      }
      buffer.writeln(blockColor(' ' * blockWidth));
      lineCount++;
      buffer.write('');
    } else {
      buffer.writeln();
      lineCount++;
      for (final line in lines) {
        buffer.writeln('${blockColor(prefixText)} $line');
        lineCount++;
      }
    }

    return RenderResult(output: buffer.toString(), lineCount: lineCount);
  }

  List<String> _normalizeLines(Object message) {
    if (message is Iterable) {
      return message.map((e) => e.toString()).toList();
    }
    return message.toString().split('\n');
  }
}

/// Block style types.
enum BlockStyleType { info, success, warning, error, note }

/// A comment component (dimmed text with // prefix).
///
/// ```dart
/// CommentComponent(
///   text: 'This is a comment',
/// ).renderln(context);
/// ```
class CommentComponent extends CliComponent {
  const CommentComponent({required this.text});

  final Object text;

  @override
  RenderResult build(ComponentContext context) {
    final lines = text is Iterable
        ? (text as Iterable).map((e) => e.toString()).toList()
        : text.toString().split('\n');

    final buffer = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) buffer.writeln();
      buffer.write(context.style.muted('// ${lines[i]}'));
    }

    return RenderResult(output: buffer.toString(), lineCount: lines.length);
  }
}
