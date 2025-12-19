/// List component for TUI applications.
///
/// This provides an interactive list with selection, filtering,
/// pagination, and keyboard navigation.
///
/// Based on the Bubble Tea list component.
library;

import 'dart:math' as math;

import 'package:artisan_args/src/style/style.dart';
import 'package:artisan_args/src/style/color.dart';

import '../tui.dart';
import 'key_binding.dart';
import 'paginator.dart';
import 'spinner.dart';
import 'textinput.dart';

/// Item interface for list items.
abstract class ListItem {
  /// Value used for filtering.
  String filterValue();
}

/// Simple string item implementation.
class StringItem implements ListItem {
  /// Creates a string item.
  StringItem(this.value);

  /// The string value.
  final String value;

  @override
  String filterValue() => value;

  @override
  String toString() => value;
}

/// Item delegate for rendering list items.
abstract class ItemDelegate {
  /// Render the item at the given index.
  String render(ListModel model, int index, ListItem item);

  /// Height of each list item in lines.
  int get height;

  /// Spacing between items in lines.
  int get spacing;

  /// Handle update messages for items.
  Cmd? update(Msg msg, ListModel model);
}

/// Default item delegate with simple rendering.
class DefaultItemDelegate implements ItemDelegate {
  /// Creates a default item delegate.
  DefaultItemDelegate({
    Style? normalStyle,
    Style? selectedStyle,
    Style? matchedStyle,
  }) : normalStyle = normalStyle ?? Style(),
       selectedStyle =
           selectedStyle ?? Style().bold().foreground(AnsiColor(212)),
       matchedStyle = matchedStyle ?? Style().underline();

  /// Style for normal items.
  final Style normalStyle;

  /// Style for selected item.
  final Style selectedStyle;

  /// Style for matched characters in filtered items.
  final Style matchedStyle;

  @override
  int get height => 1;

  @override
  int get spacing => 0;

  @override
  String render(ListModel model, int index, ListItem item) {
    final selected = model.index == index;
    final value = item.filterValue();
    final matches = model.matchesForItem(index);

    String styledValue;
    if (matches != null && matches.isNotEmpty) {
      // Highlight matched characters
      final buffer = StringBuffer();
      for (var i = 0; i < value.length; i++) {
        if (matches.contains(i)) {
          buffer.write(matchedStyle.render(value[i]));
        } else {
          buffer.write(value[i]);
        }
      }
      styledValue = buffer.toString();
    } else {
      styledValue = value;
    }

    if (selected) {
      return selectedStyle.render('> $styledValue');
    }
    return normalStyle.render('  $styledValue');
  }

  @override
  Cmd? update(Msg msg, ListModel model) => null;
}

/// Filter state for the list.
enum FilterState {
  /// No filter applied.
  unfiltered,

  /// User is actively typing a filter.
  filtering,

  /// A filter has been applied.
  filterApplied,
}

/// Filtered item with match information.
class FilteredItem {
  /// Creates a filtered item.
  FilteredItem({
    required this.index,
    required this.item,
    this.matches = const [],
  });

  /// Index in the original unfiltered list.
  final int index;

  /// The matched item.
  final ListItem item;

  /// Rune indices of matched characters.
  final List<int> matches;
}

/// Rank from filtering.
class Rank {
  /// Creates a rank.
  Rank({required this.index, this.matchedIndexes = const []});

  /// Index in the original list.
  final int index;

  /// Indices of matched characters.
  final List<int> matchedIndexes;
}

/// Filter function type.
typedef FilterFunc = List<Rank> Function(String term, List<String> targets);

/// Default fuzzy filter implementation.
List<Rank> defaultFilter(String term, List<String> targets) {
  if (term.isEmpty) {
    return List.generate(targets.length, (i) => Rank(index: i));
  }

  final results = <Rank>[];
  final termLower = term.toLowerCase();

  for (var i = 0; i < targets.length; i++) {
    final target = targets[i].toLowerCase();
    final matches = <int>[];
    var termIdx = 0;

    for (var j = 0; j < target.length && termIdx < termLower.length; j++) {
      if (target[j] == termLower[termIdx]) {
        matches.add(j);
        termIdx++;
      }
    }

    if (termIdx == termLower.length) {
      results.add(Rank(index: i, matchedIndexes: matches));
    }
  }

  // Sort by number of matches and position
  results.sort((a, b) {
    final aScore = _scoreRank(a, targets[a.index]);
    final bScore = _scoreRank(b, targets[b.index]);
    return aScore.compareTo(bScore);
  });

  return results;
}

