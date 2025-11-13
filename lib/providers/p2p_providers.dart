import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/p2p/wifi_direct_manager.dart';
import '../core/p2p/bluetooth_classic_manager.dart';
import '../core/p2p/hybrid_connection_engine.dart';
import '../core/security/secure_transfer_engine.dart';
import '../core/transfer/chunk_transfer_engine.dart';

/// Provider for WiFi Direct Manager singleton
final wifiDirectManagerProvider = Provider<WiFiDirectManager>((ref) {
  return WiFiDirectManager();
});

/// Provider for Bluetooth Classic Manager singleton
final bluetoothClassicManagerProvider = Provider<BluetoothClassicManager>((ref) {
  return BluetoothClassicManager();
});

/// Provider for Hybrid Connection Engine
/// This is the main provider that orchestrates WiFi Direct + Bluetooth
final hybridConnectionEngineProvider = Provider<HybridConnectionEngine>((ref) {
  final wifiManager = ref.watch(wifiDirectManagerProvider);
  final bluetoothManager = ref.watch(bluetoothClassicManagerProvider);
  
  return HybridConnectionEngine(
    wifiDirectManager: wifiManager,
    bluetoothManager: bluetoothManager,
  );
});

/// Provider for Secure Transfer Engine
final secureTransferEngineProvider = Provider<SecureTransferEngine>((ref) {
  return SecureTransferEngine();
});

/// Provider for Chunk Transfer Engine
final chunkTransferEngineProvider = Provider<ChunkTransferEngine>((ref) {
  return ChunkTransferEngine();
});

/// Stream provider for unified device discovery
/// This exposes nearby devices from both WiFi Direct and Bluetooth
final nearbyDevicesStreamProvider = StreamProvider<List<UnifiedDevice>>((ref) {
  final hybridEngine = ref.watch(hybridConnectionEngineProvider);
  return hybridEngine.devicesStream;
});

/// Stream provider for connection status
final connectionStatusStreamProvider = StreamProvider<HybridConnectionStatus>((ref) {
  final hybridEngine = ref.watch(hybridConnectionEngineProvider);
  return hybridEngine.statusStream;
});

/// State notifier for device discovery
class DiscoveryState {
  final bool isScanning;
  final List<UnifiedDevice> devices;
  final String? error;
  
  const DiscoveryState({
    this.isScanning = false,
    this.devices = const [],
    this.error,
  });
  
  DiscoveryState copyWith({
    bool? isScanning,
    List<UnifiedDevice>? devices,
    String? error,
  }) {
    return DiscoveryState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
      error: error,
    );
  }
}

/// Discovery state notifier provider
class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final HybridConnectionEngine _hybridEngine;
  
  DiscoveryNotifier(this._hybridEngine) : super(const DiscoveryState()) {
    // Listen to device stream
    _hybridEngine.devicesStream.listen((devices) {
      state = state.copyWith(devices: devices, error: null);
    }, onError: (error) {
      state = state.copyWith(error: error.toString());
    });
  }
  
  /// Start discovering nearby devices
  Future<void> startDiscovery() async {
    try {
      state = state.copyWith(isScanning: true, error: null);
      await _hybridEngine.startDiscovery();
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Failed to start discovery: $e',
      );
    }
  }
  
  /// Stop device discovery
  Future<void> stopDiscovery() async {
    try {
      await _hybridEngine.stopDiscovery();
      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop discovery: $e');
    }
  }
  
  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final discoveryNotifierProvider = StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final hybridEngine = ref.watch(hybridConnectionEngineProvider);
  return DiscoveryNotifier(hybridEngine);
});

/// Transfer state model
class TransferState {
  final String? fileId;
  final String? fileName;
  final int? fileSize;
  final double progress; // 0.0 to 1.0
  final TransferStatus status;
  final String? error;
  final int? bytesTransferred;
  final double? speed; // bytes per second
  
  const TransferState({
    this.fileId,
    this.fileName,
    this.fileSize,
    this.progress = 0.0,
    this.status = TransferStatus.idle,
    this.error,
    this.bytesTransferred,
    this.speed,
  });
  
  TransferState copyWith({
    String? fileId,
    String? fileName,
    int? fileSize,
    double? progress,
    TransferStatus? status,
    String? error,
    int? bytesTransferred,
    double? speed,
  }) {
    return TransferState(
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      speed: speed ?? this.speed,
    );
  }
  
  bool get isTransferring => status == TransferStatus.transferring;
  bool get isComplete => status == TransferStatus.completed;
  bool get hasError => status == TransferStatus.error;
  
  String get progressText => '${(progress * 100).toStringAsFixed(1)}%';
  
