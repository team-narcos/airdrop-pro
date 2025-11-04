import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';

/// Proximity-based device discovery
/// Supports: Touch-to-touch (NFC), Near (BLE <5m), Mid (WiFi <50m), Far (Internet)
class ProximityDiscoveryEngine {
  // Distance ranges
  static const double DISTANCE_TOUCH = 0.1; // Touch distance (NFC range)
  static const double DISTANCE_NEAR = 5.0; // Near range (BLE)
  static const double DISTANCE_MID = 50.0; // Mid range (WiFi)
  static const double DISTANCE_FAR = double.infinity; // Far range (Internet)
  
  // Discovery methods
  static const String METHOD_NFC = 'nfc';
  static const String METHOD_BLE = 'ble';
  static const String METHOD_WIFI = 'wifi';
  static const String METHOD_MDNS = 'mdns';
  static const String METHOD_INTERNET = 'internet';
  
  final _deviceStreamController = StreamController<List<ProximityDevice>>.broadcast();
  Stream<List<ProximityDevice>> get deviceStream => _deviceStreamController.stream;
  
  final _proximityController = StreamController<ProximityEvent>.broadcast();
  Stream<ProximityEvent> get proximityEventStream => _proximityController.stream;
  
  bool _isScanning = false;
  List<ProximityDevice> _discoveredDevices = [];
  Timer? _updateTimer;
  Timer? _rssiUpdateTimer;
  
  // Platform channels for native features
  static const platform = MethodChannel('com.airdrop.proximity');
  
  /// Start proximity-based discovery
  Future<void> startDiscovery({
    bool enableNFC = true,
    bool enableBLE = true,
    bool enableWiFi = true,
    bool enableInternet = false,
  }) async {
    if (_isScanning) return;
    
    _isScanning = true;
    _discoveredDevices.clear();
    
    print('[ProximityDiscovery] Starting discovery...');
    print('[ProximityDiscovery] NFC: $enableNFC, BLE: $enableBLE, WiFi: $enableWiFi, Internet: $enableInternet');
    
    try {
      // Start NFC listening (touch-to-touch)
      if (enableNFC) {
        await _startNFCDiscovery();
      }
      
      // Start BLE scanning (near range)
      if (enableBLE) {
        await _startBLEDiscovery();
      }
      
      // Start WiFi/mDNS discovery (mid range)
      if (enableWiFi) {
        await _startWiFiDiscovery();
      }
      
      // Start internet-based discovery (far range)
      if (enableInternet) {
        await _startInternetDiscovery();
      }
      
      // Start periodic updates
      _startPeriodicUpdates();
      
    } catch (e) {
      print('[ProximityDiscovery] Error starting discovery: $e');
    }
  }
  
  /// Stop all discovery methods
  Future<void> stopDiscovery() async {
    _isScanning = false;
    _updateTimer?.cancel();
    _rssiUpdateTimer?.cancel();
    
    try {
      await _stopNFCDiscovery();
      await _stopBLEDiscovery();
      await _stopWiFiDiscovery();
      await _stopInternetDiscovery();
    } catch (e) {
      print('[ProximityDiscovery] Error stopping discovery: $e');
    }
    
    print('[ProximityDiscovery] Discovery stopped');
  }
  
