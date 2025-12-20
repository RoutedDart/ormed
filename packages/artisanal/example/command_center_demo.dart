/// Command Center TUI Demo - A monitoring dashboard with multiple panels.
///
/// Uses responsive layout with percentage-based panel heights.
///
/// Run:
///   dart run packages/artisanal/example/command_center_demo.dart
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/uv.dart' show Percent, Fixed, splitVertical, Rectangle;

// ─────────────────────────────────────────────────────────────────────────────
// Log Entry Model
// ─────────────────────────────────────────────────────────────────────────────

enum LogLevel { info, debug, warning, error }

final class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.project,
    required this.environment,
    required this.source,
    required this.message,
    this.filename,
    this.lineNumber,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String project;
  final String environment;
  final String source;
  final String message;
  final String? filename;
  final int? lineNumber;

  String get levelStr => switch (level) {
        LogLevel.info => 'INF',
        LogLevel.debug => 'DBG',
        LogLevel.warning => 'WRN',
        LogLevel.error => 'ERR',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake Log Generator
// ─────────────────────────────────────────────────────────────────────────────

final _random = math.Random();

const _logProjects = ['kasm', '███', 'vault', 'sync', 'api', 'auth'];
const _logEnvironments = ['PROD', 'STAG', 'DEV'];

const _logSources = [
  'kasm_rdp',
  'kasm_gua',
  'db',
  'nginx',
  'worker',
  'scheduler',
  'api_gw',
  'redis',
  'auth_svc',
  'health',
];

const _logFilenames = [
  'main.go',
  'handler.go',
  'server.go',
  'client.py',
  'worker.rs',
  'index.ts',
];

const _infoLogMessages = [
  'Received a healthcheck',
  'checkpoint starting: time',
  'Connection pool initialized',
  'Session established for user',
  'Request completed successfully',
  'Cache refreshed',
  'Metrics exported to prometheus',
  'Worker registered successfully',
  'Configuration reloaded',
  'Background job completed',
];

const _debugLogMessages = [
  'Hostnames received: [kasm→',
  'Parsing request headers',
  'Executing query: SELECT * FROM',
  'Validating JWT token claims',
  'Resolving DNS for upstream host',
  'Building response object',
  'Trace context propagated',
  'Cache lookup for key=session_',
];

const _warningLogMessages = [
  'Slow query detected (>500ms)',
  'Connection pool near capacity: 85%',
  'Rate limit threshold approaching',
  'Retry attempt 2/3 for upstream',
  'Memory usage above threshold: 82%',
  'Certificate expires in 7 days',
  'Queue depth increasing: 1,024',
];

const _errorLogMessages = [
  'Connection refused to upstream',
  'Query timeout after 30s',
  'Authentication failed for user',
  'Service unavailable: db-primary',
  'Out of memory: killed process',
  'Rate limit exceeded: 429',
  'Permission denied: access_token',
];

LogEntry _generateLogEntry() {
  final level = switch (_random.nextDouble()) {
    < 0.45 => LogLevel.info,
    < 0.75 => LogLevel.debug,
    < 0.92 => LogLevel.warning,
    _ => LogLevel.error,
  };

  final messages = switch (level) {
    LogLevel.info => _infoLogMessages,
    LogLevel.debug => _debugLogMessages,
    LogLevel.warning => _warningLogMessages,
    LogLevel.error => _errorLogMessages,
  };

  String? filename;
  int? lineNumber;
  if (_random.nextDouble() < 0.4) {
    filename = _logFilenames[_random.nextInt(_logFilenames.length)];
    lineNumber = 50 + _random.nextInt(400);
  }

  return LogEntry(
    timestamp: DateTime.now(),
    level: level,
    project: _logProjects[_random.nextInt(_logProjects.length)],
    environment: _logEnvironments[_random.nextInt(_logEnvironments.length)],
    source: _logSources[_random.nextInt(_logSources.length)],
    message: messages[_random.nextInt(messages.length)],
    filename: filename,
    lineNumber: lineNumber,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Main navigation tabs.
const _mainTabs = [
  'Overview',
  'Infrastructure',
  'Applications',
  'MONITORING',
  'Operations',
  'Configuration',
];

/// Sub-tabs for the Monitoring section.
const _subTabs = ['Logs', 'Database', 'Log Database', 'Health'];

/// Project names for the header.
const _projects = [
  'KASM Workspaces',
  'CloudSync',
  'API Gateway',
  'truck-reports',
  'vault',
  'metrics-hub',
];

// ─────────────────────────────────────────────────────────────────────────────
// Styles
// ─────────────────────────────────────────────────────────────────────────────

/// Cyan accent style for active elements.
Style _cyanStyle() => Style().foreground(Colors.cyan);

/// Cyan bold style for titles.
Style _cyanBoldStyle() => Style().foreground(Colors.cyan).bold();

/// Gray style for inactive elements.
Style _grayStyle() => Style().foreground(Colors.gray);

/// Dim gray style for very subdued elements.
Style _dimGrayStyle() => Style().foreground(Colors.gray).dim();

/// White bold style for highlighted text.
Style _whiteBoldStyle() => Style().foreground(Colors.white).bold();

/// Active tab style (cyan background, black text).
Style _activeTabStyle() =>
    Style().foreground(Colors.black).background(Colors.cyan).bold();

/// Blue dim border style.
Style _borderStyle() => Style().foreground(Colors.blue).dim();

/// Green style for LIVE indicators.
Style _greenStyle() => Style().foreground(Colors.green);

/// Yellow style for warnings.
Style _yellowStyle() => Style().foreground(Colors.yellow);

/// Red style for errors.
Style _redStyle() => Style().foreground(Colors.red);

/// Blue style for debug.
Style _blueStyle() => Style().foreground(Colors.blue);

/// Purple style for source tags.
Style _purpleStyle() => Style().foreground(Colors.purple);

// ─────────────────────────────────────────────────────────────────────────────
// Messages
// ─────────────────────────────────────────────────────────────────────────────

class _TickMsg extends tui.Msg {
  const _TickMsg();
}

class _NewLogMsg extends tui.Msg {
  const _NewLogMsg(this.entry);
  final LogEntry entry;
}

// ─────────────────────────────────────────────────────────────────────────────
// Command Center Model
// ─────────────────────────────────────────────────────────────────────────────

final class CommandCenterModel implements tui.Model {
  CommandCenterModel({
    required this.width,
    required this.height,
    required this.activeMainTab,
    required this.activeSubTab,
    required this.projects,
    required this.currentTime,
    required this.version,
    required this.logs,
    required this.totalLogs,
    required this.viewport,
    required this.liveMode,
    required this.latencyMs,
  });

  factory CommandCenterModel.initial() {
    return CommandCenterModel(
      width: 100,
      height: 24,
      activeMainTab: 3, // MONITORING tab (0-indexed)
      activeSubTab: 0, // Logs sub-tab (0-indexed)
      projects: _projects,
      currentTime: DateTime.now(),
      version: 'v2.0.0',
      logs: [],
      totalLogs: 1908196, // Simulated total log count
      viewport: tui.ViewportModel(width: 96, height: 14),
      liveMode: true,
      latencyMs: 138,
    );
  }

  final int width;
  final int height;
  final int activeMainTab;
  final int activeSubTab;
  final List<String> projects;
  final DateTime currentTime;
  final String version;
  final List<LogEntry> logs;
  final int totalLogs;
  final tui.ViewportModel viewport;
  final bool liveMode;
  final int latencyMs;

  // Max logs to keep in buffer
  static const maxLogs = 500;

  CommandCenterModel copyWith({
    int? width,
    int? height,
    int? activeMainTab,
    int? activeSubTab,
    List<String>? projects,
    DateTime? currentTime,
    String? version,
    List<LogEntry>? logs,
    int? totalLogs,
    tui.ViewportModel? viewport,
    bool? liveMode,
    int? latencyMs,
  }) {
    return CommandCenterModel(
      width: width ?? this.width,
      height: height ?? this.height,
      activeMainTab: activeMainTab ?? this.activeMainTab,
      activeSubTab: activeSubTab ?? this.activeSubTab,
      projects: projects ?? this.projects,
      currentTime: currentTime ?? this.currentTime,
      version: version ?? this.version,
      logs: logs ?? this.logs,
      totalLogs: totalLogs ?? this.totalLogs,
      viewport: viewport ?? this.viewport,
      liveMode: liveMode ?? this.liveMode,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  tui.Cmd _scheduleNewLog() {
    // Random interval between 50-300ms for realistic log flow
    final interval = 50 + _random.nextInt(250);
    return tui.Cmd.tick(Duration(milliseconds: interval), (_) {
      return _NewLogMsg(_generateLogEntry());
    });
  }

  @override
  tui.Cmd? init() {
    return tui.Cmd.batch([
      tui.Cmd.tick(
        const Duration(milliseconds: 1000),
        (_) => const _TickMsg(),
      ),
      _scheduleNewLog(),
    ]);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.WindowSizeMsg(:final width, :final height):
        final nextViewport = viewport.copyWith(
          width: width - 4,
          height: math.max(6, height - 16), // Adjust for panels 1-3 and 5
        );
        // Re-format logs for new width
        final logLines =
            logs.map((e) => _formatLogEntry(e, nextViewport.width)).toList();
        final updatedViewport = nextViewport.setContent(logLines.join('\n'));

        return (
          copyWith(
            width: width,
            height: height,
            viewport: updatedViewport,
          ),
          null,
        );

      case tui.KeyMsg(:final key):
        // Quit
        if (key.isChar('q') || key.type == tui.KeyType.escape) {
          return (this, tui.Cmd.quit());
        }

        // Main tab switching (1-6)
        if (key.isChar('1')) return (copyWith(activeMainTab: 0), null);
        if (key.isChar('2')) return (copyWith(activeMainTab: 1), null);
        if (key.isChar('3')) return (copyWith(activeMainTab: 2), null);
        if (key.isChar('4')) return (copyWith(activeMainTab: 3), null);
        if (key.isChar('5')) return (copyWith(activeMainTab: 4), null);
        if (key.isChar('6')) return (copyWith(activeMainTab: 5), null);

        // Sub-tab switching (A-D)
        if (key.isChar('a') || key.isChar('A')) {
          return (copyWith(activeSubTab: 0), null);
        }
        if (key.isChar('b') || key.isChar('B')) {
          return (copyWith(activeSubTab: 1), null);
        }
        if (key.isChar('c') || key.isChar('C')) {
          return (copyWith(activeSubTab: 2), null);
        }
        if (key.isChar('d') || key.isChar('D')) {
          return (copyWith(activeSubTab: 3), null);
        }

        // Toggle live mode
        if (key.isChar('t') || key.isChar('T')) {
          return (copyWith(liveMode: !liveMode), null);
        }

        // Refresh (simulate latency change)
        if (key.isChar('r') || key.isChar('R')) {
          final newLatency = 50 + _random.nextInt(200);
          return (copyWith(latencyMs: newLatency), null);
        }

        // Go to bottom (follow mode)
        if (key.isChar('G')) {
          final nextViewport = viewport.gotoBottom();
          return (copyWith(viewport: nextViewport), null);
        }

        // Go to top
        if (key.isChar('g')) {
          final nextViewport = viewport.gotoTop();
          return (copyWith(viewport: nextViewport), null);
        }

        // Delegate scroll keys to viewport
        final (nextViewport, viewportCmd) = viewport.update(msg);
        return (copyWith(viewport: nextViewport), viewportCmd);

      case tui.MouseMsg():
        // Delegate to viewport
        final (nextViewport, viewportCmd) = viewport.update(msg);
        return (copyWith(viewport: nextViewport), viewportCmd);

      case _NewLogMsg(:final entry):
        if (!liveMode) {
          return (this, _scheduleNewLog());
        }

        var newLogs = List<LogEntry>.from(logs)..add(entry);
        var newTotal = totalLogs + 1;

        if (newLogs.length > maxLogs) {
          newLogs = newLogs.sublist(newLogs.length - maxLogs);
        }

        // Update viewport content
        final logLines =
            newLogs.map((e) => _formatLogEntry(e, viewport.width)).toList();
        var nextViewport = viewport.setContent(logLines.join('\n'));

        // Auto-scroll if it was at the bottom before adding the new log
        if (viewport.atBottom) {
          nextViewport = nextViewport.gotoBottom();
        }

        // Simulate latency fluctuation
        final newLatency = latencyMs + (_random.nextInt(21) - 10);
        final clampedLatency = newLatency.clamp(50, 300);

        return (
          copyWith(
            logs: newLogs,
            totalLogs: newTotal,
            viewport: nextViewport,
            latencyMs: clampedLatency,
          ),
          _scheduleNewLog(),
        );

      case _TickMsg():
        return (
          copyWith(currentTime: DateTime.now()),
          tui.Cmd.tick(
            const Duration(milliseconds: 1000),
            (_) => const _TickMsg(),
          ),
        );

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    if (width == 0 || height == 0) return 'Initializing...';

    final lines = <String>[];

    // Panel 1: Header Panel
    lines.addAll(_buildHeaderPanel());

    // Panel 2: Navigation Tabs Panel
    lines.addAll(_buildNavigationPanel());

    // Panel 3: Breadcrumb + Sub-tabs Panel
    lines.addAll(_buildBreadcrumbPanel());

    // Panel 4: Main Log Panel
    lines.addAll(_buildLogPanel());

    // Panel 5: Footer Panel
    lines.addAll(_buildFooterPanel());

    // Pad to screen height
    while (lines.length < height) {
      lines.add('');
    }

    // Trim to screen height
    if (lines.length > height) {
      return lines.sublist(0, height).join('\n');
    }

    return lines.join('\n');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 1: Header Panel
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildHeaderPanel() {
    // Title line
    final title = _cyanBoldStyle().render('◆ ███ ███ COMMAND CENTER ◆');

    // Time and version (right side)
    final timeStr = _formatTime(currentTime);
    final rightSide =
        '${_grayStyle().render(timeStr)}  ${_dimGrayStyle().render(version)}';

    // Project line with pills/badges
    final projectLine = _buildProjectLine();

    // Build content lines
    final titleLen = Style.visibleLength(title);
    final rightLen = Style.visibleLength(rightSide);
    final innerWidth = width - 4; // Account for panel borders and padding

    // First line: title on left, time/version on right
    final padding1 = innerWidth - titleLen - rightLen;
    final line1 =
        padding1 > 0 ? '$title${' ' * padding1}$rightSide' : '$title  $rightSide';

    final panel = tui.Panel()
      .lines([line1, projectLine])
      .border(Border.rounded)
      .borderStyle(_borderStyle())
      .padding(0, 1)
      .width(width);

    return panel.render().split('\n');
  }

  String _buildProjectLine() {
    final label = _cyanStyle().render('● PROJECT:');
    final countStr = _grayStyle().render(' ${projects.length} total projects: ');

    final pills = <String>[];
    for (final project in projects) {
      pills.add(_buildPill(project));
    }

    return '$label$countStr${pills.join(' ')}';
  }

  String _buildPill(String text) {
    // Create a pill/badge style
    return _dimGrayStyle().render('[$text]');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 2: Navigation Tabs Panel
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildNavigationPanel() {
    final buffer = StringBuffer();

    for (var i = 0; i < _mainTabs.length; i++) {
      final isActive = i == activeMainTab;
      final tabLabel = '${_mainTabs[i]}[${i + 1}]';

      if (i > 0) buffer.write(_grayStyle().render(' | '));

      if (isActive) {
        buffer.write(_activeTabStyle().render(' $tabLabel '));
      } else {
        buffer.write(_grayStyle().render(' $tabLabel '));
      }
    }

    final panel = tui.Panel()
      .content(buffer.toString())
      .border(Border.rounded)
      .borderStyle(_borderStyle())
      .padding(0, 1)
      .width(width);

    return panel.render().split('\n');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 3: Breadcrumb + Sub-tabs Panel
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildBreadcrumbPanel() {
    // Breadcrumb line
    final breadcrumb =
        '${_grayStyle().render('Monitoring')} → ${_whiteBoldStyle().render('Logs')}';

    // Sub-tabs line
    final subTabsLine = _buildSubTabsLine();

    final panel = tui.Panel()
      .lines([breadcrumb, subTabsLine])
      .border(Border.rounded)
      .borderStyle(_borderStyle())
      .padding(0, 1)
      .width(width);

    return panel.render().split('\n');
  }

  String _buildSubTabsLine() {
    final buffer = StringBuffer();
    buffer.write('▶ ');

    final keys = ['A', 'B', 'C', 'D'];

    for (var i = 0; i < _subTabs.length; i++) {
      final isActive = i == activeSubTab;
      final tabLabel = '${_subTabs[i]} [${keys[i]}]';

      if (i > 0) buffer.write(_grayStyle().render(' | '));

      if (isActive) {
        buffer.write(_cyanStyle().render(tabLabel));
      } else {
        buffer.write(_grayStyle().render(tabLabel));
      }
    }

    return buffer.toString();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 4: Main Log Panel
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildLogPanel() {
    // Title line: "◎ LOGS [1,908,196] ● LIVE"
    final titlePart = _cyanBoldStyle().render('◎ LOGS');
    final countPart = '[${_formatNumber(totalLogs)}]';
    final liveIndicator = liveMode
        ? _greenStyle().render('● LIVE')
        : _yellowStyle().render('● PAUSED');
    final panelTitle = '$titlePart $countPart $liveIndicator';

    // Search/Filter bar
    final searchBar = _buildSearchFilterBar();

    // Scroll indicator
    final scrollIndicator = viewport.atBottom
        ? ''
        : _yellowStyle()
            .render('▲ Scroll up for older (${logs.length} loaded / '
                '${_formatNumber(totalLogs)} total)');

    // Build log content
    final viewportContent = viewport.view();

    // Follow indicator
    final followIndicator = viewport.atBottom
        ? _greenStyle().render('● Following new logs')
        : _yellowStyle()
            .render('▲ Scrollback mode - Press G to follow');

    // Panel controls line
    final controlsLine = _buildLogPanelControls();

    // Combine all content
    final contentLines = <String>[
      searchBar,
      if (scrollIndicator.isNotEmpty) scrollIndicator,
      '',
      viewportContent,
      '',
      followIndicator,
      controlsLine,
    ];

    final panel = tui.Panel()
      .lines(contentLines)
      .border(Border.rounded)
      .borderStyle(_borderStyle())
      .title(panelTitle)
      .padding(0, 1)
      .width(width);

    return panel.render().split('\n');
  }

  String _buildSearchFilterBar() {
    final buffer = StringBuffer();

    // Search input
    buffer.write(_grayStyle().render('[/] [ search ... ]'));
    buffer.write('  ');

    // Filters
    final filters = [
      ('[P]', 'All Projects', true),
      ('[E]', 'all', false),
      ('[C]', 'all', false),
      ('[L]', 'all', false),
      ('[T]', 'All', true),
      ('[S]', 'newest', false),
    ];

    for (final (key, value, isCyan) in filters) {
      buffer.write(_grayStyle().render(key));
      buffer.write(' ');
      if (isCyan) {
        buffer.write(_cyanStyle().render(value));
      } else {
        buffer.write(_dimGrayStyle().render(value));
      }
      buffer.write('  ');
    }

    return buffer.toString();
  }

  String _buildLogPanelControls() {
    final buffer = StringBuffer();

    // Left side: controls
    final controls = [
      '[↑↓] Scroll',
      '[<>] Pan',
      '[T] Live',
      '[R] Refresh',
    ];
    buffer.write(_grayStyle().render(controls.join('  ')));

    // Calculate padding
    final leftPart = buffer.toString();
    final leftLen = Style.visibleLength(leftPart);

    // Right side: latency + time
    final latencyStr = _grayStyle().render('${latencyMs}ms');
    final timeStr = _grayStyle().render(_formatTime(currentTime));
    final rightPart = '$latencyStr  $timeStr';
    final rightLen = Style.visibleLength(rightPart);

    final innerWidth = width - 4; // Account for border and padding
    final padding = innerWidth - leftLen - rightLen;

    if (padding > 0) {
      return '$leftPart${' ' * padding}$rightPart';
    }
    return '$leftPart  $rightPart';
  }

  String _formatLogEntry(LogEntry entry, int maxWidth) {
    // Timestamp: [HH:MM:SS]
    final h = entry.timestamp.hour.toString().padLeft(2, '0');
    final m = entry.timestamp.minute.toString().padLeft(2, '0');
    final s = entry.timestamp.second.toString().padLeft(2, '0');
    final timestamp = _grayStyle().render('[$h:$m:$s]');

    // Level with color
    final levelStyle = switch (entry.level) {
      LogLevel.info => _greenStyle(),
      LogLevel.debug => _blueStyle(),
      LogLevel.warning => _yellowStyle(),
      LogLevel.error => _redStyle().bold(),
    };
    final level = levelStyle.render(entry.levelStr);

    // Project/Env badge: "kasm/PROD" (cyan/green pill style)
    final projectBadge = '${_cyanStyle().render(entry.project)}/'
        '${_greenStyle().render(entry.environment)}';

    // Source tag: [kasm_rdp] (purple in brackets)
    final sourceTag = _purpleStyle().render('[${entry.source}]');

    // ISO timestamp for the message
    final isoTime = _formatIsoTimestamp(entry.timestamp);

    // Build file:line if present
    String fileLine = '';
    if (entry.filename != null && entry.lineNumber != null) {
      fileLine = '${entry.filename}:${entry.lineNumber} ';
    }

    // Full message
    final message = '$isoTime $fileLine${entry.message}';

    // Build the log line
    final parts = [timestamp, level, projectBadge, sourceTag, message];
    var line = parts.join(' ');

    // Truncate if too long
    final visibleLen = Style.visibleLength(line);
    if (visibleLen > maxWidth) {
      // Crude truncation - keep ANSI codes but add ellipsis
      final overflow = visibleLen - maxWidth + 1;
      if (line.length > overflow + 3) {
        line = '${line.substring(0, line.length - overflow)}→';
      }
    }

    return line;
  }

  String _formatIsoTimestamp(DateTime dt) {
    final y = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$y-$mo-${d}T$h:$m:$s.${ms}Z';
  }

  String _formatNumber(int n) {
    final str = n.toString();
    final result = StringBuffer();
    var count = 0;
    for (var i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 5: Footer Panel
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildFooterPanel() {
    // Left side: controls
    final leftPart = _grayStyle().render(
        '[1-6] Navigate | [←→] Switch | [R] Refresh | [Q] Quit | Click to navigate');

    // Right side: breadcrumb
    final breadcrumb =
        '${_cyanStyle().render('MONITORING')} → ${_whiteBoldStyle().render('LOGS')}';

    // Calculate padding
    final leftLen = Style.visibleLength(leftPart);
    final rightLen = Style.visibleLength(breadcrumb);
    final innerWidth = width - 4; // Account for border and padding

    final padding = innerWidth - leftLen - rightLen;
    String content;
    if (padding > 0) {
      content = '$leftPart${' ' * padding}$breadcrumb';
    } else {
      content = '$leftPart  $breadcrumb';
    }

    final panel = tui.Panel()
      .content(content)
      .border(Border.rounded)
      .borderStyle(_borderStyle())
      .padding(0, 1)
      .width(width);

    return panel.render().split('\n');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m:$s $ampm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  final p = tui.Program(
    CommandCenterModel.initial(),
    options: const tui.ProgramOptions(
      useUltravioletRenderer: true,
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );

  await p.run();
}
