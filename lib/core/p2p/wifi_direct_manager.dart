import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// WiFi Direct Manager for true P2P connectivity
/// 
/// Features:
/// - Direct device-to-device connection (NO router/WiFi network needed)
/// - Fast transfer speeds: 100-250 Mbps
/// - Range: 200+ meters
/// - Automatic device discovery
/// - Group owner/member management
/// - Socket-based file transfer
class WiFiDirectManager {
  static const MethodChannel _channel = MethodChannel('com.airdrop.pro/wifi_direct');
  
  // Connection state
  bool _isInitialized = false;
  bool _isDiscovering = false;
  bool _isConnected = false;
  String? _groupOwnerAddress;
  int _serverPort = 8988;
  
  // Discovered devices
  final StreamController<List<WiFiDirectDevice>> _devicesController =
      StreamController<List<WiFiDirectDevice>>.broadcast();
  
  // Connection status
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  
  // File transfer progress
  final StreamController<TransferProgress> _progressController =
      StreamController<TransferProgress>.broadcast();

  /// Get stream of discovered devices
  Stream<List<WiFiDirectDevice>> get devicesStream => _devicesController.stream;
  
  /// Get stream of connection status
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  
  /// Get stream of transfer progress
  Stream<TransferProgress> get progressStream => _progressController.stream;

  /// Initialize WiFi Direct
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      final result = await _channel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      
      if (_isInitialized) {
        _setupNativeCallbacks();
        _statusController.add(ConnectionStatus.initialized);
        logInfo('WiFi Direct initialized successfully');
      }
      