  /// Start NFC discovery for touch-to-touch pairing
  Future<void> _startNFCDiscovery() async {
    print('[ProximityDiscovery] Starting NFC discovery...');
    
    try {
      // Check if NFC is available
      final nfcAvailable = await platform.invokeMethod('isNFCAvailable');
      
      if (!nfcAvailable) {
        print('[ProximityDiscovery] NFC not available on this device');
        return;
      }
      
      // Start NFC reader session
      await platform.invokeMethod('startNFCSession');
      
      // Listen for NFC tag detections
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onNFCDeviceDetected') {
          final deviceData = call.arguments as Map;
          _handleNFCDevice(deviceData);
        }
      });
      
      print('[ProximityDiscovery] NFC discovery started');
    } catch (e) {
      print('[ProximityDiscovery] NFC error: $e');
    }
  }
  
  /// Start BLE discovery for nearby devices
  Future<void> _startBLEDiscovery() async {
    print('[ProximityDiscovery] Starting BLE discovery...');
    
    try {
      // Check BLE availability
      final bleAvailable = await platform.invokeMethod('isBLEAvailable');
      
      if (!bleAvailable) {
        print('[ProximityDiscovery] BLE not available');
        return;
      }
      
      // Start BLE scanning
      await platform.invokeMethod('startBLEScanning', {
        'serviceUUID': 'airdrop-service-uuid',
        'scanDuration': 30000, // 30 seconds
      });
      
      // Listen for BLE discoveries
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onBLEDeviceFound') {
          final deviceData = call.arguments as Map;
          _handleBLEDevice(deviceData);
        } else if (call.method == 'onBLERSSIUpdate') {
          final rssiData = call.arguments as Map;
          _updateDeviceRSSI(rssiData);
        }
      });
      
      print('[ProximityDiscovery] BLE discovery started');
    } catch (e) {
      print('[ProximityDiscovery] BLE error: $e');
      // Fallback to mock discovery for development
      _startMockBLEDiscovery();
    }
  }
  
  /// Start WiFi/mDNS discovery for local network
  Future<void> _startWiFiDiscovery() async {
    print('[ProximityDiscovery] Starting WiFi/mDNS discovery...');
    
    try {
      // Start mDNS broadcasting
      await platform.invokeMethod('startMDNSBroadcast', {
        'serviceName': '_airdrop._tcp',
        'port': 37777,
      });
      
      // Start mDNS discovery
      await platform.invokeMethod('startMDNSDiscovery', {
        'serviceType': '_airdrop._tcp',
      });
      
      // Listen for mDNS discoveries
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onMDNSDeviceFound') {
          final deviceData = call.arguments as Map;
          _handleWiFiDevice(deviceData);
        }
      });
      
      print('[ProximityDiscovery] WiFi/mDNS discovery started');
    } catch (e) {
      print('[ProximityDiscovery] WiFi/mDNS error: $e');
      // Fallback to mock discovery
      _startMockWiFiDiscovery();
    }
  }
  
  /// Start internet-based discovery using relay server
  Future<void> _startInternetDiscovery() async {
    print('[ProximityDiscovery] Starting internet discovery...');
    
    // This would connect to a relay/signaling server
    // For now, we'll implement a basic approach
    
    try {
      // Connect to relay server
      final socket = await Socket.connect(
        'relay.airdrop.example.com', // Your relay server
        8080,
        timeout: Duration(seconds: 10),
      );
      
      // Register this device
      socket.write('REGISTER:${_getDeviceId()}');
      
      // Listen for other devices
      socket.listen((data) {
        // Parse device data
        final deviceInfo = String.fromCharCodes(data);
        if (deviceInfo.startsWith('DEVICE:')) {
          _handleInternetDevice(deviceInfo);
        }
      });
      
    } catch (e) {
      print('[ProximityDiscovery] Internet discovery error: $e');
    }
  }
  
  /// Handle NFC device detection (touch-to-touch)
  void _handleNFCDevice(Map deviceData) {
    print('[ProximityDiscovery] NFC device detected!');
    
    final device = ProximityDevice(
      id: deviceData['id'] as String,
      name: deviceData['name'] as String,
      distance: DISTANCE_TOUCH,
      rssi: -10, // Very strong signal
      discoveryMethod: METHOD_NFC,
      ipAddress: deviceData['ipAddress'] as String?,
      port: deviceData['port'] as int?,
      lastSeen: DateTime.now(),
    );
    
    _addOrUpdateDevice(device);
    
    // Trigger proximity event
    _proximityController.add(ProximityEvent(
      device: device,
      eventType: ProximityEventType.touchDetected,
      timestamp: DateTime.now(),
    ));
    
    // Vibrate for touch feedback
    HapticFeedback.mediumImpact();
  }
  
  /// Handle BLE device discovery
  void _handleBLEDevice(Map deviceData) {
    final rssi = deviceData['rssi'] as int;
    final distance = _calculateDistanceFromRSSI(rssi.toDouble());
    
    print('[ProximityDiscovery] BLE device found: ${deviceData['name']} at ${distance.toStringAsFixed(1)}m');
    
    final device = ProximityDevice(
      id: deviceData['id'] as String,
      name: deviceData['name'] as String,
      distance: distance,
      rssi: rssi.toDouble(),
      discoveryMethod: METHOD_BLE,
      ipAddress: null,
      port: null,
      lastSeen: DateTime.now(),
    );
    
    _addOrUpdateDevice(device);
    
    // Check for proximity changes
    if (distance < 1.0) {
      _proximityController.add(ProximityEvent(
        device: device,
        eventType: ProximityEventType.veryNear,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  /// Handle WiFi/mDNS device discovery
  void _handleWiFiDevice(Map deviceData) {
    print('[ProximityDiscovery] WiFi device found: ${deviceData['name']}');
    
    final device = ProximityDevice(
      id: deviceData['id'] as String,
      name: deviceData['name'] as String,
      distance: DISTANCE_MID,
      rssi: -60, // Mid-range signal
      discoveryMethod: METHOD_WIFI,
      ipAddress: deviceData['ipAddress'] as String,
      port: deviceData['port'] as int,
      lastSeen: DateTime.now(),
    );
    
    _addOrUpdateDevice(device);
  }
  
  /// Handle internet-based device discovery
  void _handleInternetDevice(String deviceInfo) {
    // Parse device info from relay server
    final parts = deviceInfo.split(':');
    if (parts.length < 3) return;
    
    final device = ProximityDevice(
      id: parts[1],
      name: parts[2],
      distance: DISTANCE_FAR,
      rssi: -100, // Weakest signal
      discoveryMethod: METHOD_INTERNET,
      ipAddress: parts.length > 3 ? parts[3] : null,
      port: parts.length > 4 ? int.parse(parts[4]) : null,
      lastSeen: DateTime.now(),
    );
    
    _addOrUpdateDevice(device);
  }
  
  /// Add or update device in discovered list
  void _addOrUpdateDevice(ProximityDevice device) {
    final index = _discoveredDevices.indexWhere((d) => d.id == device.id);
    
    if (index >= 0) {
      // Update existing device
      _discoveredDevices[index] = device;
    } else {
      // Add new device
      _discoveredDevices.add(device);
    }
    
    // Sort by distance (closest first)
    _discoveredDevices.sort((a, b) => a.distance.compareTo(b.distance));
    
    // Emit updated list
    _deviceStreamController.add(List.from(_discoveredDevices));
  }
  
  /// Update device RSSI and recalculate distance
  void _updateDeviceRSSI(Map rssiData) {
    final deviceId = rssiData['id'] as String;
    final newRSSI = (rssiData['rssi'] as int).toDouble();
    
    final index = _discoveredDevices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;
    
    final device = _discoveredDevices[index];
    final newDistance = _calculateDistanceFromRSSI(newRSSI);
    
    _discoveredDevices[index] = device.copyWith(
      distance: newDistance,
      rssi: newRSSI,
      lastSeen: DateTime.now(),
    );
    
    _deviceStreamController.add(List.from(_discoveredDevices));
  }
  
  /// Calculate distance from RSSI using path loss model
  double _calculateDistanceFromRSSI(double rssi) {
    // Path loss model: RSSI = -10n * log10(d) + A
    // where n = path loss exponent (2-4), A = RSSI at 1m (-40 to -50)
    
    const n = 2.5; // Path loss exponent
    const A = -45.0; // RSSI at 1 meter
    
    final distance = math.pow(10, (A - rssi) / (10 * n)).toDouble();
    
    return distance.clamp(0.0, DISTANCE_MID);
  }
  
  /// Start periodic updates for device list
  void _startPeriodicUpdates() {
    // Update device list every 2 seconds
    _updateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _cleanupStaleDevices();
    });
    
    // Update RSSI every 500ms for smooth animations
    _rssiUpdateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      // Request RSSI updates from platform
      if (_isScanning) {
        platform.invokeMethod('updateRSSI');
      }
    });
  }
  
  /// Remove devices that haven't been seen recently
  void _cleanupStaleDevices() {
    final now = DateTime.now();
    _discoveredDevices.removeWhere((device) {
      final timeSinceLastSeen = now.difference(device.lastSeen);
      return timeSinceLastSeen.inSeconds > 10; // Remove after 10 seconds
    });
    
    _deviceStreamController.add(List.from(_discoveredDevices));
  }
  
  /// Mock BLE discovery for development
  void _startMockBLEDiscovery() {
    print('[ProximityDiscovery] Starting mock BLE discovery');
    
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }
      
      // Simulate discovering a device
      final mockDevice = ProximityDevice(
        id: 'mock-${_discoveredDevices.length + 1}',
        name: 'Test Device ${_discoveredDevices.length + 1}',
        distance: (math.Random().nextDouble() * 10),
        rssi: -40 - (math.Random().nextDouble() * 60),
        discoveryMethod: METHOD_BLE,
        ipAddress: '192.168.1.${100 + _discoveredDevices.length}',
        port: 37777,
        lastSeen: DateTime.now(),
      );
      
      _addOrUpdateDevice(mockDevice);
    });
  }
  
  /// Mock WiFi discovery for development
  void _startMockWiFiDiscovery() {
    print('[ProximityDiscovery] Starting mock WiFi discovery');
    
    Timer(Duration(seconds: 2), () {
      if (!_isScanning) return;
      
      final mockDevice = ProximityDevice(
        id: 'wifi-device-1',
        name: 'Nearby Laptop',
        distance: 15.0,
        rssi: -65,
        discoveryMethod: METHOD_WIFI,
        ipAddress: '192.168.1.105',
        port: 37777,
        lastSeen: DateTime.now(),
      );
      
      _addOrUpdateDevice(mockDevice);
    });
  }
  
  /// Get device ID
  String _getDeviceId() {
    // Would use actual device ID
    return 'device-${Platform.operatingSystem}-${math.Random().nextInt(10000)}';
  }
  
  /// Stop NFC discovery
  Future<void> _stopNFCDiscovery() async {
    try {
      await platform.invokeMethod('stopNFCSession');
    } catch (e) {
      print('[ProximityDiscovery] Error stopping NFC: $e');
    }
  }
  
  /// Stop BLE discovery
  Future<void> _stopBLEDiscovery() async {
    try {
      await platform.invokeMethod('stopBLEScanning');
    } catch (e) {
      print('[ProximityDiscovery] Error stopping BLE: $e');
    }
  }
  
  /// Stop WiFi discovery
  Future<void> _stopWiFiDiscovery() async {
    try {
      await platform.invokeMethod('stopMDNSDiscovery');
      await platform.invokeMethod('stopMDNSBroadcast');
    } catch (e) {
      print('[ProximityDiscovery] Error stopping WiFi: $e');
    }
  }
  
  /// Stop internet discovery
  Future<void> _stopInternetDiscovery() async {
    // Close relay connection
  }
  
  /// Dispose resources
  void dispose() {
    stopDiscovery();
    _deviceStreamController.close();
    _proximityController.close();
  }
}

