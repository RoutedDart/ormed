import 'dart:io' as dartio;

import 'package:args/command_runner.dart';

import '../io/artisan_io.dart';
import '../style/artisan_style.dart';
import '../style/verbosity.dart';
import 'command_listing.dart';

/// Callback for writing a line to output.
typedef ArtisanWrite = void Function(String line);

/// Callback for writing raw text to output.
typedef ArtisanWriteRaw = void Function(String text);

/// Callback for reading a line of input.
typedef ArtisanReadLine = String? Function();

/// Callback for setting the process exit code.
typedef ArtisanExitCodeSetter = void Function(int code);

/// An Artisan-inspired wrapper around `package:args` [CommandRunner].
///
/// Provides a polished CLI experience with:
/// - Grouped namespaced commands (e.g., `ui:*`, `db:*`) in help output
/// - Sectioned command help (`Description`, `Usage`, `Options`)
/// - Friendly error handling without stack traces
/// - Global flags for verbosity, ANSI, and interactivity
///
/// ```dart
/// final runner = ArtisanCommandRunner('myapp', 'My application')
///   ..addCommand(ServeCommand())
///   ..addCommand(DbMigrateCommand());
///
/// await runner.run(args);
/// ```
class ArtisanCommandRunner<T> extends CommandRunner<T> {
  /// Creates a new command runner.
  ///
  /// - [executableName]: The name of the executable (shown in usage).
  /// - [description]: A description of the application.
  /// - [namespaceSeparator]: Character used to group commands (default: `:`).
  /// - [usageExitCode]: Exit code for usage errors (default: 64).
  /// - [ansi]: Force ANSI output on/off (auto-detected by default).
  ArtisanCommandRunner(
    super.executableName,
    super.description, {
    this.namespaceSeparator = ':',
    this.usageExitCode = 64,
    bool? ansi,
    ArtisanWrite? out,
    ArtisanWrite? err,
    ArtisanWriteRaw? outRaw,
    ArtisanWriteRaw? errRaw,
    ArtisanReadLine? readLine,
    ArtisanExitCodeSetter? setExitCode,
    int? usageLineLength,
  }) : _out = out ?? ((line) => dartio.stdout.writeln(line)),
       _err = err ?? ((line) => dartio.stderr.writeln(line)),
       _outRaw = outRaw ?? ((text) => dartio.stdout.write(text)),
       _errRaw = errRaw ?? ((text) => dartio.stderr.write(text)),
       _readLine = readLine,
       _setExitCode = setExitCode ?? ((code) => dartio.exitCode = code),
       _ansiOverride = ansi,
       _style = ArtisanStyle(ansi: ansi ?? dartio.stdout.supportsAnsiEscapes),
       super(usageLineLength: usageLineLength) {
    _setupGlobalFlags();
  }

  /// Separator used to group commands into namespaces.
  final String namespaceSeparator;

  /// Exit code set when a [UsageException] occurs.
  final int usageExitCode;

  final ArtisanWrite _out;
  final ArtisanWrite _err;
  final ArtisanWriteRaw _outRaw;
  final ArtisanWriteRaw _errRaw;
  final ArtisanReadLine? _readLine;
  final ArtisanExitCodeSetter _setExitCode;
  final bool? _ansiOverride;
  ArtisanStyle _style;
  ArtisanVerbosity _verbosity = ArtisanVerbosity.normal;
  bool _interactive = true;
  ArtisanIO? _io;

  /// The current ANSI style configuration.
  ArtisanStyle get style => _style;

  /// The current verbosity level.
  ArtisanVerbosity get verbosity => _verbosity;

  /// Whether interactive prompts are enabled.
  bool get interactive => _interactive;

  /// The I/O helper for console output.
  ArtisanIO get io => _io ??= _buildIo();

  @override
  String get usage => formatGlobalUsage();

  @override
  Never usageException(String message) => throw UsageException(
    message,
    formatGlobalUsage(includeDescription: false),
  );

  /// Writes a line to stdout.
  void writeOut(String line) => _out(line);

  /// Writes a line to stderr.
  void writeErr(String line) => _err(line);

  @override
  void printUsage() => writeOut(formatGlobalUsage());

  @override
  Future<T?> run(Iterable<String> args) async {
    _style = ArtisanStyle(ansi: _resolveAnsiForArgs(args));
    _verbosity = _resolveVerbosityForArgs(args);
    _interactive = _resolveInteractiveForArgs(args);
    _io = null;

    try {
      return await super.run(args);
    } on UsageException catch (e) {
      _printUsageError(e);
      _setExitCode(usageExitCode);
      return null;
    }
  }

