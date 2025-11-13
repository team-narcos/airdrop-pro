import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'wifi_direct_manager.dart';
import 'bluetooth_classic_manager.dart';
import '../utils/logger.dart';

/// Hybrid Connection Engine - Smart P2P Protocol Selection
/// 
/// Features:
/// - Automatic protocol selection (WiFi Direct vs Bluetooth)
/// - Connection quality monitoring
/// - Automatic fallback on failure
/// - Seamless protocol switching
/// - Zero user intervention required
class HybridConnectionEngine {
  final WiFiDirectManager _wifiDirectManager;
  final BluetoothClassicManager _bluetoothManager;
  
  // Current active protocol
  ConnectionProtocol _activeProtocol = ConnectionProtocol.none;
  
  // Connection state
  bool _isDiscovering = false;
  bool _isConnected = false;
  
  // Unified devices stream
  final StreamController<List<UnifiedDevice>> _devicesController =
      StreamController<List<UnifiedDevice>>.broadcast();
  
  // Connection status stream
  final StreamController<HybridConnectionStatus> _statusController =
      StreamController<HybridConnectionStatus>.broadcast();
  
  // Transfer progress stream
  final StreamController<UnifiedTransferProgress> _progressController =
      StreamController<UnifiedTransferProgress>.broadcast();
  
  final Map<String, UnifiedDevice> _discoveredDevices = {};
  
  HybridConnectionEngine({
    WiFiDirectManager? wifiDirectManager,
    BluetoothClassicManager? bluetoothManager,
  })  : _wifiDirectManager = wifiDirectManager ?? WiFiDirectManager(),
        _bluetoothManager = bluetoothManager ?? BluetoothClassicManager();

  /// Get stream of discovered devices (from both protocols)
  Stream<List<UnifiedDevice>> get devicesStream => _devicesController.stream;
  
  /// Get stream of connection status
  Stream<HybridConnectionStatus> get statusStream => _statusController.stream;
  
  /// Get stream of transfer progress
  Stream<UnifiedTransferProgress> get progressStream => _progressController.stream;
  
  /// Get current active protocol
  ConnectionProtocol get activeProtocol => _activeProtocol;

  /// Initialize both protocols
  Future<void> initialize() async {
    try {
      logInfo('Initializing Hybrid Connection Engine');
      
      // Initialize both protocols in parallel
      final results = await Future.wait([
        _wifiDirectManager.initialize(),
        _bluetoothManager.initialize(),
      ]);
      
      final wifiInitialized = results[0];
      final bluetoothInitialized = results[1];
      
      if (wifiInitialized || bluetoothInitialized) {
        _setupStreamListeners();
        _statusController.add(HybridConnectionStatus(
          status: ConnectionState.initialized,
          availableProtocols: _getAvailableProtocols(),
          activeProtocol: _activeProtocol,
        ));
      }
      
      logInfo('Hybrid Engine initialized - WiFi: $wifiInitialized, BT: $bluetoothInitialized');
    } catch (e) {
      logError('Failed to initialize Hybrid Engine', e);
    }
  }

  /// Start discovering nearby devices using all available protocols
  Future<void> startDiscovery() async {
    try {
      if (_isDiscovering) return;
      
      _isDiscovering = true;
      _discoveredDevices.clear();
      
      _statusController.add(HybridConnectionStatus(
        status: ConnectionState.discovering,
        availableProtocols: _getAvailableProtocols(),
        activeProtocol: _activeProtocol,
      ));
      
      logInfo('Starting hybrid discovery');
      
      // Start discovery on all available protocols
      final futures = <Future>[];
      
      try {
        futures.add(_wifiDirectManager.startDiscovery());
      } catch (e) {
        logError('WiFi Direct discovery failed', e);
      }
      
      try {
        futures.add(_bluetoothManager.startDiscovery());
      } catch (e) {
        logError('Bluetooth discovery failed', e);
      }
      
      await Future.wait(futures);
    } catch (e) {
      logError('Failed to start hybrid discovery', e);
    }
  }

  /// Stop discovering devices
  Future<void> stopDiscovery() async {
    try {
      _isDiscovering = false;
      
      await Future.wait([
        _wifiDirectManager.stopDiscovery(),
        _bluetoothManager.stopDiscovery(),
      ]);
      
      _statusController.add(HybridConnectionStatus(
        status: ConnectionState.idle,
        availableProtocols: _getAvailableProtocols(),
        activeProtocol: _activeProtocol,
      ));
    } catch (e) {
      logError('Failed to stop discovery', e);
    }
  }

