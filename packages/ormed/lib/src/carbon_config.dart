import 'package:carbonized/carbonized.dart';

/// Configuration for Carbon date/time functionality in Ormed.
///
/// This class provides static configuration for Carbon instances used
/// throughout the ORM, including timezone settings and locale preferences.
///
/// Example:
/// ```dart
/// // Configure before using the ORM
/// CarbonConfig.configure(
///   defaultTimezone: 'America/New_York',
///   defaultLocale: 'en_US',
/// );
///
/// // Or configure with TimeMachine for named timezone support
/// await CarbonConfig.configureWithTimeMachine(
///   defaultTimezone: 'America/New_York',
///   defaultLocale: 'en_US',
/// );
/// ```
class CarbonConfig {
  static String _defaultTimezone = 'UTC';
  static String _defaultLocale = 'en_US';
  static bool _isTimeMachineConfigured = false;

  static bool _isFixedOffsetTimezone(String timezone) {
    final tz = timezone.trim();
    if (tz == 'UTC' || tz == 'Z') {
      return true;
    }
    // Supports: +05, +0530, +05:30, -04, -0400, -04:00
    return RegExp(r'^[+-]\d{2}(?::?\d{2})?$').hasMatch(tz);
  }

  /// Gets the default timezone for Carbon instances.
  ///
  /// Defaults to 'UTC' unless changed via [configure].
  static String get defaultTimezone => _defaultTimezone;

  /// Gets the default locale for Carbon instances.
  ///
  /// Defaults to 'en_US' unless changed via [configure].
  static String get defaultLocale => _defaultLocale;

  /// Returns true if TimeMachine has been configured for named timezone support.
  ///
  /// Named timezones like 'America/New_York' require TimeMachine to be configured.
  /// UTC and fixed offsets (like '+05:30') work without configuration.
  static bool get isTimeMachineConfigured => _isTimeMachineConfigured;

  /// Configures Carbon settings for the ORM.
  ///
  /// Parameters:
  /// - [defaultTimezone]: Default timezone for Carbon instances (default: 'UTC')
  /// - [defaultLocale]: Default locale for Carbon instances (default: 'en_US')
  ///
  /// Note: For named timezones other than 'UTC', you must use [configureWithTimeMachine].
  ///
  /// Example:
  /// ```dart
  /// CarbonConfig.configure(
  ///   defaultTimezone: 'UTC',
  ///   defaultLocale: 'en_US',
  /// );
  /// ```
  static void configure({String? defaultTimezone, String? defaultLocale}) {
    if (defaultTimezone != null) {
      _defaultTimezone = defaultTimezone;
    }
    if (defaultLocale != null) {
      _defaultLocale = defaultLocale;
    }
  }

  /// Configures Carbon with TimeMachine support for named timezones.
  ///
  /// This enables the use of named timezones like 'America/New_York',
  /// 'Europe/London', etc. in Carbon instances.
  ///
  /// Parameters:
  /// - [defaultTimezone]: Default timezone for Carbon instances (default: 'UTC')
  /// - [defaultLocale]: Default locale for Carbon instances (default: 'en_US')
  ///
  /// Example:
  /// ```dart
  /// await CarbonConfig.configureWithTimeMachine(
  ///   defaultTimezone: 'America/New_York',
  ///   defaultLocale: 'en_US',
  /// );
  /// ```
  ///
  /// Note: This is an async operation that loads timezone data.
  static Future<void> configureWithTimeMachine({
    String? defaultTimezone,
    String? defaultLocale,
  }) async {
    // Configure TimeMachine for named timezone support
    await Carbon.configureTimeMachine();
    _isTimeMachineConfigured = true;

    // Set defaults
    configure(defaultTimezone: defaultTimezone, defaultLocale: defaultLocale);
  }

  /// Resets configuration to defaults.
  ///
  /// This is primarily useful for testing. Sets timezone to 'UTC',
  /// locale to 'en_US', and marks TimeMachine as not configured.
  static void reset() {
    _defaultTimezone = 'UTC';
    _defaultLocale = 'en_US';
    _isTimeMachineConfigured = false;
  }

  /// Creates a Carbon instance with the configured defaults.
  ///
  /// Parameters:
  /// - [dateTime]: The DateTime to wrap (defaults to current time)
  /// - [timezone]: Override default timezone for this instance
  /// - [locale]: Override default locale for this instance
  ///
  /// Example:
  /// ```dart
  /// final now = CarbonConfig.createCarbon();
  /// final utc = CarbonConfig.createCarbon(timezone: 'UTC');
  /// final custom = CarbonConfig.createCarbon(
  ///   dateTime: DateTime(2024, 12, 25),
  ///   timezone: 'America/New_York',
  /// );
  /// ```
  static Carbon createCarbon({
    DateTime? dateTime,
    String? timezone,
    String? locale,
  }) {
    final dt = dateTime ?? DateTime.now();
    final tz = timezone ?? _defaultTimezone;
    final resolvedLocale = locale ?? _defaultLocale;

    // Apply timezone if specified or use default
    if (tz != 'UTC' &&
        !_isTimeMachineConfigured &&
        !_isFixedOffsetTimezone(tz)) {
      throw StateError(
        'Named timezone "$tz" requires calling '
        'CarbonConfig.configureWithTimeMachine() first. '
        'UTC and fixed offsets (like "+05:30") work without configuration.',
      );
    }

    // If the caller passed a "local" DateTime and the configured timezone is
    // non-UTC, interpret the wall-clock components in that configured timezone.
    // This avoids reliance on the host machine's local timezone (e.g. CI in UTC).
    if (tz != 'UTC' && !dt.isUtc) {
      return Carbon.parse(
        dt.toIso8601String(),
        timeZone: tz,
        locale: resolvedLocale,
      );
    }

    final carbon = Carbon.fromDateTime(dt, locale: resolvedLocale);
    return carbon.tz(tz) as Carbon;
  }

  /// Parses a date string into a Carbon instance with configured defaults.
  ///
  /// Parameters:
  /// - [dateString]: The date string to parse (ISO8601 format recommended)
  /// - [timezone]: Override default timezone for this instance
  /// - [locale]: Override default locale for this instance
  ///
  /// Example:
  /// ```dart
  /// final date = CarbonConfig.parseCarbon('2024-12-25T10:30:00Z');
  /// final custom = CarbonConfig.parseCarbon(
  ///   '2024-12-25',
  ///   timezone: 'America/New_York',
  /// );
  /// ```
  static Carbon parseCarbon(
    String dateString, {
    String? timezone,
    String? locale,
  }) {
    final tz = timezone ?? _defaultTimezone;
    final resolvedLocale = locale ?? _defaultLocale;

    // Apply timezone if specified or use default
    if (tz != 'UTC' &&
        !_isTimeMachineConfigured &&
        !_isFixedOffsetTimezone(tz)) {
      throw StateError(
        'Named timezone "$tz" requires calling '
        'CarbonConfig.configureWithTimeMachine() first. '
        'UTC and fixed offsets (like "+05:30") work without configuration.',
      );
    }

    return Carbon.parse(dateString, timeZone: tz, locale: resolvedLocale);
  }
}