/// Proximity device model
class ProximityDevice {
  final String id;
  final String name;
  final double distance; // in meters
  final double rssi; // Signal strength
  final String discoveryMethod;
  final String? ipAddress;
  final int? port;
  final DateTime lastSeen;
  
  ProximityDevice({
    required this.id,
    required this.name,
    required this.distance,
    required this.rssi,
    required this.discoveryMethod,
    this.ipAddress,
    this.port,
    required this.lastSeen,
  });
  
  /// Get proximity level
  ProximityLevel get proximityLevel {
    if (distance < ProximityDiscoveryEngine.DISTANCE_TOUCH) {
      return ProximityLevel.touch;
    } else if (distance < ProximityDiscoveryEngine.DISTANCE_NEAR) {
      return ProximityLevel.near;
    } else if (distance < ProximityDiscoveryEngine.DISTANCE_MID) {
      return ProximityLevel.mid;
    } else {
      return ProximityLevel.far;
    }
  }
  
  /// Get formatted distance
  String get distanceFormatted {
    if (distance < 1.0) {
      return '${(distance * 100).toInt()} cm';
    } else if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
  
  /// Get signal strength bars (0-5)
  int get signalBars {
    if (rssi > -50) return 5;
    if (rssi > -60) return 4;
    if (rssi > -70) return 3;
    if (rssi > -80) return 2;
    if (rssi > -90) return 1;
    return 0;
  }
  
  ProximityDevice copyWith({
    String? id,
    String? name,
    double? distance,
    double? rssi,
    String? discoveryMethod,
    String? ipAddress,
    int? port,
    DateTime? lastSeen,
  }) {
    return ProximityDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      distance: distance ?? this.distance,
      rssi: rssi ?? this.rssi,
      discoveryMethod: discoveryMethod ?? this.discoveryMethod,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Proximity level enum
enum ProximityLevel {
  touch, // <10cm (NFC range)
  near, // <5m (BLE range)
  mid, // <50m (WiFi range)
  far, // >50m (Internet range)
}

/// Proximity event
class ProximityEvent {
  final ProximityDevice device;
  final ProximityEventType eventType;
  final DateTime timestamp;
  
  ProximityEvent({
    required this.device,
    required this.eventType,
    required this.timestamp,
  });
}

/// Proximity event types
enum ProximityEventType {
  touchDetected, // Device touched (NFC)
  veryNear, // Device very close (<1m)
  approaching, // Device getting closer
  leaving, // Device moving away
  lost, // Device lost
}