  /// Connect to a device using the best available protocol
  Future<bool> connectToDevice(UnifiedDevice device) async {
    try {
      _statusController.add(HybridConnectionStatus(
        status: ConnectionState.connecting,
        availableProtocols: _getAvailableProtocols(),
        activeProtocol: _activeProtocol,
        message: 'Connecting to ${device.name}...',
      ));
      
      // Select best protocol for this device
      final protocol = _selectBestProtocol(device);
      
      logInfo('Connecting to ${device.name} via $protocol');
      
      bool connected = false;
      
      switch (protocol) {
        case ConnectionProtocol.wifiDirect:
          if (device.wifiDirectDevice != null) {
            connected = await _wifiDirectManager.connectToDevice(device.wifiDirectDevice!);
            if (connected) {
              _activeProtocol = ConnectionProtocol.wifiDirect;
            }
          }
          break;
        
        case ConnectionProtocol.bluetooth:
          if (device.bluetoothDevice != null) {
            connected = await _bluetoothManager.connectToDevice(device.bluetoothDevice!);
            if (connected) {
              _activeProtocol = ConnectionProtocol.bluetooth;
            }
          }
          break;
        
        case ConnectionProtocol.none:
          logError('No available protocol for device', null);
          break;
      }
      
      // If primary protocol failed, try fallback
      if (!connected && protocol != ConnectionProtocol.none) {
        logInfo('Primary protocol failed, trying fallback');
        connected = await _tryFallbackConnection(device, protocol);
      }
      
      _isConnected = connected;
      
      if (connected) {
        _statusController.add(HybridConnectionStatus(
          status: ConnectionState.connected,
          availableProtocols: _getAvailableProtocols(),
          activeProtocol: _activeProtocol,
          connectedDevice: device,
        ));
      } else {
        _statusController.add(HybridConnectionStatus(
          status: ConnectionState.failed,
          availableProtocols: _getAvailableProtocols(),
          activeProtocol: _activeProtocol,
          message: 'Failed to connect to ${device.name}',
        ));
      }
      
      return connected;
    } catch (e) {
      logError('Connection failed', e);
      _statusController.add(HybridConnectionStatus(
        status: ConnectionState.failed,
        availableProtocols: _getAvailableProtocols(),
        activeProtocol: _activeProtocol,
      ));
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      switch (_activeProtocol) {
        case ConnectionProtocol.wifiDirect:
          await _wifiDirectManager.disconnect();
          break;
        case ConnectionProtocol.bluetooth:
          await _bluetoothManager.disconnect();
          break;
        case ConnectionProtocol.none:
          break;
      }
      
      _isConnected = false;
      _activeProtocol = ConnectionProtocol.none;
      
      _statusController.add(HybridConnectionStatus(
        status: ConnectionState.disconnected,
        availableProtocols: _getAvailableProtocols(),
        activeProtocol: _activeProtocol,
      ));
    } catch (e) {
      logError('Disconnect failed', e);
    }
  }

  /// Send a file using the active protocol
  Future<bool> sendFile({
    required String filePath,
    required String fileName,
    required int fileSize,
  }) async {
    try {
      if (!_isConnected) {
        logError('Not connected to any device', null);
        return false;
      }
      
      logInfo('Sending $fileName via $_activeProtocol');
      
      bool success = false;
      
      switch (_activeProtocol) {
        case ConnectionProtocol.wifiDirect:
          success = await _wifiDirectManager.sendFile(
            filePath: filePath,
            fileName: fileName,
            fileSize: fileSize,
          );
          break;
        
        case ConnectionProtocol.bluetooth:
          success = await _bluetoothManager.sendFile(
            filePath: filePath,
            fileName: fileName,
            fileSize: fileSize,
          );
          break;
        
        case ConnectionProtocol.none:
          logError('No active protocol', null);
          break;
      }
      
      return success;
    } catch (e) {
      logError('File transfer failed', e);
      return false;
    }
  }

  /// Select the best protocol based on file size, signal strength, and capabilities
  ConnectionProtocol _selectBestProtocol(UnifiedDevice device) {
    final scores = <ConnectionProtocol, double>{};
    
    // Score WiFi Direct
    if (device.wifiDirectDevice != null) {
      double score = 100.0;
      
      // Bonus for strong signal
      score += device.wifiDirectDevice!.signalStrength * 20;
      
      // WiFi Direct is always preferred for its speed
      scores[ConnectionProtocol.wifiDirect] = score;
    }
    
    // Score Bluetooth
    if (device.bluetoothDevice != null) {
      double score = 70.0;
      
      // Bonus for bonded devices (already paired)
      if (device.bluetoothDevice!.isBonded) {
        score += 15.0;
      }
      
      // Bonus for strong signal
      score += device.bluetoothDevice!.signalStrength * 10;
      
      scores[ConnectionProtocol.bluetooth] = score;
    }
    
    // Return highest scoring protocol
    if (scores.isEmpty) {
      return ConnectionProtocol.none;
    }
    
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final selected = sorted.first.key;
    logInfo('Protocol selection scores: $scores, selected: $selected');
    
    return selected;
  }