      return _isInitialized;
    } catch (e) {
      logError('Failed to initialize WiFi Direct', e);
      return false;
    }
  }

  /// Start discovering nearby WiFi Direct devices
  Future<bool> startDiscovery() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final result = await _channel.invokeMethod<bool>('startDiscovery');
      _isDiscovering = result ?? false;
      
      if (_isDiscovering) {
        _statusController.add(ConnectionStatus.discovering);
        logInfo('WiFi Direct discovery started');
      }
      
      return _isDiscovering;
    } catch (e) {
      logError('Failed to start discovery', e);
      return false;
    }
  }

  /// Stop discovering devices
  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
      _isDiscovering = false;
      _statusController.add(ConnectionStatus.idle);
    } catch (e) {
      logError('Failed to stop discovery', e);
    }
  }

  /// Connect to a discovered device
  Future<bool> connectToDevice(WiFiDirectDevice device) async {
    try {
      _statusController.add(ConnectionStatus.connecting);
      
      final result = await _channel.invokeMethod<bool>('connect', {
        'deviceAddress': device.address,
        'deviceName': device.name,
      });
      
      _isConnected = result ?? false;
      
      if (_isConnected) {
        _statusController.add(ConnectionStatus.connected);
        logInfo('Connected to ${device.name}');
      } else {
        _statusController.add(ConnectionStatus.failed);
      }
      
      return _isConnected;
    } catch (e) {
      logError('Failed to connect to device', e);
      _statusController.add(ConnectionStatus.failed);
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _groupOwnerAddress = null;
      _statusController.add(ConnectionStatus.disconnected);
      logInfo('Disconnected from device');
    } catch (e) {
      logError('Failed to disconnect', e);
    }
  }

  /// Create a WiFi Direct group (become group owner / hotspot)
  Future<bool> createGroup() async {
    try {
      final result = await _channel.invokeMethod<bool>('createGroup');
      
      if (result == true) {
        _statusController.add(ConnectionStatus.groupCreated);
        logInfo('WiFi Direct group created (Group Owner)');
        return true;
      }
      
      return false;
    } catch (e) {
      logError('Failed to create group', e);
      return false;
    }
  }

  /// Remove WiFi Direct group
  Future<void> removeGroup() async {
    try {
      await _channel.invokeMethod('removeGroup');
      _statusController.add(ConnectionStatus.idle);
    } catch (e) {
      logError('Failed to remove group', e);
    }
  }

  /// Send a file via WiFi Direct
  Future<bool> sendFile({
    required String filePath,
    required String fileName,
    required int fileSize,
    String? targetAddress,
  }) async {
    try {
      if (!_isConnected && _groupOwnerAddress == null) {
        logError('Not connected to any device', null);
        return false;
      }
      
      _progressController.add(TransferProgress(
        fileName: fileName,
        totalBytes: fileSize,
        transferredBytes: 0,
        percentage: 0,
        status: TransferStatus.preparing,
      ));
      
      final result = await _channel.invokeMethod<bool>('sendFile', {
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': fileSize,
        'targetAddress': targetAddress ?? _groupOwnerAddress,
        'port': _serverPort,
      });
      
      return result ?? false;
    } catch (e) {
      logError('Failed to send file', e);
      _progressController.add(TransferProgress(
        fileName: fileName,
        totalBytes: fileSize,
        transferredBytes: 0,
        percentage: 0,
        status: TransferStatus.failed,
      ));
      return false;
    }
  }

  /// Start receiving files (as server)
  Future<bool> startReceiving() async {
    try {
      final result = await _channel.invokeMethod<bool>('startServer', {
        'port': _serverPort,
      });
      
      if (result == true) {
        logInfo('Started receiving on port $_serverPort');
      }
      
      return result ?? false;
    } catch (e) {
      logError('Failed to start receiving', e);
      return false;
    }
  }

  /// Stop receiving files
  Future<void> stopReceiving() async {
    try {
      await _channel.invokeMethod('stopServer');
    } catch (e) {
      logError('Failed to stop receiving', e);
    }
  }

  /// Get connection info (IP address, group owner status, etc.)
  Future<WiFiDirectConnectionInfo?> getConnectionInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getConnectionInfo');
      
      if (result != null) {
        return WiFiDirectConnectionInfo(
          groupOwnerAddress: result['groupOwnerAddress'] as String?,
          isGroupOwner: result['isGroupOwner'] as bool? ?? false,
          groupFormed: result['groupFormed'] as bool? ?? false,
        );
      }
      
      return null;
    } catch (e) {
      logError('Failed to get connection info', e);
      return null;
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
      final device = WiFiDirectDevice.fromMap(arguments);
      logInfo('Device found: ${device.name}');
      // TODO: Update devices list and emit
    } catch (e) {
      logError('Failed to handle device found', e);
    }
  }

  void _handleDeviceLost(dynamic arguments) {
    try {
      final deviceAddress = arguments['deviceAddress'] as String;
      logInfo('Device lost: $deviceAddress');
      // TODO: Update devices list and emit
    } catch (e) {
      logError('Failed to handle device lost', e);
    }
  }

  void _handleConnectionChanged(dynamic arguments) {
    try {
      final isConnected = arguments['isConnected'] as bool? ?? false;
      _isConnected = isConnected;
      
      if (isConnected) {
        _groupOwnerAddress = arguments['groupOwnerAddress'] as String?;
        _statusController.add(ConnectionStatus.connected);
      } else {
        _statusController.add(ConnectionStatus.disconnected);
      }
    } catch (e) {
      logError('Failed to handle connection change', e);
    }
  }

  void _handleTransferProgress(dynamic arguments) {
    try {
      final progress = TransferProgress(
        fileName: arguments['fileName'] as String,
        totalBytes: arguments['totalBytes'] as int,
        transferredBytes: arguments['transferredBytes'] as int,
        percentage: arguments['percentage'] as double,
        status: TransferStatus.transferring,
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
      
      _progressController.add(TransferProgress(
        fileName: fileName,
        totalBytes: 0,
        transferredBytes: 0,
        percentage: 100,
        status: TransferStatus.completed,
        filePath: filePath,
      ));
      
      logInfo('Transfer complete: $fileName');
    } catch (e) {
      logError('Failed to handle transfer complete', e);
    }
  }

  void _handleTransferFailed(dynamic arguments) {
    try {
      final fileName = arguments['fileName'] as String;
      final error = arguments['error'] as String?;
      
      _progressController.add(TransferProgress(
        fileName: fileName,
        totalBytes: 0,
        transferredBytes: 0,
        percentage: 0,
        status: TransferStatus.failed,
        error: error,
      ));
      
      logError('Transfer failed: $fileName', error);
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

/// Discovered WiFi Direct device
class WiFiDirectDevice {
  final String address;
  final String name;
  final String deviceType;
  final int signalLevel;
  final bool isGroupOwner;

  WiFiDirectDevice({
    required this.address,
    required this.name,
    this.deviceType = 'Unknown',
    this.signalLevel = 0,
    this.isGroupOwner = false,
  });

  factory WiFiDirectDevice.fromMap(Map<dynamic, dynamic> map) {
    return WiFiDirectDevice(
      address: map['deviceAddress'] as String? ?? '',
      name: map['deviceName'] as String? ?? 'Unknown Device',
      deviceType: map['deviceType'] as String? ?? 'Unknown',
      signalLevel: map['signalLevel'] as int? ?? 0,
      isGroupOwner: map['isGroupOwner'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceAddress': address,
      'deviceName': name,
      'deviceType': deviceType,
      'signalLevel': signalLevel,
      'isGroupOwner': isGroupOwner,
    };
  }

  /// Convert signal level to strength percentage (0.0 - 1.0)
  double get signalStrength {
    // WiFi signal levels typically range from -100 to 0 dBm
    // Normalize to 0.0 - 1.0
    if (signalLevel >= -50) return 1.0;
    if (signalLevel <= -100) return 0.0;
    return (signalLevel + 100) / 50.0;
  }

  /// Estimate distance based on signal strength (rough approximation)
  String get estimatedDistance {
    final strength = signalStrength;
    if (strength >= 0.8) return '<2m';
    if (strength >= 0.6) return '2-5m';
    if (strength >= 0.4) return '5-10m';
    if (strength >= 0.2) return '10-20m';
    return '>20m';
  }
}

/// WiFi Direct connection information
class WiFiDirectConnectionInfo {
  final String? groupOwnerAddress;
  final bool isGroupOwner;
  final bool groupFormed;

  WiFiDirectConnectionInfo({
    this.groupOwnerAddress,
    required this.isGroupOwner,
    required this.groupFormed,
  });
}

/// Connection status
enum ConnectionStatus {
  idle,
  initialized,
  discovering,
  connecting,
  connected,
  groupCreated,
  disconnected,
  failed,
}

/// Transfer status
enum TransferStatus {
  preparing,
  transferring,
  completed,
  failed,
  cancelled,
}

/// Transfer progress information
class TransferProgress {
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final double percentage;
  final TransferStatus status;
  final String? filePath;
  final String? error;

  TransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.percentage,
    required this.status,
    this.filePath,
    this.error,
  });

  /// Format transferred bytes (e.g., "1.5 MB")
  String get formattedTransferred => _formatBytes(transferredBytes);
  
  /// Format total bytes (e.g., "10 MB")
  String get formattedTotal => _formatBytes(totalBytes);
  
  /// Calculate transfer speed (bytes per second)
  double get speed {
    // TODO: Implement speed calculation based on time
    return 0.0;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
