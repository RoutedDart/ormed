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
export 'src/io/validators.dart' show Validators;

// Terminal utilities
export 'src/output/terminal.dart' show Terminal, RawModeState, KeyCode;

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
export 'src/components/progress_bar.dart'
    show ProgressBarComponent, StatefulProgressBar;

// Component System - Input
export 'src/components/input.dart'
    show TextInput, Confirm, SecretInputComponent;

// Component System - Select
export 'src/components/select.dart' show Select, MultiSelect;

// Component System - Spinner
export 'src/components/spinner.dart'
    show SpinnerComponent, SpinnerFrames, StatefulSpinner, withSpinner;

// Component System - Output Components
export 'src/components/alert.dart' show AlertComponent, AlertType;
export 'src/components/columns.dart' show ColumnsComponent;
export 'src/components/definition_list.dart' show DefinitionListComponent;
export 'src/components/panel.dart' show PanelComponent, PanelAlignment;
export 'src/components/panel_chars.dart' show PanelBoxChars, PanelBoxCharSet;
export 'src/components/task.dart' show TaskComponent, TaskStatus;
export 'src/components/tree.dart' show TreeComponent;
export 'src/components/two_column_detail.dart' show TwoColumnDetailComponent;

// Component System - Table
export 'src/components/table.dart'
    show TableComponent, HorizontalTableComponent;

// Component System - Styled Block
export 'src/components/styled_block.dart'
    show StyledBlockComponent, BlockStyleType, CommentComponent;

// Component System - Exception
export 'src/components/exception.dart'
    show ExceptionComponent, SimpleExceptionComponent;

// Component System - Link
export 'src/components/link.dart' show LinkComponent, LinkGroupComponent;

// Component System - Search & Interactive
export 'src/components/search.dart'
    show
        SearchComponent,
        SearchComponentConfig,
        PauseComponent,
        CountdownComponent;

// Component System - Anticipate/Autocomplete
export 'src/components/anticipate.dart'
    show AnticipateComponent, AnticipateComponentConfig;

// Component System - Password
export 'src/components/password.dart' show PasswordComponent;

// Component System - Textarea
export 'src/components/textarea.dart' show TextareaComponent;

// Component System - Wizard
export 'src/components/wizard.dart'
    show WizardComponent, WizardStep, WizardStepResult;
