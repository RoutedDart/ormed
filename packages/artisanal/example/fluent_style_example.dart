/// Example demonstrating the new fluent Style API.
///
/// Run with: dart run example/fluent_style_example.dart
library;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  print('=== Fluent Style System Demo ===\n');

  // ─────────────────────────────────────────────────────────────────────────
  // Basic Styling
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Basic Styling ---');

  // Simple text styles
  final boldStyle = Style().bold();
  print(boldStyle.render('This is bold text'));

  final coloredStyle = Style().foreground(Colors.green);
  print(coloredStyle.render('This is green text'));

  final combinedStyle = Style().bold().italic().foreground(Colors.cyan);
  print(combinedStyle.render('Bold, italic, and cyan!'));

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Semantic Colors
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Semantic Colors ---');

  final successStyle = Style().bold().foreground(Colors.success);
  final errorStyle = Style().bold().foreground(Colors.error);
  final warningStyle = Style().bold().foreground(Colors.warning);
  final infoStyle = Style().bold().foreground(Colors.info);

  print(successStyle.render('✓ Success: Operation completed'));
  print(errorStyle.render('✗ Error: Something went wrong'));
  print(warningStyle.render('⚠ Warning: Check your configuration'));
  print(infoStyle.render('ℹ Info: Starting process...'));

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Width and Alignment
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Width and Alignment ---');

  final leftAligned = Style().width(30).align(HorizontalAlign.left);
  final centered = Style().width(30).align(HorizontalAlign.center);
  final rightAligned = Style().width(30).align(HorizontalAlign.right);

  print('[${leftAligned.render("Left")}]');
  print('[${centered.render("Center")}]');
  print('[${rightAligned.render("Right")}]');

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Padding
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Padding ---');

  final paddedStyle = Style()
      .foreground(Colors.white)
      .background(Colors.blue)
      .padding(1, 3); // 1 vertical, 3 horizontal

  print(paddedStyle.render('Padded Box'));

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Borders
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Borders ---');

  final roundedBox = Style().border(Border.rounded).padding(0, 1);
  print(roundedBox.render('Rounded Border'));

  final thickBox = Style().border(Border.thick).padding(0, 1);
  print(thickBox.render('Thick Border'));

  final asciiBox = Style().border(Border.ascii).padding(0, 1);
  print(asciiBox.render('ASCII Border'));

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Style Composition with inherit()
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Style Composition ---');

  // Base style for all messages
  final baseStyle = Style().padding(0, 1).border(Border.rounded);

  // Accent styles that only set colors
  final successAccent = Style().foreground(Colors.success).bold();
  final errorAccent = Style().foreground(Colors.error).bold();

  // Combine base + accent
  final successBox = baseStyle.copy()..inherit(successAccent);
  final errorBox = baseStyle.copy()..inherit(errorAccent);

  print(successBox.render('Inherited success styling'));
  print(errorBox.render('Inherited error styling'));

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Layout Utilities
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Layout: Join Horizontal ---');

  final leftPanel = Style()
      .border(Border.rounded)
      .width(20)
      .align(HorizontalAlign.center)
      .render('Left Panel');

  final rightPanel = Style()
      .border(Border.rounded)
      .width(20)
      .align(HorizontalAlign.center)
      .render('Right Panel');

  print(Layout.joinHorizontal(VerticalAlign.top, [leftPanel, rightPanel]));

  print('');

  print('--- Layout: Join Vertical ---');

  final header = Style()
      .bold()
      .foreground(Colors.cyan)
      .width(40)
      .alignCenter()
      .render('HEADER');

  final content = Style().width(40).alignCenter().render('Content goes here');

  final footer = Style().dim().width(40).alignCenter().render('Footer text');

  print(Layout.joinVertical(HorizontalAlign.center, [header, content, footer]));

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Transform Functions
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Transform ---');

  final upperStyle = Style()
      .transform((s) => s.toUpperCase())
      .bold()
      .foreground(Colors.yellow);

  print(upperStyle.render('this will be uppercase'));

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Adaptive Colors (for light/dark terminals)
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Adaptive Colors ---');

  final adaptiveText = AdaptiveColor(
    light: Colors.black, // Use on light backgrounds
    dark: Colors.white, // Use on dark backgrounds
  );

  final adaptiveStyle = Style().foreground(adaptiveText);
  print(adaptiveStyle.render('This adapts to terminal background'));

  print('');

  // ─────────────────────────────────────────────────────────────────────────
  // Complex Example: Status Table Row
  // ─────────────────────────────────────────────────────────────────────────

  print('--- Complex Example ---');

  void printStatusRow(String name, String status, bool isOk) {
    final nameStyle = Style().width(15).foreground(Colors.cyan);
    final statusStyle = Style()
        .width(10)
        .align(HorizontalAlign.center)
        .bold()
        .foreground(isOk ? Colors.success : Colors.error);
    final iconStyle = Style().foreground(isOk ? Colors.success : Colors.error);

    final icon = isOk ? '✓' : '✗';

    print(
      '${iconStyle.render(icon)} ${nameStyle.render(name)} ${statusStyle.render(status)}',
    );
  }

  printStatusRow('Database', 'CONNECTED', true);
  printStatusRow('Cache', 'READY', true);
  printStatusRow('Queue', 'DOWN', false);
  printStatusRow('API', 'HEALTHY', true);

  print('');

  // ─────────────────────────────────────────────────────────────────────────────
  // Fluent Table with StyleFunc
  // ─────────────────────────────────────────────────────────────────────────────

  print('--- Fluent Table with StyleFunc ---');

  final table = Table()
      .headers(['Name', 'Status', 'Score'])
      .row(['Alice', 'Active', '95'])
      .row(['Bob', 'Inactive', '72'])
      .row(['Charlie', 'Active', '88'])
      .row(['Diana', 'Pending', '91'])
      .border(Border.rounded)
      .styleFunc((row, col, data) {
        // Style header row
        if (row == Table.headerRow) {
          return Style().bold().foreground(Colors.cyan);
        }
        // Style Status column based on value
        if (col == 1) {
          if (data == 'Active') {
            return Style().foreground(Colors.success);
          } else if (data == 'Inactive') {
            return Style().foreground(Colors.error);
          } else {
            return Style().foreground(Colors.warning);
          }
        }
        // Style high scores
        if (col == 2) {
          final score = int.tryParse(data) ?? 0;
          if (score >= 90) {
            return Style().bold().foreground(Colors.success);
          }
        }
        return null;
      });

  print(table.render());

  print('');

  // ─────────────────────────────────────────────────────────────────────────────
  // Fluent Tree with Enumerators
  // ─────────────────────────────────────────────────────────────────────────────

  print('--- Fluent Tree with Enumerators ---');

  // Normal enumerator (default)
  print('\nNormal style:');
  final normalTree = Tree()
      .root('project/')
      .child(
        Tree().root('src/').children([
          Tree().root('lib/').children(['main.dart', 'utils.dart']),
          'config.dart',
        ]),
      )
      .child('pubspec.yaml')
      .child('README.md');

  print(normalTree.render());

  // Rounded enumerator
  print('\nRounded style:');
  final roundedTree = Tree()
      .root('project/')
      .child(Tree().root('src/').child('main.dart'))
      .child('README.md')
      .enumerator(TreeEnumerator.rounded);

  print(roundedTree.render());

  // ASCII enumerator
  print('\nASCII style:');
  final asciiTree = Tree()
      .root('project/')
      .child(Tree().root('src/').child('main.dart'))
      .child('README.md')
      .enumerator(TreeEnumerator.ascii);

  print(asciiTree.render());

  print('');

  // ─────────────────────────────────────────────────────────────────────────────
  // Tree with ItemStyleFunc
  // ─────────────────────────────────────────────────────────────────────────────

  print('--- Tree with ItemStyleFunc ---');

  final styledTree = Tree()
      .root('my-app/')
      .child(
        Tree().root('src/').children([
          Tree().root('components/').children(['button.dart', 'input.dart']),
          'app.dart',
        ]),
      )
      .child('test/')
      .child('pubspec.yaml')
      .enumerator(TreeEnumerator.rounded)
      .itemStyleFunc((children, index) {
        final node = children[index];
        final item = node.value;
        final isDirectory = node.childrenNodes.isNotEmpty;

        if (isDirectory) {
          return Style().bold().foreground(Colors.blue);
        }
        if (item.endsWith('.dart')) {
          return Style().foreground(Colors.green);
        }
        if (item.endsWith('.yaml')) {
          return Style().foreground(Colors.yellow);
        }
        return Style();
      });

  print(styledTree.render());

  print('\n=== Demo Complete ===');
}
