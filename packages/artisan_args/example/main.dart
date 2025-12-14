import 'dart:async';
import 'dart:io' as dartio;

import 'package:artisan_args/artisan_args.dart';

Future<void> main(List<String> args) async {
  final runner =
      ArtisanCommandRunner<void>('artisan-demo', 'artisan_args demo CLI')
        ..addCommand(DemoCommand())
        ..addCommand(UiTaskCommand())
        ..addCommand(UiTableCommand())
        ..addCommand(UiPromptsCommand())
        ..addCommand(UiProgressCommand())
        ..addCommand(UiComponentsCommand())
        ..addCommand(UiSecretCommand())
        ..addCommand(UiSelectCommand())
        ..addCommand(UiMultiSelectCommand())
        ..addCommand(UiSpinCommand())
        ..addCommand(UiSpinnerCommand())
        ..addCommand(UiPanelCommand())
        ..addCommand(UiTreeCommand())
        ..addCommand(UiSearchCommand())
        ..addCommand(UiPauseCommand())
        ..addCommand(UiChalkCommand())
        ..addCommand(UiValidatorsCommand())
        ..addCommand(UiExceptionCommand())
        ..addCommand(UiHorizontalTableCommand())
        ..addCommand(UiPasswordCommand())
        ..addCommand(UiBlockCommand())
        ..addCommand(UiColumnsCommand())
        ..addCommand(UiTerminalCommand())
        ..addCommand(UiAnticipateCommand())
        ..addCommand(UiTextareaCommand())
        ..addCommand(UiWizardCommand())
        ..addCommand(UiLinkCommand())
        ..addCommand(UiComponentSystemCommand())
        ..addCommand(UiAllCommand());

  await runner.run(args);
}

class DemoCommand extends ArtisanCommand<void> {
  @override
  String get name => 'demo';

  @override
  String get description =>
      'Showcase basic output helpers (title/section/blocks/listing).';

  @override
  Future<void> run() async {
    io.title('artisan_args');

    io.section('Messages');
    io.info('Info message');
    io.success('Success message');
    io.warning('Warning message');
    io.error('Error message');
    io.note('Note message');
    io.caution('Caution message');

    io.section('Listing');
    io.listing(['one', 'two', 'three']);

    io.section('Two Column Detail');
    io.twoColumnDetail('Driver', 'sqlite');
    io.twoColumnDetail('Database', 'example.sqlite');
    io.newLine();

    io.section('Task');
    await io.task(
      'Run a sample task',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return .success;
      },
    );
  }
}

class UiTaskCommand extends ArtisanCommand<void> {
  UiTaskCommand() {
    argParser
      ..addFlag('fail', negatable: false, help: 'Return FAIL instead of DONE.')
      ..addFlag(
        'skip',
        negatable: false,
        help: 'Return SKIPPED instead of DONE.',
      );
  }

  @override
  String get name => 'ui:task';

  @override
  String get description => 'Render a Laravel-like task line.';

  @override
  Future<void> run() async {
    final fail = argResults?['fail'] == true;
    final skip = argResults?['skip'] == true;

    await io.task(
      'Build something',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (fail) return ArtisanTaskResult.failure;
        if (skip) return ArtisanTaskResult.skipped;
        return ArtisanTaskResult.success;
      },
    );
  }
}

class UiTableCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:table';

  @override
  String get description => 'Render a simple ASCII table.';

  @override
  Future<void> run() async {
    io.table(
      headers: ['id', 'name', 'status'],
      rows: [
        [1, 'create_users_table', io.style.success('DONE')],
        [2, 'add_posts_table', io.style.warning('PENDING')],
      ],
    );
  }
}

class UiPromptsCommand extends ArtisanCommand<void> {
  UiPromptsCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use defaults so --no-interaction can run.',
    );
  }

  @override
  String get name => 'ui:prompts';

  @override
  String get description => 'Demonstrate confirm/ask/choice prompts.';

  @override
  Future<void> run() async {
    final useDefaults = argResults?['defaults'] == true;

    io.title('Prompts');

    final confirmed = io.confirm('Continue?', defaultValue: true);
    io.twoColumnDetail('confirm', confirmed.toString());

    final name = io.ask(
      'Your name',
      defaultValue: useDefaults ? 'Anonymous' : null,
      validator: (value) =>
          value.trim().isEmpty ? 'Name cannot be empty' : null,
    );
    io.twoColumnDetail('ask', name);

    final selected = io.choice(
      'Pick a driver',
      choices: const ['sqlite', 'postgres', 'mysql'],
      defaultIndex: useDefaults ? 0 : null,
    );
    io.twoColumnDetail('choice', selected.toString());
  }
}

class UiProgressCommand extends ArtisanCommand<void> {
  UiProgressCommand() {
    argParser.addOption(
      'count',
      defaultsTo: '25',
      help: 'How many steps to run.',
    );
  }

  @override
  String get name => 'ui:progress';

  @override
  String get description => 'Render a simple progress bar.';

  @override
  Future<void> run() async {
    final countRaw = argResults?['count'] as String? ?? '25';
    final count = int.tryParse(countRaw) ?? 25;

    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );

    final bar = io.createProgressBar(max: count);
    bar.start(context);
    for (var i = 0; i < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bar.advance(context);
    }
    bar.finish(context);
    io.newLine();
  }
}

/// Demonstrate the components facade (Laravel-style higher-level components).
class UiComponentsCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:components';

  @override
  String get description =>
      'Demonstrate the components facade (bulletList, definitionList, rule, etc).';

  @override
  Future<void> run() async {
    io.title('Components Facade');

    io.section('Bullet List');
    io.components.bulletList([
      'First item in the list',
      'Second item in the list',
      'Third item in the list',
    ]);

    io.section('Definition List');
    io.components.definitionList({
      'Application Name': 'artisan_args Demo',
      'Version': '1.0.0',
      'Environment': 'development',
      'Debug Mode': 'enabled',
    });

    io.section('Horizontal Rule');
    io.components.rule();
    io.components.rule('Section Divider');

    io.section('Line Separator');
    io.components.line();
    io.components.line(40);

    io.section('Titled Messages');
    io.components.info('Information', 'This is an informational message.');
    io.components.success('Success', 'Operation completed successfully!');
    io.components.warn('Warning', 'Please review before proceeding.');
    io.components.error('Error', 'Something went wrong.');

    io.section('Alert Box');
    io.components.alert('This is an important alert message!');

    io.section('Two Column Detail');
    io.components.twoColumnDetail('Database', 'SQLite');
    io.components.twoColumnDetail('Host', 'localhost');
    io.components.twoColumnDetail('Port', '5432');

    io.section('Task (via components)');
    await io.components.task(
      'Running migrations',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return ArtisanTaskResult.success;
      },
    );
  }
}

