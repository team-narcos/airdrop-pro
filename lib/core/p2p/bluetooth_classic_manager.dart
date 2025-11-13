import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Bluetooth Classic Manager for P2P connectivity fallback
/// 
/// Features:
/// - Device discovery via Bluetooth
/// - 2-3 Mbps transfer speeds
/// - 10-100 meter range
/// - Universal compatibility
/// - Automatic fallback when WiFi Direct unavailable
class BluetoothClassicManager {
  static const MethodChannel _channel = MethodChannel('com.airdrop.pro/bluetooth');
  
  // Connection state
  bool _isInitialized = false;
  bool _isDiscovering = false;
  bool _isConnected = false;
  String? _connectedDeviceAddress;
  
  // Discovered devices
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();
  
  // Connection status
  final StreamController<BluetoothConnectionStatus> _statusController =
      StreamController<BluetoothConnectionStatus>.broadcast();
  
  // Transfer progress
  final StreamController<BluetoothTransferProgress> _progressController =
      StreamController<BluetoothTransferProgress>.broadcast();
  
  final List<BluetoothDevice> _discoveredDevices = [];

  /// Get stream of discovered devices
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  
  /// Get stream of connection status
  Stream<BluetoothConnectionStatus> get statusStream => _statusController.stream;
  
  /// Get stream of transfer progress
  Stream<BluetoothTransferProgress> get progressStream => _progressController.stream;

  /// Initialize Bluetooth
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      final result = await _channel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      
      if (_isInitialized) {
        _setupNativeCallbacks();
        _statusController.add(BluetoothConnectionStatus.initialized);
        logInfo('Bluetooth Classic initialized successfully');
      }
      
