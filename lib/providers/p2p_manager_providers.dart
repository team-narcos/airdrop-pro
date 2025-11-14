import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/p2p/p2p.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// P2P Manager singleton provider
final p2pManagerProvider = Provider<P2PManager>((ref) {
  return P2PManager();
});

// Stream providers removed - data accessed through p2pManagerStateProvider instead

/// State provider for P2P manager initialization and running status
final p2pManagerStateProvider = StateNotifierProvider<P2PManagerStateNotifier, P2PManagerState>((ref) {
  final manager = ref.watch(p2pManagerProvider);
  return P2PManagerStateNotifier(manager);
});

/// P2P Manager state model
class P2PManagerState {
  final bool isInitialized;
  final bool isRunning;
  final List<P2PDevice> discoveredDevices;
  final List<DeviceConnection> activeConnections;
  final String? error;
  
  const P2PManagerState({
    this.isInitialized = false,
    this.isRunning = false,
    this.discoveredDevices = const [],
    this.activeConnections = const [],
    this.error,
  });
  
  P2PManagerState copyWith({
    bool? isInitialized,
    bool? isRunning,
    List<P2PDevice>? discoveredDevices,
    List<DeviceConnection>? activeConnections,
    String? error,
  }) {
    return P2PManagerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isRunning: isRunning ?? this.isRunning,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      activeConnections: activeConnections ?? this.activeConnections,
      error: error,
    );
  }
}

/// P2P Manager state notifier
class P2PManagerStateNotifier extends StateNotifier<P2PManagerState> {
  final P2PManager _manager;
  
  P2PManagerStateNotifier(this._manager) : super(const P2PManagerState()) {
    // Streams will be listened to after initialization
  }
  
  /// Initialize the P2P manager
  Future<void> initialize() async {
    if (state.isInitialized) return;
    
    try {
      await _manager.initialize();
      state = state.copyWith(isInitialized: true, error: null);
      
      // Now set up stream listeners after initialization
      _manager.devicesStream.listen((devices) {
        if (mounted) {
          state = state.copyWith(discoveredDevices: devices);
        }
      });
      
      _manager.connectionsStream.listen((connections) {
        if (mounted) {
          state = state.copyWith(activeConnections: connections);
        }
      });
    } catch (e) {
      state = state.copyWith(error: 'Initialization failed: $e');
    }
  }
  
  /// Start discovery and server
  Future<void> start() async {
    if (!state.isInitialized) {
      await initialize();
    }
    
    try {
      await _manager.start();
      state = state.copyWith(isRunning: true, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to start: $e');
    }
  }
  
  /// Stop discovery and server
  Future<void> stop() async {
    try {
      await _manager.stop();
      state = state.copyWith(isRunning: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop: $e');
    }
  }
  
  /// Connect to a device
  Future<bool> connectToDevice(P2PDevice device) async {
    try {
      final success = await _manager.connectToDevice(device);
      if (!success) {
        state = state.copyWith(error: 'Failed to connect to ${device.name}');
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Connection error: $e');
      return false;
    }
  }
  
  /// Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      await _manager.disconnectFromDevice(deviceId);
    } catch (e) {
      state = state.copyWith(error: 'Disconnection error: $e');
    }
  }
  
  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for getting device info
final deviceInfoProvider = Provider<String>((ref) {
  final manager = ref.watch(p2pManagerProvider);
  return manager.deviceName;
});

/// Provider for transfer updates stream
final transferUpdatesProvider = StreamProvider<P2PTransfer>((ref) {
  final manager = ref.watch(p2pManagerProvider);
  return manager.fileCoordinator.transferUpdates;
});

/// Provider for active transfers list
final activeTransfersProvider = Provider<List<P2PTransfer>>((ref) {
  final manager = ref.watch(p2pManagerProvider);
  return manager.fileCoordinator.activeTransfers;
});

/// Function to send files
Future<String?> sendFilesToDevice(
  WidgetRef ref, {
  required List<String> filePaths,
  required P2PDevice device,
}) async {
  try {
    final manager = ref.read(p2pManagerProvider);
    
    // Use P2P Manager's public API
    final transferId = await manager.sendFiles(
      filePaths: filePaths,
      device: device,
    );
    
    return transferId;
  } catch (e) {
    print('[sendFiles] Error: $e');
    return null;
  }
}

/// Get default downloads directory
Future<String> getDownloadsDirectory() async {
  if (Platform.isAndroid) {
    return '/storage/emulated/0/Download';
  } else if (Platform.isIOS) {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      return '$home/Downloads';
    }
  }
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/Downloads';
}
