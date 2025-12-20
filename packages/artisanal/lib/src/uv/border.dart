import 'cell.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';

/// UvBorder primitives.
///
/// Upstream: `third_party/ultraviolet/border.go`.
final class Side {
  const Side({
    this.content = '',
    this.style = const UvStyle(),
    this.link = const Link(),
  });

  final String content;
  final UvStyle style;
  final Link link;

  Side copyWith({String? content, UvStyle? style, Link? link}) => Side(
    content: content ?? this.content,
    style: style ?? this.style,
    link: link ?? this.link,
  );
}

final class UvBorder implements Drawable {
  const UvBorder({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final Side top;
  final Side bottom;
  final Side left;
  final Side right;
  final Side topLeft;
  final Side topRight;
  final Side bottomLeft;
  final Side bottomRight;

  @override
  Rectangle bounds() => const Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);

  /// Returns a new [UvBorder] with [style] applied to all sides.
  ///
  /// Upstream: `UvBorder.UvStyle`.
  UvBorder style(UvStyle style) => UvBorder(
    top: top.copyWith(style: style),
    bottom: bottom.copyWith(style: style),
    left: left.copyWith(style: style),
    right: right.copyWith(style: style),
    topLeft: topLeft.copyWith(style: style),
    topRight: topRight.copyWith(style: style),
    bottomLeft: bottomLeft.copyWith(style: style),
    bottomRight: bottomRight.copyWith(style: style),
  );

  /// Returns a new [UvBorder] with [link] applied to all sides.
  ///
  /// Upstream: `UvBorder.Link`.
  UvBorder link(Link link) => UvBorder(
    top: top.copyWith(link: link),
    bottom: bottom.copyWith(link: link),
    left: left.copyWith(link: link),
    right: right.copyWith(link: link),
    topLeft: topLeft.copyWith(link: link),
    topRight: topRight.copyWith(link: link),
    bottomLeft: bottomLeft.copyWith(link: link),
    bottomRight: bottomRight.copyWith(link: link),
  );

  @override
  void draw(Screen screen, Rectangle area) {
    for (var y = area.minY; y < area.maxY; y++) {
      for (var x = area.minX; x < area.maxX; x++) {
        Side side;
        if (y == area.minY && x == area.minX) {
          side = topLeft;
        } else if (y == area.minY && x == area.maxX - 1) {
          side = topRight;
        } else if (y == area.maxY - 1 && x == area.minX) {
          side = bottomLeft;
        } else if (y == area.maxY - 1 && x == area.maxX - 1) {
          side = bottomRight;
        } else if (y == area.minY) {
          side = top;
        } else if (y == area.maxY - 1) {
          side = bottom;
        } else if (x == area.minX) {
          side = left;
        } else if (x == area.maxX - 1) {
          side = right;
        } else {
          continue;
        }

        final cell = Cell.newCell(screen.widthMethod(), side.content)
          ..style = side.style
          ..link = side.link;
        screen.setCell(x, y, cell);
      }
    }
  }
}

// Constructors (parity with Ultraviolet).

UvBorder normalBorder() => const UvBorder(
  top: Side(content: '─'),
  bottom: Side(content: '─'),
  left: Side(content: '│'),
  right: Side(content: '│'),
  topLeft: Side(content: '┌'),
  topRight: Side(content: '┐'),
  bottomLeft: Side(content: '└'),
  bottomRight: Side(content: '┘'),
);

UvBorder roundedBorder() => const UvBorder(
  top: Side(content: '─'),
  bottom: Side(content: '─'),
  left: Side(content: '│'),
  right: Side(content: '│'),
  topLeft: Side(content: '╭'),
  topRight: Side(content: '╮'),
  bottomLeft: Side(content: '╰'),
  bottomRight: Side(content: '╯'),
);

UvBorder blockBorder() => const UvBorder(
  top: Side(content: '█'),
  bottom: Side(content: '█'),
  left: Side(content: '█'),
  right: Side(content: '█'),
  topLeft: Side(content: '█'),
  topRight: Side(content: '█'),
  bottomLeft: Side(content: '█'),
  bottomRight: Side(content: '█'),
);

UvBorder outerHalfBlockBorder() => const UvBorder(
  top: Side(content: '▀'),
  bottom: Side(content: '▄'),
  left: Side(content: '▌'),
  right: Side(content: '▐'),
  topLeft: Side(content: '▛'),
  topRight: Side(content: '▜'),
  bottomLeft: Side(content: '▙'),
  bottomRight: Side(content: '▟'),
);

UvBorder innerHalfBlockBorder() => const UvBorder(
  top: Side(content: '▄'),
  bottom: Side(content: '▀'),
  left: Side(content: '▐'),
  right: Side(content: '▌'),
  topLeft: Side(content: '▗'),
  topRight: Side(content: '▖'),
  bottomLeft: Side(content: '▝'),
  bottomRight: Side(content: '▘'),
);

UvBorder thickBorder() => const UvBorder(
  top: Side(content: '━'),
  bottom: Side(content: '━'),
  left: Side(content: '┃'),
  right: Side(content: '┃'),
  topLeft: Side(content: '┏'),
  topRight: Side(content: '┓'),
  bottomLeft: Side(content: '┗'),
  bottomRight: Side(content: '┛'),
);

UvBorder doubleBorder() => const UvBorder(
  top: Side(content: '═'),
  bottom: Side(content: '═'),
  left: Side(content: '║'),
  right: Side(content: '║'),
  topLeft: Side(content: '╔'),
  topRight: Side(content: '╗'),
  bottomLeft: Side(content: '╚'),
  bottomRight: Side(content: '╝'),
);

UvBorder hiddenBorder() => const UvBorder(
  top: Side(content: ' '),
  bottom: Side(content: ' '),
  left: Side(content: ' '),
  right: Side(content: ' '),
  topLeft: Side(content: ' '),
  topRight: Side(content: ' '),
  bottomLeft: Side(content: ' '),
  bottomRight: Side(content: ' '),
);

UvBorder markdownBorder() => const UvBorder(
  top: Side(content: ''),
  bottom: Side(content: ''),
  left: Side(content: '|'),
  right: Side(content: '|'),
  topLeft: Side(content: '|'),
  topRight: Side(content: '|'),
  bottomLeft: Side(content: '|'),
  bottomRight: Side(content: '|'),
);

UvBorder asciiBorder() => const UvBorder(
  top: Side(content: '-'),
  bottom: Side(content: '-'),
  left: Side(content: '|'),
  right: Side(content: '|'),
  topLeft: Side(content: '+'),
  topRight: Side(content: '+'),
  bottomLeft: Side(content: '+'),
  bottomRight: Side(content: '+'),
);