      return _isInitialized;
    } catch (e) {
      logError('Failed to initialize Bluetooth', e);
      return false;
    }
  }

  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      logError('Failed to check Bluetooth availability', e);
      return false;
    }
  }

  /// Request to enable Bluetooth
  Future<bool> requestEnable() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestEnable');
      return result ?? false;
    } catch (e) {
      logError('Failed to enable Bluetooth', e);
      return false;
    }
  }

  /// Start discovering nearby Bluetooth devices
  Future<bool> startDiscovery() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Check if Bluetooth is available
      final isAvailable = await isBluetoothAvailable();
      if (!isAvailable) {
        logError('Bluetooth not available', null);
        return false;
      }
      
      final result = await _channel.invokeMethod<bool>('startDiscovery');
      _isDiscovering = result ?? false;
      
      if (_isDiscovering) {
        _discoveredDevices.clear();
        _statusController.add(BluetoothConnectionStatus.discovering);
        logInfo('Bluetooth discovery started');
      }
      
      return _isDiscovering;
    } catch (e) {
      logError('Failed to start Bluetooth discovery', e);
      return false;
    }
  }

  /// Stop discovering devices
  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
      _isDiscovering = false;
      _statusController.add(BluetoothConnectionStatus.idle);
    } catch (e) {
      logError('Failed to stop Bluetooth discovery', e);
    }
  }

  /// Get list of bonded (paired) devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final result = await _channel.invokeMethod<List>('getBondedDevices');
      
      if (result != null) {
        return result.map((device) => BluetoothDevice.fromMap(device)).toList();
      }
      
      return [];
    } catch (e) {
      logError('Failed to get bonded devices', e);
      return [];
    }
  }

  /// Connect to a discovered device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _statusController.add(BluetoothConnectionStatus.connecting);
      
      final result = await _channel.invokeMethod<bool>('connect', {
        'deviceAddress': device.address,
        'deviceName': device.name,
      });
      
      _isConnected = result ?? false;
      
      if (_isConnected) {
        _connectedDeviceAddress = device.address;
        _statusController.add(BluetoothConnectionStatus.connected);
        logInfo('Connected to ${device.name}');
      } else {
        _statusController.add(BluetoothConnectionStatus.failed);
      }
      
      return _isConnected;
    } catch (e) {
      logError('Failed to connect to device', e);
      _statusController.add(BluetoothConnectionStatus.failed);
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _connectedDeviceAddress = null;
      _statusController.add(BluetoothConnectionStatus.disconnected);
      logInfo('Disconnected from device');
    } catch (e) {
      logError('Failed to disconnect', e);
    }
  }

  /// Send a file via Bluetooth
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
      
      _progressController.add(BluetoothTransferProgress(
        fileName: fileName,
        totalBytes: fileSize,
        transferredBytes: 0,
        percentage: 0,
        status: BluetoothTransferStatus.preparing,
      ));
      
      final result = await _channel.invokeMethod<bool>('sendFile', {
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': fileSize,
        'deviceAddress': _connectedDeviceAddress,
      });
      
      return result ?? false;
    } catch (e) {
      logError('Failed to send file via Bluetooth', e);
      _progressController.add(BluetoothTransferProgress(
        fileName: fileName,
        totalBytes: fileSize,
        transferredBytes: 0,
        percentage: 0,
        status: BluetoothTransferStatus.failed,
      ));
      return false;
    }
  }

  /// Start listening for incoming connections (server mode)
  Future<bool> startListening() async {
    try {
      final result = await _channel.invokeMethod<bool>('startListening');
      
      if (result == true) {
        logInfo('Started listening for Bluetooth connections');
      }
      
      return result ?? false;
    } catch (e) {
      logError('Failed to start Bluetooth listening', e);
      return false;
    }
  }

  /// Stop listening for incoming connections
  Future<void> stopListening() async {
    try {
      await _channel.invokeMethod('stopListening');
    } catch (e) {
      logError('Failed to stop Bluetooth listening', e);
    }
  }

  /// Get connection strength/quality
  Future<int> getConnectionStrength() async {
    try {
      final result = await _channel.invokeMethod<int>('getConnectionStrength');
      return result ?? 0;
    } catch (e) {
      logError('Failed to get connection strength', e);
      return 0;
    }
  }

  /// Setup native callbacks for events
  void _setupNativeCallbacks() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDeviceFound':
          _handleDeviceFound(call.arguments);
          break;
        
        case 'onDeviceLost':
          _handleDeviceLost(call.arguments);
          break;
        
        case 'onConnectionChanged':
          _handleConnectionChanged(call.arguments);
          break;
        
        case 'onTransferProgress':
          _handleTransferProgress(call.arguments);
          break;
        
        case 'onTransferComplete':
          _handleTransferComplete(call.arguments);
          break;
        
        case 'onTransferFailed':
          _handleTransferFailed(call.arguments);
          break;
      }
    });
  }

  void _handleDeviceFound(dynamic arguments) {
    try {
      final device = BluetoothDevice.fromMap(arguments);
      
      // Add to list if not already present
      final existingIndex = _discoveredDevices.indexWhere(
        (d) => d.address == device.address
      );
      
      if (existingIndex >= 0) {
        _discoveredDevices[existingIndex] = device;
      } else {
        _discoveredDevices.add(device);
      }
      
      _devicesController.add(List.from(_discoveredDevices));
      logInfo('Bluetooth device found: ${device.name}');
    } catch (e) {
      logError('Failed to handle device found', e);
    }
  }

  void _handleDeviceLost(dynamic arguments) {
    try {
      final deviceAddress = arguments['deviceAddress'] as String;
      _discoveredDevices.removeWhere((d) => d.address == deviceAddress);
      _devicesController.add(List.from(_discoveredDevices));
      logInfo('Bluetooth device lost: $deviceAddress');
    } catch (e) {
      logError('Failed to handle device lost', e);
    }
  }

  void _handleConnectionChanged(dynamic arguments) {
    try {
      final isConnected = arguments['isConnected'] as bool? ?? false;
      _isConnected = isConnected;
      
      if (isConnected) {
        _connectedDeviceAddress = arguments['deviceAddress'] as String?;
        _statusController.add(BluetoothConnectionStatus.connected);
      } else {
        _statusController.add(BluetoothConnectionStatus.disconnected);
      }
    } catch (e) {
      logError('Failed to handle connection change', e);
    }
  }

  void _handleTransferProgress(dynamic arguments) {
    try {
      final progress = BluetoothTransferProgress(
        fileName: arguments['fileName'] as String,
        totalBytes: arguments['totalBytes'] as int,
        transferredBytes: arguments['transferredBytes'] as int,
        percentage: arguments['percentage'] as double,
        status: BluetoothTransferStatus.transferring,
      );
      
      _progressController.add(progress);
    } catch (e) {
      logError('Failed to handle transfer progress', e);
    }
  }

  void _handleTransferComplete(dynamic arguments) {
    try {
      final fileName = arguments['fileName'] as String;
      final filePath = arguments['filePath'] as String?;
      
      _progressController.add(BluetoothTransferProgress(
        fileName: fileName,
        totalBytes: 0,
        transferredBytes: 0,
        percentage: 100,
        status: BluetoothTransferStatus.completed,
        filePath: filePath,
      ));
      
      logInfo('Bluetooth transfer complete: $fileName');
    } catch (e) {
      logError('Failed to handle transfer complete', e);
    }
  }

  void _handleTransferFailed(dynamic arguments) {
    try {
      final fileName = arguments['fileName'] as String;
      final error = arguments['error'] as String?;
      
      _progressController.add(BluetoothTransferProgress(
        fileName: fileName,
        totalBytes: 0,
        transferredBytes: 0,
        percentage: 0,
        status: BluetoothTransferStatus.failed,
        error: error,
      ));
      
      logError('Bluetooth transfer failed: $fileName', error);
    } catch (e) {
      logError('Failed to handle transfer failed', e);
    }
  }

  /// Dispose resources
  void dispose() {
    _devicesController.close();
    _statusController.close();
    _progressController.close();
  }
}

