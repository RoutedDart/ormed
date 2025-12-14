/// Artisan-style command runner UX wrapper for package:args.
///
/// Provides a polished CLI experience with:
/// - Grouped namespaced commands (e.g., `ui:*`, `db:*`)
/// - Formatted help output with sections
/// - Progress bars, tables, and task status indicators
/// - Interactive prompts (confirm, ask, choice, secret)
/// - ANSI color support with graceful fallback
/// - Animated spinners and panels
/// - Search prompts with fuzzy filtering
/// - Terminal control utilities
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisan_args/artisan_args.dart';
///
/// void main(List<String> args) async {
///   final runner = ArtisanCommandRunner('myapp', 'My Application')
///     ..addCommand(ServeCommand())
///     ..addCommand(MigrateCommand());
///
///   await runner.run(args);
/// }
///
/// class ServeCommand extends ArtisanCommand<void> {
///   @override
///   String get name => 'serve';
///
///   @override
///   String get description => 'Start the development server.';
///
///   @override
///   Future<void> run() async {
///     io.title('Starting Server');
///     await io.task('Compiling assets', run: () async {
///       return ArtisanTaskResult.success;
///     });
///     io.success('Server running at http://localhost:8080');
///   }
/// }
/// ```
library artisan_args;

// Runner
export 'src/runner/command.dart' show ArtisanCommand;
export 'src/runner/command_listing.dart'
    show CommandListingEntry, formatCommandListing, indentBlock;
export 'src/runner/command_runner.dart' show ArtisanCommandRunner;

// I/O
export 'src/io/artisan_io.dart' show ArtisanIO, ArtisanTaskResult;
export 'src/io/components.dart' show ArtisanComponents;
export 'src/io/prompts.dart'
    show InteractiveChoice, SecretInput, ChoiceConfig, ChoiceResult;
export 'src/io/search.dart' show SearchPrompt, SearchConfig, pause, countdown;
export 'src/io/validators.dart' show Validators;
export 'src/io/anticipate.dart' show Anticipate, AnticipateConfig;
export 'src/io/textarea.dart' show Textarea, editText;
export 'src/io/wizard.dart'
    show Wizard, WizardStep, WizardStepResult, WizardContext;

// Output
export 'src/output/progress_bar.dart' show ArtisanProgressBar;
export 'src/output/table.dart' show ArtisanTable;
export 'src/output/spinner.dart'
    show Spinner, SpinnerConfig, SpinnerFrames, withSpinner;
export 'src/output/panel.dart'
    show Panel, PanelAlign, Columns, Tree, BoxChars, BoxCharSet;
export 'src/output/terminal.dart' show Terminal, RawModeState, KeyCode;
export 'src/output/formatting.dart'
    show ExceptionRenderer, HorizontalTable, StyledBlock, BlockStyle;
export 'src/output/link.dart' show TerminalLink, LinkGroup, link;

// Style
export 'src/style/artisan_style.dart' show ArtisanStyle;
export 'src/style/verbosity.dart' show ArtisanVerbosity;
export 'src/style/chalk.dart' show ArtisanChalk, ColorPresets;

// Component System - Base
export 'src/components/base.dart'
    show CliComponent, InteractiveComponent, ComponentContext, RenderResult;

// Component System - Layout
export 'src/components/layout.dart'
    show CompositeComponent, ColumnComponent, RowComponent;

// Component System - Text
export 'src/components/text.dart' show Text, StyledText, Rule;

// Component System - List
export 'src/components/list.dart' show BulletList, NumberedList;

// Component System - Box
export 'src/components/box.dart'
    show KeyValue, Box, BorderStyle, ComponentBoxChars;

// Component System - Progress
export 'src/components/progress.dart' show ProgressBar, SpinnerFrame;

// Component System - Input
export 'src/components/input.dart'
    show TextInput, Confirm, SecretInputComponent;

// Component System - Select
export 'src/components/select.dart' show Select, MultiSelect;

// Component System - Spinner
export 'src/components/spinner.dart' show SpinnerComponent;
