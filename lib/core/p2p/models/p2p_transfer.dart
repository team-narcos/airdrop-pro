import 'package:flutter/foundation.dart';
import 'p2p_device.dart';

/// Transfer status
enum TransferStatus {
  pending,       // Waiting for user acceptance
  accepted,      // User accepted, preparing to transfer
  connecting,    // Establishing connection
  transferring,  // Actively transferring data
  paused,        // Transfer paused
  completed,     // Successfully completed
  failed,        // Transfer failed
  cancelled,     // User cancelled
}

extension TransferStatusExtension on TransferStatus {
  String get displayName {
    switch (this) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.accepted:
        return 'Accepted';
      case TransferStatus.connecting:
        return 'Connecting';
      case TransferStatus.transferring:
        return 'Transferring';
      case TransferStatus.paused:
        return 'Paused';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.failed:
        return 'Failed';
      case TransferStatus.cancelled:
        return 'Cancelled';
    }
  }
  
  bool get isActive => this == TransferStatus.transferring;
  bool get isComplete => this == TransferStatus.completed;
  bool get isFailed => this == TransferStatus.failed || this == TransferStatus.cancelled;
  bool get canResume => this == TransferStatus.paused || this == TransferStatus.failed;
}

/// Transfer direction
enum TransferDirection {
  sending,
  receiving,
}

/// P2P file transfer
@immutable
class P2PTransfer {
  final String id;                     // Unique transfer ID
  final String deviceId;               // Device we're transferring with
  final TransferDirection direction;   // Sending or receiving
  final TransferStatus status;
  final List<TransferFile> files;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  
  const P2PTransfer({
    required this.id,
    required this.deviceId,
    required this.direction,
    required this.status,
    required this.files,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });
  
  /// Create new outgoing transfer
  factory P2PTransfer.sending({
    required String id,
    required String deviceId,
    required List<TransferFile> files,
  }) {
    return P2PTransfer(
      id: id,
      deviceId: deviceId,
      direction: TransferDirection.sending,
      status: TransferStatus.connecting,
      files: files,
      createdAt: DateTime.now(),
    );
  }
  
  /// Create new incoming transfer
  factory P2PTransfer.receiving({
    required String id,
    required String deviceId,
    required List<TransferFile> files,
  }) {
    return P2PTransfer(
      id: id,
      deviceId: deviceId,
      direction: TransferDirection.receiving,
      status: TransferStatus.pending,
      files: files,
      createdAt: DateTime.now(),
    );
  }
  