/// Demonstrate secret/password input (no echo).
class UiSecretCommand extends ArtisanCommand<void> {
  UiSecretCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use fallback value for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:secret';

  @override
  String get description => 'Demonstrate secret/password input (no echo).';

  @override
  Future<void> run() async {
    final useDefaults = argResults?['defaults'] == true;

    io.title('Secret Input');
    io.text('Characters will not be echoed as you type.');
    io.newLine();

    final password = io.secret(
      'Enter your password',
      fallback: useDefaults ? '***hidden***' : null,
    );

    io.newLine();
    io.success('Password received (${password.length} characters)');
    io.twoColumnDetail('Length', '${password.length} chars');
  }
}

/// Demonstrate interactive single-select with arrow-key navigation.
class UiSelectCommand extends ArtisanCommand<void> {
  UiSelectCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use default selection for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:select';

  @override
  String get description =>
      'Demonstrate interactive single-select with arrow-key navigation.';

  @override
  Future<void> run() async {
    final useDefaults = argResults?['defaults'] == true;

    io.title('Interactive Single Select');
    io.text('Use arrow keys to navigate, Enter to select, q to cancel.');
    io.newLine();

    final databases = [
      'SQLite (lightweight, file-based)',
      'PostgreSQL (powerful, ACID-compliant)',
      'MySQL (popular, widely deployed)',
      'MongoDB (document-oriented, NoSQL)',
    ];

    final selected = await io.selectChoice(
      'Choose your database',
      choices: databases,
      defaultIndex: useDefaults ? 1 : 0,
    );

    io.newLine();
    if (selected != null) {
      io.success('Selected: $selected');
    } else {
      io.warning('Selection cancelled');
    }
  }
}

/// Demonstrate interactive multi-select with arrow-key navigation.
class UiMultiSelectCommand extends ArtisanCommand<void> {
  UiMultiSelectCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use default selections for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:multiselect';

  @override
  String get description =>
      'Demonstrate interactive multi-select with arrow-key navigation.';

  @override
  Future<void> run() async {
    final useDefaults = argResults?['defaults'] == true;

    io.title('Interactive Multi Select');
    io.text('Use arrow keys to navigate, Space to toggle, Enter to confirm.');
    io.newLine();

    final features = [
      'Authentication',
      'Database ORM',
      'REST API',
      'GraphQL',
      'WebSocket Support',
      'Email Service',
      'Queue System',
      'Cache Layer',
    ];

    final selected = await io.multiSelectChoice(
      'Select features to enable',
      choices: features,
      defaultSelected: useDefaults ? [0, 1, 2] : [],
    );

    io.newLine();
    if (selected.isEmpty) {
      io.warning('No features selected');
    } else {
      io.success('Selected ${selected.length} feature(s):');
      io.components.bulletList(selected);
    }
  }
}

/// Demonstrate the spin component (spinner with success/fail indicator).
class UiSpinCommand extends ArtisanCommand<void> {
  UiSpinCommand() {
    argParser.addFlag('fail', negatable: false, help: 'Simulate a failure.');
  }

  @override
  String get name => 'ui:spin';

  @override
  String get description =>
      'Demonstrate the spin component (processing indicator).';

  @override
  Future<void> run() async {
    final shouldFail = argResults?['fail'] == true;

    io.title('Spin Component');
    io.text('Shows a processing indicator with success/fail status.');
    io.newLine();

    try {
      final result = await io.components.spin(
        'Connecting to database',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return 'Connection established';
        },
      );
      io.twoColumnDetail('Result', result);
    } catch (e) {
      io.error('Connection failed');
    }

    try {
      await io.components.spin(
        'Running migrations',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (shouldFail) {
            throw Exception('Migration failed');
          }
          return null;
        },
      );
      io.success('Migrations completed');
    } catch (e) {
      io.error('Migration error: $e');
    }

    try {
      final count = await io.components.spin(
        'Seeding database',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          return 42;
        },
      );
      io.twoColumnDetail('Records seeded', count.toString());
    } catch (e) {
      io.error('Seeding failed');
    }
  }
}

/// Demonstrate animated spinner.
class UiSpinnerCommand extends ArtisanCommand<void> {
  UiSpinnerCommand() {
    argParser.addOption(
      'frames',
      abbr: 'f',
      defaultsTo: 'dots',
      help: 'Spinner frame style (dots, line, circle, arc, arrows)',
    );
  }

  @override
  String get name => 'ui:spinner';

  @override
  String get description =>
      'Demonstrate animated spinner with different styles.';

  @override
  Future<void> run() async {
    final frameStyle = argResults?['frames'] as String? ?? 'dots';

    final frames = switch (frameStyle) {
      'line' => SpinnerFrames.line,
      'circle' => SpinnerFrames.circle,
      'arc' => SpinnerFrames.arc,
      'arrows' => SpinnerFrames.arrows,
      _ => SpinnerFrames.dots,
    };

    io.title('Animated Spinner');
    io.text('This demonstrates a real animated spinner.');
    io.newLine();

    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );

    final result = await withSpinner(
      message: 'Processing your request...',
      context: context,
      frames: frames,
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return 'Completed successfully!';
      },
    );

    io.success('Result: $result');
  }
}

/// Demonstrate panels with box drawing.
class UiPanelCommand extends ArtisanCommand<void> {
  UiPanelCommand() {
    argParser.addOption(
      'style',
      abbr: 's',
      defaultsTo: 'rounded',
      help: 'Box style (rounded, single, double, heavy, ascii)',
    );
  }

  @override
  String get name => 'ui:panel';

  @override
  String get description => 'Demonstrate boxed panels with different styles.';

