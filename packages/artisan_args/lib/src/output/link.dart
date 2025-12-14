import 'dart:io' as io;

import '../style/artisan_style.dart';

/// Creates clickable hyperlinks in terminals that support OSC 8.
///
/// OSC 8 is an escape sequence that allows terminals to render clickable links.
/// Not all terminals support this feature.
///
/// ```dart
/// final link = TerminalLink(style: style, stdout: io.stdout);
/// link.write('https://dart.dev', text: 'Dart Website');
/// ```
class TerminalLink {
  TerminalLink({required this.style, required io.Stdout stdout})
    : _stdout = stdout;

  final ArtisanStyle style;
  final io.Stdout _stdout;

  /// Whether the terminal likely supports OSC 8 links.
  bool get isSupported {
    if (!style.enabled) return false;

    // Check for known supporting terminals
    final term = io.Platform.environment['TERM'] ?? '';
    final termProgram = io.Platform.environment['TERM_PROGRAM'] ?? '';
    final wtSession = io.Platform.environment['WT_SESSION'];
    final conemu = io.Platform.environment['ConEmuANSI'];

    // Known supporting terminals
    if (termProgram == 'iTerm.app') return true;
    if (termProgram == 'vscode') return true;
    if (termProgram == 'Hyper') return true;
    if (termProgram == 'WezTerm') return true;
    if (wtSession != null) return true; // Windows Terminal
    if (conemu == 'ON') return true; // ConEmu
    if (term.contains('xterm') || term.contains('256color')) return true;

    // Default to true if ANSI is supported - most modern terminals support OSC 8
    return true;
  }

  /// Creates an OSC 8 hyperlink string.
  ///
  /// If [text] is null, the URL is used as the display text.
  /// If [id] is provided, it's used to group related links.
  String create(String url, {String? text, String? id}) {
    if (!style.enabled) {
      return text ?? url;
    }

    final displayText = text ?? url;
    final params = id != null ? 'id=$id' : '';

    // OSC 8 format: \e]8;params;url\e\\text\e]8;;\e\\
    // Using \x1B for escape, and \x07 (BEL) or \x1B\\ as terminator
    return '\x1B]8;$params;$url\x07$displayText\x1B]8;;\x07';
  }

  /// Writes a hyperlink to stdout.
  void write(String url, {String? text, String? id}) {
    _stdout.write(create(url, text: text, id: id));
  }

  /// Writes a hyperlink followed by a newline.
  void writeln(String url, {String? text, String? id}) {
    _stdout.writeln(create(url, text: text, id: id));
  }

  /// Creates a styled link with underline and color.
  String styled(String url, {String? text, String? id}) {
    final link = create(url, text: text, id: id);
    if (!style.enabled) return link;

    // Apply underline and blue color
    return '\x1B[4;34m$link\x1B[0m';
  }

  /// Writes a styled link to stdout.
  void writeStyled(String url, {String? text, String? id}) {
    _stdout.write(styled(url, text: text, id: id));
  }

  /// Writes a styled link followed by a newline.
  void writelnStyled(String url, {String? text, String? id}) {
    _stdout.writeln(styled(url, text: text, id: id));
  }
}

/// Creates a clickable terminal link string.
///
/// ```dart
/// print(link('https://dart.dev', text: 'Visit Dart'));
/// ```
String link(String url, {String? text, String? id, bool styled = false}) {
  final displayText = text ?? url;

  // Check if ANSI is likely supported
  final supportsAnsi = io.stdout.supportsAnsiEscapes;
  if (!supportsAnsi) {
    return displayText;
  }

  final params = id != null ? 'id=$id' : '';
  final linkText = '\x1B]8;$params;$url\x07$displayText\x1B]8;;\x07';

  if (styled) {
    return '\x1B[4;34m$linkText\x1B[0m';
  }

  return linkText;
}

/// Creates multiple related links (e.g., for footnotes).
///
/// ```dart
/// final links = LinkGroup();
/// print('See ${links.add('https://dart.dev', 'Dart')} and ${links.add('https://flutter.dev', 'Flutter')}');
/// ```
class LinkGroup {
  LinkGroup({this.prefix = 'link'});

  final String prefix;
  int _counter = 0;

  /// Adds a link to the group and returns the link string.
  String add(String url, {String? text}) {
    final id = '$prefix-${_counter++}';
    return link(url, text: text, id: id);
  }

  /// Adds a styled link to the group.
  String addStyled(String url, {String? text}) {
    final id = '$prefix-${_counter++}';
    return link(url, text: text, id: id, styled: true);
  }
}