int _scoreRank(Rank rank, String target) {
  if (rank.matchedIndexes.isEmpty) return target.length;
  // Lower score is better - prefer matches at the start
  var score = 0;
  for (final idx in rank.matchedIndexes) {
    score += idx;
  }
  return score;
}

/// Key map for list navigation.
class ListKeyMap implements KeyMap {
  /// Creates a list key map with default bindings.
  ListKeyMap({
    KeyBinding? cursorUp,
    KeyBinding? cursorDown,
    KeyBinding? nextPage,
    KeyBinding? prevPage,
    KeyBinding? goToStart,
    KeyBinding? goToEnd,
    KeyBinding? filter,
    KeyBinding? clearFilter,
    KeyBinding? acceptWhileFiltering,
    KeyBinding? cancelWhileFiltering,
    KeyBinding? quit,
    KeyBinding? showFullHelp,
    KeyBinding? closeFullHelp,
  }) : cursorUp =
           cursorUp ??
           KeyBinding(
             keys: ['up', 'k'],
             help: Help(key: '↑/k', desc: 'up'),
           ),
       cursorDown =
           cursorDown ??
           KeyBinding(
             keys: ['down', 'j'],
             help: Help(key: '↓/j', desc: 'down'),
           ),
       nextPage =
           nextPage ??
           KeyBinding(
             keys: ['right', 'l', 'pgdown'],
             help: Help(key: '→/l', desc: 'next page'),
           ),
       prevPage =
           prevPage ??
           KeyBinding(
             keys: ['left', 'h', 'pgup'],
             help: Help(key: '←/h', desc: 'prev page'),
           ),
       goToStart =
           goToStart ??
           KeyBinding(
             keys: ['home', 'g'],
             help: Help(key: 'g', desc: 'go to start'),
           ),
       goToEnd =
           goToEnd ??
           KeyBinding(
             keys: ['end', 'G'],
             help: Help(key: 'G', desc: 'go to end'),
           ),
       filter =
           filter ??
           KeyBinding(
             keys: ['/'],
             help: Help(key: '/', desc: 'filter'),
           ),
       clearFilter =
           clearFilter ??
           KeyBinding(
             keys: ['esc'],
             help: Help(key: 'esc', desc: 'clear filter'),
           ),
       acceptWhileFiltering =
           acceptWhileFiltering ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: 'enter', desc: 'apply filter'),
           ),
       cancelWhileFiltering =
           cancelWhileFiltering ??
           KeyBinding(
             keys: ['esc'],
             help: Help(key: 'esc', desc: 'cancel'),
           ),
       quit =
           quit ??
           KeyBinding(
             keys: ['q', 'ctrl+c'],
             help: Help(key: 'q', desc: 'quit'),
           ),
       showFullHelp =
           showFullHelp ??
           KeyBinding(
             keys: ['?'],
             help: Help(key: '?', desc: 'more'),
           ),
       closeFullHelp =
           closeFullHelp ??
           KeyBinding(
             keys: ['?'],
             help: Help(key: '?', desc: 'less'),
           );

  /// Move cursor up.
  final KeyBinding cursorUp;

  /// Move cursor down.
  final KeyBinding cursorDown;

  /// Go to next page.
  final KeyBinding nextPage;

  /// Go to previous page.
  final KeyBinding prevPage;

  /// Go to start.
  final KeyBinding goToStart;

  /// Go to end.
  final KeyBinding goToEnd;

  /// Start filtering.
  final KeyBinding filter;

  /// Clear current filter.
  final KeyBinding clearFilter;

  /// Accept filter while filtering.
  final KeyBinding acceptWhileFiltering;

  /// Cancel filtering.
  final KeyBinding cancelWhileFiltering;

  /// Quit the list.
  final KeyBinding quit;

  /// Show full help.
  final KeyBinding showFullHelp;

  /// Close full help.
  final KeyBinding closeFullHelp;

  @override
  List<KeyBinding> shortHelp() => [cursorUp, cursorDown, filter, quit];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [cursorUp, cursorDown],
    [nextPage, prevPage],
    [goToStart, goToEnd],
    [filter, clearFilter],
    [quit],
  ];
}

