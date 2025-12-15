import '../style/color.dart';
import 'base.dart';

/// An exception renderer component.
///
/// ```dart
/// ExceptionComponent(
///   exception: myException,
///   stackTrace: stackTrace,
/// ).renderln(context);
/// ```
class ExceptionComponent extends CliComponent {
  const ExceptionComponent({
    required this.exception,
    this.stackTrace,
    this.maxStackFrames = 10,
    this.showFullPaths = false,
  });

  final Object exception;
  final StackTrace? stackTrace;
  final int maxStackFrames;
  final bool showFullPaths;

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    var lineCount = 0;

    // Exception header
    final exceptionType = exception.runtimeType.toString();
    final message = exception.toString();

    buffer.writeln();
    lineCount++;
    buffer.writeln(
      context
          .newStyle()
          .foreground(Colors.error)
          .bold()
          .render('  $exceptionType  '),
    );
    lineCount++;
    buffer.writeln();
    lineCount++;

    // Exception message
    final messageLines = message.split('\n');
    for (final line in messageLines) {
      buffer.writeln(
        '  ${context.newStyle().foreground(Colors.warning).bold().render(line)}',
      );
      lineCount++;
    }

    // Stack trace
    if (stackTrace != null) {
      buffer.writeln();
      lineCount++;
      buffer.writeln(context.newStyle().dim().render('  Stack trace:'));
      lineCount++;
      buffer.writeln();
      lineCount++;

      final frames = _parseStackTrace(stackTrace!);
      final displayFrames = frames.take(maxStackFrames).toList();

      for (var i = 0; i < displayFrames.length; i++) {
        final frame = displayFrames[i];
        final number = (i + 1).toString().padLeft(2);
        final location = showFullPaths
            ? frame.location
            : _shortenPath(frame.location);

        buffer.writeln(
          '  ${context.newStyle().dim().render(number)}  ${context.newStyle().foreground(Colors.info).bold().render(frame.member)}',
        );
        lineCount++;
        buffer.writeln('      ${context.newStyle().dim().render(location)}');
        lineCount++;
      }

      if (frames.length > maxStackFrames) {
        final remaining = frames.length - maxStackFrames;
        buffer.writeln();
        lineCount++;
        buffer.writeln(
          context.newStyle().dim().render('  ... and $remaining more frames'),
        );
        lineCount++;
      }
    }

    buffer.writeln();
    lineCount++;

    return RenderResult(output: buffer.toString(), lineCount: lineCount);
  }

  List<_StackFrame> _parseStackTrace(StackTrace stackTrace) {
    final frames = <_StackFrame>[];
    final lines = stackTrace.toString().split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final match = RegExp(r'#\d+\s+(\S+)\s+\((.+)\)').firstMatch(line);
      if (match != null) {
        frames.add(
          _StackFrame(
            member: match.group(1) ?? 'unknown',
            location: match.group(2) ?? 'unknown',
          ),
        );
      } else {
        final altMatch = RegExp(r'#\d+\s+(.+)').firstMatch(line);
        if (altMatch != null) {
          frames.add(
            _StackFrame(member: altMatch.group(1) ?? 'unknown', location: ''),
          );
        }
      }
    }

    return frames;
  }

  String _shortenPath(String path) {
    if (path.startsWith('package:')) {
      return path;
    }
    final match = RegExp(r'([^/]+:\d+:\d+)$').firstMatch(path);
    if (match != null) {
      return match.group(1) ?? path;
    }
    return path;
  }
}

class _StackFrame {
  _StackFrame({required this.member, required this.location});

  final String member;
  final String location;
}

/// A simple one-line exception component.
///
/// ```dart
/// SimpleExceptionComponent(
///   exception: myException,
/// ).renderln(context);
/// ```
class SimpleExceptionComponent extends CliComponent {
  const SimpleExceptionComponent({required this.exception});

  final Object exception;

  @override
  RenderResult build(ComponentContext context) {
    final exceptionType = exception.runtimeType.toString();
    final message = exception.toString().split('\n').first;
    return RenderResult(
      output:
          '${context.newStyle().foreground(Colors.error).bold().render('[$exceptionType]')} $message',
      lineCount: 1,
    );
  }
}
