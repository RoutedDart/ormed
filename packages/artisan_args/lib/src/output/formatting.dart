import '../style/artisan_style.dart';

/// Renders exceptions with pretty formatting.
///
/// ```dart
/// final renderer = ExceptionRenderer(style: style, terminalWidth: 80);
/// print(renderer.render(exception, stackTrace));
/// ```
class ExceptionRenderer {
  ExceptionRenderer({
    required this.style,
    required this.terminalWidth,
    this.maxStackFrames = 10,
    this.showFullPaths = false,
  });

  final ArtisanStyle style;
  final int terminalWidth;
  final int maxStackFrames;
  final bool showFullPaths;

  /// Renders an exception with its stack trace.
  String render(Object exception, [StackTrace? stackTrace]) {
    final buffer = StringBuffer();

    // Exception header
    final exceptionType = exception.runtimeType.toString();
    final message = exception.toString();

    buffer.writeln();
    buffer.writeln(style.error('  $exceptionType  '));
    buffer.writeln();

    // Exception message
    final messageLines = message.split('\n');
    for (final line in messageLines) {
      buffer.writeln('  ${style.warning(line)}');
    }

    // Stack trace
    if (stackTrace != null) {
      buffer.writeln();
      buffer.writeln(style.muted('  Stack trace:'));
      buffer.writeln();

      final frames = _parseStackTrace(stackTrace);
      final displayFrames = frames.take(maxStackFrames).toList();

      for (var i = 0; i < displayFrames.length; i++) {
        final frame = displayFrames[i];
        final number = (i + 1).toString().padLeft(2);
        final location = showFullPaths
            ? frame.location
            : _shortenPath(frame.location);

        buffer.writeln('  ${style.muted(number)}  ${style.info(frame.member)}');
        buffer.writeln('      ${style.muted(location)}');
      }

      if (frames.length > maxStackFrames) {
        final remaining = frames.length - maxStackFrames;
        buffer.writeln();
        buffer.writeln(style.muted('  ... and $remaining more frames'));
      }
    }

    buffer.writeln();
    return buffer.toString();
  }

  /// Renders a simple one-line exception.
  String renderSimple(Object exception) {
    final exceptionType = exception.runtimeType.toString();
    final message = exception.toString().split('\n').first;
    return '${style.error('[$exceptionType]')} $message';
  }

