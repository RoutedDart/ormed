import '../style/color.dart';
import '../style/style.dart';
import 'base.dart';

/// Callback for per-item styling in trees.
///
/// [item] is the item being rendered (the label/name).
/// [depth] is the nesting depth (0 for root level).
/// [isDirectory] indicates if the item has children.
///
/// Return a [Style] to apply to the item, or `null` for no styling.
typedef TreeStyleFunc =
    Style? Function(String item, int depth, bool isDirectory);

/// Defines the characters used to draw tree branches.
///
/// ```dart
/// // Use a preset
/// Tree().enumerator(TreeEnumerator.rounded)
///
/// // Or create custom
/// Tree().enumerator(TreeEnumerator(
///   pipe: '│',
///   tee: '├',
///   elbow: '╰',
///   dash: '──',
/// ))
/// ```
class TreeEnumerator {
  /// Creates a tree enumerator with the specified characters.
  const TreeEnumerator({
    required this.pipe,
    required this.tee,
    required this.elbow,
    required this.dash,
    this.indent = '   ',
  });

  /// Vertical pipe character for continuing branches.
  final String pipe;

  /// T-junction character for non-last items.
  final String tee;

  /// Elbow/corner character for last items.
  final String elbow;

  /// Horizontal dash connecting to items.
  final String dash;

  /// Indentation string when no pipe is needed.
  final String indent;

  // ─────────────────────────────────────────────────────────────────────────
  // Preset Enumerators
  // ─────────────────────────────────────────────────────────────────────────

  /// Normal/standard tree characters (├── └──).
  static const normal = TreeEnumerator(
    pipe: '│',
    tee: '├',
    elbow: '└',
    dash: '──',
    indent: '    ',
  );

  /// Rounded tree characters with curved elbow (├── ╰──).
  static const rounded = TreeEnumerator(
    pipe: '│',
    tee: '├',
    elbow: '╰',
    dash: '──',
    indent: '    ',
  );

  /// ASCII-only characters for maximum compatibility (+-- `--).
  static const ascii = TreeEnumerator(
    pipe: '|',
    tee: '+',
    elbow: '`',
    dash: '--',
    indent: '    ',
  );

  /// Bullet-style list (• for all items).
  static const bullet = TreeEnumerator(
    pipe: ' ',
    tee: '•',
    elbow: '•',
    dash: ' ',
    indent: '  ',
  );

  /// Arrow-style list (→ for all items).
  static const arrow = TreeEnumerator(
    pipe: ' ',
    tee: '→',
    elbow: '→',
    dash: ' ',
    indent: '  ',
  );

  /// Dash-style list (- for all items).
  static const dash_ = TreeEnumerator(
    pipe: ' ',
    tee: '-',
    elbow: '-',
    dash: ' ',
    indent: '  ',
  );

  /// Heavy/thick tree characters.
  static const heavy = TreeEnumerator(
    pipe: '┃',
    tee: '┣',
    elbow: '┗',
    dash: '━━',
    indent: '    ',
  );

  /// Double-line tree characters.
  static const doubleLine = TreeEnumerator(
    pipe: '║',
    tee: '╠',
    elbow: '╚',
    dash: '══',
    indent: '    ',
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreeEnumerator &&
        other.pipe == pipe &&
        other.tee == tee &&
        other.elbow == elbow &&
        other.dash == dash &&
        other.indent == indent;
  }

  @override
  int get hashCode => Object.hash(pipe, tee, elbow, dash, indent);

  @override
  String toString() => 'TreeEnumerator(pipe: $pipe, tee: $tee, elbow: $elbow)';
}

/// A tree structure component.
///
/// ```dart
/// TreeComponent(
///   data: {
///     'src': {
///       'lib': ['main.dart', 'utils.dart'],
///       'test': ['main_test.dart'],
///     },
///     'pubspec.yaml': null,
///   },
/// ).renderln(context);
/// ```
class TreeComponent extends CliComponent {
  final Map<String, dynamic> data;
  final bool showRoot;
  final String rootLabel;

