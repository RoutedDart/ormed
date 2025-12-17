/// Lipgloss-style List component for terminal output.
///
/// Provides a fluent, chainable API for creating styled lists.
///
/// ```dart
/// final list = LipList.create(['Foo', 'Bar', 'Baz'])
///     .enumerator(ListEnumerators.bullet)
///     .itemStyle(Style().foreground(Colors.cyan));
///
/// print(list);
/// ```
library;

import '../layout/layout.dart';
import 'style.dart';

/// Callback for determining the style of a list item.
typedef ListStyleFunc = Style Function(ListItems items, int index);

/// Callback for generating the enumerator string for a list item.
typedef ListEnumeratorFunc = String Function(ListItems items, int index);

/// Callback for generating indentation for nested items.
typedef ListIndenterFunc = String Function(ListItems items, int index);

/// Provides access to list items for style/enumerator functions.
abstract class ListItems {
  /// Returns the item at the given index.
  ListItem at(int index);

  /// Returns the number of items.
  int get length;
}

/// A single item in a list.
abstract class ListItem {
  /// The value/content of this item.
  String get value;

  /// The children of this item (for nested lists).
  ListItems get children;

  /// Whether this item is hidden.
  bool get hidden;
}

// ═══════════════════════════════════════════════════════════════════════════
// List Implementation
// ═══════════════════════════════════════════════════════════════════════════

/// Internal implementation of ListItems.
class _ListItems implements ListItems {
  final List<_ListNode> _nodes;

  _ListItems(this._nodes);

  @override
  ListItem at(int index) =>
      (index >= 0 && index < _nodes.length) ? _nodes[index] : _EmptyItem();

  @override
  int get length => _nodes.length;

  /// Returns visible items only.
  List<_ListNode> get visible => _nodes.where((n) => !n._hidden).toList();
}

/// Empty item placeholder.
class _EmptyItem implements ListItem {
  @override
  String get value => '';

  @override
  ListItems get children => _ListItems([]);

  @override
  bool get hidden => true;
}

/// Internal node implementation.
class _ListNode implements ListItem {
  String _value;
  final List<_ListNode> _children = [];
  bool _hidden = false;

  _ListNode(this._value);

  @override
  String get value => _value;

  @override
  ListItems get children => _ListItems(_children);

  @override
  bool get hidden => _hidden;
}

// ═══════════════════════════════════════════════════════════════════════════
// LipList - Fluent List Builder
// ═══════════════════════════════════════════════════════════════════════════

/// A fluent, chainable list builder inspired by Go's lipgloss list.
///
/// ```dart
/// final groceries = LipList.create([
///   'Bananas',
///   'Barley',
///   'Cashews',
///   LipList.create(['Almond Milk', 'Coconut Milk', 'Full Fat Milk']),
///   'Eggs',
/// ]);
///
/// print(groceries);
/// ```
class LipList {
  final List<_ListNode> _items = [];
  ListEnumeratorFunc _enumerator = ListEnumerators.bullet;
  ListIndenterFunc _indenter = (_, __) => ' ';
  ListStyleFunc _itemStyleFunc = (_, __) => Style();
  ListStyleFunc _enumeratorStyleFunc = (_, __) => Style();
  int _startOffset = 0;
  int _endOffset = 0;
  bool _hidden = false;

  /// Creates a new empty list.
  LipList();

