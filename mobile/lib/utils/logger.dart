import 'package:flutter/foundation.dart';

/// Log levels for different types of messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// A utility class for logging messages with different levels of severity
class AppLogger {

  /// Whether to show timestamps in logs
  static bool showTimestamps = true;
  
  /// Whether to show log levels in logs
  static bool showLogLevels = true;
  
  /// Whether logging is enabled
  static bool loggingEnabled = true;

  /// Log a debug message
  static void d(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// Log an info message
  static void i(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Log a warning message
  static void w(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  /// Log an error message
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag);
    if (error != null) {
      _printToConsole('ERROR: $error');
    }
    if (stackTrace != null) {
      _printToConsole('STACK TRACE: $stackTrace');
    }
  }

  /// Internal method to log messages with the appropriate format
  static void _log(LogLevel level, String message, {String? tag}) {
    if (!loggingEnabled) return;
    
    final StringBuffer logMessage = StringBuffer();
    
    // Add timestamp if enabled
    if (showTimestamps) {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
      logMessage.write('[$timeStr] ');
    }
    
    // Add log level if enabled
    if (showLogLevels) {
      final levelStr = level.toString().split('.').last.toUpperCase();
      logMessage.write('[$levelStr] ');
    }
    
    // Add tag if provided
    if (tag != null && tag.isNotEmpty) {
      logMessage.write('[$tag] ');
    }
    
    // Add the actual message
    logMessage.write(message);
    
    // Print to console
    _printToConsole(logMessage.toString());
  }
  
  /// Print to console with appropriate emoji for visual distinction
  static void _printToConsole(String message) {
    // Use print in release mode, debugPrint in debug mode
    if (kDebugMode) {
      // debugPrint handles line breaking better for long messages
      debugPrint('🔍 $message');
    } else {
      // In release mode, only print if explicitly enabled
      if (loggingEnabled) {
        print('🔍 $message');
      }
    }
  }
}

/// Shorthand for AppLogger.d
void logDebug(String message, {String? tag}) {
  AppLogger.d(message, tag: tag);
}

/// Shorthand for AppLogger.i
void logInfo(String message, {String? tag}) {
  AppLogger.i(message, tag: tag);
}

/// Shorthand for AppLogger.w
void logWarning(String message, {String? tag}) {
  AppLogger.w(message, tag: tag);
}

/// Shorthand for AppLogger.e
void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
  AppLogger.e(message, tag: tag, error: error, stackTrace: stackTrace);
}