  /// Copy with updated fields
  P2PTransfer copyWith({
    String? id,
    String? deviceId,
    TransferDirection? direction,
    TransferStatus? status,
    List<TransferFile>? files,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return P2PTransfer(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      files: files ?? this.files,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  /// Get total size of all files
  int get totalSize => files.fold(0, (sum, file) => sum + file.size);
  
  /// Get total bytes transferred
  int get bytesTransferred => files.fold(0, (sum, file) => sum + file.bytesTransferred);
  
  /// Get transfer progress (0.0 to 1.0)
  double get progress {
    if (totalSize == 0) return 0.0;
    return bytesTransferred / totalSize;
  }
  
  /// Get transfer speed in bytes per second
  double get speedBytesPerSecond {
    if (startedAt == null) return 0.0;
    final duration = DateTime.now().difference(startedAt!);
    if (duration.inSeconds == 0) return 0.0;
    return bytesTransferred / duration.inSeconds;
  }
  
  /// Get estimated time remaining in seconds
  int? get estimatedSecondsRemaining {
    if (speedBytesPerSecond == 0) return null;
    final remaining = totalSize - bytesTransferred;
    return (remaining / speedBytesPerSecond).ceil();
  }
  
  /// Get formatted speed (e.g., "150 MB/s")
  String get formattedSpeed {
    final speed = speedBytesPerSecond;
    if (speed < 1024) return '${speed.toStringAsFixed(0)} B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
  
  /// Get formatted size (e.g., "1.5 GB")
  String get formattedSize {
    return _formatBytes(totalSize);
  }
  
  /// Get formatted bytes transferred
  String get formattedBytesTransferred {
    return _formatBytes(bytesTransferred);
  }
  
  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  /// Get transfer duration
  Duration? get duration {
    if (startedAt == null) return null;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is P2PTransfer && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'P2PTransfer(id: $id, device: $deviceId, status: $status, ${files.length} files)';
  }
}

/// Individual file within a transfer
@immutable
class TransferFile {
  final String id;                    // Unique file ID within transfer
  final String name;                  // Original filename
  final String path;                  // Local file path
  final int size;                     // Total file size in bytes
  final String mimeType;              // MIME type
  final String? sha256;               // Optional file hash
  final int bytesTransferred;         // Bytes transferred so far
  final int chunkSize;                // Size of each chunk
  final List<bool> chunksReceived;    // Track which chunks are received (for resume)
  final TransferStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  
  const TransferFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.sha256,
    this.bytesTransferred = 0,
    this.chunkSize = 4194304,          // 4MB default
    required this.chunksReceived,
    this.status = TransferStatus.pending,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });
  
  /// Create new file for sending
  factory TransferFile.forSending({
    required String id,
    required String name,
    required String path,
    required int size,
    required String mimeType,
    String? sha256,
    int chunkSize = 4194304,
  }) {
    final totalChunks = (size / chunkSize).ceil();
    return TransferFile(
      id: id,
      name: name,
      path: path,
      size: size,
      mimeType: mimeType,
      sha256: sha256,
      chunkSize: chunkSize,
      chunksReceived: List.filled(totalChunks, false),
      status: TransferStatus.pending,
    );
  }
  
  /// Create new file for receiving
  factory TransferFile.forReceiving({
    required String id,
    required String name,
    required String savePath,
    required int size,
    required String mimeType,
    String? sha256,
    int chunkSize = 4194304,
  }) {
    final totalChunks = (size / chunkSize).ceil();
    return TransferFile(
      id: id,
      name: name,
      path: savePath,
      size: size,
      mimeType: mimeType,
      sha256: sha256,
      chunkSize: chunkSize,
      chunksReceived: List.filled(totalChunks, false),
      status: TransferStatus.pending,
    );
  }
  
  /// Copy with updated fields
  TransferFile copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    String? mimeType,
    String? sha256,
    int? bytesTransferred,
    int? chunkSize,
    List<bool>? chunksReceived,
    TransferStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return TransferFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      sha256: sha256 ?? this.sha256,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      chunkSize: chunkSize ?? this.chunkSize,
      chunksReceived: chunksReceived ?? this.chunksReceived,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  /// Mark chunk as received
  TransferFile markChunkReceived(int chunkIndex) {
    if (chunkIndex < 0 || chunkIndex >= chunksReceived.length) {
      throw RangeError('Chunk index $chunkIndex out of range');
    }
    
    final newChunks = List<bool>.from(chunksReceived);
    newChunks[chunkIndex] = true;
    
    // Calculate new bytes transferred
    final newBytes = newChunks.where((received) => received).length * chunkSize;
    final actualBytes = newBytes > size ? size : newBytes;
    
    return copyWith(
      chunksReceived: newChunks,
      bytesTransferred: actualBytes,
    );
  }
  
  /// Get total number of chunks
  int get totalChunks => chunksReceived.length;
  
  /// Get number of chunks received
  int get chunksReceivedCount => chunksReceived.where((r) => r).length;
  
  /// Get transfer progress (0.0 to 1.0)
  double get progress {
    if (size == 0) return 0.0;
    return bytesTransferred / size;
  }
  
  /// Check if all chunks are received
  bool get isComplete => chunksReceived.every((r) => r);
  
  /// Get list of missing chunk indices (for resume)
  List<int> get missingChunks {
    final missing = <int>[];
    for (var i = 0; i < chunksReceived.length; i++) {
      if (!chunksReceived[i]) {
        missing.add(i);
      }
    }
    return missing;
  }
  
  /// Get formatted size
  String get formattedSize => P2PTransfer._formatBytes(size);
  
  /// Get formatted bytes transferred
  String get formattedBytesTransferred => P2PTransfer._formatBytes(bytesTransferred);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferFile && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'TransferFile(id: $id, name: $name, $formattedBytesTransferred/$formattedSize)';
  }
}

/// Connection state for a device
@immutable
class DeviceConnection {
  final P2PDevice device;
  final DeviceStatus status;
  final DateTime connectedAt;
  final DateTime? lastActivity;
  final String? sessionId;
  final bool isEncrypted;
  
  const DeviceConnection({
    required this.device,
    required this.status,
    required this.connectedAt,
    this.lastActivity,
    this.sessionId,
    this.isEncrypted = false,
  });
  
  /// Create new connection
  factory DeviceConnection.connecting(P2PDevice device) {
    return DeviceConnection(
      device: device,
      status: DeviceStatus.connecting,
      connectedAt: DateTime.now(),
    );
  }
  
  /// Copy with updated fields
  DeviceConnection copyWith({
    P2PDevice? device,
    DeviceStatus? status,
    DateTime? connectedAt,
    DateTime? lastActivity,
    String? sessionId,
    bool? isEncrypted,
  }) {
    return DeviceConnection(
      device: device ?? this.device,
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      sessionId: sessionId ?? this.sessionId,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }
  
  /// Check if connection is stale (no activity for 30 seconds)
  bool get isStale {
    if (lastActivity == null) return false;
    final age = DateTime.now().difference(lastActivity!);
    return age.inSeconds > 30;
  }
  
  /// Update last activity timestamp
  DeviceConnection updateActivity() {
    return copyWith(lastActivity: DateTime.now());
  }
  
  @override
  String toString() {
    return 'DeviceConnection(device: ${device.name}, status: $status)';
  }
}
