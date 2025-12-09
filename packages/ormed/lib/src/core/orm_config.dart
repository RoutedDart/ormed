import 'package:carbonized/carbonized.dart';

/// Global configuration for the ORM.
class OrmConfig {
  static bool _carbonInitialized = false;

  /// Initializes Carbon timezone support.
  /// 
  /// This should be called once at application startup if you want to use
  /// Carbon's timezone features. Configures Time Machine for named timezone support.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   OrmConfig.initializeCarbon();
  ///   // ... rest of your application
  /// }
  /// ```
  static void initializeCarbon({String? defaultTimezone}) {
    if (_carbonInitialized) return;
    
    try {
      Carbon.configureTimeMachine();
      _carbonInitialized = true;
      
      if (defaultTimezone != null) {
        // Note: This would require Carbon to support setting a global default TZ
        // For now, timezone must be specified per instance
      }
    } catch (e) {
      throw StateError('Failed to initialize Carbon: $e');
    }
  }
  
  /// Whether Carbon has been initialized.
  static bool get isCarbonInitialized => _carbonInitialized;
  
  /// Ensures Carbon is initialized. Called automatically by the ORM.
  /// This is idempotent and safe to call multiple times.
  static void ensureInitialized() {
    initializeCarbon();
  }
}