  @override
  Future<void> run() async {
    final boxStyle = argResults?['style'] as String? ?? 'rounded';

    final chars = switch (boxStyle) {
      'single' => PanelBoxChars.single,
      'double' => PanelBoxChars.double,
      'heavy' => PanelBoxChars.heavy,
      'ascii' => PanelBoxChars.ascii,
      _ => PanelBoxChars.rounded,
    };

    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );

    io.title('Panels');

    // Simple panel
    PanelComponent(
      content:
          'This is a simple panel with some content.\nIt can have multiple lines.',
      title: 'Info',
      chars: chars,
    ).renderln(context);
    io.newLine();

    // Success panel
    PanelComponent(
      content: 'Your operation completed successfully!',
      title: 'Success',
      chars: chars,
    ).renderln(context);
    io.newLine();

    // Warning panel
    PanelComponent(
      content: 'Please review your configuration before proceeding.',
      title: 'Warning',
      titleAlign: PanelAlignment.center,
      chars: chars,
    ).renderln(context);
    io.newLine();

    // Columns demo
    io.section('Multi-Column Layout');
    ColumnsComponent(
      items: [
        'apple',
        'banana',
        'cherry',
        'date',
        'elderberry',
        'fig',
        'grape',
        'honeydew',
        'kiwi',
        'lemon',
        'mango',
        'nectarine',
      ],
      columnCount: 4,
    ).renderln(context);
  }
}

/// Demonstrate tree rendering.
class UiTreeCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:tree';

  @override
  String get description => 'Demonstrate tree structure rendering.';

  @override
  Future<void> run() async {
    io.title('Tree Structure');

    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );

    TreeComponent(
      data: {
        'lib': {
          'src': {
            'io': ['artisan_io.dart', 'components.dart', 'prompts.dart'],
            'output': ['progress_bar.dart', 'spinner.dart', 'table.dart'],
            'runner': ['command.dart', 'command_runner.dart'],
            'style': ['artisan_style.dart', 'chalk.dart'],
          },
          'artisan_args.dart': null,
        },
        'test': ['artisan_io_test.dart', 'command_runner_test.dart'],
        'example': ['main.dart'],
        'pubspec.yaml': null,
        'README.md': null,
      },
    ).renderln(context);
  }
}

/// Demonstrate search prompt.
class UiSearchCommand extends ArtisanCommand<void> {
  UiSearchCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use default for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:search';

  @override
  String get description => 'Demonstrate searchable selection prompt.';

  @override
  Future<void> run() async {
    io.title('Search Prompt');
    io.text('Type to filter, use arrow keys to navigate, Enter to select.');
    io.newLine();

    final packages = [
      'flutter',
      'dart',
      'args',
      'path',
      'http',
      'json_annotation',
      'build_runner',
      'test',
      'mockito',
      'provider',
      'bloc',
      'riverpod',
      'get_it',
      'dio',
      'sqflite',
      'shared_preferences',
      'hive',
      'drift',
    ];

    final search = SearchPrompt(
      style: io.style,
      stdin: dartio.stdin,
      stdout: dartio.stdout,
    );

    final selected = await search.run(
      question: 'Select a package',
      choices: packages,
    );

    io.newLine();
    if (selected != null) {
      io.success('Selected: $selected');
    } else {
      io.warning('Selection cancelled');
    }
  }
}

/// Demonstrate pause and countdown.
class UiPauseCommand extends ArtisanCommand<void> {
  UiPauseCommand() {
    argParser.addFlag(
      'countdown',
      abbr: 'c',
      negatable: false,
      help: 'Show countdown instead of pause.',
    );
  }

  @override
  String get name => 'ui:pause';

  @override
  String get description => 'Demonstrate pause and countdown.';

  @override
  Future<void> run() async {
    final showCountdown = argResults?['countdown'] == true;

    io.title('Pause & Countdown');

    if (showCountdown) {
      io.text('Starting countdown...');
      io.newLine();

      await countdown(
        seconds: 5,
        message: 'Continuing in',
        stdout: dartio.stdout,
        style: io.style,
        onComplete: () {
          io.success('Countdown complete!');
        },
      );
    } else {
      io.text('Press any key to continue after this message.');
      io.newLine();

      await pause(
        message: 'Press any key to continue...',
        stdout: dartio.stdout,
        stdin: dartio.stdin,
        style: io.style,
      );

      io.success('You pressed a key!');
    }
  }
}

