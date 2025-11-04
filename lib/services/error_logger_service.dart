import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Comprehensive error logging service for debugging and crash reporting
class ErrorLoggerService {
  static final ErrorLoggerService _instance = ErrorLoggerService._internal();
  factory ErrorLoggerService() => _instance;
  ErrorLoggerService._internal();

  final List<LogEntry> _logBuffer = [];
  final int _maxBufferSize = 100;
  final StreamController<LogEntry> _logController = StreamController.broadcast();
  
  File? _logFile;
  bool _isInitialized = false;

  /// Initialize the error logger
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(p.join(dir.path, 'ErrorLogs'));
      
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      _logFile = File(p.join(logsDir.path, 'log_$timestamp.txt'));
      
      _isInitialized = true;
      
      // Log initialization
      await logInfo('ErrorLogger', 'Logger initialized successfully');
      
      // Clean old logs (keep last 7 days)
      _cleanOldLogs(logsDir);
    } catch (e) {
      debugPrint('[ErrorLogger] Failed to initialize: $e');
    }
  }

  /// Log an error with stack trace
  Future<void> logError(
    String source,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      source: source,
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      context: context,
    );
    
    await _logEntry(entry);
  }

  /// Log a warning
  Future<void> logWarning(
    String source,
    String message, {
    Map<String, dynamic>? context,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.warning,
      source: source,
      message: message,
      context: context,
    );
    
    await _logEntry(entry);
  }

  /// Log an info message
  Future<void> logInfo(
    String source,
    String message, {
    Map<String, dynamic>? context,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      source: source,
      message: message,
      context: context,
    );
    
    await _logEntry(entry);
  }

  /// Log a debug message
  Future<void> logDebug(
    String source,
    String message, {
    Map<String, dynamic>? context,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.debug,
      source: source,
      message: message,
      context: context,
    );
    
    await _logEntry(entry);
  }

  /// Log a critical error
  Future<void> logCritical(
    String source,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.critical,
      source: source,
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      context: context,
    );
    
    await _logEntry(entry);
  }

  /// Get recent logs from buffer
  List<LogEntry> getRecentLogs({int? limit}) {
    if (limit != null && limit < _logBuffer.length) {
      return _logBuffer.sublist(_logBuffer.length - limit);
    }
    return List.from(_logBuffer);
  }

  /// Stream of log entries
  Stream<LogEntry> get logStream => _logController.stream;

  /// Export logs to a file
  Future<File?> exportLogs() async {
    try {
      if (_logFile == null || !await _logFile!.exists()) {
        return null;
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(dir.path, 'ExportedLogs'));
      
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportFile = File(p.join(exportDir.path, 'export_$timestamp.txt'));
      
      await _logFile!.copy(exportFile.path);
      return exportFile;
    } catch (e) {
      debugPrint('[ErrorLogger] Failed to export logs: $e');
      return null;
    }
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    try {
      _logBuffer.clear();
      
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.delete();
      }
      
      // Reinitialize with new file
      _isInitialized = false;
      await initialize();
    } catch (e) {
      debugPrint('[ErrorLogger] Failed to clear logs: $e');
    }
  }

  // Private methods

  Future<void> _logEntry(LogEntry entry) async {
    // Add to buffer
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
    
    // Emit to stream
    _logController.add(entry);
    
    // Print to console in debug mode
    if (kDebugMode) {
      final prefix = _getLevelPrefix(entry.level);
      debugPrint('$prefix [${entry.source}] ${entry.message}');
      if (entry.error != null) {
        debugPrint('  Error: ${entry.error}');
      }
      if (entry.stackTrace != null) {
        debugPrint('  Stack: ${entry.stackTrace}');
      }
    }
    
    // Write to file
    await _writeToFile(entry);
  }

  Future<void> _writeToFile(LogEntry entry) async {
    if (!_isInitialized || _logFile == null) {
      return;
    }
    
    try {
      final formatted = _formatLogEntry(entry);
      await _logFile!.writeAsString(
        '$formatted\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('[ErrorLogger] Failed to write to file: $e');
    }
  }

  String _formatLogEntry(LogEntry entry) {
    final buffer = StringBuffer();
    
    // Timestamp and level
    buffer.write('[${entry.timestamp.toIso8601String()}] ');
    buffer.write('[${entry.level.name.toUpperCase()}] ');
    buffer.write('[${entry.source}] ');
    buffer.writeln(entry.message);
    
    // Error details
    if (entry.error != null) {
      buffer.writeln('  Error: ${entry.error}');
    }
    
    // Stack trace
    if (entry.stackTrace != null) {
      buffer.writeln('  Stack Trace:');
      final lines = entry.stackTrace!.split('\n');
      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          buffer.writeln('    $line');
        }
      }
    }
    
    // Context
    if (entry.context != null && entry.context!.isNotEmpty) {
      buffer.writeln('  Context:');
      entry.context!.forEach((key, value) {
        buffer.writeln('    $key: $value');
      });
    }
    
    buffer.writeln('---');
    
    return buffer.toString();
  }

  String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🔥';
    }
  }

  Future<void> _cleanOldLogs(Directory logsDir) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      await for (final entity in logsDir.list()) {
        if (entity is File && entity.path.endsWith('.txt')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('[ErrorLogger] Failed to clean old logs: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _logController.close();
  }
}

/// Log entry model
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String source;
  final String message;
  final String? error;
  final String? stackTrace;
  final Map<String, dynamic>? context;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'source': source,
    'message': message,
    if (error != null) 'error': error,
    if (stackTrace != null) 'stackTrace': stackTrace,
    if (context != null) 'context': context,
  };
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Global error logger instance
final errorLogger = ErrorLoggerService();
