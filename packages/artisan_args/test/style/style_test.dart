import 'package:artisan_args/artisan_args.dart';
import 'package:test/test.dart';

void main() {
  group('Style', () {
    group('fluent chaining', () {
      test('basic chaining works', () {
        final style = Style().bold().italic().underline();

        expect(style.isBold, isTrue);
        expect(style.isItalic, isTrue);
        expect(style.isUnderline, isTrue);
      });

      test('color chaining works', () {
        final style = Style().foreground(Colors.green).background(Colors.black);

        expect(style.getForeground, equals(Colors.green));
        expect(style.getBackground, equals(Colors.black));
      });

      test('dimension chaining works', () {
        final style = Style().width(40).height(10);

        expect(style.getWidth, equals(40));
        expect(style.getHeight, equals(10));
      });

      test('padding chaining works', () {
        final style = Style().padding(1, 2);

        expect(style.getPadding.top, equals(1));
        expect(style.getPadding.bottom, equals(1));
        expect(style.getPadding.left, equals(2));
        expect(style.getPadding.right, equals(2));
      });

      test('margin chaining works', () {
        final style = Style().margin(2);

        expect(style.getMargin.top, equals(2));
        expect(style.getMargin.bottom, equals(2));
        expect(style.getMargin.left, equals(2));
        expect(style.getMargin.right, equals(2));
      });

      test('border chaining works', () {
        final style = Style().border(Border.rounded);

        expect(style.getBorder, equals(Border.rounded));
      });

      test('all methods return Style for chaining', () {
        // This test ensures the fluent API works as expected
        final style = Style()
            .bold()
            .italic()
            .underline()
            .strikethrough()
            .dim()
            .inverse()
            .foreground(Colors.red)
            .background(Colors.white)
            .width(80)
            .height(24)
            .padding(1)
            .margin(2)
            .border(Border.normal)
            .align(HorizontalAlign.center);

        expect(style, isA<Style>());
      });
    });

    group('property tracking', () {
      test('unset properties are not tracked', () {
        final style = Style();

        expect(style.isBold, isFalse);
        expect(style.getForeground, isNull);
        expect(style.getWidth, equals(0));
      });

      test('set properties are tracked', () {
        final style = Style().bold();

        expect(style.isBold, isTrue);
        expect(style.hasTextAttributes, isTrue);
      });

      test('hasTextAttributes returns true when any text attribute is set', () {
        expect(Style().bold().hasTextAttributes, isTrue);
        expect(Style().italic().hasTextAttributes, isTrue);
        expect(Style().underline().hasTextAttributes, isTrue);
        expect(Style().strikethrough().hasTextAttributes, isTrue);
        expect(Style().dim().hasTextAttributes, isTrue);
        expect(Style().inverse().hasTextAttributes, isTrue);
      });

      test('hasColors returns true when colors are set', () {
        expect(Style().foreground(Colors.red).hasColors, isTrue);
        expect(Style().background(Colors.blue).hasColors, isTrue);
        expect(Style().hasColors, isFalse);
      });

      test('hasSpacing returns true when padding or margin is set', () {
        expect(Style().padding(1).hasSpacing, isTrue);
        expect(Style().margin(1).hasSpacing, isTrue);
        expect(Style().paddingTop(1).hasSpacing, isTrue);
        expect(Style().marginLeft(2).hasSpacing, isTrue);
        expect(Style().hasSpacing, isFalse);
      });
    });

    group('unset methods', () {
      test('unsetBold clears bold', () {
        final style = Style().bold().unsetBold();

        expect(style.isBold, isFalse);
      });

      test('unsetForeground clears foreground', () {
        final style = Style().foreground(Colors.red).unsetForeground();

        expect(style.getForeground, isNull);
      });

      test('unsetWidth clears width', () {
        final style = Style().width(40).unsetWidth();

        expect(style.getWidth, equals(0));
      });

      test('unsetPadding clears all padding', () {
        final style = Style().padding(2).unsetPadding();

        expect(style.getPadding.isZero, isTrue);
      });

      test('unsetMargin clears all margin', () {
        final style = Style().margin(2).unsetMargin();

        expect(style.getMargin.isZero, isTrue);
      });

      test('unsetBorder clears border', () {
        final style = Style().border(Border.rounded).unsetBorder();

        expect(style.getBorder, isNull);
      });
    });

    group('copy', () {
      test('copy creates independent instance', () {
        final original = Style().bold().foreground(Colors.green);
        final copied = original.copy();

        // Copied has same values
        expect(copied.isBold, isTrue);
        expect(copied.getForeground, equals(Colors.green));

        // Modifying copied doesn't affect original
        copied.italic().foreground(Colors.red);
        expect(original.isItalic, isFalse);
        expect(original.getForeground, equals(Colors.green));
      });

      test('copy preserves all properties', () {
        final original = Style()
            .bold()
            .italic()
            .foreground(Colors.cyan)
            .background(Colors.black)
            .width(60)
            .padding(2)
            .margin(1)
            .border(Border.thick)
            .align(HorizontalAlign.right);

        final copied = original.copy();

        expect(copied.isBold, equals(original.isBold));
        expect(copied.isItalic, equals(original.isItalic));
        expect(copied.getForeground, equals(original.getForeground));
        expect(copied.getBackground, equals(original.getBackground));
        expect(copied.getWidth, equals(original.getWidth));
        expect(copied.getPadding, equals(original.getPadding));
        expect(copied.getMargin, equals(original.getMargin));
        expect(copied.getBorder, equals(original.getBorder));
        expect(copied.getAlign, equals(original.getAlign));
      });
    });

    group('inherit', () {
      test('inherit copies explicitly set properties', () {
        final base = Style().foreground(Colors.white).padding(1);
        final override = Style().bold().foreground(Colors.cyan);

        base.inherit(override);

        // Bold was set in override, so it's inherited
        expect(base.isBold, isTrue);
        // Foreground was set in override, so it's overwritten
        expect(base.getForeground, equals(Colors.cyan));
        // Padding was not in override, so it stays
        expect(base.getPadding.top, equals(1));
      });

      test('inherit only copies set properties', () {
        final base = Style().bold().foreground(Colors.red);
        final override = Style().italic(); // Only italic is set

        base.inherit(override);

        // Bold stays from base
        expect(base.isBold, isTrue);
        // Italic is inherited
        expect(base.isItalic, isTrue);
        // Foreground stays from base
        expect(base.getForeground, equals(Colors.red));
      });

      test('inherit does not copy unset properties', () {
        final base = Style().foreground(Colors.green);
        final override = Style(); // Nothing set

        base.inherit(override);

        // Foreground stays
        expect(base.getForeground, equals(Colors.green));
      });

      test('inherit returns this for chaining', () {
        final style = Style().inherit(Style().bold());

        expect(style, isA<Style>());
        expect(style.isBold, isTrue);
      });
    });

    group('render', () {
      test('render returns text when no styling', () {
        final style = Style();
        style.colorProfile = ColorProfile.ascii;

        expect(style.render('Hello'), equals('Hello'));
      });

      test('render applies ANSI codes for colors', () {
        final style = Style().foreground(Colors.red);
        style.colorProfile = ColorProfile.trueColor;

        final result = style.render('Hello');

        // Should contain ANSI escape sequences
        expect(result, contains('\x1B['));
        expect(result, contains('Hello'));
      });

      test('render applies text attributes', () {
        final style = Style().bold();
        style.colorProfile = ColorProfile.trueColor;

        final result = style.render('Hello');

        // Should contain ANSI bold sequence
        expect(result, contains('\x1B['));
        expect(result, contains('Hello'));
      });

      test('render applies padding', () {
        final style = Style().padding(1);
        style.colorProfile = ColorProfile.ascii;

        final result = style.render('Hi');

        // Should have empty lines for vertical padding
        expect(result.split('\n').length, greaterThan(1));
      });

      test('render applies width with alignment', () {
        final style = Style().width(10).align(HorizontalAlign.center);
        style.colorProfile = ColorProfile.ascii;

        final result = style.render('Hi');

        // "Hi" centered in 10 chars = "    Hi    "
        expect(Style.visibleLength(result), equals(10));
      });

      test('render applies border', () {
        final style = Style().border(Border.ascii);
        style.colorProfile = ColorProfile.ascii;

        final result = style.render('X');

        expect(result, contains('+'));
        expect(result, contains('-'));
        expect(result, contains('|'));
      });

      test('render applies transform', () {
        final style = Style().transform((s) => s.toUpperCase());
        style.colorProfile = ColorProfile.ascii;

        final result = style.render('hello');

        expect(result, contains('HELLO'));
      });

      test('inline mode skips layout processing', () {
        final style = Style().inline().bold().padding(5).margin(5);
        style.colorProfile = ColorProfile.trueColor;

        final result = style.render('Test');

        // Inline mode should not add padding/margin lines
        expect(result.split('\n').length, equals(1));
      });
    });

    group('visibleLength', () {
      test('returns correct length for plain text', () {
        expect(Style.visibleLength('Hello'), equals(5));
      });

      test('ignores ANSI codes', () {
        const ansiText = '\x1B[1;32mHello\x1B[0m';
        expect(Style.visibleLength(ansiText), equals(5));
      });

      test('handles empty string', () {
        expect(Style.visibleLength(''), equals(0));
      });
    });
  });

  group('Padding', () {
    test('all creates uniform padding', () {
      final p = Padding.all(2);

      expect(p.top, equals(2));
      expect(p.right, equals(2));
      expect(p.bottom, equals(2));
      expect(p.left, equals(2));
    });

    test('symmetric creates vertical/horizontal padding', () {
      final p = Padding.symmetric(vertical: 1, horizontal: 3);

      expect(p.top, equals(1));
      expect(p.bottom, equals(1));
      expect(p.left, equals(3));
      expect(p.right, equals(3));
    });

    test('only creates per-side padding', () {
      final p = Padding.only(top: 1, left: 2);

      expect(p.top, equals(1));
      expect(p.left, equals(2));
      expect(p.bottom, equals(0));
      expect(p.right, equals(0));
    });

    test('isZero returns true for zero padding', () {
      expect(Padding.zero.isZero, isTrue);
      expect(Padding.all(1).isZero, isFalse);
    });

    test('horizontal returns sum of left and right', () {
      expect(Padding(left: 2, right: 3).horizontal, equals(5));
    });

    test('vertical returns sum of top and bottom', () {
      expect(Padding(top: 1, bottom: 4).vertical, equals(5));
    });

    test('equality works', () {
      expect(Padding.all(2), equals(Padding.all(2)));
      expect(Padding.all(1), isNot(equals(Padding.all(2))));
    });
  });

  group('Margin', () {
    test('all creates uniform margin', () {
      final m = Margin.all(3);

      expect(m.top, equals(3));
      expect(m.right, equals(3));
      expect(m.bottom, equals(3));
      expect(m.left, equals(3));
    });

    test('symmetric creates vertical/horizontal margin', () {
      final m = Margin.symmetric(vertical: 2, horizontal: 4);

      expect(m.top, equals(2));
      expect(m.bottom, equals(2));
      expect(m.left, equals(4));
      expect(m.right, equals(4));
    });

    test('isZero returns true for zero margin', () {
      expect(Margin.zero.isZero, isTrue);
      expect(Margin.all(1).isZero, isFalse);
    });
  });

  group('Align', () {
    test('preset alignments exist', () {
      expect(Align.topLeft.horizontal, equals(HorizontalAlign.left));
      expect(Align.topLeft.vertical, equals(VerticalAlign.top));

      expect(Align.center.horizontal, equals(HorizontalAlign.center));
      expect(Align.center.vertical, equals(VerticalAlign.center));

      expect(Align.bottomRight.horizontal, equals(HorizontalAlign.right));
      expect(Align.bottomRight.vertical, equals(VerticalAlign.bottom));
    });

    test('position extension returns correct values', () {
      expect(HorizontalAlign.left.position, equals(0.0));
      expect(HorizontalAlign.center.position, equals(0.5));
      expect(HorizontalAlign.right.position, equals(1.0));

      expect(VerticalAlign.top.position, equals(0.0));
      expect(VerticalAlign.center.position, equals(0.5));
      expect(VerticalAlign.bottom.position, equals(1.0));
    });
  });

  group('Colors', () {
    test('semantic colors exist', () {
      expect(Colors.success, isA<Color>());
      expect(Colors.error, isA<Color>());
      expect(Colors.warning, isA<Color>());
      expect(Colors.info, isA<Color>());
      expect(Colors.muted, isA<Color>());
    });

    test('named colors exist', () {
      expect(Colors.red, isA<Color>());
      expect(Colors.green, isA<Color>());
      expect(Colors.blue, isA<Color>());
      expect(Colors.yellow, isA<Color>());
      expect(Colors.cyan, isA<Color>());
      expect(Colors.magenta, isA<Color>());
      expect(Colors.white, isA<Color>());
      expect(Colors.black, isA<Color>());
    });

    test('factory methods work', () {
      expect(Colors.hex('#ff0000'), isA<BasicColor>());
      expect(Colors.ansi(196), isA<AnsiColor>());
      expect(Colors.rgb(255, 128, 0), isA<BasicColor>());
      expect(
        Colors.adaptive(light: Colors.black, dark: Colors.white),
        isA<AdaptiveColor>(),
      );
    });

    test('none is NoColor', () {
      expect(Colors.none, isA<NoColor>());
    });
  });

  group('Border', () {
    test('preset borders exist', () {
      expect(Border.normal.topLeft, equals('┌'));
      expect(Border.rounded.topLeft, equals('╭'));
      expect(Border.thick.topLeft, equals('┏'));
      expect(Border.double.topLeft, equals('╔'));
      expect(Border.ascii.topLeft, equals('+'));
      expect(Border.hidden.topLeft, equals(' '));
    });

    test('isVisible returns correct value', () {
      expect(Border.normal.isVisible, isTrue);
      expect(Border.none.isVisible, isFalse);
    });

    test('buildTop creates correct string', () {
      expect(Border.ascii.buildTop(5), equals('+-----+'));
    });

    test('buildBottom creates correct string', () {
      expect(Border.ascii.buildBottom(5), equals('+-----+'));
    });

    test('wrapLine wraps content with borders', () {
      expect(Border.ascii.wrapLine('test'), equals('|test|'));
    });

    test('equality works', () {
      expect(Border.rounded, equals(Border.rounded));
      expect(Border.rounded, isNot(equals(Border.normal)));
    });
  });

  group('BorderSides', () {
    test('all shows all sides', () {
      expect(BorderSides.all.top, isTrue);
      expect(BorderSides.all.bottom, isTrue);
      expect(BorderSides.all.left, isTrue);
      expect(BorderSides.all.right, isTrue);
    });

    test('none shows no sides', () {
      expect(BorderSides.none.top, isFalse);
      expect(BorderSides.none.bottom, isFalse);
      expect(BorderSides.none.left, isFalse);
      expect(BorderSides.none.right, isFalse);
    });

    test('horizontal shows only top and bottom', () {
      expect(BorderSides.horizontal.top, isTrue);
      expect(BorderSides.horizontal.bottom, isTrue);
      expect(BorderSides.horizontal.left, isFalse);
      expect(BorderSides.horizontal.right, isFalse);
    });

    test('hasAny returns correct value', () {
      expect(BorderSides.all.hasAny, isTrue);
      expect(BorderSides.none.hasAny, isFalse);
      expect(BorderSides.topOnly.hasAny, isTrue);
    });
  });

  group('BasicColor', () {
    test('identifies hex colors', () {
      expect(BasicColor('#ff0000').isHex, isTrue);
      expect(BasicColor('ff0000').isHex, isTrue);
      expect(BasicColor('f00').isHex, isTrue);
      expect(BasicColor('196').isHex, isFalse);
    });

    test('toAnsi returns empty for ascii profile', () {
      final color = BasicColor('#ff0000');
      expect(color.toAnsi(ColorProfile.ascii), isEmpty);
    });

    test('toAnsi returns escape sequence for trueColor', () {
      final color = BasicColor('#ff0000');
      final ansi = color.toAnsi(ColorProfile.trueColor);
      expect(ansi, startsWith('\x1B['));
    });

    test('equality works', () {
      expect(BasicColor('#ff0000'), equals(BasicColor('#ff0000')));
      expect(BasicColor('#ff0000'), isNot(equals(BasicColor('#00ff00'))));
    });
  });

  group('AnsiColor', () {
    test('produces foreground ANSI sequence', () {
      final color = AnsiColor(196);
      final ansi = color.toAnsi(ColorProfile.ansi256);
      expect(ansi, equals('\x1B[38;5;196m'));
    });

    test('produces background ANSI sequence', () {
      final color = AnsiColor(196);
      final ansi = color.toAnsi(ColorProfile.ansi256, background: true);
      expect(ansi, equals('\x1B[48;5;196m'));
    });

    test('returns empty for ascii profile', () {
      final color = AnsiColor(196);
      expect(color.toAnsi(ColorProfile.ascii), isEmpty);
    });
  });

  group('AdaptiveColor', () {
    test('uses dark variant on dark background', () {
      final color = AdaptiveColor(
        light: BasicColor('#000000'),
        dark: BasicColor('#ffffff'),
      );

      final ansi = color.toAnsi(
        ColorProfile.trueColor,
        hasDarkBackground: true,
      );
      // Should use white (dark variant)
      expect(ansi, isNotEmpty);
    });

    test('uses light variant on light background', () {
      final color = AdaptiveColor(
        light: BasicColor('#000000'),
        dark: BasicColor('#ffffff'),
      );

      final ansi = color.toAnsi(
        ColorProfile.trueColor,
        hasDarkBackground: false,
      );
      // Should use black (light variant)
      expect(ansi, isNotEmpty);
    });
  });

  group('CompleteColor', () {
    test('uses trueColor for trueColor profile', () {
      final color = CompleteColor(
        trueColor: '#ff0000',
        ansi256: '196',
        ansi: '1',
      );

      final ansi = color.toAnsi(ColorProfile.trueColor);
      expect(ansi, isNotEmpty);
    });

    test('uses ansi256 for ansi256 profile', () {
      final color = CompleteColor(
        trueColor: '#ff0000',
        ansi256: '196',
        ansi: '1',
      );

      final ansi = color.toAnsi(ColorProfile.ansi256);
      expect(ansi, contains('196'));
    });

    test('uses ansi for ansi profile', () {
      final color = CompleteColor(
        trueColor: '#ff0000',
        ansi256: '196',
        ansi: '1',
      );

      final ansi = color.toAnsi(ColorProfile.ansi);
      expect(ansi, contains('31')); // 30 + 1 = 31 (red)
    });
  });

  group('NoColor', () {
    test('toAnsi returns empty string', () {
      expect(NoColor().toAnsi(ColorProfile.trueColor), isEmpty);
    });

    test('equality works', () {
      expect(NoColor(), equals(NoColor()));
    });
  });
}