/// Demonstrate advanced chalk styling.
class UiChalkCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:chalk';

  @override
  String get description => 'Demonstrate advanced color styling with chalk.';

  @override
  Future<void> run() async {
    final chalk = ArtisanChalk(enabled: io.style.enabled);

    io.title('Advanced Styling with Chalk');

    io.section('Basic Colors');
    io.writeln(
      '  ${chalk.red('Red')} ${chalk.green('Green')} ${chalk.blue('Blue')} ${chalk.yellow('Yellow')}',
    );
    io.writeln(
      '  ${chalk.magenta('Magenta')} ${chalk.cyan('Cyan')} ${chalk.white('White')} ${chalk.black('Black (on light bg)')}',
    );
    io.newLine();

    io.section('Bright Colors');
    io.writeln(
      '  ${chalk.brightRed('Bright Red')} ${chalk.brightGreen('Bright Green')} ${chalk.brightBlue('Bright Blue')}',
    );
    io.writeln(
      '  ${chalk.brightYellow('Bright Yellow')} ${chalk.brightMagenta('Bright Magenta')} ${chalk.brightCyan('Bright Cyan')}',
    );
    io.newLine();

    io.section('Text Styles');
    io.writeln(
      '  ${chalk.bold('Bold')} ${chalk.dim('Dim')} ${chalk.italic('Italic')} ${chalk.underline('Underline')}',
    );
    io.writeln(
      '  ${chalk.inverse('Inverse')} ${chalk.strikethrough('Strikethrough')}',
    );
    io.newLine();

    io.section('True Color (RGB)');
    io.writeln('  ${chalk.rgb(255, 100, 50, 'Orange RGB')}');
    io.writeln('  ${chalk.rgb(150, 50, 255, 'Purple RGB')}');
    io.writeln('  ${chalk.rgb(50, 200, 150, 'Teal RGB')}');
    io.newLine();

    io.section('Hex Colors');
    io.writeln('  ${chalk.hex('#ff6b6b', 'Coral')}');
    io.writeln('  ${chalk.hex('#4ecdc4', 'Turquoise')}');
    io.writeln('  ${chalk.hex('#ffe66d', 'Lemon')}');
    io.newLine();

    io.section('Semantic Styles');
    io.writeln('  ${chalk.success('Success message')}');
    io.writeln('  ${chalk.error('Error message')}');
    io.writeln('  ${chalk.warning('Warning message')}');
    io.writeln('  ${chalk.info('Info message')}');
    io.writeln('  ${chalk.muted('Muted message')}');
    io.writeln('  ${chalk.highlight('Highlighted text')}');
  }
}

/// Demonstrate validators.
class UiValidatorsCommand extends ArtisanCommand<void> {
  UiValidatorsCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use defaults for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:validators';

  @override
  String get description => 'Demonstrate built-in input validators.';

  @override
  Future<void> run() async {
    io.title('Input Validators (powered by Acanthis)');

    io.section('Email Validator');
    try {
      final email = io.ask(
        'Enter your email',
        defaultValue: 'test@example.com',
        validator: Validators.combine([
          Validators.required(),
          Validators.email(),
        ]),
      );
      io.success('Valid email: $email');
    } catch (e) {
      io.error('Validation failed: $e');
    }

    io.section('Numeric Validator');
    try {
      final age = io.ask(
        'Enter your age',
        defaultValue: '25',
        validator: Validators.combine([
          Validators.required(),
          Validators.integer(min: 0, max: 150),
        ]),
      );
      io.success('Valid age: $age');
    } catch (e) {
      io.error('Validation failed: $e');
    }

    io.section('URL Validator');
    try {
      final url = io.ask(
        'Enter a URL',
        defaultValue: 'https://example.com',
        validator: Validators.url(),
      );
      io.success('Valid URL: $url');
    } catch (e) {
      io.error('Validation failed: $e');
    }

    io.section('UUID Validator');
    try {
      final uuid = io.ask(
        'Enter a UUID',
        defaultValue: '550e8400-e29b-41d4-a716-446655440000',
        validator: Validators.uuid(),
      );
      io.success('Valid UUID: $uuid');
    } catch (e) {
      io.error('Validation failed: $e');
    }

    io.section('Using Acanthis Schema Directly');
    io.components.comment('You can also use Acanthis schemas directly:');
    io.writeln('');
    io.writeln('  // Create schema');
    io.writeln('  final schema = string().email().min(5).max(100);');
    io.writeln('');
    io.writeln('  // Use as validator');
    io.writeln('  validator: schema.toValidator()');
    io.writeln('');
    io.writeln('  // Or parse directly');
    io.writeln('  final result = schema.tryParse(value);');
    io.writeln('  if (result.success) { ... }');
    io.newLine();

    io.section('Available Validators');
    io.components.bulletList([
      'Validators.required() - non-empty input',
      'Validators.email() - valid email format',
      'Validators.url() / uri() - valid URL/URI',
      'Validators.uuid() - valid UUID format',
      'Validators.jwt() / base64() - token formats',
      'Validators.hexColor() - hex color codes',
      'Validators.dateTime() - date-time strings',
      'Validators.numeric() / integer() - number validation',
      'Validators.positive() / negative() - sign validation',
      'Validators.between(min, max) - range validation',
      'Validators.minLength(n) / maxLength(n) - length constraints',
      'Validators.pattern(regex) - custom regex',
      'Validators.letters() / digits() / alphanumeric()',
      'Validators.uppercase() / lowercase()',
      'Validators.startsWith() / endsWith() / contains()',
      'Validators.inList(values) / notIn(values)',
      'Validators.ip() / port() - network validation',
      'Validators.identifier() - valid identifier format',
      'Validators.combine([...]) - chain validators',
      'Validators.fromSchema(acanthisSchema) - use Acanthis directly',
    ]);
  }
}

/// Demonstrate exception rendering.
class UiExceptionCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:exception';

  @override
  String get description => 'Demonstrate pretty exception rendering.';

  @override
  Future<void> run() async {
    io.title('Exception Rendering');

    io.section('Simple Exception');
    try {
      throw FormatException('Invalid input format: expected JSON');
    } catch (e, stack) {
      io.components.renderException(e, stack);
    }

    io.section('Custom Exception');
    try {
      throw StateError('Cannot perform operation while loading');
    } catch (e, stack) {
      io.components.renderException(e, stack);
    }

    io.section('Using ExceptionComponent directly');
    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );
    try {
      throw ArgumentError.value('invalid', 'name', 'Name cannot be "invalid"');
    } catch (e, stack) {
      ExceptionComponent(
        exception: e,
        stackTrace: stack,
        maxStackFrames: 5,
      ).renderln(context);
    }
  }
}

/// Demonstrate horizontal table.
class UiHorizontalTableCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:htable';

  @override
  String get description => 'Demonstrate horizontal table (row-as-headers).';

  @override
  Future<void> run() async {
    io.title('Horizontal Table');

    io.section('Application Info');
    io.components.horizontalTable({
      'Name': 'artisan_args Demo',
      'Version': '1.0.0',
      'Environment': 'development',
      'Debug': 'enabled',
      'Dart SDK': dartio.Platform.version.split(' ').first,
    });

    io.section('Database Configuration');
    io.components.horizontalTable({
      'Driver': 'PostgreSQL',
      'Host': 'localhost',
      'Port': '5432',
      'Database': 'myapp_dev',
      'Username': 'postgres',
      'SSL': 'disabled',
    });

    io.section('Using HorizontalTableComponent directly');
    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );
    HorizontalTableComponent(
      data: {
        'Status': io.style.success('● Online'),
        'Uptime': '3 days, 14 hours',
        'Memory': '256 MB / 1 GB',
        'CPU': '12%',
      },
    ).renderln(context);
  }
}