  String get speedText {
    if (speed == null) return '';
    if (speed! < 1024) return '${speed!.toStringAsFixed(0)} B/s';
    if (speed! < 1024 * 1024) return '${(speed! / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed! / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

enum TransferStatus {
  idle,
  connecting,
  keyExchange,
  transferring,
  completed,
  error,
  cancelled,
}

/// Transfer state notifier
class TransferNotifier extends StateNotifier<TransferState> {
  final HybridConnectionEngine _hybridEngine;
  final SecureTransferEngine _secureEngine;
  final ChunkTransferEngine _chunkEngine;
  
  TransferNotifier(
    this._hybridEngine,
    this._secureEngine,
    this._chunkEngine,
  ) : super(const TransferState());
  
  /// Send file to a device
  Future<void> sendFile({
    required UnifiedDevice device,
    required String filePath,
    required String fileName,
    required int fileSize,
  }) async {
    try {
      // Update state: connecting
      state = state.copyWith(
        fileId: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        fileSize: fileSize,
        status: TransferStatus.connecting,
        progress: 0.0,
        error: null,
      );
      
      // Connect to device
      await _hybridEngine.connectToDevice(device);
      
      // Update state: key exchange
      state = state.copyWith(status: TransferStatus.keyExchange);
      
      // Generate ephemeral keys
      await _secureEngine.generateEphemeralKeys();
      
      // Perform ECDH key exchange
      // TODO: Exchange public keys with peer device via socket
      // For now, this is a placeholder
      // await _secureEngine.performKeyExchange(peerPublicKeyBytes);
      
      // Update state: transferring
      state = state.copyWith(status: TransferStatus.transferring);
      
      // TODO: Implement actual file transfer with progress updates
      // This would:
      // 1. Read file in chunks
      // 2. Encrypt each chunk
      // 3. Send through socket
      // 4. Update progress
      
      // Simulate progress for now
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        state = state.copyWith(
          progress: i / 100,
          bytesTransferred: (fileSize * i / 100).toInt(),
          speed: 1024 * 1024 * 2.5, // Simulated 2.5 MB/s
        );
      }
      
      // Update state: completed
      state = state.copyWith(
        status: TransferStatus.completed,
        progress: 1.0,
        bytesTransferred: fileSize,
      );
    } catch (e) {
      state = state.copyWith(
        status: TransferStatus.error,
        error: 'Transfer failed: $e',
      );
    }
  }
  
  /// Cancel ongoing transfer
  Future<void> cancelTransfer() async {
    state = state.copyWith(status: TransferStatus.cancelled);
    await _hybridEngine.disconnect();
  }
  
  /// Reset transfer state
  void reset() {
    state = const TransferState();
  }
}

final transferNotifierProvider = StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  final hybridEngine = ref.watch(hybridConnectionEngineProvider);
  final secureEngine = ref.watch(secureTransferEngineProvider);
  final chunkEngine = ref.watch(chunkTransferEngineProvider);
  
  return TransferNotifier(hybridEngine, secureEngine, chunkEngine);
});

/// Settings state
class SettingsState {
  final bool wifiDirectEnabled;
  final bool bluetoothEnabled;
  final bool encryptionEnabled;
  final String deviceName;
  final bool autoAcceptFiles;
  
  const SettingsState({
    this.wifiDirectEnabled = true,
    this.bluetoothEnabled = true,
    this.encryptionEnabled = true,
    this.deviceName = 'My Device',
    this.autoAcceptFiles = false,
  });
  
  SettingsState copyWith({
    bool? wifiDirectEnabled,
    bool? bluetoothEnabled,
    bool? encryptionEnabled,
    String? deviceName,
    bool? autoAcceptFiles,
  }) {
    return SettingsState(
      wifiDirectEnabled: wifiDirectEnabled ?? this.wifiDirectEnabled,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      deviceName: deviceName ?? this.deviceName,
      autoAcceptFiles: autoAcceptFiles ?? this.autoAcceptFiles,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());
  
  void toggleWifiDirect(bool enabled) {
    state = state.copyWith(wifiDirectEnabled: enabled);
  }
  
  void toggleBluetooth(bool enabled) {
    state = state.copyWith(bluetoothEnabled: enabled);
  }
  
  void toggleEncryption(bool enabled) {
    state = state.copyWith(encryptionEnabled: enabled);
  }
  
  void setDeviceName(String name) {
    state = state.copyWith(deviceName: name);
  }
  
  void toggleAutoAccept(bool enabled) {
    state = state.copyWith(autoAcceptFiles: enabled);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Connection info state
class ConnectionInfo {
  final bool isConnected;
  final UnifiedDevice? connectedDevice;
  final String? connectionType; // 'wifi_direct' or 'bluetooth'
  final int? signalStrength;
  
  const ConnectionInfo({
    this.isConnected = false,
    this.connectedDevice,
    this.connectionType,
    this.signalStrength,
  });
  
  ConnectionInfo copyWith({
    bool? isConnected,
    UnifiedDevice? connectedDevice,
    String? connectionType,
    int? signalStrength,
  }) {
    return ConnectionInfo(
      isConnected: isConnected ?? this.isConnected,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      connectionType: connectionType ?? this.connectionType,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }
  
  String get signalQuality {
    if (signalStrength == null) return 'Unknown';
    if (signalStrength! >= 80) return 'Excellent';
    if (signalStrength! >= 60) return 'Good';
    if (signalStrength! >= 40) return 'Fair';
    return 'Poor';
  }
}

/// Connection info provider
final connectionInfoProvider = StateProvider<ConnectionInfo>((ref) {
  return const ConnectionInfo();
});
