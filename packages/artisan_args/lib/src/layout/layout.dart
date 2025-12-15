/// Layout utilities for composing styled content blocks.
///
/// Provides functions for joining blocks horizontally or vertically,
/// and positioning content within containers.
///
/// ```dart
/// // Join blocks side by side
/// final dashboard = Layout.joinHorizontal(
///   VerticalAlign.top,
///   [leftPanel.render(), rightPanel.render()],
/// );
///
/// // Stack blocks vertically
/// final page = Layout.joinVertical(
///   HorizontalAlign.left,
///   [header.render(), content.render(), footer.render()],
/// );
///
/// // Center content in a container
/// final centered = Layout.place(
///   width: 80,
///   height: 24,
///   horizontal: HorizontalAlign.center,
///   vertical: VerticalAlign.center,
///   content: 'Welcome!',
/// );
/// ```
library;

import '../style/properties.dart';

/// Layout utilities for composing rendered blocks.
class Layout {
  Layout._();

  // ─────────────────────────────────────────────────────────────────────────────
  // Constants
  // ─────────────────────────────────────────────────────────────────────────────

  static final _ansiRegex = RegExp(r'\x1B\[[0-9;]*m');

  // ─────────────────────────────────────────────────────────────────────────────
  // String Utilities
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns the visible length of a string, ignoring ANSI escape codes.
  static int visibleLength(String text) {
    return text.replaceAll(_ansiRegex, '').length;
  }

  /// Strips all ANSI escape codes from a string.
  static String stripAnsi(String text) {
    return text.replaceAll(_ansiRegex, '');
  }

  /// Pads a string to a given width, respecting ANSI codes.
  ///
  /// The padding is added to the right by default.
  static String pad(String text, int width, [String char = ' ']) {
    final visible = visibleLength(text);
    if (visible >= width) return text;
    return '$text${char * (width - visible)}';
  }

  /// Pads a string to a given width on the left.
  static String padLeft(String text, int width, [String char = ' ']) {
    final visible = visibleLength(text);
    if (visible >= width) return text;
    return '${char * (width - visible)}$text';
  }