/// Demonstrate password with confirmation.
class UiPasswordCommand extends ArtisanCommand<void> {
  UiPasswordCommand() {
    argParser.addFlag(
      'confirm',
      abbr: 'c',
      negatable: false,
      help: 'Require password confirmation.',
    );
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use defaults for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:password';

  @override
  String get description => 'Demonstrate password input with confirmation.';

  @override
  Future<void> run() async {
    final confirm = argResults?['confirm'] == true;

    io.title('Password Input');
    io.text(
      confirm
          ? 'Enter a password (will be asked to confirm)'
          : 'Enter a password (no confirmation)',
    );
    io.newLine();

    final secretInput = SecretInput(
      style: io.style,
      write: io.write,
      writeln: io.writeln,
      stdin: dartio.stdin,
      stdout: dartio.stdout,
    );

    try {
      final password = secretInput.readPassword(
        'Password',
        confirm: confirm,
        confirmPrompt: 'Confirm password',
      );
      io.newLine();
      io.success('Password set successfully!');
      io.twoColumnDetail('Length', '${password.length} characters');
    } catch (e) {
      io.newLine();
      io.error('$e');
    }
  }
}

/// Demonstrate styled blocks (Symfony-style).
class UiBlockCommand extends ArtisanCommand<void> {
  UiBlockCommand() {
    argParser.addFlag(
      'large',
      abbr: 'l',
      negatable: false,
      help: 'Show large block style.',
    );
  }

  @override
  String get name => 'ui:block';

  @override
  String get description => 'Demonstrate styled block output (Symfony-style).';

  @override
  Future<void> run() async {
    final large = argResults?['large'] == true;

    io.title('Styled Blocks');

    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );

    io.section('Info Block');
    StyledBlockComponent(
      message: 'This is an informational message that provides context.',
      blockStyle: BlockStyleType.info,
      large: large,
    ).renderln(context);

    io.section('Success Block');
    StyledBlockComponent(
      message:
          'Operation completed successfully!\nAll tasks finished without errors.',
      blockStyle: BlockStyleType.success,
      large: large,
    ).renderln(context);

    io.section('Warning Block');
    StyledBlockComponent(
      message: 'Please review the configuration before proceeding.',
      blockStyle: BlockStyleType.warning,
      large: large,
    ).renderln(context);

    io.section('Error Block');
    StyledBlockComponent(
      message: 'An error occurred during the operation.',
      blockStyle: BlockStyleType.error,
      large: large,
    ).renderln(context);

    io.section('Note Block');
    StyledBlockComponent(
      message: 'This is a note with additional information.',
      blockStyle: BlockStyleType.note,
      large: large,
    ).renderln(context);

    io.section('Comment Style');
    CommentComponent(
      text: [
        'This is a comment block.',
        'It displays text in a dimmed, code-comment style.',
        'Useful for showing hints or secondary information.',
      ],
    ).renderln(context);
  }
}

/// Demonstrate multi-column layout.
class UiColumnsCommand extends ArtisanCommand<void> {
  UiColumnsCommand() {
    argParser.addOption(
      'cols',
      abbr: 'c',
      defaultsTo: '4',
      help: 'Number of columns.',
    );
  }

  @override
  String get name => 'ui:columns';

  @override
  String get description => 'Demonstrate multi-column layout.';

  @override
  Future<void> run() async {
    final colCount = int.tryParse(argResults?['cols'] as String? ?? '4') ?? 4;

    io.title('Multi-Column Layout');

    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );

    io.section('Fruits ($colCount columns)');
    ColumnsComponent(
      items: [
        'Apple',
        'Banana',
        'Cherry',
        'Date',
        'Elderberry',
        'Fig',
        'Grape',
        'Honeydew',
        'Kiwi',
        'Lemon',
        'Mango',
        'Nectarine',
        'Orange',
        'Papaya',
        'Quince',
        'Raspberry',
      ],
      columnCount: colCount,
    ).renderln(context);
    io.newLine();

    io.section('Commands (auto columns)');
    ColumnsComponent(
      items: [
        'make:model',
        'make:controller',
        'make:migration',
        'make:seeder',
        'db:migrate',
        'db:seed',
        'db:rollback',
        'db:fresh',
        'serve',
        'build',
        'test',
        'lint',
        'cache:clear',
        'config:cache',
        'route:list',
        'queue:work',
      ],
    ).renderln(context);
    io.newLine();

    io.section('Status Items');
    ColumnsComponent(
      items: [
        '${io.style.success("●")} Online',
        '${io.style.error("●")} Offline',
        '${io.style.warning("●")} Degraded',
        '${io.style.info("●")} Maintenance',
        '${io.style.success("●")} Healthy',
        '${io.style.error("●")} Critical',
      ],
      columnCount: 3,
    ).renderln(context);
  }
}

/// Demonstrate terminal utilities.
class UiTerminalCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:terminal';

  @override
  String get description => 'Demonstrate terminal utilities and info.';

  @override
  Future<void> run() async {
    final terminal = Terminal(stdout: dartio.stdout, stdin: dartio.stdin);

    io.title('Terminal Utilities');

    io.section('Terminal Information');
    io.components.horizontalTable({
      'Width': '${terminal.width} columns',
      'Height': '${terminal.height} rows',
      'Supports ANSI': terminal.supportsAnsi ? 'Yes' : 'No',
      'Is Terminal': terminal.isTerminal ? 'Yes' : 'No',
    });

    io.section('Available Operations');
    io.components.bulletList([
      'terminal.hideCursor() / showCursor() - cursor visibility',
      'terminal.cursorUp(n) / cursorDown(n) - move cursor vertically',
      'terminal.cursorLeft(n) / cursorRight(n) - move cursor horizontally',
      'terminal.cursorTo(row, col) - absolute positioning',
      'terminal.saveCursor() / restoreCursor() - save/restore position',
      'terminal.clearScreen() - clear entire screen',
      'terminal.clearLine() - clear current line',
      'terminal.clearPreviousLines(n) - clear n lines above',
      'terminal.scrollUp(n) / scrollDown(n) - scroll viewport',
      'terminal.enterAlternateScreen() / exitAlternateScreen()',
      'terminal.bell() - ring terminal bell',
      'terminal.setTitle(title) - set terminal window title',
      'terminal.enableRawMode() - character-by-character input',
    ]);

    io.section('Key Codes');
    io.components.definitionList({
      'KeyCode.enter': '10 (\\n)',
      'KeyCode.escape': '27',
      'KeyCode.space': '32',
      'KeyCode.backspace': '127',
      'KeyCode.tab': '9',
      'KeyCode.ctrlC': '3',
      'KeyCode.arrowUp/Down/Left/Right': '65/66/67/68 (after ESC[)',
    });

    io.section('Demo: Bell');
    io.text('Ringing terminal bell...');
    terminal.bell();
    io.success('Bell rang! (you may have heard a beep)');
  }
}