  /// Formats global usage, grouping commands by namespace.
  String formatGlobalUsage({bool includeDescription = true}) {
    final buffer = StringBuffer();

    if (includeDescription && description.trim().isNotEmpty) {
      buffer.writeln(description.trim());
      buffer.writeln();
    }

    buffer.writeln(style.heading('Usage:'));
    buffer.writeln('  ${invocation.trim()}');
    buffer.writeln();

    buffer.writeln(style.heading('Options:'));
    final globalOptions = argParser.usage.trimRight();
    if (globalOptions.isNotEmpty) {
      buffer.writeln(indentBlock(style.formatOptionsUsage(globalOptions), 2));
    }
    buffer.writeln();

    buffer.writeln(style.heading('Available commands:'));
    buffer.writeln(
      formatCommandListing(
        _uniqueTopLevelEntries(),
        namespaceSeparator: namespaceSeparator,
        styleNamespace: style.heading,
        styleCommand: style.command,
      ),
    );
    buffer.writeln();
    buffer.writeln(
      'Run ${style.emphasize('"$executableName <command> --help"')} for more information about a command.',
    );

    return buffer.toString().trimRight();
  }

  void _setupGlobalFlags() {
    argParser.addFlag(
      'ansi',
      help: 'Force (or disable with --no-ansi) ANSI output.',
    );
    argParser.addFlag(
      'quiet',
      abbr: 'q',
      negatable: false,
      help: 'Do not output any message.',
    );
    argParser.addFlag('silent', negatable: false, help: 'Alias for --quiet.');
    argParser.addFlag(
      'no-interaction',
      abbr: 'n',
      negatable: false,
      help: 'Do not ask any interactive question.',
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help:
          'Increase verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.',
    );
  }

  Iterable<CommandListingEntry> _uniqueTopLevelEntries() {
    final seen = <Command<T>>{};
    final unique = <CommandListingEntry>[];
    for (final cmd in commands.values) {
      if (!seen.add(cmd)) continue;
      if (cmd.name == 'help') continue;
      unique.add(CommandListingEntry(name: cmd.name, description: cmd.summary));
    }
    unique.sort((a, b) => a.name.compareTo(b.name));
    return unique;
  }

  void _printUsageError(UsageException e) {
    final message = e.message.trim();
    if (message.isNotEmpty) {
      writeErr(style.error('Error: $message'));
      writeErr('');
    }
    writeOut(e.usage.trimRight());
  }

  bool _resolveAnsiForArgs(Iterable<String> args) {
    bool? last;
    for (final arg in args) {
      if (arg == '--ansi') last = true;
      if (arg == '--no-ansi') last = false;
    }
    if (last != null) return last;
    if (_ansiOverride != null) return _ansiOverride;
    return dartio.stdout.supportsAnsiEscapes;
  }

  ArtisanIO _buildIo() {
    final width = dartio.stdout.hasTerminal
        ? dartio.stdout.terminalColumns
        : null;
    return ArtisanIO(
      style: style,
      out: writeOut,
      err: writeErr,
      outRaw: _outRaw,
      errRaw: _errRaw,
      readLine: _readLine ?? (() => dartio.stdin.readLineSync()),
      interactive: interactive,
      verbosity: verbosity,
      terminalWidth: width,
    );
  }

  bool _resolveInteractiveForArgs(Iterable<String> args) {
    for (final arg in args) {
      if (arg == '--no-interaction' || arg == '-n') return false;
    }
    return true;
  }

  ArtisanVerbosity _resolveVerbosityForArgs(Iterable<String> args) {
    var quiet = false;
    var vCount = 0;

    for (final arg in args) {
      if (arg == '--quiet' || arg == '-q' || arg == '--silent') {
        quiet = true;
        continue;
      }
      if (arg == '--verbose' || arg == '-v') {
        vCount++;
        continue;
      }
      final match = RegExp(r'^-v+$').firstMatch(arg);
      if (match != null) {
        vCount += arg.length - 1;
      }
    }

    if (quiet) return ArtisanVerbosity.quiet;
    if (vCount <= 0) return ArtisanVerbosity.normal;
    if (vCount == 1) return ArtisanVerbosity.verbose;
    if (vCount == 2) return ArtisanVerbosity.veryVerbose;
    return ArtisanVerbosity.debug;
  }
}