  /// Centers a string within a given width.
  static String center(String text, int width, [String char = ' ']) {
    final visible = visibleLength(text);
    if (visible >= width) return text;
    final total = width - visible;
    final left = total ~/ 2;
    final right = total - left;
    return '${char * left}$text${char * right}';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Alignment
  // ─────────────────────────────────────────────────────────────────────────────

  /// Aligns text within a given width.
  static String alignText(String text, int width, HorizontalAlign align) {
    switch (align) {
      case HorizontalAlign.left:
        return pad(text, width);
      case HorizontalAlign.center:
        return center(text, width);
      case HorizontalAlign.right:
        return padLeft(text, width);
    }
  }

  /// Aligns a list of lines within a given width.
  static List<String> alignLines(
    List<String> lines,
    int width,
    HorizontalAlign align,
  ) {
    return lines.map((line) => alignText(line, width, align)).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Joining
  // ─────────────────────────────────────────────────────────────────────────────

  /// Joins multiple blocks horizontally with vertical alignment.
  ///
  /// Each block is a multi-line string. Blocks are placed side by side
  /// and aligned according to [align].
  ///
  /// ```dart
  /// final result = Layout.joinHorizontal(
  ///   VerticalAlign.top,
  ///   [leftBlock, middleBlock, rightBlock],
  ///   gap: 2,  // Optional gap between blocks
  /// );
  /// ```
  static String joinHorizontal(
    VerticalAlign align,
    List<String> blocks, {
    int gap = 0,
    String gapChar = ' ',
  }) {
    if (blocks.isEmpty) return '';
    if (blocks.length == 1) return blocks.first;

    // Split each block into lines
    final blockLines = blocks.map((b) => b.split('\n')).toList();

    // Find the maximum height
    final maxHeight = blockLines
        .map((b) => b.length)
        .reduce((a, b) => a > b ? a : b);

    // Find the width of each block
    final widths = blockLines.map((lines) {
      if (lines.isEmpty) return 0;
      return lines.map(visibleLength).reduce((a, b) => a > b ? a : b);
    }).toList();

    // Pad each block to have the same height
    final paddedBlocks = <List<String>>[];
    for (var i = 0; i < blockLines.length; i++) {
      final lines = blockLines[i];
      final width = widths[i];
      final padded = _padBlockHeight(lines, maxHeight, width, align);
      paddedBlocks.add(padded);
    }

    // Ensure each line has consistent width
    final normalizedBlocks = <List<String>>[];
    for (var i = 0; i < paddedBlocks.length; i++) {
      final lines = paddedBlocks[i];
      final width = widths[i];
      normalizedBlocks.add(lines.map((l) => pad(l, width)).toList());
    }

    // Build the gap string
    final gapStr = gapChar * gap;

    // Join lines horizontally
    final result = <String>[];
    for (var row = 0; row < maxHeight; row++) {
      final rowParts = <String>[];
      for (var col = 0; col < normalizedBlocks.length; col++) {
        rowParts.add(normalizedBlocks[col][row]);
      }
      result.add(rowParts.join(gapStr));
    }

    return result.join('\n');
  }

  /// Joins multiple blocks vertically with horizontal alignment.
  ///
  /// Each block is a multi-line string. Blocks are stacked vertically
  /// and aligned according to [align].
  ///
  /// ```dart
  /// final result = Layout.joinVertical(
  ///   HorizontalAlign.center,
  ///   [header, content, footer],
  ///   gap: 1,  // Optional gap between blocks
  /// );
  /// ```
  static String joinVertical(
    HorizontalAlign align,
    List<String> blocks, {
    int gap = 0,
  }) {
    if (blocks.isEmpty) return '';
    if (blocks.length == 1) return blocks.first;

    // Split each block into lines
    final allLines = <List<String>>[];
    for (final block in blocks) {
      allLines.add(block.split('\n'));
    }

    // Find the maximum width
    var maxWidth = 0;
    for (final lines in allLines) {
      for (final line in lines) {
        final w = visibleLength(line);
        if (w > maxWidth) maxWidth = w;
      }
    }

    // Build result with aligned lines
    final result = <String>[];
    for (var i = 0; i < allLines.length; i++) {
      if (i > 0 && gap > 0) {
        // Add gap lines
        for (var g = 0; g < gap; g++) {
          result.add(' ' * maxWidth);
        }
      }

      // Add aligned lines from this block
      for (final line in allLines[i]) {
        result.add(alignText(line, maxWidth, align));
      }
    }

    return result.join('\n');
  }

  /// Pads a block to a given height with vertical alignment.
  static List<String> _padBlockHeight(
    List<String> lines,
    int targetHeight,
    int width,
    VerticalAlign align,
  ) {
    if (lines.length >= targetHeight) {
      return lines.take(targetHeight).toList();
    }

    final diff = targetHeight - lines.length;
    final emptyLine = ' ' * width;

    switch (align) {
      case VerticalAlign.top:
        return [...lines, ...List.filled(diff, emptyLine)];
      case VerticalAlign.center:
        final top = diff ~/ 2;
        final bottom = diff - top;
        return [
          ...List.filled(top, emptyLine),
          ...lines,
          ...List.filled(bottom, emptyLine),
        ];
      case VerticalAlign.bottom:
        return [...List.filled(diff, emptyLine), ...lines];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Placement
  // ─────────────────────────────────────────────────────────────────────────────

  /// Places content at a position within a container.
  ///
  /// Creates a box of the given [width] and [height], and positions
  /// the [content] according to the alignment parameters.
  ///
  /// ```dart
  /// final centered = Layout.place(
  ///   width: 80,
  ///   height: 24,
  ///   horizontal: HorizontalAlign.center,
  ///   vertical: VerticalAlign.center,
  ///   content: 'Hello, World!',
  /// );
  /// ```
  static String place({
    required int width,
    required int height,
    required HorizontalAlign horizontal,
    required VerticalAlign vertical,
    required String content,
    String fillChar = ' ',
  }) {
    final lines = content.split('\n');
    final contentHeight = lines.length;
    final contentWidth = lines.isEmpty
        ? 0
        : lines.map(visibleLength).reduce((a, b) => a > b ? a : b);

    // Ensure content fits
    final effectiveWidth = width > contentWidth ? width : contentWidth;
    final effectiveHeight = height > contentHeight ? height : contentHeight;

    // Align horizontally
    final alignedLines = lines
        .map((l) => alignText(l, effectiveWidth, horizontal))
        .toList();

    // Pad to width
    final paddedLines = alignedLines
        .map((l) => pad(l, effectiveWidth))
        .toList();

    // Align vertically
    final verticalPadded = _padBlockHeight(
      paddedLines,
      effectiveHeight,
      effectiveWidth,
      vertical,
    );

    // Replace empty lines with fill char if needed
    final result = verticalPadded.map((l) {
      if (l.trim().isEmpty && fillChar != ' ') {
        return fillChar * effectiveWidth;
      }
      return l;
    }).toList();

    return result.join('\n');
  }

  /// Places content within a width, respecting the given alignment.
  ///
  /// This is a simpler version of [place] that only handles width.
  static String placeWidth({
    required int width,
    required HorizontalAlign align,
    required String content,
  }) {
    final lines = content.split('\n');
    return lines.map((l) => alignText(l, width, align)).join('\n');
  }

  /// Places content within a height, respecting the given alignment.
  ///
  /// This is a simpler version of [place] that only handles height.
  static String placeHeight({
    required int height,
    required VerticalAlign align,
    required String content,
    String fillChar = ' ',
  }) {
    final lines = content.split('\n');
    final width = lines.isEmpty
        ? 0
        : lines.map(visibleLength).reduce((a, b) => a > b ? a : b);

    final padded = _padBlockHeight(lines, height, width, align);
    return padded.join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Sizing
  // ─────────────────────────────────────────────────────────────────────────────

  /// Gets the dimensions of a block of text.
  ///
  /// Returns a record with width and height.
  static ({int width, int height}) getSize(String content) {
    final lines = content.split('\n');
    final height = lines.length;
    final width = lines.isEmpty
        ? 0
        : lines.map(visibleLength).reduce((a, b) => a > b ? a : b);
    return (width: width, height: height);
  }

  /// Gets the width of a block of text (maximum line width).
  static int getWidth(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return 0;
    return lines.map(visibleLength).reduce((a, b) => a > b ? a : b);
  }

  /// Gets the height of a block of text (number of lines).
  static int getHeight(String content) {
    return content.split('\n').length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Truncation
  // ─────────────────────────────────────────────────────────────────────────────

  /// Truncates text to a maximum width, adding an ellipsis if needed.
  ///
  /// Handles ANSI codes properly (though imperfectly for mid-sequence truncation).
  static String truncate(String text, int maxWidth, {String ellipsis = '…'}) {
    final visible = visibleLength(text);
    if (visible <= maxWidth) return text;

    final ellipsisLen = ellipsis.length;
    final targetLen = maxWidth - ellipsisLen;
    if (targetLen <= 0) {
      return ellipsis.substring(0, maxWidth);
    }

    // Simple truncation - doesn't perfectly handle mid-ANSI truncation
    // For proper handling, we'd need to track ANSI state
    var currentLen = 0;
    var result = StringBuffer();
    var i = 0;

    while (i < text.length && currentLen < targetLen) {
      if (text[i] == '\x1B') {
        // Find end of ANSI sequence
        final end = text.indexOf('m', i);
        if (end != -1) {
          result.write(text.substring(i, end + 1));
          i = end + 1;
          continue;
        }
      }
      result.write(text[i]);
      currentLen++;
      i++;
    }

    // Add reset and ellipsis
    result.write('\x1B[0m$ellipsis');
    return result.toString();
  }

  /// Truncates each line of text to a maximum width.
  static String truncateLines(
    String content,
    int maxWidth, {
    String ellipsis = '…',
  }) {
    return content
        .split('\n')
        .map((l) => truncate(l, maxWidth, ellipsis: ellipsis))
        .join('\n');
  }

  /// Truncates text to a maximum height (number of lines).
  static String truncateHeight(
    String content,
    int maxHeight, {
    String? lastLineIndicator,
  }) {
    final lines = content.split('\n');
    if (lines.length <= maxHeight) return content;

    final truncated = lines.take(maxHeight).toList();
    if (lastLineIndicator != null && truncated.isNotEmpty) {
      truncated[truncated.length - 1] = lastLineIndicator;
    }
    return truncated.join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Wrapping
  // ─────────────────────────────────────────────────────────────────────────────

  /// Wraps text to a maximum width.
  ///
  /// Simple word wrapping that breaks on spaces.
  static String wrap(String text, int maxWidth) {
    if (maxWidth <= 0) return text;

    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = StringBuffer();
    var currentWidth = 0;

    for (final word in words) {
      final wordWidth = visibleLength(word);

      if (currentWidth == 0) {
        // Start of line
        currentLine.write(word);
        currentWidth = wordWidth;
      } else if (currentWidth + 1 + wordWidth <= maxWidth) {
        // Word fits on current line
        currentLine.write(' $word');
        currentWidth += 1 + wordWidth;
      } else {
        // Start new line
        lines.add(currentLine.toString());
        currentLine = StringBuffer(word);
        currentWidth = wordWidth;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine.toString());
    }

    return lines.join('\n');
  }

  /// Wraps each line of text to a maximum width.
  static String wrapLines(String content, int maxWidth) {
    return content.split('\n').map((l) => wrap(l, maxWidth)).join('\n');
  }
}
