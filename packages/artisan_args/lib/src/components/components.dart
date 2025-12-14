/// CLI Component System
///
/// A structured way to create and compose CLI components, similar to Flutter's
/// widget pattern.
///
/// ## Static Components
///
/// Static components render output without user interaction:
///
/// ```dart
/// // Simple text
/// Text('Hello World').renderln(context);
///
/// // Styled text
/// StyledText.success('Done!').renderln(context);
///
/// // Bullet list
/// BulletList(items: ['One', 'Two', 'Three']).renderln(context);
///
/// // Box
/// Box(content: 'Important message', title: 'Notice').renderln(context);
/// ```
///
/// ## Interactive Components
///
/// Interactive components handle user input and return a value:
///
/// ```dart
/// // Text input
/// final name = await TextInput(prompt: 'Name').run(context);
///
/// // Confirmation
/// final ok = await Confirm(prompt: 'Continue?').run(context);
///
/// // Single select
/// final choice = await Select(
///   prompt: 'Pick one',
///   options: ['A', 'B', 'C'],
/// ).run(context);
///
/// // Multi select
/// final choices = await MultiSelect(
///   prompt: 'Pick many',
///   options: ['A', 'B', 'C'],
/// ).run(context);
/// ```
///
/// ## Composition
///
/// Components can be composed together:
///
/// ```dart
/// ColumnComponent(
///   children: [
///     StyledText.heading('My App'),
///     Rule(),
///     BulletList(items: ['Feature 1', 'Feature 2']),
///   ],
/// ).renderln(context);
/// ```
///
/// ## Custom Components
///
/// Create custom components by extending the base classes:
///
/// ```dart
/// class MyBanner extends CliComponent {
///   final String title;
///   MyBanner(this.title);
///
///   @override
///   RenderResult build(ComponentContext context) {
///     final border = '═' * (title.length + 4);
///     final output = '''
/// ╔$border╗
/// ║  $title  ║
/// ╚$border╝''';
///     return RenderResult(output: output, lineCount: 3);
///   }
/// }
/// ```
library;

// Base classes
export 'base.dart';

// Layout components
export 'layout.dart';

// Text components
export 'text.dart';

// List components
export 'list.dart';

// Box components
export 'box.dart';

// Progress components
export 'progress.dart';
export 'progress_bar.dart';

// Input components
export 'input.dart';

// Select components
export 'select.dart';

// Spinner component
export 'spinner.dart';

// Output components (Panel, Tree, Columns, etc.)
export 'output.dart';

// Table components
export 'table.dart';

// Styled block components
export 'styled_block.dart';

// Exception components
export 'exception.dart';

// Link components
export 'link.dart';

// Search components
export 'search.dart';

// Anticipate/autocomplete components
export 'anticipate.dart';

// Password components
export 'password.dart';

// Textarea components
export 'textarea.dart';

// Wizard components
export 'wizard.dart';
