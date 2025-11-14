import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// Stub mDNS discovery service for Windows testing
/// This is a temporary implementation for UI testing only
class MDNSDiscoveryService {
  final _uuid = const Uuid();
  
  late final String _deviceId;
  String? _deviceName;
  int? _servicePort;
  
  final Map<String, P2PDevice> _devices = {};
  final _devicesController = StreamController<List<P2PDevice>>.broadcast();
  
  bool _isDiscovering = false;
  Timer? _mockDiscoveryTimer;
  
  MDNSDiscoveryService() {
    _deviceId = _uuid.v4();
  }
  
  Stream<List<P2PDevice>> get devicesStream => _devicesController.stream;
  List<P2PDevice> get devices => _devices.values.toList();
  List<P2PDevice> get activeDevices => devices.where((d) => d.isActive).toList();
  bool get isDiscovering => _isDiscovering;
  String get deviceId => _deviceId;
  
  Future<void> initialize({
    required String deviceName,
    required int port,
  }) async {
    _deviceName = deviceName;
    _servicePort = port;
    debugPrint('[mDNS Stub] Initialized with device: $deviceName, port: $port');
  }
  
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    
    _isDiscovering = true;
    debugPrint('[mDNS Stub] Discovery started (stub mode - no real devices will be found)');
    debugPrint('[mDNS Stub] For real device discovery, run on Android/iOS/macOS');
    
    // Optionally add a mock device for UI testing
    // _addMockDevice();
  }
  
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _mockDiscoveryTimer?.cancel();
    _devices.clear();
    _devicesController.add([]);
    debugPrint('[mDNS Stub] Discovery stopped');
  }
  
  void _addMockDevice() {
    final mockDevice = P2PDevice(
      id: 'mock_device_1',
      name: 'Mock Device',
      platform: 'Windows',
      ipAddress: '192.168.1.100',
      port: 8080,
      capabilities: DeviceCapabilities.defaults(),
      lastSeen: DateTime.now(),
    );
    
    _devices[mockDevice.id] = mockDevice;
    _devicesController.add(devices);
  }
  
  void dispose() {
    stopDiscovery();
    _devicesController.close();
  }
}