/// Run all UI demos in sequence.
class UiAllCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:all';

  @override
  String get description => 'Run all UI component demos in sequence.';

  @override
  Future<void> run() async {
    io.title('Complete artisan_args Demo');
    io.text('This demo showcases all available UI components.');
    io.newLine();

    // Basic output
    io.section('1. Basic Output');
    io.info('Info message');
    io.success('Success message');
    io.warning('Warning message');
    io.error('Error message');
    io.note('Note message');
    io.caution('Caution message');
    io.newLine();

    // Listing
    io.section('2. Listing');
    io.listing(['First item', 'Second item', 'Third item']);

    // Two column detail
    io.section('3. Two Column Detail');
    io.twoColumnDetail('Application', 'artisan_args');
    io.twoColumnDetail('Version', '1.0.0');
    io.twoColumnDetail('Environment', 'development');
    io.newLine();

    // Table
    io.section('4. Table');
    io.table(
      headers: ['ID', 'Name', 'Status'],
      rows: [
        ['1', 'users', io.style.success('migrated')],
        ['2', 'posts', io.style.success('migrated')],
        ['3', 'comments', io.style.warning('pending')],
      ],
    );

    // Horizontal table
    io.section('5. Horizontal Table');
    io.components.horizontalTable({
      'Database': 'PostgreSQL',
      'Host': 'localhost',
      'Port': '5432',
    });

    // Components
    io.section('6. Components');

    io.writeln('Bullet List:');
    io.components.bulletList(['Item A', 'Item B', 'Item C']);

    io.writeln('Definition List:');
    io.components.definitionList({'Key 1': 'Value 1', 'Key 2': 'Value 2'});

    io.writeln('Rule:');
    io.components.rule('Section');

    io.writeln('Comment:');
    io.components.comment('This is a comment');
    io.newLine();

    io.writeln('Alert:');
    io.components.alert('Important alert message!');

    // Panel
    io.section('7. Panel');
    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );
    PanelComponent(
      content: 'This is a boxed panel with a title.',
      title: 'Panel Title',
    ).renderln(context);
    io.newLine();

    // Tree
    io.section('8. Tree');
    TreeComponent(
      data: {
        'src': {
          'lib': ['main.dart'],
          'test': ['main_test.dart'],
        },
        'pubspec.yaml': null,
      },
    ).renderln(context);
    io.newLine();

    // Columns
    io.section('9. Columns');
    ColumnsComponent(
      items: ['one', 'two', 'three', 'four', 'five', 'six'],
      columnCount: 3,
    ).renderln(context);
    io.newLine();

    // Progress bar
    io.section('10. Progress Bar');
    final bar = io.createProgressBar(max: 20);
    bar.start(context);
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bar.advance(context);
    }
    bar.finish(context);
    io.newLine();

    // Task
    io.section('11. Task');
    await io.task(
      'Running task',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return ArtisanTaskResult.success;
      },
    );

    // Spin
    io.section('12. Spin Component');
    await io.components.spin(
      'Processing',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return null;
      },
    );
    io.newLine();

    // Colors
    io.section('13. Chalk Colors');
    final chalk = ArtisanChalk(enabled: io.style.enabled);
    io.writeln(
      '  ${chalk.red("Red")} ${chalk.green("Green")} ${chalk.blue("Blue")} ${chalk.yellow("Yellow")}',
    );
    io.writeln(
      '  ${chalk.bold("Bold")} ${chalk.italic("Italic")} ${chalk.underline("Underline")}',
    );
    io.writeln(
      '  ${chalk.hex("#ff6b6b", "Coral")} ${chalk.hex("#4ecdc4", "Turquoise")} ${chalk.rgb(255, 100, 50, "Orange")}',
    );
    io.newLine();

    // Terminal info
    io.section('14. Terminal Info');
    final terminal = Terminal(stdout: dartio.stdout);
    io.twoColumnDetail('Size', '${terminal.width}x${terminal.height}');
    io.twoColumnDetail('ANSI', terminal.supportsAnsi ? 'Yes' : 'No');
    io.newLine();

    // Summary
    io.section('Summary');
    io.success('All demos completed!');
    io.newLine();
    io.text('Run individual commands to see interactive demos:');
    io.components.bulletList([
      'ui:prompts - interactive prompts (confirm/ask/choice)',
      'ui:secret - password input',
      'ui:password - password with confirmation',
      'ui:select - arrow-key selection',
      'ui:multiselect - multi-select with checkboxes',
      'ui:search - searchable selection',
      'ui:spinner - animated spinner',
      'ui:pause - press any key / countdown',
      'ui:validators - input validation',
      'ui:anticipate - autocomplete suggestions',
      'ui:textarea - multi-line editor input',
      'ui:wizard - multi-step wizard flow',
      'ui:link - clickable terminal links',
    ]);
  }
}

/// Demonstrate autocomplete/anticipate prompt.
class UiAnticipateCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:anticipate';

  @override
  String get description => 'Demonstrate autocomplete input with suggestions.';

  @override
  Future<void> run() async {
    io.title('Autocomplete / Anticipate');
    io.text('Type to see matching suggestions. Use arrow keys to navigate.');
    io.newLine();

    final anticipate = Anticipate(
      style: io.style,
      stdin: dartio.stdin,
      stdout: dartio.stdout,
    );

    // Country selection
    final countries = [
      'United States',
      'United Kingdom',
      'Canada',
      'Australia',
      'Germany',
      'France',
      'Japan',
      'China',
      'India',
      'Brazil',
      'Mexico',
      'Spain',
      'Italy',
      'Netherlands',
      'Sweden',
      'Norway',
      'Denmark',
      'Finland',
      'Switzerland',
      'Austria',
    ];

    final country = await anticipate.run(
      question: 'Select your country',
      suggestions: countries,
      defaultValue: 'United States',
    );

    io.newLine();
    if (country != null) {
      io.success('Selected: $country');
    } else {
      io.warning('Selection cancelled');
    }

    io.newLine();

    // Package selection
    final packages = [
      'flutter',
      'dart',
      'http',
      'dio',
      'provider',
      'bloc',
      'riverpod',
      'get_it',
      'injectable',
      'freezed',
      'json_serializable',
      'equatable',
      'dartz',
      'rxdart',
      'stream_transform',
    ];

    final package = await anticipate.run(
      question: 'Select a package',
      suggestions: packages,
    );

    io.newLine();
    if (package != null) {
      io.success('Selected: $package');
    } else {
      io.warning('Selection cancelled');
    }
  }
}