/// Styles for list rendering.
class ListStyles {
  /// Creates list styles.
  ListStyles({
    Style? title,
    Style? titleBar,
    Style? filterPrompt,
    Style? filterCursor,
    Style? statusBar,
    Style? statusEmpty,
    Style? statusBarActiveFilter,
    Style? noItems,
    Style? paginationStyle,
    Style? helpStyle,
    String? activePaginationDot,
    String? inactivePaginationDot,
    Style? spinner,
  }) : title = title ?? Style(),
       titleBar = titleBar ?? Style(),
       filterPrompt = filterPrompt ?? Style(),
       filterCursor = filterCursor ?? Style(),
       statusBar = statusBar ?? Style(),
       statusEmpty = statusEmpty ?? Style(),
       statusBarActiveFilter = statusBarActiveFilter ?? Style(),
       noItems = noItems ?? Style(),
       paginationStyle = paginationStyle ?? Style(),
       helpStyle = helpStyle ?? Style(),
       activePaginationDot = activePaginationDot,
       inactivePaginationDot = inactivePaginationDot,
       spinner = spinner ?? Style();

  /// Title style.
  final Style title;

  /// Title bar style.
  final Style titleBar;

  /// Filter prompt style.
  final Style filterPrompt;

  /// Filter cursor style.
  final Style filterCursor;

  /// Status bar style.
  final Style statusBar;

  /// Empty status style.
  final Style statusEmpty;

  /// Active filter status style.
  final Style statusBarActiveFilter;

  /// No items message style.
  final Style noItems;

  /// Pagination style.
  final Style paginationStyle;

  /// Help style.
  final Style helpStyle;

  /// Active pagination dot.
  final String? activePaginationDot;

  /// Inactive pagination dot.
  final String? inactivePaginationDot;

  /// Spinner style.
  final Style spinner;

  /// Creates default styles.
  factory ListStyles.defaults() => ListStyles(
    title: Style().bold(),
    titleBar: Style().background(AnsiColor(62)), // Purple background
    filterPrompt: Style().foreground(AnsiColor(241)), // Gray
    filterCursor: Style().foreground(AnsiColor(62)), // Purple
    statusBar: Style().foreground(AnsiColor(241)), // Gray
    statusEmpty: Style().foreground(AnsiColor(240)), // Dark gray
    statusBarActiveFilter: Style().foreground(AnsiColor(62)), // Purple
    noItems: Style().foreground(AnsiColor(240)), // Dark gray
    paginationStyle: Style().foreground(AnsiColor(241)),
    helpStyle: Style().foreground(AnsiColor(241)),
    activePaginationDot: Style().foreground(AnsiColor(62)).render('●'),
    inactivePaginationDot: Style().foreground(AnsiColor(241)).render('○'),
  );
}

/// Filter matches message.
class FilterMatchesMsg implements Msg {
  /// Creates a filter matches message.
  FilterMatchesMsg(this.matches);

  /// The filtered items.
  final List<FilteredItem> matches;
}

/// Status message timeout message.
class StatusMessageTimeoutMsg implements Msg {}

