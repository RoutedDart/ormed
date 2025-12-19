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
///
/// ## Bubble Prompts
///
/// For Bubble Tea-style interactive prompts, use the bubbles in `tui.dart` or
/// the prompt helpers exported from this library:
///
/// ```dart
/// final terminal = StdioTerminal();
/// final name = await runTextInputPrompt(
///   TextInputModel(prompt: 'Name: '),
///   terminal,
/// );
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

// Terminal utilities (unified module)
export 'src/terminal/terminal.dart'
    show
        Terminal,
        StdioTerminal,
        StringTerminal,
        RawModeGuard,
        Ansi,
        Key,
        KeyType,
        Keys;

// TUI Runtime (Bubble Tea-style) + Bubbles
export 'tui.dart' hide Renderer, ListItem, PasteMsg;

// Style - Verbosity
export 'src/style/verbosity.dart' show ArtisanVerbosity;

// Style - Fluent Style System
export 'src/style/style.dart' show Style, styleRunes;
export 'src/style/ranges.dart' show StyleRange, styleRanges, Ranges;
export 'src/style/blending.dart' show blend1D, blend2D;
export 'src/style/writer.dart'
    show
        Writer,
        resetWriter,
        Print,
        PrintAll,
        Println,
        PrintlnAll,
        Printf,
        SprintAll,
        SprintlnAll,
        Sprintf,
        Fprint,
        Fprintln,
        Fprintf,
        stringForProfile;
export 'src/style/properties.dart'
    show
        Padding,
        Margin,
        Align,
        UnderlineStyle,
        HorizontalAlign,
        VerticalAlign,
        HorizontalAlignPosition,
        VerticalAlignPosition;
export 'src/style/color.dart'
    show
        Color,
        BasicColor,
        AnsiColor,
        AdaptiveColor,
        CompleteColor,
        CompleteAdaptiveColor,
        NoColor,
        Colors,
        ColorProfile;
export 'src/style/border.dart' show Border, BorderSides;

// Renderer
export 'src/renderer/renderer.dart'
    show
        Renderer,
        TerminalRenderer,
        StringRenderer,
        NullRenderer,
        defaultRenderer,
        resetDefaultRenderer;

// Layout
export 'src/layout/layout.dart' show Layout, WhitespaceOptions;

// Component System - Base
export 'src/tui/bubbles/components/base.dart'
    show RenderConfig, DisplayComponent;

// Component System - Layout
export 'src/tui/bubbles/components/layout.dart'
    show CompositeComponent, ColumnComponent, RowComponent;

// Component System - Text
export 'src/tui/bubbles/components/text.dart' show Text, StyledText, Rule;

// Component System - List
export 'src/tui/bubbles/components/list.dart'
    show BulletList, NumberedList, ListEnumerator, ListStyleFunc;

// Component System - List (Fluent/Lipgloss-style)
export 'src/style/list.dart'
    show
        LipList,
        ListItems,
        ListItem,
        ListEnumerators,
        ListIndenters,
        ListEnumeratorFunc,
        ListIndenterFunc;

// Component System - Box (Legacy + Fluent)
export 'src/tui/bubbles/components/box.dart'
    show
        KeyValue,
        Box,
        BorderStyle,
        ComponentBoxChars,
        BoxBuilder,
        BoxAlign,
        BoxContentStyleFunc,
        BoxPresets;

// Component System - Progress
export 'src/tui/bubbles/components/progress.dart'
    show ProgressBar, SpinnerFrame;
export 'src/tui/bubbles/components/progress_bar.dart'
    show
        ProgressBarComponent,
        ProgressBarModel,
        ProgressBarMsg,
        ProgressBarSetMsg,
        ProgressBarAdvanceMsg,
        ProgressBarIterateDoneMsg,
        ProgressBarIterateErrorMsg,
        progressIterateCmd;

// Interactive components now live under `src/tui/bubbles/` and are exposed via
// `package:artisan_args/tui.dart` + `package:artisan_args/artisan_args.dart`.

// Component System - Alert (Legacy + Fluent)
export 'src/tui/bubbles/components/alert.dart'
    show
        AlertComponent,
        AlertType,
        Alert,
        AlertDisplayStyle,
        AlertStyleFunc,
        AlertFactory;

// Component System - Columns
export 'src/tui/bubbles/components/columns.dart' show ColumnsComponent;

// Component System - Definition List (Legacy + Fluent)
export 'src/tui/bubbles/components/definition_list.dart'
    show
        DefinitionListComponent,
        DefinitionList,
        DefinitionStyleFunc,
        GroupedDefinitionList,
        DefinitionListFactory;

// Component System - Panel (Legacy + Fluent)
export 'src/tui/bubbles/components/panel.dart'
    show
        PanelComponent,
        PanelAlignment,
        Panel,
        PanelContentStyleFunc,
        PanelPresets;
export 'src/tui/bubbles/components/panel_chars.dart'
    show PanelBoxChars, PanelBoxCharSet;

// Component System - Task
export 'src/tui/bubbles/components/task.dart' show TaskComponent, TaskStatus;

// Component System - Tree (Legacy + Fluent)
export 'src/tui/bubbles/components/tree.dart'
    show
        TreeComponent,
        Tree,
        TreeEnumerator,
        TreeStyleFunc,
        TreeEnumeratorStyleFunc,
        TreeFactory;

// Component System - Two Column Detail (Legacy + Fluent)
export 'src/tui/bubbles/components/two_column_detail.dart'
    show
        TwoColumnDetailComponent,
        TwoColumnDetail,
        TwoColumnStyleFunc,
        TwoColumnDetailList,
        TwoColumnDetailFactory;

// Component System - Table (Legacy + Fluent)
export 'src/tui/bubbles/components/table.dart'
    show
        TableComponent,
        HorizontalTableComponent,
        Table,
        TableStyleFunc,
        TableFactory;

// Component System - Styled Block (Legacy + Fluent)
export 'src/tui/bubbles/components/styled_block.dart'
    show
        StyledBlockComponent,
        BlockStyleType,
        CommentComponent,
        StyledBlock,
        StyledBlockDisplayStyle,
        StyledBlockStyleFunc,
        StyledBlockFactory,
        Comment;

// Component System - Exception
export 'src/tui/bubbles/components/exception.dart'
    show ExceptionComponent, SimpleExceptionComponent;

// Component System - Link
export 'src/tui/bubbles/components/link.dart'
    show LinkComponent, LinkGroupComponent;

// Component System - Artisan Facade Helpers
export 'src/tui/bubbles/components/titled_block.dart' show TitledBlockComponent;