/// Demonstrate textarea (multi-line editor input).
class UiTextareaCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:textarea';

  @override
  String get description =>
      'Demonstrate multi-line text input via external editor.';

  @override
  Future<void> run() async {
    io.title('Textarea / Editor Input');
    io.text('Opens your default editor for multi-line input.');
    io.newLine();

    final textarea = Textarea(style: io.style);

    io.section('Simple Text Input');
    try {
      final text = await textarea.edit(
        prompt: 'Enter a description',
        helpText:
            'Enter your description below.\nLines starting with # are ignored.',
        initialContent: 'This is the default content.\nYou can edit it.',
      );

      if (text != null && text.isNotEmpty) {
        io.success('Received ${text.split('\n').length} line(s):');
        io.newLine();
        for (final line in text.split('\n')) {
          io.writeln('  $line');
        }
      } else {
        io.warning('No content entered');
      }
    } catch (e) {
      io.error('Editor not available: $e');
      io.note('Set the \$EDITOR environment variable to use this feature.');
    }
  }
}

/// Demonstrate wizard (multi-step flow).
class UiWizardCommand extends ArtisanCommand<void> {
  UiWizardCommand() {
    argParser.addFlag(
      'non-interactive',
      abbr: 'n',
      negatable: false,
      help: 'Use defaults for all prompts.',
    );
  }

  @override
  String get name => 'ui:wizard';

  @override
  String get description => 'Demonstrate multi-step wizard flow.';

  @override
  Future<void> run() async {
    final nonInteractive = argResults?['non-interactive'] == true;

    io.title('Wizard / Multi-Step Flow');

    final wizard = Wizard(
      title: 'Create New Project',
      description: 'This wizard will guide you through creating a new project.',
      steps: [
        WizardStep.ask(
          'name',
          'Project name',
          defaultValue: 'my_project',
          validator: (value) {
            if (value.isEmpty) return 'Name is required';
            if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(value)) {
              return 'Name must be a valid Dart identifier';
            }
            return null;
          },
        ),
        // Interactive select with arrow keys!
        WizardStep.select(
          'template',
          'Project template',
          choices: ['console', 'package', 'server', 'flutter'],
          defaultIndex: 0,
        ),
        WizardStep.confirm(
          'git',
          'Initialize Git repository?',
          defaultValue: true,
        ),
        WizardStep.conditional(
          WizardStep.ask('git_remote', 'Git remote URL (optional)'),
          condition: (answers) => answers['git'] == true,
        ),
        // Interactive multi-select with arrow keys and space to toggle!
        WizardStep.multiSelect(
          'features',
          'Select features to include',
          choices: ['Testing', 'CI/CD', 'Documentation', 'Linting', 'Docker'],
          defaultSelected: [0, 3],
        ),
        WizardStep.group(
          'author',
          'Author Information',
          steps: [
            WizardStep.ask(
              'author_name',
              'Author name',
              defaultValue: 'Anonymous',
            ),
            WizardStep.ask('author_email', 'Author email'),
          ],
        ),
      ],
      style: io.style,
      stdin: dartio.stdin,
      stdout: dartio.stdout,
      noInteraction: nonInteractive,
    );

    final results = await wizard.run();

    io.section('Wizard Results');
    io.components.horizontalTable({
      'Name': results['name'],
      'Template': results['template'],
      'Git': results['git'] == true ? 'Yes' : 'No',
      'Git Remote': results['git_remote'] ?? '-',
      'Features': (results['features'] as List?)?.join(', ') ?? '-',
      'Author': results['author_name'] ?? '-',
      'Email': results['author_email'] ?? '-',
    });
  }
}

/// Demonstrate clickable terminal links.
class UiLinkCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:link';

  @override
  String get description =>
      'Demonstrate clickable terminal hyperlinks (OSC 8).';

  @override
  Future<void> run() async {
    io.title('Terminal Hyperlinks (OSC 8)');
    io.text('Modern terminals support clickable links.');
    io.newLine();

    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );

    io.section('Link Support');
    io.twoColumnDetail(
      'OSC 8 Supported',
      LinkComponent.isSupported ? 'Yes' : 'No',
    );
    io.newLine();

    io.section('Basic Links');
    io.write('  Visit ');
    LinkComponent(url: 'https://dart.dev', text: 'Dart').render(context);
    io.writeln(' for more information.');

    io.write('  Check out ');
    LinkComponent(url: 'https://flutter.dev', text: 'Flutter').render(context);
    io.writeln(' for mobile development.');

    io.write('  Read the ');
    LinkComponent(
      url: 'https://pub.dev/packages/artisan_args',
      text: 'artisan_args docs',
    ).render(context);
    io.writeln('.');
    io.newLine();

    io.section('Styled Links');
    io.write('  ');
    LinkComponent(
      url: 'https://github.com',
      text: 'GitHub (underlined & blue)',
      styled: true,
    ).renderln(context);
    io.newLine();

    io.section('Using LinkComponent');
    io.write('  ');
    LinkComponent(url: 'https://google.com', text: 'Google').renderln(context);
    io.write('  ');
    LinkComponent(
      url: 'https://dart.dev/guides',
      text: 'Dart Guides',
      styled: true,
    ).renderln(context);
    io.newLine();

    io.section('Link Group (for footnotes)');
    final links = LinkGroupComponent(prefix: 'ref');
    io.writeln(
      '  Dart${links.add('https://dart.dev', text: '[1]')} is great for building ',
    );
    io.writeln(
      '  Flutter${links.add('https://flutter.dev', text: '[2]')} apps.',
    );
    io.newLine();
    io.writeln('  References:');
    links.renderln(context);
    io.newLine();

    io.note('Links may not be clickable in all terminals.');
    io.text('Supported: iTerm2, Windows Terminal, VS Code, Hyper, WezTerm');
  }
}

/// Demonstrate the new component system.
class UiComponentSystemCommand extends ArtisanCommand<void> {
  @override
  String get name => 'ui:system';