  List<_StackFrame> _parseStackTrace(StackTrace stackTrace) {
    final frames = <_StackFrame>[];
    final lines = stackTrace.toString().split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Parse standard Dart stack frame format
      // #0      someFunction (package:foo/bar.dart:10:5)
      final match = RegExp(r'#\d+\s+(\S+)\s+\((.+)\)').firstMatch(line);
      if (match != null) {
        frames.add(
          _StackFrame(
            member: match.group(1) ?? 'unknown',
            location: match.group(2) ?? 'unknown',
          ),
        );
      } else {
        // Try alternative format
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
    // Remove package: prefix and shorten paths
    if (path.startsWith('package:')) {
      return path;
    }
    // For file:// URIs, just show the filename and line
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

/// Renders a horizontal table (row-as-headers).
///
/// Unlike a regular table where headers are at the top,
/// this displays data with the first column as headers.
///
/// ```dart
/// final table = HorizontalTable(style: style);
/// print(table.render({
///   'Name': 'John Doe',
///   'Email': 'john@example.com',
///   'Role': 'Admin',
/// }));
/// ```
class HorizontalTable {
  HorizontalTable({
    required this.style,
    this.padding = 1,
    this.separator = '│',
  });

  final ArtisanStyle style;
  final int padding;
  final String separator;

  /// Renders a horizontal table from a map.
  String render(Map<String, Object?> data) {
    if (data.isEmpty) return '';

    final headers = data.keys.toList();
    final values = data.values.map((v) => v?.toString() ?? '').toList();

    final maxHeaderWidth = headers
        .map((h) => ArtisanStyle.visibleLength(h))
        .fold<int>(0, (m, v) => v > m ? v : m);

    final buffer = StringBuffer();
    final pad = ' ' * padding;

    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      final value = values[i];
      final headerPadding = maxHeaderWidth - ArtisanStyle.visibleLength(header);

      buffer.writeln(
        '$pad${style.info(header)}${' ' * headerPadding}$pad$separator$pad$value',
      );
    }

    return buffer.toString().trimRight();
  }

  /// Renders multiple rows as a horizontal table.
  String renderRows(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return '';

    // Get all unique keys
    final allKeys = <String>{};
    for (final row in rows) {
      allKeys.addAll(row.keys);
    }
    final headers = allKeys.toList();

    final maxHeaderWidth = headers
        .map((h) => ArtisanStyle.visibleLength(h))
        .fold<int>(0, (m, v) => v > m ? v : m);

    // Get max value width for each column
    final maxValueWidths = <int>[];
    for (final row in rows) {
      for (var i = 0; i < headers.length; i++) {
        final value = row[headers[i]]?.toString() ?? '';
        final width = ArtisanStyle.visibleLength(value);
        if (i >= maxValueWidths.length) {
          maxValueWidths.add(width);
        } else if (width > maxValueWidths[i]) {
          maxValueWidths[i] = width;
        }
      }
    }

    final buffer = StringBuffer();
    final pad = ' ' * padding;

    for (final header in headers) {
      final headerPadding = maxHeaderWidth - ArtisanStyle.visibleLength(header);
      buffer.write(
        '$pad${style.info(header)}${' ' * headerPadding}$pad$separator',
      );

      for (var i = 0; i < rows.length; i++) {
        final value = rows[i][header]?.toString() ?? '';
        final valuePadding =
            maxValueWidths[i] - ArtisanStyle.visibleLength(value);
        buffer.write('$pad$value${' ' * valuePadding}');
        if (i < rows.length - 1) {
          buffer.write(pad);
        }
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }
}

/// Styled block output (similar to Symfony's block()).
///
/// ```dart
/// final block = StyledBlock(style: style, terminalWidth: 80);
/// print(block.render(
///   'This is an important message!',
///   blockStyle: BlockStyle.error,
/// ));
/// ```
class StyledBlock {
  StyledBlock({
    required this.style,
    required this.terminalWidth,
    this.padding = 1,
  });

  final ArtisanStyle style;
  final int terminalWidth;
  final int padding;

  /// Renders a styled block.
  String render(
    Object message, {
    BlockStyle blockStyle = BlockStyle.info,
    String? prefix,
    bool large = false,
  }) {
    final lines = _normalizeLines(message);
    final buffer = StringBuffer();

    final blockColor = switch (blockStyle) {
      BlockStyle.info => style.info,
      BlockStyle.success => style.success,
      BlockStyle.warning => style.warning,
      BlockStyle.error => style.error,
      BlockStyle.note => style.muted,
    };

    final prefixText =
        prefix ??
        switch (blockStyle) {
          BlockStyle.info => '[INFO]',
          BlockStyle.success => '[OK]',
          BlockStyle.warning => '[WARNING]',
          BlockStyle.error => '[ERROR]',
          BlockStyle.note => '[NOTE]',
        };

    final pad = ' ' * padding;

    if (large) {
      // Large block with background
      final maxWidth = lines
          .map((l) => ArtisanStyle.visibleLength(l))
          .fold<int>(0, (m, v) => v > m ? v : m);
      final blockWidth = (maxWidth + padding * 2 + prefixText.length + 2).clamp(
        40,
        terminalWidth - 4,
      );

      buffer.writeln();
      buffer.writeln(blockColor(' ' * blockWidth));
      buffer.writeln(
        blockColor(
          '$pad$prefixText${' ' * (blockWidth - prefixText.length - padding)}',
        ),
      );
      for (final line in lines) {
        final fill =
            blockWidth - ArtisanStyle.visibleLength(line) - padding * 2;
        buffer.writeln(
          blockColor('$pad$line${' ' * (fill > 0 ? fill : 0)}$pad'),
        );
      }
      buffer.writeln(blockColor(' ' * blockWidth));
      buffer.writeln();
    } else {
      // Simple block
      buffer.writeln();
      for (final line in lines) {
        buffer.writeln('${blockColor(prefixText)} $line');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Renders a comment (dimmed/italic text).
  String comment(Object message) {
    final lines = _normalizeLines(message);
    final buffer = StringBuffer();

    for (final line in lines) {
      buffer.writeln(style.muted('// $line'));
    }

    return buffer.toString().trimRight();
  }

  List<String> _normalizeLines(Object message) {
    if (message is Iterable) {
      return message.map((e) => e.toString()).toList();
    }
    return message.toString().split('\n');
  }
}

/// Block styles for StyledBlock.
enum BlockStyle { info, success, warning, error, note }
