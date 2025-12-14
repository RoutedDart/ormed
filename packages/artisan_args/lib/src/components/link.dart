import 'dart:io' as io;

import 'base.dart';

/// A clickable hyperlink component (OSC 8).
///
/// ```dart
/// LinkComponent(
///   url: 'https://dart.dev',
///   text: 'Visit Dart',
/// ).renderln(context);
/// ```
class LinkComponent extends CliComponent {
  const LinkComponent({
    required this.url,
    this.text,
    this.id,
    this.styled = false,
  });

  final String url;
  final String? text;
  final String? id;
  final bool styled;

  @override
  RenderResult build(ComponentContext context) {
    final displayText = text ?? url;

    if (!context.style.enabled) {
      return RenderResult(output: displayText, lineCount: 1);
    }

    final params = id != null ? 'id=$id' : '';
    final linkText = '\x1B]8;$params;$url\x07$displayText\x1B]8;;\x07';

    if (styled) {
      // Apply underline and blue color
      return RenderResult(output: '\x1B[4;34m$linkText\x1B[0m', lineCount: 1);
    }

    return RenderResult(output: linkText, lineCount: 1);
  }

  /// Whether the terminal likely supports OSC 8 links.
  static bool get isSupported {
    final term = io.Platform.environment['TERM'] ?? '';
    final termProgram = io.Platform.environment['TERM_PROGRAM'] ?? '';
    final wtSession = io.Platform.environment['WT_SESSION'];
    final conemu = io.Platform.environment['ConEmuANSI'];

    if (termProgram == 'iTerm.app') return true;
    if (termProgram == 'vscode') return true;
    if (termProgram == 'Hyper') return true;
    if (termProgram == 'WezTerm') return true;
    if (wtSession != null) return true;
    if (conemu == 'ON') return true;
    if (term.contains('xterm') || term.contains('256color')) return true;

    return io.stdout.supportsAnsiEscapes;
  }
}

/// A group of related links component.
///
/// Collects links and renders them as a numbered list of footnotes.
///
/// ```dart
/// final links = LinkGroupComponent();
/// final ref1 = links.add('https://dart.dev', text: 'Dart');
/// final ref2 = links.add('https://flutter.dev', text: 'Flutter');
/// print('See $ref1 and $ref2');
/// links.renderln(context); // Renders: [1] https://dart.dev  [2] https://flutter.dev
/// ```
class LinkGroupComponent extends CliComponent {
  LinkGroupComponent({this.prefix = 'link'});

  final String prefix;
  int _counter = 0;
  final List<_LinkEntry> _links = [];

  /// Adds a link to the group and returns a reference string.
  String add(String url, {String? text, bool styled = false}) {
    final id = '$prefix-${_counter++}';
    final displayText = text ?? url;
    final refNumber = _links.length + 1;

    _links.add(_LinkEntry(url: url, text: displayText, id: id));

    if (!io.stdout.supportsAnsiEscapes) {
      return '$displayText[$refNumber]';
    }

    final params = 'id=$id';
    final linkText = '\x1B]8;$params;$url\x07$displayText\x1B]8;;\x07';

    if (styled) {
      return '\x1B[4;34m$linkText\x1B[0m';
    }

    return linkText;
  }

  /// Creates a link string without adding to the group (for inline use).
  String createLink(String url, {String? text, bool styled = false}) {
    final id = '$prefix-inline-${_counter++}';
    final displayText = text ?? url;

    if (!io.stdout.supportsAnsiEscapes) {
      return displayText;
    }

    final params = 'id=$id';
    final linkText = '\x1B]8;$params;$url\x07$displayText\x1B]8;;\x07';

    if (styled) {
      return '\x1B[4;34m$linkText\x1B[0m';
    }

    return linkText;
  }

  @override
  RenderResult build(ComponentContext context) {
    if (_links.isEmpty) return RenderResult.empty;

    final buffer = StringBuffer();
    for (var i = 0; i < _links.length; i++) {
      final link = _links[i];
      final refNumber = i + 1;

      if (i > 0) buffer.writeln();

      if (context.style.enabled) {
        final params = 'id=${link.id}';
        final linkText =
            '\x1B]8;$params;${link.url}\x07${link.url}\x1B]8;;\x07';
        buffer.write('${context.style.muted('[$refNumber]')} $linkText');
      } else {
        buffer.write('[$refNumber] ${link.url}');
      }
    }

    return RenderResult(output: buffer.toString(), lineCount: _links.length);
  }

  /// Clears all collected links.
  void clear() {
    _links.clear();
    _counter = 0;
  }
}

class _LinkEntry {
  _LinkEntry({required this.url, required this.text, required this.id});

  final String url;
  final String text;
  final String id;
}
