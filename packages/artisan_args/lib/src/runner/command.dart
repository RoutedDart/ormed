import 'dart:io' as dartio;

import 'package:args/command_runner.dart';

import '../io/artisan_io.dart';
import '../style/artisan_style.dart';
import 'command_listing.dart';
import 'command_runner.dart';

/// Base command class for Artisan-style CLI commands.
///
/// Provides access to the [io] helper for console output and
/// renders help with proper section formatting.
///
/// ```dart
/// class ServeCommand extends ArtisanCommand<void> {
///   @override
///   String get name => 'serve';
///
///   @override
///   String get description => 'Start the development server.';
///
///   @override
///   Future<void> run() async {
///     io.title('Starting server...');
///     // ...
///   }
/// }
/// ```
abstract class ArtisanCommand<T> extends Command<T> {
  /// Creates a new command with optional aliases.
  ArtisanCommand({List<String> aliases = const []}) : _aliases = aliases;

  final List<String> _aliases;

  @override
  List<String> get aliases => _aliases;

  /// Access to the I/O helper for console output.
  ///
  /// Use this to output formatted messages, tables, progress bars, etc.
  ArtisanIO get io {
    final r = runner;
    if (r is ArtisanCommandRunner<T>) {
      return r.io;
    }
    return ArtisanIO(
      style: ArtisanStyle(ansi: false),
      out: dartio.stdout.writeln,
      err: dartio.stderr.writeln,
    );
  }

  /// Separator used to group subcommands for display.
  ///
  /// Defaults to `:` (matching Artisan-style namespaces).
  String get namespaceSeparator {
    final r = runner;
    if (r is ArtisanCommandRunner<T>) {
      return r.namespaceSeparator;
    }
    return ':';
  }

  @override
  void printUsage() {
    final r = runner;
    if (r is ArtisanCommandRunner<T>) {
      r.writeOut(formatUsage());
      return;
    }
    dartio.stdout.writeln(formatUsage());
  }

  @override
  Never usageException(String message) =>
      throw UsageException(message, formatUsage(includeDescription: true));

  /// Formats help output for this command.
  String formatUsage({bool includeDescription = true}) {
    final buffer = StringBuffer();
    final style = runner is ArtisanCommandRunner<T>
        ? (runner as ArtisanCommandRunner<T>).style
        : ArtisanStyle(ansi: false);

    final desc = description.trim();
    if (includeDescription && desc.isNotEmpty) {
      buffer.writeln(style.heading('Description:'));
      buffer.writeln('  $desc');
      buffer.writeln();
    }

    buffer.writeln(style.heading('Usage:'));
    buffer.writeln('  ${invocation.trim()}');
    buffer.writeln();

    buffer.writeln(style.heading('Options:'));
    final options = argParser.usage.trimRight();
    if (options.isEmpty) {
      buffer.writeln('  (none)');
    } else {
      buffer.writeln(indentBlock(style.formatOptionsUsage(options), 2));
    }

    final uniqueSubs = <Command<T>>{};
    final entries = <CommandListingEntry>[];
    for (final sub in subcommands.values) {
      if (!uniqueSubs.add(sub)) continue;
      if (sub.hidden) continue;
      entries.add(
        CommandListingEntry(name: sub.name, description: sub.summary),
      );
    }
    if (entries.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(style.heading('Available commands:'));
      buffer.writeln(
        formatCommandListing(
          entries,
          namespaceSeparator: namespaceSeparator,
          styleNamespace: style.heading,
          styleCommand: style.command,
        ),
      );
    }

    return buffer.toString().trimRight();
  }
}
