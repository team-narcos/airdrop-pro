import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/discovery/discovery_engine.dart';

class UdpDiscoveryService {
  static const int DISCOVERY_PORT = 37020;
  static const String BROADCAST_MESSAGE = 'AIRDROP_DISCOVER';
  static const Duration BROADCAST_INTERVAL = Duration(seconds: 3);
  
  RawDatagramSocket? _socket;
  MDnsClient? _mdnsClient;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;
  Timer? _mdnsTimer;
  bool _isRunning = false;
  bool _isWifiConnected = false;
  String? _wifiName;
  
  final _deviceController = StreamController<List<PeerDevice>>.broadcast();
  final Map<String, _DiscoveredDevice> _discoveredDevices = {};
  
  String? _myDeviceId;
  String? _myDeviceName;
  int? _myPort;
  
  Stream<List<PeerDevice>> get devicesStream => _deviceController.stream;
  List<PeerDevice> get currentDevices => _discoveredDevices.values
      .where((d) => d.device.id != _myDeviceId)
      .map((d) => d.device)
      .toList();
  
  Future<void> start() async {
    if (_isRunning) return;
    
    print('[UDP Discovery] Starting service...');
    _isRunning = true;
    
    // Check WiFi connectivity
    await _checkWifiConnectivity();
    if (!_isWifiConnected) {
      print('[UDP Discovery] Not connected to WiFi');
      return;
    }
    
    // Get device info
    await _initializeDeviceInfo();
    
    // Start mDNS discovery
    await _startMdnsDiscovery();
    
    // Start UDP socket
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, DISCOVERY_PORT);
      _socket!.broadcastEnabled = true;
      _myPort = _socket!.port;
      
      print('[UDP Discovery] Socket bound to port $_myPort');
      
      // Listen for incoming messages
      _socket!.listen(_handleIncomingPacket);
      
      // Start broadcasting
      _startBroadcasting();
      
      // Start cleanup timer
      _startCleanupTimer();
      