  /// The tree enumerator (branch characters) to use.
  final TreeEnumerator enumerator;

  /// Optional callback for per-item styling.
  final TreeStyleFunc? itemStyleFunc;

  /// Creates a TreeComponent with optional enumerator.
  const TreeComponent({
    required this.data,
    this.showRoot = false,
    this.rootLabel = '.',
    this.enumerator = TreeEnumerator.normal,
    this.itemStyleFunc,
  });

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    final nodeFn = (String s) =>
        context.newStyle().foreground(Colors.info).render(s);
    final leafFn = (String s) => s;
    final e = enumerator;

    if (showRoot) {
      String label = rootLabel;
      if (itemStyleFunc != null) {
        final style = itemStyleFunc!(rootLabel, 0, true);
        if (style != null) {
          style.colorProfile = context.colorProfile;
          style.hasDarkBackground = context.hasDarkBackground;
          label = style.render(rootLabel);
        } else {
          label = nodeFn(rootLabel);
        }
      } else {
        label = nodeFn(rootLabel);
      }
      buffer.writeln(label);
    }

    _renderNode(buffer, data, '', true, nodeFn, leafFn, e, 0, context);

    final output = buffer.toString().trimRight();
    final lineCount = output.split('\n').length;

    return RenderResult(output: output, lineCount: lineCount);
  }

  void _renderNode(
    StringBuffer buffer,
    dynamic node,
    String prefix,
    bool isLast,
    String Function(String) nodeFn,
    String Function(String) leafFn,
    TreeEnumerator e,
    int depth,
    ComponentContext context,
  ) {
    if (node is Map<String, dynamic>) {
      final entries = node.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLastEntry = i == entries.length - 1;
        final connector = isLastEntry ? e.elbow : e.tee;

        final isDirectory = entry.value is Map || entry.value is List;
        String label = entry.key;

        if (itemStyleFunc != null) {
          final style = itemStyleFunc!(label, depth + 1, isDirectory);
          if (style != null) {
            style.colorProfile = context.colorProfile;
            style.hasDarkBackground = context.hasDarkBackground;
            label = style.render(label);
          } else if (isDirectory) {
            label = nodeFn(label);
          } else {
            label = leafFn(label);
          }
        } else {
          if (isDirectory) {
            label = nodeFn(label);
          } else {
            label = leafFn(label);
          }
        }

        if (isDirectory) {
          buffer.writeln('$prefix$connector${e.dash} $label');
          final newPrefix = prefix + (isLastEntry ? e.indent : '${e.pipe}   ');
          _renderNode(
            buffer,
            entry.value,
            newPrefix,
            isLastEntry,
            nodeFn,
            leafFn,
            e,
            depth + 1,
            context,
          );
        } else {
          buffer.writeln('$prefix$connector${e.dash} $label');
        }
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        final item = node[i];
        final isLastItem = i == node.length - 1;
        final connector = isLastItem ? e.elbow : e.tee;

        final isDirectory = item is Map || item is List;

        if (isDirectory) {
          _renderNode(
            buffer,
            item,
            prefix,
            isLastItem,
            nodeFn,
            leafFn,
            e,
            depth,
            context,
          );
        } else {
          String label = item.toString();
          if (itemStyleFunc != null) {
            final style = itemStyleFunc!(label, depth + 1, false);
            if (style != null) {
              style.colorProfile = context.colorProfile;
              style.hasDarkBackground = context.hasDarkBackground;
              label = style.render(label);
            } else {
              label = leafFn(label);
            }
          } else {
            label = leafFn(label);
          }

          buffer.writeln('$prefix$connector${e.dash} $label');
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent Tree Builder
// ─────────────────────────────────────────────────────────────────────────────

/// A fluent builder for creating styled trees.
///
/// Provides a chainable API for tree configuration with support for
/// customizable enumerators and per-item conditional styling.
///
/// ```dart
/// final tree = Tree()
///     .root('Project')
///     .child('src/', [
///       Tree().root('lib/').child(['main.dart', 'utils.dart']),
///       'README.md',
///     ])
///     .enumerator(TreeEnumerator.rounded)
///     .itemStyleFunc((item, depth, isDir) {
///       if (isDir) {
///         return Style().bold().foreground(Colors.blue);
///       }
///       return null;
///     })
///     .render();
///
/// print(tree);
/// ```
class Tree extends FluentComponent<Tree> {
  /// Creates a new empty tree builder.
  Tree();

  String? _root;
  final List<dynamic> _children = [];
  TreeEnumerator _enumerator = TreeEnumerator.normal;
  TreeStyleFunc? _styleFunc;
  bool _showRoot = true;
  Style? _rootStyle;
  Style? _directoryStyle;
  Style? _fileStyle;
  Style? _branchStyle;

  /// Sets the root label.
  Tree root(String label) {
    _root = label;
    return this;
  }

  /// Adds a child item.
  ///
  /// [item] can be:
  /// - A string (leaf node)
  /// - A [Tree] (nested subtree)
  /// - A list of items
  Tree child(dynamic item) {
    _children.add(item);
    return this;
  }

  /// Adds multiple children.
  Tree children(List<dynamic> items) {
    _children.addAll(items);
    return this;
  }

  /// Sets the tree enumerator (branch characters).
  Tree enumerator(TreeEnumerator e) {
    _enumerator = e;
    return this;
  }

  /// Sets the style function for per-item conditional styling.
  Tree itemStyleFunc(TreeStyleFunc func) {
    _styleFunc = func;
    return this;
  }

  /// Sets whether to show the root node.
  Tree showRoot(bool value) {
    _showRoot = value;
    return this;
  }

  /// Sets the root node style.
  Tree rootStyle(Style style) {
    _rootStyle = style;
    return this;
  }

  /// Sets the directory/folder style (items with children).
  Tree directoryStyle(Style style) {
    _directoryStyle = style;
    return this;
  }

  /// Sets the file/leaf style (items without children).
  Tree fileStyle(Style style) {
    _fileStyle = style;
    return this;
  }

  /// Sets the branch character style.
  Tree branchStyle(Style style) {
    _branchStyle = style;
    return this;
  }

  /// Renders the tree to a string.
  @override
  String render() {
    final buffer = StringBuffer();

    if (_showRoot && _root != null) {
      final styled = _applyStyle(_root!, 0, _children.isNotEmpty, isRoot: true);
      buffer.writeln(styled);
    }

    _renderChildren(buffer, _children, '', 0);

    return buffer.toString().trimRight();
  }

  void _renderChildren(
    StringBuffer buffer,
    List<dynamic> children,
    String prefix,
    int depth,
  ) {
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final isLast = i == children.length - 1;
      final connector = isLast ? _enumerator.elbow : _enumerator.tee;
      final nextPrefix =
          prefix + (isLast ? _enumerator.indent : '${_enumerator.pipe}   ');

      // Style the branch characters
      final styledConnector = _styleBranch('$connector${_enumerator.dash}');

      if (child is Tree) {
        // Nested tree
        final hasChildren = child._children.isNotEmpty;
        final label = child._root ?? '';
        final styled = _applyStyle(label, depth, hasChildren);
        buffer.writeln('$prefix$styledConnector $styled');
        _renderChildren(buffer, child._children, nextPrefix, depth + 1);
      } else if (child is List) {
        // List of children
        _renderChildren(buffer, child, prefix, depth);
      } else {
        // Leaf node
        final label = child.toString();
        final styled = _applyStyle(label, depth, false);
        buffer.writeln('$prefix$styledConnector $styled');
      }
    }
  }

  String _applyStyle(
    String text,
    int depth,
    bool isDirectory, {
    bool isRoot = false,
  }) {
    // Try style function first
    if (_styleFunc != null) {
      final style = _styleFunc!(text, depth, isDirectory);
      if (style != null) {
        return configureStyle(style).render(text);
      }
    }

    // Apply specific styles
    if (isRoot && _rootStyle != null) {
      return configureStyle(_rootStyle!).render(text);
    }

    if (isDirectory && _directoryStyle != null) {
      return configureStyle(_directoryStyle!).render(text);
    }

    if (!isDirectory && _fileStyle != null) {
      return configureStyle(_fileStyle!).render(text);
    }

    return text;
  }

  String _styleBranch(String text) {
    if (_branchStyle != null) {
      return configureStyle(_branchStyle!).render(text);
    }
    return text;
  }

  /// Returns the number of lines in the rendered tree.
  @override
  int get lineCount {
    var count = _showRoot && _root != null ? 1 : 0;
    count += _countChildren(_children);
    return count;
  }

  int _countChildren(List<dynamic> children) {
    var count = 0;
    for (final child in children) {
      if (child is Tree) {
        count += 1 + _countChildren(child._children);
      } else if (child is List) {
        count += _countChildren(child);
      } else {
        count += 1;
      }
    }
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree Factory Methods
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common tree styles.
extension TreeFactory on Tree {
  /// Creates a tree from a nested map structure.
  static Tree fromMap(Map<String, dynamic> data, {String? root}) {
    final tree = Tree();
    if (root != null) tree.root(root);

    void addItems(Tree t, Map<String, dynamic> map) {
      for (final entry in map.entries) {
        if (entry.value is Map<String, dynamic>) {
          final subtree = Tree()..root(entry.key);
          addItems(subtree, entry.value as Map<String, dynamic>);
          t.child(subtree);
        } else if (entry.value is List) {
          final subtree = Tree()..root(entry.key);
          for (final item in entry.value as List) {
            if (item is Map<String, dynamic>) {
              final nested = Tree();
              addItems(nested, item);
              subtree.child(nested);
            } else {
              subtree.child(item.toString());
            }
          }
          t.child(subtree);
        } else {
          t.child(entry.key);
        }
      }
    }

    addItems(tree, data);
    return tree;
  }

  /// Creates a file tree with directory styling.
  static Tree fileTree(Map<String, dynamic> structure, {String? root}) {
    return fromMap(structure, root: root)
      ..enumerator(TreeEnumerator.normal)
      ..directoryStyle(Style().bold().foreground(Colors.info))
      ..fileStyle(Style().foreground(Colors.white));
  }

  /// Creates a rounded tree.
  static Tree rounded(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.rounded);
  }

  /// Creates an ASCII-compatible tree.
  static Tree ascii(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.ascii);
  }

  /// Creates a bullet-style list tree.
  static Tree bulletList(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.bullet);
  }

  /// Creates an arrow-style list tree.
  static Tree arrowList(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.arrow);
  }

  /// Creates a tree with colored depth levels.
  static Tree coloredDepth(String rootLabel, {List<Color>? depthColors}) {
    final colors =
        depthColors ??
        [Colors.info, Colors.cyan, Colors.green, Colors.yellow, Colors.magenta];

    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.rounded)
      ..itemStyleFunc((item, depth, isDir) {
        final colorIndex = depth % colors.length;
        final style = Style().foreground(colors[colorIndex]);
        if (isDir) return style.bold();
        return style;
      });
  }

  /// Creates a tree that highlights directories.
  static Tree highlightDirectories(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.normal)
      ..directoryStyle(Style().bold().foreground(Colors.info))
      ..branchStyle(Style().dim());
  }

  /// Creates a tree with muted styling.
  static Tree muted(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.normal)
      ..rootStyle(Style().dim())
      ..directoryStyle(Style().dim())
      ..fileStyle(Style().dim())
      ..branchStyle(Style().dim());
  }
}