/// List model for interactive lists.
///
/// Features:
/// - Item selection with keyboard navigation
/// - Optional fuzzy filtering
/// - Pagination
/// - Loading spinner
/// - Status messages
/// - Help view
///
/// Example:
/// ```dart
/// final list = ListModel(
///   items: ['Apple', 'Banana', 'Cherry'].map(StringItem.new).toList(),
///   title: 'Fruits',
/// );
/// ```
class ListModel extends ViewComponent {
  /// Creates a new list model.
  ListModel({
    List<ListItem>? items,
    ItemDelegate? delegate,
    int width = 80,
    int height = 20,
    this.title = 'List',
    this.showTitle = true,
    this.showFilter = true,
    this.showStatusBar = true,
    this.showPagination = true,
    this.showHelp = true,
    this.filteringEnabled = true,
    this.infiniteScrolling = false,
    this.itemNameSingular = 'item',
    this.itemNamePlural = 'items',
    ListKeyMap? keyMap,
    ListStyles? styles,
    FilterFunc? filter,
    Duration? statusMessageLifetime,
  }) : _items = items ?? [],
       _delegate = delegate ?? DefaultItemDelegate(),
       keyMap = keyMap ?? ListKeyMap(),
       styles = styles ?? ListStyles.defaults(),
       _filter = filter ?? defaultFilter,
       statusMessageLifetime =
           statusMessageLifetime ?? const Duration(seconds: 1),
       _width = width,
       _height = height {
    _paginator = PaginatorModel(
      type: PaginationType.dots,
      activeDot: this.styles.activePaginationDot ?? '●',
      inactiveDot: this.styles.inactivePaginationDot ?? '○',
    );
    _filterInput = TextInputModel(prompt: 'Filter: ', charLimit: 64);
    _spinner = SpinnerModel(spinner: Spinners.line);
    _updatePagination();
  }

  /// List title.
  String title;

  /// Whether to show the title.
  bool showTitle;

  /// Whether to show the filter input.
  bool showFilter;

  /// Whether to show the status bar.
  bool showStatusBar;

  /// Whether to show pagination.
  bool showPagination;

  /// Whether to show help.
  bool showHelp;

  /// Whether filtering is enabled.
  bool filteringEnabled;

  /// Whether to enable infinite scrolling.
  bool infiniteScrolling;

  /// Singular item name for status.
  String itemNameSingular;

  /// Plural item name for status.
  String itemNamePlural;

  /// Key bindings.
  ListKeyMap keyMap;

  /// List styles.
  ListStyles styles;

  /// Status message lifetime.
  Duration statusMessageLifetime;

  // Internal state
  List<ListItem> _items;
  ItemDelegate _delegate;
  FilterFunc _filter;
  late PaginatorModel _paginator;
  late TextInputModel _filterInput;
  late SpinnerModel _spinner;
  int _cursor = 0;
  int _width;
  int _height;
  FilterState _filterState = FilterState.unfiltered;
  List<FilteredItem> _filteredItems = [];
  String _statusMessage = '';
  bool _showSpinner = false;

  /// Gets the items.
  List<ListItem> get items => _items;

  /// Sets the items.
  set items(List<ListItem> value) {
    _items = value;
    if (_filterState != FilterState.unfiltered) {
      _filteredItems = [];
      _runFilter();
    }
    _updatePagination();
  }

  /// Sets the items (parity with bubbles).
  void setItems(List<ListItem> items) {
    this.items = items;
  }

  /// Inserts an item at the given index.
  void insertItem(int index, ListItem item) {
    _items.insert(index, item);
    _updatePagination();
  }

