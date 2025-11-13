import 'dart:developer' as developer;

/// Base class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  const AppException({
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });
  
  /// User-friendly message to display in UI
  String getUserMessage() => userMessage ?? message;
  
  @override
  String toString() => 'AppException: $message';
}

/// WiFi Direct related errors
class WiFiDirectException extends AppException {
  const WiFiDirectException({
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    userMessage: userMessage,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Bluetooth related errors
class BluetoothException extends AppException {
  const BluetoothException({
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    userMessage: userMessage,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Connection related errors
class ConnectionException extends AppException {
  const ConnectionException({
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    userMessage: userMessage,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// File transfer errors
class TransferException extends AppException {
  const TransferException({
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    userMessage: userMessage,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Encryption/Security errors
class SecurityException extends AppException {
  const SecurityException({
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    userMessage: userMessage,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Permission errors
class PermissionException extends AppException {
  final String permissionName;
  
  const PermissionException({
    required String message,
    required this.permissionName,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    userMessage: userMessage,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// File system errors
class FileSystemException extends AppException {
  const FileSystemException({
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    userMessage: userMessage,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Timeout errors
class TimeoutException extends AppException {
  final Duration timeout;
  
  const TimeoutException({
    required String message,
    required this.timeout,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    userMessage: userMessage,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Centralized error handler
class ErrorHandler {
  /// Handle errors with logging and user-friendly message extraction
  static String handle(dynamic error, {StackTrace? stackTrace}) {
    // Log the error
    _logError(error, stackTrace);
    
    // Extract user-friendly message
    return _getUserMessage(error);
  }
  
  /// Log error to console/analytics
  static void _logError(dynamic error, StackTrace? stackTrace) {
    if (error is AppException) {
      developer.log(
        'Error: ${error.message}',
        name: 'ErrorHandler',
        error: error.originalError ?? error,
        stackTrace: error.stackTrace ?? stackTrace,
        level: 1000, // Error level
      );
    } else {
      developer.log(
        'Unexpected error: $error',
        name: 'ErrorHandler',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
    
    // TODO: Send to analytics/crash reporting service
    // e.g., FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  
  /// Extract user-friendly message from error
  static String _getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.getUserMessage();
    }
    
    // Handle common Flutter/Dart errors
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket')) {
      return 'Connection lost. Please try again.';
    }
    
    if (errorString.contains('permission')) {
      return 'Permission required. Please grant access in settings.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Operation timed out. Please check your connection.';
    }
    
    if (errorString.contains('file')) {
      return 'File access error. Please check file permissions.';
    }
    
    if (errorString.contains('bluetooth')) {
      return 'Bluetooth error. Please enable Bluetooth and try again.';
    }
    
    if (errorString.contains('wifi')) {
      return 'WiFi error. Please check WiFi settings.';
    }
    
    // Default message
    return 'Something went wrong. Please try again.';
  }
}

/// Factory methods for creating common errors
class ErrorFactory {
  // WiFi Direct errors
  static WiFiDirectException wifiDirectNotSupported() {
    return const WiFiDirectException(
      message: 'WiFi Direct not supported on this device',
      userMessage: 'Your device doesn\'t support WiFi Direct. We\'ll use Bluetooth instead.',
    );
  }
  
  static WiFiDirectException wifiDirectDisabled() {
    return const WiFiDirectException(
      message: 'WiFi Direct is disabled',
      userMessage: 'Please enable WiFi to discover nearby devices.',
    );
  }
  
  static WiFiDirectException discoveryFailed(dynamic error) {
    return WiFiDirectException(
      message: 'Device discovery failed',
      userMessage: 'Couldn\'t find nearby devices. Please check WiFi settings.',
      originalError: error,
    );
  }
  
  static WiFiDirectException connectionFailed(String deviceName, dynamic error) {
    return WiFiDirectException(
      message: 'Failed to connect to $deviceName',
      userMessage: 'Couldn\'t connect to $deviceName. Please try again.',
      originalError: error,
    );
  }
  
  // Bluetooth errors
  static BluetoothException bluetoothNotSupported() {
    return const BluetoothException(
      message: 'Bluetooth not supported on this device',
      userMessage: 'Your device doesn\'t support Bluetooth.',
    );
  }
  
  static BluetoothException bluetoothDisabled() {
    return const BluetoothException(
      message: 'Bluetooth is disabled',
      userMessage: 'Please enable Bluetooth to discover nearby devices.',
    );
  }
  
  static BluetoothException bluetoothPairingFailed(String deviceName) {
    return BluetoothException(
      message: 'Bluetooth pairing failed with $deviceName',
      userMessage: 'Couldn\'t pair with $deviceName. Please try pairing manually.',
    );
  }
  
  // Connection errors
  static ConnectionException noDevicesFound() {
    return const ConnectionException(
      message: 'No devices found nearby',
      userMessage: 'No nearby devices found. Make sure the other device has AirDrop Pro open.',
    );
  }
  
  static ConnectionException connectionTimeout(String deviceName) {
    return ConnectionException(
      message: 'Connection timeout to $deviceName',
      userMessage: 'Connection to $deviceName timed out. Please move closer and try again.',
    );
  }
  
  static ConnectionException connectionLost() {
    return const ConnectionException(
      message: 'Connection lost during transfer',
      userMessage: 'Connection was lost. Transfer will resume when reconnected.',
    );
  }
  
  static ConnectionException bothProtocolsFailed() {
    return const ConnectionException(
      message: 'Both WiFi Direct and Bluetooth failed',
      userMessage: 'Couldn\'t connect using WiFi or Bluetooth. Please check your settings.',
    );
  }
  
  // Transfer errors
  static TransferException fileTooLarge(int fileSize, int maxSize) {
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
    final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(1);
    return TransferException(
      message: 'File too large: $fileSizeMB MB (max: $maxSizeMB MB)',
      userMessage: 'File is too large ($fileSizeMB MB). Maximum supported size is $maxSizeMB MB.',
    );
  }
  
  static TransferException transferFailed(String fileName, dynamic error) {
    return TransferException(
      message: 'Transfer failed for $fileName',
      userMessage: 'Failed to transfer $fileName. Please try again.',
      originalError: error,
    );
  }
  
  static TransferException chunkVerificationFailed(int chunkIndex) {
    return TransferException(
      message: 'Chunk $chunkIndex verification failed',
      userMessage: 'Transfer interrupted. Retrying...',
    );
  }
  
  static TransferException insufficientStorage(int requiredBytes) {
    final requiredMB = (requiredBytes / (1024 * 1024)).toStringAsFixed(1);
    return TransferException(
      message: 'Insufficient storage: need $requiredMB MB',
      userMessage: 'Not enough storage space. Please free up at least $requiredMB MB.',
    );
  }
  
  // Security errors
  static SecurityException keyExchangeFailed(dynamic error) {
    return SecurityException(
      message: 'Key exchange failed',
      userMessage: 'Secure connection failed. Please try again.',
      originalError: error,
    );
  }
  
  static SecurityException encryptionFailed(dynamic error) {
    return SecurityException(
      message: 'Encryption failed',
      userMessage: 'Failed to encrypt file. Please try again.',
      originalError: error,
    );
  }
  
  static SecurityException decryptionFailed(dynamic error) {
    return SecurityException(
      message: 'Decryption failed',
      userMessage: 'Failed to decrypt file. File may be corrupted.',
      originalError: error,
    );
  }
  
  static SecurityException integrityCheckFailed() {
    return const SecurityException(
      message: 'File integrity check failed',
      userMessage: 'File verification failed. The file may be corrupted.',
    );
  }
  
  // Permission errors
  static PermissionException locationPermissionDenied() {
    return const PermissionException(
      message: 'Location permission denied',
      permissionName: 'Location',
      userMessage: 'Location permission is required for WiFi Direct. Please grant it in settings.',
    );
  }
  
  static PermissionException bluetoothPermissionDenied() {
    return const PermissionException(
      message: 'Bluetooth permission denied',
      permissionName: 'Bluetooth',
      userMessage: 'Bluetooth permission is required. Please grant it in settings.',
    );
  }
  
  static PermissionException storagePermissionDenied() {
    return const PermissionException(
      message: 'Storage permission denied',
      permissionName: 'Storage',
      userMessage: 'Storage permission is required to save files. Please grant it in settings.',
    );
  }
  
  static PermissionException nearbyDevicesPermissionDenied() {
    return const PermissionException(
      message: 'Nearby devices permission denied',
      permissionName: 'Nearby Devices',
      userMessage: 'Permission to find nearby devices is required. Please grant it in settings.',
    );
  }
  
  // File system errors
  static FileSystemException fileNotFound(String filePath) {
    return FileSystemException(
      message: 'File not found: $filePath',
      userMessage: 'File not found. It may have been moved or deleted.',
    );
  }
  
  static FileSystemException fileAccessDenied(String filePath) {
    return FileSystemException(
      message: 'Access denied to file: $filePath',
      userMessage: 'Cannot access file. Please check permissions.',
    );
  }
  
  static FileSystemException fileWriteFailed(String filePath, dynamic error) {
    return FileSystemException(
      message: 'Failed to write file: $filePath',
      userMessage: 'Failed to save file. Please check storage space.',
      originalError: error,
    );
  }
  
  // Timeout errors
  static TimeoutException operationTimeout(String operation, Duration timeout) {
    return TimeoutException(
      message: '$operation timed out after ${timeout.inSeconds}s',
      timeout: timeout,
      userMessage: 'Operation took too long. Please try again.',
    );
  }
  
  static TimeoutException discoveryTimeout() {
    return const TimeoutException(
      message: 'Device discovery timed out',
      timeout: Duration(seconds: 30),
      userMessage: 'No devices found. Please make sure other devices are nearby and have the app open.',
    );
  }
}

/// Result type for operations that can fail
class Result<T> {
  final T? data;
  final AppException? error;
  
  const Result._({this.data, this.error});
  
  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(AppException error) => Result._(error: error);
  
  bool get isSuccess => data != null && error == null;
  bool get isFailure => error != null;
  
  /// Transform success data
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      try {
        return Result.success(transform(data as T));
      } catch (e, stackTrace) {
        return Result.failure(TransferException(
          message: 'Transform failed',
          originalError: e,
          stackTrace: stackTrace,
        ));
      }
    }
    return Result.failure(error!);
  }
  
  /// Execute function on success
  void onSuccess(void Function(T data) callback) {
    if (isSuccess) callback(data as T);
  }
  
  /// Execute function on failure
  void onFailure(void Function(AppException error) callback) {
    if (isFailure) callback(error!);
  }
  
  /// Get data or throw error
  T getOrThrow() {
    if (isSuccess) return data as T;
    throw error!;
  }
  
  /// Get data or return default
  T getOrDefault(T defaultValue) {
    return data ?? defaultValue;
  }
}

/// Extension for Future<Result<T>>
extension ResultFutureExtension<T> on Future<Result<T>> {
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    final result = await this;
    if (result.isSuccess) {
      try {
        final transformed = await transform(result.data as T);
        return Result.success(transformed);
      } catch (e, stackTrace) {
        return Result.failure(TransferException(
          message: 'Async transform failed',
          originalError: e,
          stackTrace: stackTrace,
        ));
      }
    }
    return Result.failure(result.error!);
  }
}

/// Retry helper for operations
class RetryHelper {
  /// Retry an operation with exponential backoff
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (true) {
      attempts++;
      
      try {
        return await operation();
      } catch (e, stackTrace) {
        if (attempts >= maxAttempts) {
          rethrow;
        }
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }
        
        // Log retry attempt
        developer.log(
          'Retry attempt $attempts/$maxAttempts after error: $e',
          name: 'RetryHelper',
          level: 800, // Warning level
        );
        
        // Wait before retrying
        await Future.delayed(delay);
        delay *= backoffMultiplier;
      }
    }
  }
}
