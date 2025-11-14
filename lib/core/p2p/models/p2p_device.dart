import 'package:flutter/foundation.dart';

/// Represents a discovered device on the local network
@immutable
class P2PDevice {
  final String id;              // Unique device ID (UUID)
  final String name;            // User-friendly device name
  final String platform;        // windows, macos, linux, android, ios
  final String ipAddress;       // Local IP address
  final int port;               // TCP port for connection
  final DateTime lastSeen;      // Last discovery time
  final bool isConnected;       // Current connection status
  final bool isTrusted;         // Paired/trusted device
  final DeviceCapabilities capabilities;
  
  const P2PDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.ipAddress,
    required this.port,
    required this.lastSeen,
    this.isConnected = false,
    this.isTrusted = false,
    required this.capabilities,
  });
  
  /// Create from mDNS discovery data
  factory P2PDevice.fromMDNS({
    required String id,
    required String name,
    required String ipAddress,
    required int port,
    required Map<String, String> txt,
  }) {
    return P2PDevice(
      id: id,
      name: name,
      platform: txt['platform'] ?? 'unknown',
      ipAddress: ipAddress,
      port: port,
      lastSeen: DateTime.now(),
      capabilities: DeviceCapabilities.fromMap(txt),
    );
  }
  
  /// Copy with updated fields
  P2PDevice copyWith({
    String? id,
    String? name,
    String? platform,
    String? ipAddress,
    int? port,
    DateTime? lastSeen,
    bool? isConnected,
    bool? isTrusted,
    DeviceCapabilities? capabilities,
  }) {
    return P2PDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
      isTrusted: isTrusted ?? this.isTrusted,
      capabilities: capabilities ?? this.capabilities,
    );
  }
  
  /// Check if device is still active (seen within last 30 seconds)
  bool get isActive {
    final age = DateTime.now().difference(lastSeen);
    return age.inSeconds < 30;
  }
  
  /// Get device icon based on platform
  String get icon {
    switch (platform.toLowerCase()) {
      case 'windows':
        return 'device_laptop';
      case 'macos':
        return 'device_laptop';
      case 'linux':
        return 'device_desktop';
      case 'android':
        return 'device_phone';
      case 'ios':
        return 'device_phone';
      default:
        return 'device_unknown';
    }
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is P2PDevice && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'P2PDevice(id: $id, name: $name, ip: $ipAddress, connected: $isConnected)';
  }
}

/// Device capabilities and supported features
@immutable
class DeviceCapabilities {
  final String appVersion;
  final int maxChunkSize;           // Maximum chunk size in bytes
  final List<String> compression;   // Supported compression: none, gzip, lz4
  final bool resumeSupport;         // Supports resume after interruption
  final int parallelStreams;        // Number of parallel connections
  final bool encryption;            // Supports AES-256-GCM encryption
  
  const DeviceCapabilities({
    required this.appVersion,
    this.maxChunkSize = 1048576,     // 1MB default
    this.compression = const ['none'],
    this.resumeSupport = true,
    this.parallelStreams = 4,
    this.encryption = true,
  });
  
  /// Default capabilities for this device
  factory DeviceCapabilities.defaults() {
    return const DeviceCapabilities(
      appVersion: '1.0.0',
      maxChunkSize: 4194304,          // 4MB
      compression: ['none', 'gzip'],
      resumeSupport: true,
      parallelStreams: 4,
      encryption: true,
    );
  }
  
  /// Create from mDNS TXT record
  factory DeviceCapabilities.fromMap(Map<String, String> txt) {
    return DeviceCapabilities(
      appVersion: txt['version'] ?? '1.0.0',
      maxChunkSize: int.tryParse(txt['chunk_size'] ?? '') ?? 1048576,
      compression: (txt['compression'] ?? 'none').split(','),
      resumeSupport: txt['resume'] == 'true',
      parallelStreams: int.tryParse(txt['streams'] ?? '4') ?? 4,
      encryption: txt['encryption'] != 'false',
    );
  }
  
  /// Convert to TXT record for mDNS advertising
  Map<String, String> toMap() {
    return {
      'version': appVersion,
      'chunk_size': maxChunkSize.toString(),
      'compression': compression.join(','),
      'resume': resumeSupport.toString(),
      'streams': parallelStreams.toString(),
      'encryption': encryption.toString(),
    };
  }
  
  /// Get optimal chunk size based on both devices' capabilities
  int getOptimalChunkSize(DeviceCapabilities other) {
    return maxChunkSize < other.maxChunkSize ? maxChunkSize : other.maxChunkSize;
  }
  
  /// Get common compression method
  String getCommonCompression(DeviceCapabilities other) {
    for (var method in compression) {
      if (other.compression.contains(method) && method != 'none') {
        return method;
      }
    }
    return 'none';
  }
}

/// Device connection status
enum DeviceStatus {
  discovered,    // Found via mDNS
  connecting,    // Attempting connection
  connected,     // TCP connection established
  authenticating, // Performing handshake
  ready,         // Ready for file transfer
  transferring,  // Actively transferring
  disconnected,  // Connection lost
  error,         // Error state
}

extension DeviceStatusExtension on DeviceStatus {
  String get displayName {
    switch (this) {
      case DeviceStatus.discovered:
        return 'Discovered';
      case DeviceStatus.connecting:
        return 'Connecting...';
      case DeviceStatus.connected:
        return 'Connected';
      case DeviceStatus.authenticating:
        return 'Authenticating...';
      case DeviceStatus.ready:
        return 'Ready';
      case DeviceStatus.transferring:
        return 'Transferring';
      case DeviceStatus.disconnected:
        return 'Disconnected';
      case DeviceStatus.error:
        return 'Error';
    }
  }
}
