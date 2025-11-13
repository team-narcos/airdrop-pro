import 'dart:developer' as developer;

/// Simple logger utility for P2P managers
class Logger {
  static void logInfo(String message) {
    developer.log(message, name: 'AirDropPro', level: 800);
  }
  
  static void logError(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'AirDropPro',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
  
  static void logWarning(String message) {
    developer.log(message, name: 'AirDropPro', level: 900);
  }
  
  static void logDebug(String message) {
    developer.log(message, name: 'AirDropPro', level: 500);
  }
}

/// Global logging functions for convenience
void logInfo(String message) => Logger.logInfo(message);
void logError(String message, [Object? error, StackTrace? stackTrace]) =>
    Logger.logError(message, error: error, stackTrace: stackTrace);
void logWarning(String message) => Logger.logWarning(message);
void logDebug(String message) => Logger.logDebug(message);