/// Discovered Bluetooth device
class BluetoothDevice {
  final String address;
  final String name;
  final int deviceClass;
  final int rssi; // Signal strength
  final bool isBonded;

  BluetoothDevice({
    required this.address,
    required this.name,
    this.deviceClass = 0,
    this.rssi = 0,
    this.isBonded = false,
  });

  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDevice(
      address: map['deviceAddress'] as String? ?? '',
      name: map['deviceName'] as String? ?? 'Unknown Device',
      deviceClass: map['deviceClass'] as int? ?? 0,
      rssi: map['rssi'] as int? ?? 0,
      isBonded: map['isBonded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceAddress': address,
      'deviceName': name,
      'deviceClass': deviceClass,
      'rssi': rssi,
      'isBonded': isBonded,
    };
  }

  /// Convert RSSI to strength percentage (0.0 - 1.0)
  double get signalStrength {
    // Bluetooth RSSI typically ranges from -100 to 0 dBm
    if (rssi >= -50) return 1.0;
    if (rssi <= -100) return 0.0;
    return (rssi + 100) / 50.0;
  }

  /// Estimate distance based on RSSI
  String get estimatedDistance {
    final strength = signalStrength;
    if (strength >= 0.8) return '<2m';
    if (strength >= 0.6) return '2-5m';
    if (strength >= 0.4) return '5-15m';
    if (strength >= 0.2) return '15-30m';
    return '>30m';
  }

  /// Get device type from class
  String get deviceType {
    // Bluetooth device class major types
    final majorClass = (deviceClass >> 8) & 0x1F;
    
    switch (majorClass) {
      case 0x01:
        return 'Computer';
      case 0x02:
        return 'Phone';
      case 0x03:
        return 'Network';
      case 0x04:
        return 'Audio/Video';
      case 0x05:
        return 'Peripheral';
      case 0x06:
        return 'Imaging';
      case 0x07:
        return 'Wearable';
      case 0x08:
        return 'Toy';
      default:
        return 'Unknown';
    }
  }
}

/// Bluetooth connection status
enum BluetoothConnectionStatus {
  idle,
  initialized,
  discovering,
  connecting,
  connected,
  disconnected,
  failed,
}

/// Bluetooth transfer status
enum BluetoothTransferStatus {
  preparing,
  transferring,
  completed,
  failed,
  cancelled,
}

/// Bluetooth transfer progress
class BluetoothTransferProgress {
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final double percentage;
  final BluetoothTransferStatus status;
  final String? filePath;
  final String? error;

  BluetoothTransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.percentage,
    required this.status,
    this.filePath,
    this.error,
  });

  /// Format bytes
  String get formattedTransferred => _formatBytes(transferredBytes);
  String get formattedTotal => _formatBytes(totalBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
