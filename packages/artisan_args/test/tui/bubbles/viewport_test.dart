import 'package:artisan_args/src/tui/bubbles/viewport.dart';
import 'package:artisan_args/src/style/style.dart';
import 'package:artisan_args/src/tui/component.dart';
import 'package:artisan_args/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('ViewportModel', () {
    group('New', () {
      test('creates with default values', () {
        final viewport = ViewportModel();
        expect(viewport.width, 80);
        expect(viewport.height, 24);
        expect(viewport.yOffset, 0);
        expect(viewport.xOffset, 0);
      });

      test('creates with custom dimensions', () {
        final viewport = ViewportModel(width: 120, height: 30);
        expect(viewport.width, 120);
        expect(viewport.height, 30);
      });

      test('creates with mouse settings', () {
        final viewport = ViewportModel(
          mouseWheelEnabled: false,
          mouseWheelDelta: 5,
        );
        expect(viewport.mouseWheelEnabled, isFalse);
        expect(viewport.mouseWheelDelta, 5);
      });
    });

    group('SetContent', () {
      test('sets content lines', () {
        final viewport = ViewportModel(height: 5);
        final updated = viewport.setContent('line1\nline2\nline3');
        expect(updated.lines, ['line1', 'line2', 'line3']);
      });

      test('normalizes CRLF to LF', () {
        final viewport = ViewportModel(height: 5);
        final updated = viewport.setContent('line1\r\nline2\r\nline3');
        expect(updated.lines, ['line1', 'line2', 'line3']);
      });

      test('handles empty content', () {
        final viewport = ViewportModel();
        final updated = viewport.setContent('');
        expect(updated.lines, ['']);
      });

      test('adjusts offset when content becomes shorter', () {
        final viewport = ViewportModel(height: 3, yOffset: 10);
        final updated = viewport.setContent('line1\nline2');
        expect(updated.yOffset, lessThanOrEqualTo(updated.lines.length));
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final viewport = ViewportModel(height: 3).setContent('a\nb\nc\nd');
      ViewComponent model = viewport;
      final (updated, _) = model.update(const WindowSizeMsg(80, 24));
      expect(updated, isA<ViewportModel>());
    });

    group('SetYOffset', () {
      test('sets Y offset', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4\nline5\nline6');
        final updated = viewport.setYOffset(2);
        expect(updated.yOffset, 2);
      });

      test('clamps Y offset to max', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4');
        final updated = viewport.setYOffset(100);
        expect(updated.yOffset, 1); // max is lines - height = 4 - 3 = 1
      });

      test('clamps Y offset to 0', () {
        final viewport = ViewportModel(height: 3).setContent('line1\nline2');
        final updated = viewport.setYOffset(-5);
        expect(updated.yOffset, 0);
      });
    });

    group('SetXOffset', () {
      test('sets X offset', () {
        final viewport = ViewportModel(
          width: 10,
        ).setContent('this is a very long line that exceeds width');
        final updated = viewport.setXOffset(5);
        expect(updated.xOffset, 5);
      });
    });

    group('HorizontalStep', () {
      test('disables horizontal scrolling when 0', () {
        final viewport = ViewportModel(horizontalStep: 0);
        expect(viewport.horizontalStep, 0);
      });

      test('enables horizontal scrolling when positive', () {
        final viewport = ViewportModel(horizontalStep: 4);
        expect(viewport.horizontalStep, 4);
      });
    });

    group('ScrollDown', () {
      test('scrolls down by n lines', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4\nline5\nline6');
        final updated = viewport.scrollDown(2);
        expect(updated.yOffset, 2);
      });

      test('does not scroll past bottom', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4');
        final updated = viewport.scrollDown(100);
        expect(updated.yOffset, 1); // max offset
      });

      test('does nothing when already at bottom', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4').setYOffset(1);
        expect(viewport.atBottom, isTrue);
        final updated = viewport.scrollDown(1);
        expect(updated, viewport);
      });

      test('does nothing for 0 lines', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4');
        final updated = viewport.scrollDown(0);
        expect(updated, viewport);
      });
    });

    group('ScrollUp', () {
      test('scrolls up by n lines', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4\nline5\nline6').setYOffset(3);
        final updated = viewport.scrollUp(2);
        expect(updated.yOffset, 1);
      });

      test('does not scroll past top', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4').setYOffset(1);
        final updated = viewport.scrollUp(100);
        expect(updated.yOffset, 0);
      });

      test('does nothing when already at top', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4');
        expect(viewport.atTop, isTrue);
        final updated = viewport.scrollUp(1);
        expect(updated, viewport);
      });
    });

    group('ScrollLeft', () {
      test('scrolls left by n columns', () {
        final viewport = ViewportModel(
          width: 10,
          horizontalStep: 4,
        ).setContent('this is a very long line').setXOffset(10);
        final updated = viewport.scrollLeft(5);
        expect(updated.xOffset, 5);
      });
    });

    group('ScrollRight', () {
      test('scrolls right by n columns', () {
        final viewport = ViewportModel(
          width: 10,
          horizontalStep: 4,
        ).setContent('this is a very long line');
        final updated = viewport.scrollRight(5);
        expect(updated.xOffset, 5);
      });
    });

    group('PageDown', () {
      test('scrolls down by page height', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        final updated = viewport.pageDown();
        expect(updated.yOffset, 5);
      });

      test('does nothing when at bottom', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent('line1\nline2\nline3');
        expect(viewport.atBottom, isTrue);
        final updated = viewport.pageDown();
        expect(updated, viewport);
      });
    });

    group('PageUp', () {
      test('scrolls up by page height', () {
        final viewport = ViewportModel(height: 5)
            .setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'))
            .setYOffset(10);
        final updated = viewport.pageUp();
        expect(updated.yOffset, 5);
      });

      test('does nothing when at top', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.atTop, isTrue);
        final updated = viewport.pageUp();
        expect(updated, viewport);
      });
    });

    group('HalfPageDown', () {
      test('scrolls down by half page height', () {
        final viewport = ViewportModel(
          height: 10,
        ).setContent(List.generate(30, (i) => 'line${i + 1}').join('\n'));
        final updated = viewport.halfPageDown();
        expect(updated.yOffset, 5);
      });
    });

    group('HalfPageUp', () {
      test('scrolls up by half page height', () {
        final viewport = ViewportModel(height: 10)
            .setContent(List.generate(30, (i) => 'line${i + 1}').join('\n'))
            .setYOffset(10);
        final updated = viewport.halfPageUp();
        expect(updated.yOffset, 5);
      });
    });

    group('GotoTop', () {
      test('goes to top', () {
        final viewport = ViewportModel(height: 5)
            .setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'))
            .setYOffset(10);
        final updated = viewport.gotoTop();
        expect(updated.yOffset, 0);
      });

      test('does nothing when already at top', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.atTop, isTrue);
        final updated = viewport.gotoTop();
        expect(updated, viewport);
      });
    });

    group('GotoBottom', () {
      test('goes to bottom', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        final updated = viewport.gotoBottom();
        expect(updated.yOffset, 15); // 20 lines - 5 height = 15
      });
    });

    group('AtTop', () {
      test('returns true when at top', () {
        final viewport = ViewportModel(height: 5).setContent('line1\nline2');
        expect(viewport.atTop, isTrue);
      });

      test('returns false when not at top', () {
        final viewport = ViewportModel(height: 3)
            .setContent(List.generate(10, (i) => 'line${i + 1}').join('\n'))
            .setYOffset(2);
        expect(viewport.atTop, isFalse);
      });
    });

    group('AtBottom', () {
      test('returns true when at bottom', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4').setYOffset(1);
        expect(viewport.atBottom, isTrue);
      });

      test('returns false when not at bottom', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent(List.generate(10, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.atBottom, isFalse);
      });
    });

    group('ScrollPercent', () {
      test('returns 0 at top', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.scrollPercent, 0.0);
      });

      test('returns 1 at bottom', () {
        final viewport = ViewportModel(height: 5)
            .setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'))
            .gotoBottom();
        expect(viewport.scrollPercent, 1.0);
      });

      test('returns 1 when content fits in viewport', () {
        final viewport = ViewportModel(
          height: 10,
        ).setContent('line1\nline2\nline3');
        expect(viewport.scrollPercent, 1.0);
      });
    });

    group('VisibleLineCount', () {
      test('returns visible line count', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.visibleLineCount, 5);
      });

      test('returns line count when content is shorter than viewport', () {
        final viewport = ViewportModel(
          height: 10,
        ).setContent('line1\nline2\nline3');
        expect(viewport.visibleLineCount, 3);
      });
    });

    group('TotalLineCount', () {
      test('returns total line count', () {
        final viewport = ViewportModel().setContent(
          List.generate(20, (i) => 'line${i + 1}').join('\n'),
        );
        expect(viewport.totalLineCount, 20);
      });
    });

    group('View', () {
      test('returns visible lines', () {
        final viewport = ViewportModel(
          width: 20,
          height: 3,
        ).setContent('line1\nline2\nline3\nline4\nline5');
        final view = viewport.view();
        expect(view, contains('line1'));
        expect(view, contains('line2'));
        expect(view, contains('line3'));
        expect(view, isNot(contains('line4')));
      });

      test('pads lines to width', () {
        final viewport = ViewportModel(
          width: 10,
          height: 2,
        ).setContent('short\nline');
        final lines = viewport.view().split('\n');
        expect(lines[0].length, 10);
        expect(lines[1].length, 10);
      });

      test('pads height with empty lines', () {
        final viewport = ViewportModel(
          width: 5,
          height: 5,
        ).setContent('line1\nline2');
        final lines = viewport.view().split('\n');
        expect(lines.length, 5);
      });

      test('horizontal scrolling is grapheme-aware (combining marks)', () {
        final viewport = ViewportModel(
          width: 1,
          height: 1,
        ).setContent('e\u0301x');

        final scrolled = viewport.setXOffset(1);
        expect(Style.stripAnsi(scrolled.view()), equals('x'));
      });
    });

    group('CopyWith', () {
      test('creates copy with changed values', () {
        final viewport = ViewportModel(width: 80, height: 24);
        final copy = viewport.copyWith(width: 120);
        expect(copy.width, 120);
        expect(copy.height, 24);
        expect(viewport.width, 80);
      });

      test('preserves content on copy', () {
        final viewport = ViewportModel().setContent('hello\nworld');
        final copy = viewport.copyWith(height: 5);
        expect(copy.lines, ['hello', 'world']);
      });
    });

    group('Init', () {
      test('returns null', () {
        final viewport = ViewportModel();
        expect(viewport.init(), isNull);
      });
    });
  });

  group('ViewportKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = ViewportKeyMap();
      expect(keyMap.up.keys, isNotEmpty);
      expect(keyMap.down.keys, isNotEmpty);
      expect(keyMap.pageUp.keys, isNotEmpty);
      expect(keyMap.pageDown.keys, isNotEmpty);
    });

    test('shortHelp returns navigation bindings', () {
      final keyMap = ViewportKeyMap();
      final help = keyMap.shortHelp();
      expect(help.length, greaterThanOrEqualTo(4));
    });

    test('fullHelp returns grouped bindings', () {
      final keyMap = ViewportKeyMap();
      final help = keyMap.fullHelp();
      expect(help, isNotEmpty);
    });
  });
}
