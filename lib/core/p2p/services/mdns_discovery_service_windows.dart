import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// UDP Broadcast discovery service for Windows
class MDNSDiscoveryService {
  static const int _broadcastPort = 37778;
  static const String _serviceType = 'AIRDROP_PRO';
  
  final _uuid = const Uuid();
  
  late final String _deviceId;
  String? _deviceName;
  int? _servicePort;
  
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;
  
  final Map<String, P2PDevice> _devices = {};
  final Map<String, DateTime> _lastSeen = {};
  final _devicesController = StreamController<List<P2PDevice>>.broadcast();
  
  bool _isDiscovering = false;
  
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
    debugPrint('[UDP Discovery] Initialized: $deviceName on port $port');
  }
  
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    
    try {
      _isDiscovering = true;
      
      // Create UDP socket for broadcasting and listening
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
      _socket!.broadcastEnabled = true;
      
      debugPrint('[UDP Discovery] Listening on port $_broadcastPort');
      
      // Listen for incoming broadcasts
      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _handleIncomingBroadcast(datagram);
          }
        }
      });
      
      // Broadcast our presence every 3 seconds
      _broadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _broadcastPresence();
      });
      
      // Clean up stale devices every 10 seconds
      _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _cleanupStaleDevices();
      });
      
      // Send initial broadcast
      _broadcastPresence();
      
      debugPrint('[UDP Discovery] Started successfully');
    } catch (e) {
      _isDiscovering = false;
      debugPrint('[UDP Discovery] Error starting: $e');
      rethrow;
    }
  }
  
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _devices.clear();
    _lastSeen.clear();
    _devicesController.add([]);
    debugPrint('[UDP Discovery] Stopped');
  }
  
  void _broadcastPresence() {
    if (!_isDiscovering || _socket == null) return;
    
    try {
      final message = {
        'type': _serviceType,
        'id': _deviceId,
        'name': _deviceName,
        'port': _servicePort,
        'platform': 'windows',
      };
      
      final data = utf8.encode(json.encode(message));
      
      // Broadcast to local network
      _socket!.send(
        data,
        InternetAddress('255.255.255.255'),
        _broadcastPort,
      );
      
      debugPrint('[UDP Discovery] Broadcasted presence');
    } catch (e) {
      debugPrint('[UDP Discovery] Broadcast error: $e');
    }
  }
  
  void _handleIncomingBroadcast(Datagram datagram) {
    try {
      final message = json.decode(utf8.decode(datagram.data));
      
      // Ignore our own broadcasts
      if (message['id'] == _deviceId) return;
      
      // Verify it's an AirDrop Pro device
      if (message['type'] != _serviceType) return;
      
      final deviceId = message['id'] as String;
      final deviceName = message['name'] as String;
      final port = message['port'] as int;
      final platform = message['platform'] as String? ?? 'unknown';
      final ipAddress = datagram.address.address;
      
      debugPrint('[UDP Discovery] Found device: $deviceName at $ipAddress:$port');
      
      // Create or update device
      final device = P2PDevice(
        id: deviceId,
        name: deviceName,
        platform: platform,
        ipAddress: ipAddress,
        port: port,
        capabilities: DeviceCapabilities.defaults(),
        lastSeen: DateTime.now(),
      );
      
      _devices[deviceId] = device;
      _lastSeen[deviceId] = DateTime.now();
      
      // Notify listeners
      _devicesController.add(devices);
    } catch (e) {
      debugPrint('[UDP Discovery] Error parsing broadcast: $e');
    }
  }
  
  void _cleanupStaleDevices() {
    final now = DateTime.now();
    final staleDevices = <String>[];
    
    _lastSeen.forEach((deviceId, lastSeen) {
      if (now.difference(lastSeen).inSeconds > 15) {
        staleDevices.add(deviceId);
      }
    });
    
    if (staleDevices.isNotEmpty) {
      for (final deviceId in staleDevices) {
        debugPrint('[UDP Discovery] Removing stale device: $deviceId');
        _devices.remove(deviceId);
        _lastSeen.remove(deviceId);
      }
      _devicesController.add(devices);
    }
  }
  
  void dispose() {
    stopDiscovery();
    _devicesController.close();
  }
}