      print('[UDP Discovery] Service started successfully');
    } catch (e) {
      print('[UDP Discovery] Failed to start: $e');
      _isRunning = false;
    }
  }
  
  Future<void> stop() async {
    print('[UDP Discovery] Stopping service...');
    _isRunning = false;
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _mdnsTimer?.cancel();
    _socket?.close();
    _mdnsClient?.stop();
    await _deviceController.close();
  }
  
  Future<void> _checkWifiConnectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      _isWifiConnected = connectivity.contains(ConnectivityResult.wifi);
      
      if (_isWifiConnected) {
        final networkInfo = NetworkInfo();
        _wifiName = await networkInfo.getWifiName();
        print('[UDP Discovery] Connected to WiFi: $_wifiName');
      } else {
        print('[UDP Discovery] Not connected to WiFi');
      }
    } catch (e) {
      print('[UDP Discovery] WiFi check error: $e');
      _isWifiConnected = false;
    }
  }
  
  Future<void> _startMdnsDiscovery() async {
    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();
      
      // Announce this device
      final ipAddress = await NetworkInfo().getWifiIP();
      if (ipAddress != null) {
        print('[mDNS] Announcing device at $ipAddress:37777');
        // Note: multicast_dns doesn't support direct announce, we rely on responses
      }
      
      // Start periodic mDNS scanning
      _startMdnsScanning();
    } catch (e) {
      print('[mDNS] Failed to start: $e');
    }
  }
  
  void _startMdnsScanning() {
    _mdnsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _scanMdns();
    });
    // Initial scan
    _scanMdns();
  }
  
  Future<void> _scanMdns() async {
    if (!_isRunning || _mdnsClient == null) return;
    
    try {
      await for (final PtrResourceRecord ptr in _mdnsClient!
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer('_airdrop._tcp.local'),
          )
          .timeout(const Duration(seconds: 2))) {
        
        print('[mDNS] Found service: ${ptr.domainName}');
        
        // Get SRV record for port and target
        await for (final SrvResourceRecord srv in _mdnsClient!
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )
            .timeout(const Duration(seconds: 1))) {
          
          // Get A record for IP
          await for (final IPAddressResourceRecord ip in _mdnsClient!
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )
              .timeout(const Duration(seconds: 1))) {
            
            final deviceId = ptr.domainName.split('.').first;
            if (deviceId == _myDeviceId) continue;
            
            final device = PeerDevice(
              id: deviceId,
              name: _extractDeviceName(ptr.domainName),
              platform: 'mDNS',
              ipAddress: ip.address.address,
              port: srv.port,
              isOnline: true,
              signalBars: 5,
            );
            
            _discoveredDevices[deviceId] = _DiscoveredDevice(
              device: device,
              lastSeen: DateTime.now(),
            );
            
            print('[mDNS] Added device: ${device.name} at ${ip.address.address}');
            _emitDevices();
          }
        }
      }
    } catch (e) {
      // Timeout or no devices - normal, don't spam logs
    }
  }
  
  String _extractDeviceName(String domainName) {
    final parts = domainName.split('.');
    if (parts.isNotEmpty) {
      return parts.first.replaceAll('-', ' ').replaceAll('_', ' ');
    }
    return 'Unknown Device';
  }
  
  Future<void> _initializeDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _myDeviceId = info.id;
        _myDeviceName = info.model;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        _myDeviceId = info.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
        _myDeviceName = info.name;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        _myDeviceId = info.computerName;
        _myDeviceName = info.computerName;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        _myDeviceId = info.computerName;
        _myDeviceName = info.computerName;
      }
    } catch (e) {
      _myDeviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
      _myDeviceName = 'Unknown Device';
    }
    
    print('[UDP Discovery] My device: $_myDeviceName ($_myDeviceId)');
  }
  
  void _startBroadcasting() {
    _broadcastTimer = Timer.periodic(BROADCAST_INTERVAL, (_) {
      _sendBroadcast();
    });
    // Send initial broadcast immediately
    _sendBroadcast();
  }
  
  void _sendBroadcast() {
    if (!_isRunning || _socket == null) return;
    
    try {
      final message = jsonEncode({
        'type': 'discover',
        'deviceId': _myDeviceId,
        'deviceName': _myDeviceName,
        'platform': Platform.operatingSystem,
        'port': _myPort,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      final bytes = utf8.encode(message);
      
      // Send to broadcast address
      _socket!.send(
        bytes,
        InternetAddress('255.255.255.255'),
        DISCOVERY_PORT,
      );
      
      // Also try subnet broadcasts
      _sendToCommonSubnets(bytes);
      
    } catch (e) {
      print('[UDP Discovery] Broadcast error: $e');
    }
  }
  
  void _sendToCommonSubnets(List<int> bytes) {
    // Try common local subnets
    final subnets = [
      '192.168.1.255',
      '192.168.0.255',
      '192.168.2.255',
      '10.0.0.255',
      '172.16.0.255',
    ];
    
    for (final subnet in subnets) {
      try {
        _socket!.send(bytes, InternetAddress(subnet), DISCOVERY_PORT);
      } catch (e) {
        // Ignore errors for specific subnets
      }
    }
  }
  
  void _handleIncomingPacket(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final packet = _socket!.receive();
      if (packet == null) return;
      
      try {
        final message = utf8.decode(packet.data);
        final data = jsonDecode(message);
        
        if (data['type'] == 'discover') {
          final deviceId = data['deviceId'] as String?;
          final deviceName = data['deviceName'] as String?;
          final platform = data['platform'] as String?;
          final port = data['port'] as int?;
          
          // Ignore own broadcasts
          if (deviceId == _myDeviceId) return;
          
          if (deviceId != null && deviceName != null) {
            final device = PeerDevice(
              id: deviceId,
              name: deviceName,
              platform: platform ?? 'Unknown',
              ipAddress: packet.address.address,
              port: port ?? DISCOVERY_PORT,
              isOnline: true,
              signalBars: 5, // Full signal for local network
            );
            
            // Check if this is a new device or needs update
            final existingDevice = _discoveredDevices[deviceId];
            final isNewDevice = existingDevice == null;
            final needsUpdate = existingDevice != null && 
                (existingDevice.device.ipAddress != packet.address.address ||
                 existingDevice.device.name != deviceName);
            
            _discoveredDevices[deviceId] = _DiscoveredDevice(
              device: device,
              lastSeen: DateTime.now(),
            );
            
            // Only log and emit for new devices or significant updates
            if (isNewDevice) {
              print('[UDP Discovery] New device found: $deviceName (${packet.address.address})');
              _emitDevices();
            } else if (needsUpdate) {
              print('[UDP Discovery] Device updated: $deviceName (${packet.address.address})');
              _emitDevices();
            }
            // Silently update lastSeen for existing devices
            
            // Send response
            _sendResponseTo(packet.address, packet.port);
          }
        }
      } catch (e) {
        // Ignore invalid packets
      }
    }
  }
  
  void _sendResponseTo(InternetAddress address, int port) {
    try {
      final message = jsonEncode({
        'type': 'discover',
        'deviceId': _myDeviceId,
        'deviceName': _myDeviceName,
        'platform': Platform.operatingSystem,
        'port': _myPort,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      final bytes = utf8.encode(message);
      _socket!.send(bytes, address, port);
    } catch (e) {
      print('[UDP Discovery] Response error: $e');
    }
  }
  
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _cleanup();
    });
  }
  
  void _cleanup() {
    final now = DateTime.now();
    final staleDevices = <String>[];
    
    _discoveredDevices.forEach((id, discovered) {
      if (now.difference(discovered.lastSeen).inSeconds > 15) {
        staleDevices.add(id);
      }
    });
    
    if (staleDevices.isNotEmpty) {
      for (final id in staleDevices) {
        print('[UDP Discovery] Device offline: ${_discoveredDevices[id]?.device.name}');
        _discoveredDevices.remove(id);
      }
      _emitDevices();
    }
  }
  
  void _emitDevices() {
    _deviceController.add(currentDevices);
  }
}

class _DiscoveredDevice {
  final PeerDevice device;
  final DateTime lastSeen;
  
  _DiscoveredDevice({
    required this.device,
    required this.lastSeen,
  });
}
