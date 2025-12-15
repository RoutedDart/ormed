import 'dart:io';
import 'package:artisan_args/artisan_args.dart';
import 'package:test/test.dart';

void main() {
  group('TreeEnumerator', () {
    group('presets', () {
      test('normal preset has correct characters', () {
        expect(TreeEnumerator.normal.pipe, equals('│'));
        expect(TreeEnumerator.normal.tee, equals('├'));
        expect(TreeEnumerator.normal.elbow, equals('└'));
        expect(TreeEnumerator.normal.dash, equals('──'));
      });

      test('rounded preset has curved elbow', () {
        expect(TreeEnumerator.rounded.elbow, equals('╰'));
        expect(TreeEnumerator.rounded.pipe, equals('│'));
      });

      test('ascii preset uses only ASCII characters', () {
        expect(TreeEnumerator.ascii.pipe, equals('|'));
        expect(TreeEnumerator.ascii.tee, equals('+'));
        expect(TreeEnumerator.ascii.elbow, equals('`'));
        expect(TreeEnumerator.ascii.dash, equals('--'));
      });

      test('bullet preset uses bullets', () {
        expect(TreeEnumerator.bullet.tee, equals('•'));
        expect(TreeEnumerator.bullet.elbow, equals('•'));
      });

      test('arrow preset uses arrows', () {
        expect(TreeEnumerator.arrow.tee, equals('→'));
        expect(TreeEnumerator.arrow.elbow, equals('→'));
      });

      test('dash preset uses dashes', () {
        expect(TreeEnumerator.dash_.tee, equals('-'));
        expect(TreeEnumerator.dash_.elbow, equals('-'));
      });
    });

    group('equality', () {
      test('same presets are equal', () {
        expect(TreeEnumerator.normal, equals(TreeEnumerator.normal));
        expect(TreeEnumerator.rounded, equals(TreeEnumerator.rounded));
      });

      test('different presets are not equal', () {
        expect(TreeEnumerator.normal, isNot(equals(TreeEnumerator.rounded)));
        expect(TreeEnumerator.ascii, isNot(equals(TreeEnumerator.bullet)));
      });

      test('custom enumerator equals identical custom', () {
        const a = TreeEnumerator(pipe: '|', tee: '+', elbow: 'L', dash: '-');
        const b = TreeEnumerator(pipe: '|', tee: '+', elbow: 'L', dash: '-');
        expect(a, equals(b));
      });
    });

    test('toString includes characters', () {
      final str = TreeEnumerator.normal.toString();
      expect(str, contains('TreeEnumerator'));
      expect(str, contains('pipe'));
    });
  });

  group('Tree (fluent builder)', () {
    group('basic construction', () {
      test('creates empty tree', () {
        final tree = Tree();
        expect(tree.render(), isEmpty);
      });

      test('creates tree with root', () {
        final tree = Tree().root('Project');
        final result = tree.render();

        expect(result, equals('Project'));
      });

      test('creates tree with root and children', () {
        final tree = Tree().root('Project').child('README.md').child('src/');

        final result = tree.render();

        expect(result, contains('Project'));
        expect(result, contains('README.md'));
        expect(result, contains('src/'));
      });

      test('adds multiple children at once', () {
        final tree = Tree().root('Project').children([
          'file1.txt',
          'file2.txt',
          'file3.txt',
        ]);

        final result = tree.render();

        expect(result, contains('file1.txt'));
        expect(result, contains('file2.txt'));
        expect(result, contains('file3.txt'));
      });

      test('creates nested tree', () {
        final tree = Tree()
            .root('Project')
            .child(Tree().root('src').child('main.dart').child('utils.dart'));

        final result = tree.render();

        expect(result, contains('Project'));
        expect(result, contains('src'));
        expect(result, contains('main.dart'));
        expect(result, contains('utils.dart'));
      });
    });

    group('enumerators', () {
      test('uses normal enumerator by default', () {
        final tree = Tree()
            .root('Root')
            .child('first')
            .child('second')
            .child('last');

        final result = tree.render();

        expect(result, contains('├'));
        expect(result, contains('└'));
      });

      test('rounded enumerator uses curved elbow', () {
        final tree = Tree()
            .root('Root')
            .child('child')
            .enumerator(TreeEnumerator.rounded);

        final result = tree.render();

        expect(result, contains('╰'));
      });

      test('ascii enumerator uses ASCII characters', () {
        final tree = Tree()
            .root('Root')
            .child(Tree().root('parent').child('nested'))
            .child('last')
            .enumerator(TreeEnumerator.ascii);

        final result = tree.render();

        expect(result, contains('+'));
        expect(result, contains('`'));
        expect(result, contains('|')); // Pipe appears in nested structure
      });

      test('bullet enumerator uses bullets', () {
        final tree = Tree()
            .root('Root')
            .child('item1')
            .child('item2')
            .enumerator(TreeEnumerator.bullet);

        final result = tree.render();

        expect(result, contains('•'));
      });
    });

    group('showRoot', () {
      test('shows root by default', () {
        final tree = Tree().root('MyRoot').child('child');

        final result = tree.render();

        expect(result, contains('MyRoot'));
      });

      test('can hide root', () {
        final tree = Tree().root('MyRoot').child('child').showRoot(false);

        final result = tree.render();

        expect(result, isNot(contains('MyRoot')));
        expect(result, contains('child'));
      });
    });

    group('itemStyleFunc', () {
      test('styleFunc is called for each item', () {
        final items = <String>[];

        final tree = Tree()
            .root('Root')
            .child('child1')
            .child('child2')
            .itemStyleFunc((item, depth, isDir) {
              items.add(item);
              return null;
            });

        tree.render();

        expect(items, contains('Root'));
        expect(items, contains('child1'));
        expect(items, contains('child2'));
      });

      test('styleFunc receives correct depth', () {
        final depths = <String, int>{};

        final tree = Tree()
            .root('Root')
            .child(
              Tree().root('Level1').child(Tree().root('Level2').child('Leaf')),
            )
            .itemStyleFunc((item, depth, isDir) {
              depths[item] = depth;
              return null;
            });

        tree.render();

        expect(depths['Root'], equals(0));
        expect(depths['Level1'], equals(0));
        expect(depths['Level2'], equals(1));
        expect(depths['Leaf'], equals(2));
      });

      test('styleFunc receives isDirectory flag', () {
        final dirStatus = <String, bool>{};

        final tree = Tree()
            .root('Project')
            .child(Tree().root('src/').child('main.dart'))
            .child('README.md')
            .itemStyleFunc((item, depth, isDir) {
              dirStatus[item] = isDir;
              return null;
            });

        tree.render();

        expect(dirStatus['Project'], isTrue); // Has children
        expect(dirStatus['src/'], isTrue); // Has children
        expect(dirStatus['main.dart'], isFalse); // Leaf
        expect(dirStatus['README.md'], isFalse); // Leaf
      });

      test('styleFunc applies styling', () {
        final tree = Tree()
            .root('Project')
            .child('src/')
            .child('README.md')
            .itemStyleFunc((item, depth, isDir) {
              if (isDir || item.endsWith('/')) {
                return Style().bold().foreground(Colors.blue);
              }
              return null;
            });

        final result = tree.render();

        // Should contain ANSI codes for styled items
        expect(result, contains('\x1B['));
      });
    });

    group('lineCount', () {
      test('calculates correct line count', () {
        final tree = Tree()
            .root('Root')
            .child('child1')
            .child('child2')
            .child('child3');

        // Root + 3 children = 4 lines
        expect(tree.lineCount, equals(4));
      });

      test('lineCount with nested trees', () {
        final tree = Tree()
            .root('Root')
            .child(Tree().root('Sub').child('leaf'));

        // Root + Sub + leaf = 3 lines
        expect(tree.lineCount, equals(3));
      });

      test('lineCount without root shown', () {
        final tree = Tree()
            .root('Hidden')
            .child('child1')
            .child('child2')
            .showRoot(false);

        // Just 2 children (root hidden)
        expect(tree.lineCount, equals(2));
      });
    });

    group('toString', () {
      test('toString returns rendered tree', () {
        final tree = Tree().root('Root').child('child');

        expect(tree.toString(), equals(tree.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return Tree for chaining', () {
        final tree = Tree()
            .root('Root')
            .child('child')
            .children(['a', 'b'])
            .enumerator(TreeEnumerator.rounded)
            .itemStyleFunc((i, d, dir) => null)
            .colorProfile(ColorProfile.trueColor)
            .darkBackground(true)
            .showRoot(true);

        expect(tree, isA<Tree>());
      });
    });

    group('complex structures', () {
      test('renders file tree structure', () {
        final tree = Tree()
            .root('project/')
            .child(
              Tree().root('src/').children([
                Tree().root('lib/').children(['main.dart', 'utils.dart']),
                Tree().root('test/').child('main_test.dart'),
              ]),
            )
            .child('pubspec.yaml')
            .child('README.md');

        final result = tree.render();

        expect(result, contains('project/'));
        expect(result, contains('src/'));
        expect(result, contains('lib/'));
        expect(result, contains('main.dart'));
        expect(result, contains('utils.dart'));
        expect(result, contains('test/'));
        expect(result, contains('main_test.dart'));
        expect(result, contains('pubspec.yaml'));
        expect(result, contains('README.md'));
      });

      test('handles list children directly', () {
        final tree = Tree().root('Root').child(['a', 'b', 'c']);

        final result = tree.render();

        expect(result, contains('a'));
        expect(result, contains('b'));
        expect(result, contains('c'));
      });
    });
  });

  group('TreeStyleFunc', () {
    test('typedef accepts correct signature', () {
      TreeStyleFunc func = (String item, int depth, bool isDirectory) {
        return Style().bold();
      };

      expect(func('test', 0, false), isA<Style>());
    });

    test('can return null', () {
      TreeStyleFunc func = (String item, int depth, bool isDirectory) {
        return null;
      };

      expect(func('test', 0, false), isNull);
    });
  });

  group('TreeComponent', () {
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

    test('supports enumerator parameter', () {
      // Verify the TreeComponent constructor accepts enumerator
      const component = TreeComponent(
        data: {'item': null},
        enumerator: TreeEnumerator.rounded,
      );

      expect(component.enumerator, equals(TreeEnumerator.rounded));
    });

    test('uses normal enumerator by default', () {
      const component = TreeComponent(data: {'item': null});

      expect(component.enumerator, equals(TreeEnumerator.normal));
    });

    test('supports itemStyleFunc', () {
      final component = TreeComponent(
        data: {'item': null},
        itemStyleFunc: (item, depth, isDir) => Style().bold(),
      );
      final result = component.build(
        createContext(profile: ColorProfile.trueColor),
      );
      expect(result.output, contains('\x1B['));
    });
  });
}
