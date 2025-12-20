/// Command-line argument parsing and command runners for Artisanal.
///
/// This library provides [CommandRunner] and [Command] which extend
/// `package:args` to provide a polished CLI experience with:
/// - Automatic help generation with Lip Gloss styling.
/// - Support for subcommands and nested command structures.
/// - Integration with [Console] for verbosity-aware output.
/// - Custom usage formatting and command listing.
///
/// ## Usage
///
/// ```dart
/// import 'package:artisanal/args.dart';
///
/// class MyCommand extends Command {
///   @override
///   String get name => 'hello';
///   @override
///   String get description => 'Say hello';
///
///   @override
///   void run() {
///     print('Hello, world!');
///   }
/// }
///
/// void main(List<String> args) {
///   final runner = CommandRunner('my-cli', 'A great CLI');
///   runner.addCommand(MyCommand());
///   runner.run(args);
/// }
/// ```
library artisanal.args;

export 'src/runner/command.dart' show Command;
export 'src/runner/command_listing.dart'
    show CommandListingEntry, formatCommandListing, indentBlock;
export 'src/runner/command_runner.dart' show CommandRunner;