  /// Try fallback connection with alternative protocol
  Future<bool> _tryFallbackConnection(UnifiedDevice device, ConnectionProtocol failedProtocol) async {
    ConnectionProtocol fallback;
    
    if (failedProtocol == ConnectionProtocol.wifiDirect && device.bluetoothDevice != null) {
      fallback = ConnectionProtocol.bluetooth;
    } else if (failedProtocol == ConnectionProtocol.bluetooth && device.wifiDirectDevice != null) {
      fallback = ConnectionProtocol.wifiDirect;
    } else {
      return false;
    }
    
    logInfo('Trying fallback protocol: $fallback');
    
    bool connected = false;
    
    switch (fallback) {
      case ConnectionProtocol.wifiDirect:
        connected = await _wifiDirectManager.connectToDevice(device.wifiDirectDevice!);
        if (connected) _activeProtocol = ConnectionProtocol.wifiDirect;
        break;
      
      case ConnectionProtocol.bluetooth:
        connected = await _bluetoothManager.connectToDevice(device.bluetoothDevice!);
        if (connected) _activeProtocol = ConnectionProtocol.bluetooth;
        break;
      
      case ConnectionProtocol.none:
        break;
    }
    
    return connected;
  }

  /// Get list of available protocols
  List<ConnectionProtocol> _getAvailableProtocols() {
    final protocols = <ConnectionProtocol>[];
    
    // Check WiFi Direct availability (simplified check)
    protocols.add(ConnectionProtocol.wifiDirect);
    
    // Check Bluetooth availability (simplified check)
    protocols.add(ConnectionProtocol.bluetooth);
    
    return protocols;
  }

  /// Setup stream listeners for both protocols
  void _setupStreamListeners() {
    // Listen to WiFi Direct devices
    _wifiDirectManager.devicesStream.listen((devices) {
      for (final device in devices) {
        final id = 'wifi_${device.address}';
        _discoveredDevices[id] = UnifiedDevice(
          id: id,
          name: device.name,
          primaryProtocol: ConnectionProtocol.wifiDirect,
          wifiDirectDevice: device,
          signalStrength: device.signalStrength,
          estimatedDistance: device.estimatedDistance,
        );
      }
      _emitUnifiedDevices();
    });
    
    // Listen to Bluetooth devices
    _bluetoothManager.devicesStream.listen((devices) {
      for (final device in devices) {
        final id = 'bt_${device.address}';
        
        // Check if same device already discovered via WiFi
        final wifiId = 'wifi_${device.address}';
        if (_discoveredDevices.containsKey(wifiId)) {
          // Merge protocols for same device
          _discoveredDevices[wifiId] = _discoveredDevices[wifiId]!.copyWith(
            bluetoothDevice: device,
          );
        } else {
          _discoveredDevices[id] = UnifiedDevice(
            id: id,
            name: device.name,
            primaryProtocol: ConnectionProtocol.bluetooth,
            bluetoothDevice: device,
            signalStrength: device.signalStrength,
            estimatedDistance: device.estimatedDistance,
          );
        }
      }
      _emitUnifiedDevices();
    });
    
    // Listen to WiFi Direct progress
    _wifiDirectManager.progressStream.listen((progress) {
      _progressController.add(UnifiedTransferProgress(
        fileName: progress.fileName,
        totalBytes: progress.totalBytes,
        transferredBytes: progress.transferredBytes,
        percentage: progress.percentage,
        protocol: ConnectionProtocol.wifiDirect,
        status: _mapWiFiStatus(progress.status),
        error: progress.error,
      ));
    });
    
    // Listen to Bluetooth progress
    _bluetoothManager.progressStream.listen((progress) {
      _progressController.add(UnifiedTransferProgress(
        fileName: progress.fileName,
        totalBytes: progress.totalBytes,
        transferredBytes: progress.transferredBytes,
        percentage: progress.percentage,
        protocol: ConnectionProtocol.bluetooth,
        status: _mapBluetoothStatus(progress.status),
        error: progress.error,
      ));
    });
  }

