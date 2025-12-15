import 'dart:io';
import 'package:artisan_args/artisan_args.dart';
import 'package:test/test.dart';

void main() {
  ComponentContext createContext({
    ColorProfile profile = ColorProfile.ascii,
    bool darkBackground = true,
  }) {
    return ComponentContext(
      stdout: stdout,
      stdin: stdin,
      renderer: StringRenderer(
        colorProfile: profile,
        hasDarkBackground: darkBackground,
      ),
    );
  }

  group('ListEnumerator', () {
    test('fixed enumerator returns same symbol', () {
      final enumerator = ListEnumerator.fixed('*');
      expect(enumerator(0), equals('*'));
      expect(enumerator(1), equals('*'));
    });

    test('bullet preset returns •', () {
      expect(ListEnumerator.bullet(0), equals('•'));
    });

    test('arabic preset returns numbers', () {
      expect(ListEnumerator.arabic(0), equals('1.'));
      expect(ListEnumerator.arabic(1), equals('2.'));
      expect(ListEnumerator.arabic(9), equals('10.'));
    });

    test('alphabet preset returns letters', () {
      expect(ListEnumerator.alphabet(0), equals('a.'));
      expect(ListEnumerator.alphabet(1), equals('b.'));
      expect(ListEnumerator.alphabet(25), equals('z.'));
      expect(ListEnumerator.alphabet(26), equals('aa.'));
    });

    test('roman preset returns roman numerals', () {
      expect(ListEnumerator.roman(0), equals('I.'));
      expect(ListEnumerator.roman(1), equals('II.'));
      expect(ListEnumerator.roman(3), equals('IV.'));
      expect(ListEnumerator.roman(9), equals('X.'));
    });
  });

  group('BulletList', () {
    test('renders default bullets', () {
      const list = BulletList(items: ['Item 1', 'Item 2']);
      final result = list.build(createContext());

      expect(result.output, contains('• Item 1'));
      expect(result.output, contains('• Item 2'));
    });

    test('respects custom bullet', () {
      const list = BulletList(items: ['Item 1'], bullet: '*');
      final result = list.build(createContext());

      expect(result.output, contains('* Item 1'));
    });

    test('respects custom enumerator', () {
      final list = BulletList(
        items: ['Item 1'],
        enumerator: ListEnumerator.fixed('>'),
      );
      final result = list.build(createContext());

      expect(result.output, contains('> Item 1'));
      // Custom enumerator should override bullet parameter if used logic correctly
      expect(result.output, isNot(contains('•')));
    });

    test('itemStyleFunc applies styles', () {
      final list = BulletList(
        items: ['Normal', 'Bold'],
        itemStyleFunc: (index, item) {
          if (item == 'Bold') return Style().bold();
          return null;
        },
      );
      final result = list.build(createContext(profile: ColorProfile.trueColor));

      expect(result.output, contains('Normal'));
      expect(result.output, contains('\x1B[1mBold\x1B[22m'));
    });
  });

  group('NumberedList', () {
    test('renders arabic numbers by default', () {
      const list = NumberedList(items: ['Item 1', 'Item 2']);
      final result = list.build(createContext());

      expect(result.output, contains('1. Item 1'));
      expect(result.output, contains('2. Item 2'));
    });

    test('respects startAt', () {
      const list = NumberedList(items: ['Item 1'], startAt: 5);
      final result = list.build(createContext());

      expect(result.output, contains('5. Item 1'));
    });

    test('respects custom enumerator (roman)', () {
      final list = NumberedList(
        items: ['Item 1', 'Item 2'],
        enumerator: ListEnumerator.roman,
      );
      final result = list.build(createContext());

      expect(result.output, contains('I. Item 1'));
      expect(result.output, contains('II. Item 2'));
    });

    test('pads symbols correctly', () {
      // 10 items, last one is 10. (length 3). First is 1. (length 2).
      // Should pad 1. to " 1." (length 3)
      final items = List.generate(10, (i) => 'Item ${i + 1}');
      final list = NumberedList(items: items);
      final result = list.build(createContext());

      expect(result.output, contains(' 1. Item 1'));
      expect(result.output, contains('10. Item 10'));
    });

    test('itemStyleFunc applies styles', () {
      final list = NumberedList(
        items: ['Italic'],
        itemStyleFunc: (index, item) => Style().italic(),
      );
      final result = list.build(createContext(profile: ColorProfile.trueColor));

      expect(result.output, contains('\x1B[3mItalic\x1B[23m'));
    });
  });
}
