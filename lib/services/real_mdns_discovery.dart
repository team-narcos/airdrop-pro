import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/discovery/discovery_engine.dart';

class RealMDnsDiscovery {
  final _deviceController = StreamController<List<PeerDevice>>.broadcast();
  final _discoveredDevices = <String, PeerDevice>{};
  
  MDnsClient? _client;
  Timer? _scanTimer;
  bool _isRunning = false;
  String? _myDeviceId;
  
  Stream<List<PeerDevice>> get devicesStream => _deviceController.stream;
  
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    
    // Get own device ID
    _myDeviceId = await _getDeviceId();
    
    // Start broadcasting own service
    await _startBroadcast();
    
    // Start discovery scan
    await _startScanning();
  }
  
  Future<void> stop() async {
    _isRunning = false;
    _scanTimer?.cancel();
    _client?.stop();
    await _deviceController.close();
  }
  
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        return info.computerName;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        return info.computerName;
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        return info.machineId ?? 'linux-device';
      }
    } catch (e) {
      return 'device-${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'unknown-device';
  }
  
  Future<void> _startBroadcast() async {
    // In a real implementation, would use a service like Bonjour/Avahi
    // For now, we'll just discover others
  }
  
  Future<void> _startScanning() async {
    _scanTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _scanForDevices();
    });
    
    // Initial scan
    await _scanForDevices();
  }
  
  Future<void> _scanForDevices() async {
    try {
      _client = MDnsClient();
      await _client!.start();
      
      // Look for AirDrop-like services
      await for (final PtrResourceRecord ptr in _client!
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer('_airdrop._tcp.local'),
          )
          .timeout(const Duration(seconds: 2))) {
        
        // Get service details
        await for (final SrvResourceRecord srv in _client!
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )
            .timeout(const Duration(seconds: 1))) {
          
          // Get IP address
      await for (final IPAddressResourceRecord ip in _client!
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )
              .timeout(const Duration(seconds: 1))) {
            
            final deviceId = ptr.domainName.split('.').first;
            
            // Don't add self
            if (deviceId == _myDeviceId) continue;
            
            // Create or update device
            final device = PeerDevice(
              id: deviceId,
              name: _extractDeviceName(ptr.domainName),
              platform: 'Unknown',
              ipAddress: ip.address.address,
              port: srv.port,
              isOnline: true,
            );
            
            _discoveredDevices[deviceId] = device;
          }
        }
      }
      
      _client!.stop();
      
      // Remove stale devices (not seen in last 15 seconds)
      final now = DateTime.now();
      _discoveredDevices.removeWhere((key, device) {
        // In real impl, track last seen time
        return false;
      });
      
      // Emit updated list
      _deviceController.add(_discoveredDevices.values.toList());
      
    } catch (e) {
      // Scan timeout or error - continue
      try {
        _client?.stop();
      } catch (_) {}
    }
  }
  
  String _extractDeviceName(String domainName) {
    final parts = domainName.split('.');
    if (parts.isNotEmpty) {
      return parts.first.replaceAll('-', ' ').replaceAll('_', ' ');
    }
    return 'Unknown Device';
  }
  
  // Add a mock device for testing
  void addMockDevice(String name) {
    final device = PeerDevice(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      platform: 'Mock',
      ipAddress: '192.168.1.${100 + _discoveredDevices.length}',
      port: 8080,
      isOnline: true,
    );
    _discoveredDevices[device.id] = device;
    _deviceController.add(_discoveredDevices.values.toList());
  }
}