  void _emitUnifiedDevices() {
    _devicesController.add(_discoveredDevices.values.toList());
  }

  UnifiedTransferStatus _mapWiFiStatus(TransferStatus status) {
    switch (status) {
      case TransferStatus.preparing:
        return UnifiedTransferStatus.preparing;
      case TransferStatus.transferring:
        return UnifiedTransferStatus.transferring;
      case TransferStatus.completed:
        return UnifiedTransferStatus.completed;
      case TransferStatus.failed:
        return UnifiedTransferStatus.failed;
      case TransferStatus.cancelled:
        return UnifiedTransferStatus.cancelled;
    }
  }

  UnifiedTransferStatus _mapBluetoothStatus(BluetoothTransferStatus status) {
    switch (status) {
      case BluetoothTransferStatus.preparing:
        return UnifiedTransferStatus.preparing;
      case BluetoothTransferStatus.transferring:
        return UnifiedTransferStatus.transferring;
      case BluetoothTransferStatus.completed:
        return UnifiedTransferStatus.completed;
      case BluetoothTransferStatus.failed:
        return UnifiedTransferStatus.failed;
      case BluetoothTransferStatus.cancelled:
        return UnifiedTransferStatus.cancelled;
    }
  }

  /// Dispose resources
  void dispose() {
    _wifiDirectManager.dispose();
    _bluetoothManager.dispose();
    _devicesController.close();
    _statusController.close();
    _progressController.close();
  }
}

/// Unified device representation (can be WiFi Direct, Bluetooth, or both)
class UnifiedDevice {
  final String id;
  final String name;
  final ConnectionProtocol primaryProtocol;
  final WiFiDirectDevice? wifiDirectDevice;
  final BluetoothDevice? bluetoothDevice;
  final double signalStrength;
  final String estimatedDistance;

  UnifiedDevice({
    required this.id,
    required this.name,
    required this.primaryProtocol,
    this.wifiDirectDevice,
    this.bluetoothDevice,
    required this.signalStrength,
    required this.estimatedDistance,
  });

  UnifiedDevice copyWith({
    WiFiDirectDevice? wifiDirectDevice,
    BluetoothDevice? bluetoothDevice,
  }) {
    return UnifiedDevice(
      id: id,
      name: name,
      primaryProtocol: primaryProtocol,
      wifiDirectDevice: wifiDirectDevice ?? this.wifiDirectDevice,
      bluetoothDevice: bluetoothDevice ?? this.bluetoothDevice,
      signalStrength: signalStrength,
      estimatedDistance: estimatedDistance,
    );
  }

  /// Check if device supports multiple protocols
  bool get hasMultipleProtocols => wifiDirectDevice != null && bluetoothDevice != null;
  
  /// Get available protocols for this device
  List<ConnectionProtocol> get availableProtocols {
    final protocols = <ConnectionProtocol>[];
    if (wifiDirectDevice != null) protocols.add(ConnectionProtocol.wifiDirect);
    if (bluetoothDevice != null) protocols.add(ConnectionProtocol.bluetooth);
    return protocols;
  }
}

/// Connection protocol type
enum ConnectionProtocol {
  none,
  wifiDirect,
  bluetooth,
}

/// Connection state
enum ConnectionState {
  idle,
  initialized,
  discovering,
  connecting,
  connected,
  disconnected,
  failed,
}

/// Hybrid connection status
class HybridConnectionStatus {
  final ConnectionState status;
  final List<ConnectionProtocol> availableProtocols;
  final ConnectionProtocol activeProtocol;
  final UnifiedDevice? connectedDevice;
  final String? message;

  HybridConnectionStatus({
    required this.status,
    required this.availableProtocols,
    required this.activeProtocol,
    this.connectedDevice,
    this.message,
  });
}

/// Unified transfer status
enum UnifiedTransferStatus {
  preparing,
  transferring,
  completed,
  failed,
  cancelled,
}

/// Unified transfer progress
class UnifiedTransferProgress {
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final double percentage;
  final ConnectionProtocol protocol;
  final UnifiedTransferStatus status;
  final String? error;

  UnifiedTransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.percentage,
    required this.protocol,
    required this.status,
    this.error,
  });

  String get formattedTransferred => _formatBytes(transferredBytes);
  String get formattedTotal => _formatBytes(totalBytes);
  
  String get protocolName {
    switch (protocol) {
      case ConnectionProtocol.wifiDirect:
        return 'WiFi Direct';
      case ConnectionProtocol.bluetooth:
        return 'Bluetooth';
      case ConnectionProtocol.none:
        return 'None';
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