  @override
  String get description =>
      'Demonstrate the structured component system (Flutter-like).';

  @override
  Future<void> run() async {
    // Create a component context
    final context = ComponentContext(
      style: io.style,
      stdout: dartio.stdout,
      stdin: dartio.stdin,
      terminalWidth: io.terminalWidth,
    );

    io.title('Component System Demo');
    io.text('A structured way to build CLI UIs, similar to Flutter widgets.');
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Static Components');

    // Text components
    io.writeln('Text components:');
    Text('  Plain text').renderln(context);
    StyledText.info('  Info styled text').renderln(context);
    StyledText.success('  Success styled text').renderln(context);
    StyledText.warning('  Warning styled text').renderln(context);
    StyledText.error('  Error styled text').renderln(context);
    io.newLine();

    // Rule component
    io.writeln('Rule component:');
    Rule().renderln(context);
    Rule(text: 'Section').renderln(context);
    io.newLine();

    // Lists
    io.writeln('List components:');
    BulletList(items: ['Apple', 'Banana', 'Cherry']).renderln(context);
    io.newLine();
    NumberedList(items: ['First', 'Second', 'Third']).renderln(context);
    io.newLine();

    // Key-value
    io.writeln('KeyValue component:');
    KeyValue(key: 'Name', value: 'artisan_args').renderln(context);
    KeyValue(key: 'Version', value: '1.0.0').renderln(context);
    KeyValue(key: 'Author', value: 'You').renderln(context);
    io.newLine();

    // Box
    io.writeln('Box component:');
    Box(
      content: 'This is a boxed message.\nIt can have multiple lines.',
      title: 'Notice',
      borderStyle: BorderStyle.rounded,
    ).renderln(context);
    io.newLine();

    // Progress bar
    io.writeln('ProgressBar component:');
    ProgressBar(current: 7, total: 10).renderln(context);
    ProgressBar(
      current: 3,
      total: 10,
      fillChar: '▓',
      emptyChar: '░',
    ).renderln(context);
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Composition');

    io.writeln('Components can be composed together:');
    io.newLine();

    ColumnComponent(
      children: [
        StyledText.heading('  My Application'),
        Rule(char: '─'),
        BulletList(
          items: ['Feature 1: Fast', 'Feature 2: Easy', 'Feature 3: Beautiful'],
          indent: 4,
        ),
      ],
    ).renderln(context);
    io.newLine();

    // Row composition
    io.writeln('Row composition:');
    RowComponent(
      children: [
        StyledText.success('✓ Pass'),
        Text(' | '),
        StyledText.error('✗ Fail'),
        Text(' | '),
        StyledText.warning('⚠ Warn'),
      ],
    ).renderln(context);
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Output Components');

    io.writeln('PanelComponent:');
    PanelComponent(
      content:
          'This is a panel using the component system.\nIt supports titles and alignment.',
      title: 'Panel Demo',
    ).renderln(context);
    io.newLine();

    io.writeln('TaskComponent:');
    TaskComponent(
      description: 'Compiling assets',
      status: TaskStatus.success,
    ).renderln(context);
    TaskComponent(
      description: 'Running tests',
      status: TaskStatus.failure,
    ).renderln(context);
    TaskComponent(
      description: 'Deploying',
      status: TaskStatus.skipped,
    ).renderln(context);
    io.newLine();

    io.writeln('AlertComponent:');
    AlertComponent(
      message: 'This is informational',
      type: AlertType.info,
    ).renderln(context);
    AlertComponent(
      message: 'Operation succeeded',
      type: AlertType.success,
    ).renderln(context);
    AlertComponent(
      message: 'Be careful!',
      type: AlertType.warning,
    ).renderln(context);
    AlertComponent(
      message: 'Something went wrong',
      type: AlertType.error,
    ).renderln(context);
    io.newLine();

    io.writeln('TwoColumnDetailComponent:');
    TwoColumnDetailComponent(
      left: 'Name',
      right: 'artisan_args',
    ).renderln(context);
    TwoColumnDetailComponent(left: 'Version', right: '1.0.0').renderln(context);
    TwoColumnDetailComponent(left: 'Status', right: 'Active').renderln(context);
    io.newLine();

    io.writeln('TreeComponent:');
    TreeComponent(
      data: {
        'src': {
          'lib': ['main.dart', 'utils.dart'],
          'test': ['main_test.dart'],
        },
        'pubspec.yaml': null,
        'README.md': null,
      },
    ).renderln(context);
    io.newLine();

    io.writeln('ColumnsComponent:');
    ColumnsComponent(
      items: [
        'apple',
        'banana',
        'cherry',
        'date',
        'elderberry',
        'fig',
        'grape',
        'honeydew',
      ],
      columnCount: 4,
    ).renderln(context);
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Interactive Components');

    io.text('Interactive components return values from user input.');
    io.newLine();

    io.writeln('Available interactive components:');
    io.components.bulletList([
      'TextInput - text input with validation',
      'Confirm - yes/no confirmation',
      'SecretInputComponent - password input',
      'Select<T> - single select with arrow keys',
      'MultiSelect<T> - multi select with arrow keys',
      'SpinnerComponent - async progress spinner',
    ]);
    io.newLine();

    // Demo interactive components
    io.writeln('Demo: Select component');
    final color = await Select<String>(
      prompt: 'Pick your favorite color',
      options: ['Red', 'Green', 'Blue', 'Yellow'],
    ).interact(context);

    if (color != null) {
      io.success('You selected: $color');
    }
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Custom Components');

    io.text('Create custom components by extending CliComponent:');
    io.newLine();

    io.writeln('''
    class MyBanner extends CliComponent {
      final String title;
      MyBanner(this.title);

      @override
      RenderResult build(ComponentContext context) {
        return RenderResult(
          output: context.style.heading('★ \$title ★'),
          lineCount: 1,
        );
      }
    }
    ''');

    // Demo custom component
    _CustomBanner('artisan_args').renderln(context);
  }
}

/// Example custom component.
class _CustomBanner extends CliComponent {
  const _CustomBanner(this.title);

  final String title;

  @override
  RenderResult build(ComponentContext context) {
    final stars = '★ ' * 3;
    final output = context.style.heading('$stars$title$stars');
    return RenderResult(output: output, lineCount: 1);
  }
}