  /// Removes an item at the given index.
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _updatePagination();
    }
  }

  /// Sets an item at the given index.
  void setItem(int index, ListItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
    }
  }

  /// Sets whether filtering is enabled.
  void setFilteringEnabled(bool enabled) {
    filteringEnabled = enabled;
  }

  /// Sets whether to show the title.
  void setShowTitle(bool show) {
    showTitle = show;
  }

  /// Sets whether to show the status bar.
  void setShowStatusBar(bool show) {
    showStatusBar = show;
  }

  /// Sets whether to show pagination.
  void setShowPagination(bool show) {
    showPagination = show;
  }

  /// Sets whether to show help.
  void setShowHelp(bool show) {
    showHelp = show;
  }

  /// Sets whether to show the filter.
  void setShowFilter(bool show) {
    showFilter = show;
  }

  /// Gets the width.
  int get width => _width;

  /// Gets the height.
  int get height => _height;

  /// Sets the size.
  void setSize(int width, int height) {
    _width = width;
    _height = height;
    _updatePagination();
  }

  /// Gets visible items (filtered or all).
  List<ListItem> get visibleItems {
    if (_filterState != FilterState.unfiltered) {
      return _filteredItems.map((f) => f.item).toList();
    }
    return _items;
  }

  /// Gets the current index in the visible items.
  int get index => _paginator.page * _paginator.perPage + _cursor;

  /// Gets the global index in the unfiltered items.
  int get globalIndex {
    final idx = index;
    if (_filteredItems.isEmpty || idx >= _filteredItems.length) {
      return idx;
    }
    return _filteredItems[idx].index;
  }

  /// Gets the cursor position on the current page.
  int get cursor => _cursor;

  /// Gets the selected item, or null if none.
  ListItem? get selectedItem {
    final items = visibleItems;
    final idx = index;
    if (idx < 0 || items.isEmpty || idx >= items.length) {
      return null;
    }
    return items[idx];
  }

  /// Gets match indices for an item (for highlighting).
  List<int>? matchesForItem(int index) {
    if (_filteredItems.isEmpty || index >= _filteredItems.length) {
      return null;
    }
    return _filteredItems[index].matches;
  }

  /// Gets the current filter state.
  FilterState get filterState => _filterState;

  /// Gets the current filter value.
  String get filterValue => _filterInput.value;

  /// Whether currently setting a filter.
  bool get settingFilter => _filterState == FilterState.filtering;

  /// Whether a filter is applied.
  bool get isFiltered => _filterState == FilterState.filterApplied;

  /// Move cursor up.
  void cursorUp() {
    _cursor--;
    if (_cursor < 0 && _paginator.onFirstPage) {
      if (infiniteScrolling) {
        goToEnd();
        return;
      }
      _cursor = 0;
      return;
    }
    if (_cursor >= 0) return;
    _paginator.prevPage();
    _cursor = _maxCursorIndex();
  }

  /// Move cursor down.
  void cursorDown() {
    final maxIdx = _maxCursorIndex();
    _cursor++;
    if (_cursor <= maxIdx) return;
    if (!_paginator.onLastPage) {
      _paginator.nextPage();
      _cursor = 0;
      return;
    }
    _cursor = math.max(0, maxIdx);
    if (infiniteScrolling) {
      goToStart();
    }
  }

  /// Go to start.
  void goToStart() {
    _paginator = _paginator.copyWith(page: 0);
    _cursor = 0;
  }

  /// Go to end.
  void goToEnd() {
    _paginator = _paginator.copyWith(
      page: math.max(0, _paginator.totalPages - 1),
    );
    _cursor = _maxCursorIndex();
  }

  /// Go to previous page.
  void prevPage() {
    _paginator = _paginator.prevPage();
    _cursor = _cursor.clamp(0, _maxCursorIndex());
  }

  /// Go to next page.
  void nextPage() {
    _paginator = _paginator.nextPage();
    _cursor = _cursor.clamp(0, _maxCursorIndex());
  }

  /// Select item at index.
  void select(int index) {
    _paginator = _paginator.copyWith(page: index ~/ _paginator.perPage);
    _cursor = index % _paginator.perPage;
  }

  /// Reset selection to start.
  void resetSelected() {
    select(0);
  }

  /// Reset the filter.
  void resetFilter() {
    _resetFiltering();
  }

  /// Start the spinner.
  Cmd startSpinner() {
    _showSpinner = true;
    return _spinner.tick();
  }

  /// Stop the spinner.
  void stopSpinner() {
    _showSpinner = false;
  }

  /// Set a status message.
  Cmd? newStatusMessage(String message) {
    _statusMessage = message;
    // In a real implementation, you'd return a command that clears after timeout
    return null;
  }

  int _maxCursorIndex() {
    return math.max(0, _paginator.itemsOnPage(visibleItems.length) - 1);
  }

  void _resetFiltering() {
    if (_filterState == FilterState.unfiltered) return;
    _filterState = FilterState.unfiltered;
    _filterInput.reset();
    _filteredItems = [];
    _updatePagination();
  }

  void _runFilter() {
    final targets = _items.map((i) => i.filterValue()).toList();
    final ranks = _filter(_filterInput.value, targets);
    _filteredItems = ranks
        .map(
          (r) => FilteredItem(
            index: r.index,
            item: _items[r.index],
            matches: r.matchedIndexes,
          ),
        )
        .toList();
  }

  void _updatePagination() {
    final idx = index;
    var availHeight = _height;

    if (showTitle || (showFilter && filteringEnabled)) {
      availHeight -= 1; // Title line
    }
    if (showStatusBar) {
      availHeight -= 1; // Status line
    }
    if (showPagination) {
      availHeight -= 1; // Pagination line
    }
    if (showHelp) {
      availHeight -= 1; // Help line
    }

    _paginator = _paginator.copyWith(
      perPage: math.max(
        1,
        availHeight ~/ (_delegate.height + _delegate.spacing),
      ),
    );

    final pages = visibleItems.length;
    if (pages < 1) {
      _paginator = _paginator.setTotalPages(1);
    } else {
      _paginator = _paginator.setTotalPages(pages);
    }

    // Restore index
    _paginator = _paginator.copyWith(page: idx ~/ _paginator.perPage);
    _cursor = idx % _paginator.perPage;

    // Keep page in bounds
    if (_paginator.page >= _paginator.totalPages - 1) {
      _paginator = _paginator.copyWith(
        page: math.max(0, _paginator.totalPages - 1),
      );
    }
  }

  @override
  Cmd? init() => null;

  @override
  (ListModel, Cmd?) update(Msg msg) {
    final cmds = <Cmd>[];

    if (msg is FilterMatchesMsg) {
      _filteredItems = msg.matches;
      return (this, null);
    }

    if (msg is SpinnerTickMsg && _showSpinner) {
      final (newSpinner, cmd) = _spinner.update(msg);
      _spinner = newSpinner;
      if (cmd != null) cmds.add(cmd);
    }

    if (msg is StatusMessageTimeoutMsg) {
      _statusMessage = '';
    }

    if (_filterState == FilterState.filtering) {
      final cmd = _handleFiltering(msg);
      if (cmd != null) cmds.add(cmd);
    } else {
      final cmd = _handleBrowsing(msg);
      if (cmd != null) cmds.add(cmd);
    }

    return (this, cmds.isNotEmpty ? Cmd.batch(cmds) : null);
  }

  Cmd? _handleBrowsing(Msg msg) {
    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      if (keyMatches(msg.key, [keyMap.clearFilter])) {
        _resetFiltering();
      } else if (keyMatches(msg.key, [keyMap.cursorUp])) {
        cursorUp();
      } else if (keyMatches(msg.key, [keyMap.cursorDown])) {
        cursorDown();
      } else if (keyMatches(msg.key, [keyMap.prevPage])) {
        prevPage();
      } else if (keyMatches(msg.key, [keyMap.nextPage])) {
        nextPage();
      } else if (keyMatches(msg.key, [keyMap.goToStart])) {
        goToStart();
      } else if (keyMatches(msg.key, [keyMap.goToEnd])) {
        goToEnd();
      } else if (keyMatches(msg.key, [keyMap.filter]) && filteringEnabled) {
        _statusMessage = '';
        if (_filterInput.value.isEmpty) {
          _filteredItems = _items
              .asMap()
              .entries
              .map((e) => FilteredItem(index: e.key, item: e.value))
              .toList();
        }
        goToStart();
        _filterState = FilterState.filtering;
        final focusCmd = _filterInput.focus();
        if (focusCmd != null) cmds.add(focusCmd);
      }
    }

    final delegateCmd = _delegate.update(msg, this);
    if (delegateCmd != null) cmds.add(delegateCmd);

    _cursor = _cursor.clamp(0, _maxCursorIndex());

    return cmds.isNotEmpty ? Cmd.batch(cmds) : null;
  }

  Cmd? _handleFiltering(Msg msg) {
    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      if (keyMatches(msg.key, [keyMap.cancelWhileFiltering])) {
        _resetFiltering();
      } else if (keyMatches(msg.key, [keyMap.acceptWhileFiltering])) {
        _statusMessage = '';
        if (_items.isEmpty) {
          return Cmd.batch(cmds);
        }
        if (visibleItems.isEmpty) {
          _resetFiltering();
          return Cmd.batch(cmds);
        }
        _filterInput.blur();
        _filterState = FilterState.filterApplied;
        if (_filterInput.value.isEmpty) {
          _resetFiltering();
        }
      } else {
        // Forward to filter input
        final oldValue = _filterInput.value;
        final (_, inputCmd) = _filterInput.update(msg);
        if (inputCmd != null) cmds.add(inputCmd);

        // If changed, re-run filter
        if (_filterInput.value != oldValue) {
          _runFilter();
        }
      }
    }

    _updatePagination();
    return Cmd.batch(cmds);
  }

  @override
  String view() {
    final sections = <String>[];
    var availHeight = _height;

    if (showTitle || (showFilter && filteringEnabled)) {
      final titleView = _titleView();
      sections.add(titleView);
      availHeight -= titleView.split('\n').length;
    }

    if (showStatusBar) {
      final statusView = _statusView();
      sections.add(statusView);
      availHeight -= 1;
    }

    String? pagination;
    if (showPagination) {
      pagination = _paginationView();
      availHeight -= 1;
    }

    String? help;
    if (showHelp) {
      help = _helpView();
      availHeight -= 1;
    }

    final content = _populatedView(availHeight);
    sections.add(content);

    if (pagination != null) {
      sections.add(pagination);
    }

    if (help != null) {
      sections.add(help);
    }

    return sections.join('\n');
  }

  String _titleView() {
    final buffer = StringBuffer();

    if (showTitle) {
      buffer.write(styles.titleBar.render(styles.title.render(' $title ')));
    }

    if (showFilter &&
        filteringEnabled &&
        _filterState == FilterState.filtering) {
      if (_showSpinner) {
        buffer.write(' ${_spinner.view()} ');
      }
      buffer.write(_filterInput.view());
    }

    return buffer.toString();
  }

  String _statusView() {
    final buffer = StringBuffer();

    if (_statusMessage.isNotEmpty) {
      buffer.write(styles.statusBar.render(_statusMessage));
    } else {
      final items = visibleItems;
      final total = _items.length;
      final visible = items.length;

      if (total == 0) {
        buffer.write(styles.statusBar.render('No ${itemNamePlural}'));
      } else if (_filterState == FilterState.filterApplied) {
        buffer.write(
          styles.statusBar.render(
            '$visible of $total ${visible == 1 ? itemNameSingular : itemNamePlural} ',
          ),
        );
        buffer.write(styles.statusBarActiveFilter.render('(filtered)'));
      } else {
        buffer.write(
          styles.statusBar.render(
            '$total ${total == 1 ? itemNameSingular : itemNamePlural}',
          ),
        );
      }
    }

    return buffer.toString();
  }

  String _paginationView() {
    return _paginator.view();
  }

  String _helpView() {
    final bindings = _filterState == FilterState.filtering
        ? [keyMap.acceptWhileFiltering, keyMap.cancelWhileFiltering]
        : keyMap.shortHelp();

    final helpText = bindings
        .map((b) => '${b.keys.first} ${b.help.desc}')
        .join(' • ');

    return styles.helpStyle.render(helpText);
  }

  String _populatedView(int height) {
    final items = visibleItems;

    if (items.isEmpty) {
      return styles.noItems.render('No ${itemNamePlural}');
    }

    final start = _paginator.page * _paginator.perPage;
    final end = math.min(start + _paginator.perPage, items.length);

    final lines = <String>[];
    for (var i = start; i < end; i++) {
      lines.add(_delegate.render(this, i, items[i]));
    }

    // Pad to fill available height
    while (lines.length < height) {
      lines.add('');
    }

    return lines.take(height).join('\n');
  }
}