  /// Creates a new list with the given items.
  ///
  /// Items can be strings, other LipLists (for nesting), or any object
  /// that can be converted to a string.
  factory LipList.create(List<dynamic> items) {
    final list = LipList();
    return list.items(items);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Item Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Adds a single item to the list.
  ///
  /// [item] can be a string, LipList (for nesting), or any object.
  LipList item(dynamic item) {
    if (item is LipList) {
      // Nested list - convert to a node with children
      final node = _ListNode('');
      node._children.addAll(item._items);
      _items.add(node);
    } else {
      _items.add(_ListNode(item.toString()));
    }
    return this;
  }

  /// Adds multiple items to the list.
  LipList items(List<dynamic> items) {
    for (final item in items) {
      this.item(item);
    }
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Enumerator & Indenter
  // ─────────────────────────────────────────────────────────────────────────

  /// Sets the list enumerator.
  ///
  /// The enumerator generates the prefix for each item (e.g., "•", "1.", "a.").
  ///
  /// ```dart
  /// list.enumerator(ListEnumerators.arabic)  // 1. 2. 3.
  /// list.enumerator(ListEnumerators.roman)   // I. II. III.
  /// list.enumerator(ListEnumerators.bullet)  // • • •
  /// ```
  LipList enumerator(ListEnumeratorFunc fn) {
    _enumerator = fn;
    return this;
  }

  /// Sets the indenter for nested items.
  ///
  /// The indenter generates the prefix for child items at each level.
  LipList indenter(ListIndenterFunc fn) {
    _indenter = fn;
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Styling
  // ─────────────────────────────────────────────────────────────────────────

  /// Sets a static style for all items.
  LipList itemStyle(Style style) {
    _itemStyleFunc = (_, __) => style;
    return this;
  }

  /// Sets a function to determine item style per-item.
  LipList itemStyleFunc(ListStyleFunc fn) {
    _itemStyleFunc = fn;
    return this;
  }

  /// Sets a static style for all enumerators.
  LipList enumeratorStyle(Style style) {
    _enumeratorStyleFunc = (_, __) => style;
    return this;
  }

  /// Sets a function to determine enumerator style per-item.
  LipList enumeratorStyleFunc(ListStyleFunc fn) {
    _enumeratorStyleFunc = fn;
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Visibility & Offset
  // ─────────────────────────────────────────────────────────────────────────

  /// Hides this list from rendering.
  LipList hide([bool hidden = true]) {
    _hidden = hidden;
    return this;
  }

  /// Returns whether this list is hidden.
  bool get isHidden => _hidden;

  /// Sets the start and end offset for the list.
  ///
  /// This allows showing a subset of items. Negative end values count from
  /// the end of the list.
  ///
  /// ```dart
  /// list.offset(1, -1)  // Skip first and last items
  /// ```
  LipList offset(int start, [int end = 0]) {
    _startOffset = start;
    _endOffset = end;
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Rendering
  // ─────────────────────────────────────────────────────────────────────────

  /// Renders the list to a string.
  String render() {
    if (_hidden) return '';

    final buffer = StringBuffer();
    final items = _getVisibleItems();
    _renderItems(buffer, items, '');
    return buffer.toString().trimRight();
  }

  List<_ListNode> _getVisibleItems() {
    var items = _items.where((n) => !n._hidden).toList();

    // Apply offset
    final start = _startOffset.clamp(0, items.length);
    var end = items.length - _endOffset;
    if (_endOffset < 0) {
      end = items.length + _endOffset;
    }
    end = end.clamp(start, items.length);

    return items.sublist(start, end);
  }

  void _renderItems(StringBuffer buffer, List<_ListNode> items, String prefix) {
    final listItems = _ListItems(items);

    // Calculate max enumerator width for alignment
    var maxEnumWidth = 0;
    for (var i = 0; i < items.length; i++) {
      final enumStr = _enumerator(listItems, i);
      final width = Layout.visibleLength(enumStr);
      if (width > maxEnumWidth) maxEnumWidth = width;
    }

    for (var i = 0; i < items.length; i++) {
      final node = items[i];
      if (node._hidden) continue;

      final enumStr = _enumerator(listItems, i);
      final enumStyle = _enumeratorStyleFunc(listItems, i);
      final itemStyle = _itemStyleFunc(listItems, i);

      // Pad enumerator for alignment
      final enumWidth = Layout.visibleLength(enumStr);
      final padding = maxEnumWidth - enumWidth;
      final paddedEnum = ' ' * padding + enumStr;

      // Style and render
      final styledEnum = enumStyle.render(paddedEnum);
      final styledItem = itemStyle.render(node._value);

      if (node._value.isNotEmpty) {
        buffer.writeln('$prefix$styledEnum $styledItem');
      }

      // Render children (nested list)
      if (node._children.isNotEmpty) {
        final indent = _indenter(listItems, i);
        _renderItems(buffer, node._children, prefix + indent);
      }
    }
  }

  @override
  String toString() => render();
}

// ═══════════════════════════════════════════════════════════════════════════
// Predefined Enumerators
// ═══════════════════════════════════════════════════════════════════════════

/// Predefined list enumerators.
class ListEnumerators {
  ListEnumerators._();

  /// Bullet enumerator (•).
  static String bullet(ListItems items, int index) => '•';

  /// Dash enumerator (-).
  static String dash(ListItems items, int index) => '-';

  /// Asterisk enumerator (*).
  static String asterisk(ListItems items, int index) => '*';

  /// Arabic numerals (1. 2. 3.).
  static String arabic(ListItems items, int index) => '${index + 1}.';

  /// Alphabetic (a. b. c.).
  static String alphabet(ListItems items, int index) {
    return '${_toAlpha(index)}.';
  }

  /// Uppercase alphabetic (A. B. C.).
  static String alphabetUpper(ListItems items, int index) {
    return '${_toAlpha(index).toUpperCase()}.';
  }

  /// Roman numerals (I. II. III.).
  static String roman(ListItems items, int index) {
    return '${_toRoman(index + 1)}.';
  }

  /// Lowercase roman numerals (i. ii. iii.).
  static String romanLower(ListItems items, int index) {
    return '${_toRoman(index + 1).toLowerCase()}.';
  }

  /// Creates a fixed enumerator that always returns the same string.
  static ListEnumeratorFunc fixed(String symbol) {
    return (_, __) => symbol;
  }

  /// Creates a custom enumerator from a simple index function.
  static ListEnumeratorFunc custom(String Function(int index) fn) {
    return (_, i) => fn(i);
  }

  // Helper: Convert number to alphabetic (0=a, 1=b, 26=aa, etc.)
  static String _toAlpha(int n) {
    final result = StringBuffer();
    var num = n;
    while (num >= 0) {
      result.writeCharCode(97 + (num % 26)); // 'a' = 97
      num = (num ~/ 26) - 1;
      if (num < 0) break;
    }
    return result.toString().split('').reversed.join();
  }

  // Helper: Convert number to roman numerals
  static String _toRoman(int n) {
    if (n <= 0) return '';
    final numerals = [
      ['M', 1000],
      ['CM', 900],
      ['D', 500],
      ['CD', 400],
      ['C', 100],
      ['XC', 90],
      ['L', 50],
      ['XL', 40],
      ['X', 10],
      ['IX', 9],
      ['V', 5],
      ['IV', 4],
      ['I', 1],
    ];
    final result = StringBuffer();
    var remaining = n;
    for (final entry in numerals) {
      final symbol = entry[0] as String;
      final value = entry[1] as int;
      while (remaining >= value) {
        result.write(symbol);
        remaining -= value;
      }
    }
    return result.toString();
  }
}

/// Predefined list indenters.
class ListIndenters {
  ListIndenters._();

  /// Single space indent.
  static String space(ListItems items, int index) => ' ';

  /// Double space indent.
  static String doubleSpace(ListItems items, int index) => '  ';

  /// Tab-like indent (4 spaces).
  static String tab(ListItems items, int index) => '    ';

  /// Tree-style indent with pipe for non-last items.
  static String tree(ListItems items, int index) {
    if (index == items.length - 1) {
      return '   ';
    }
    return '│  ';
  }

  /// Arrow indent.
  static String arrow(ListItems items, int index) => '→ ';

  /// Creates a fixed indenter.
  static ListIndenterFunc fixed(String indent) =>
      (_, __) => indent;
}
