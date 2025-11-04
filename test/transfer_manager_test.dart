import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:airdrop_app/core/discovery/discovery_engine.dart';

// Mock implementations for testing
class MockDiscoveryEngine implements DiscoveryEngine {
  final _controller = StreamController<List<PeerDevice>>.broadcast();
  
  @override
  Stream<List<PeerDevice>> get devices => _controller.stream;
  
  @override
  Future<void> start() async {
    // Add some mock devices
    _controller.add([
      PeerDevice(
        id: 'test-device-1',
        name: 'iPhone Test',
        platform: 'ios',
        batteryPercent: 85,
        signalBars: 4,
        isTrusted: true,
      ),
      PeerDevice(
        id: 'test-device-2', 
        name: 'Android Test',
        platform: 'android',
        batteryPercent: 72,
        signalBars: 3,
        isTrusted: false,
      ),
    ]);
  }
  
  @override
  Future<void> stop() async {
    await _controller.close();
  }
}

void main() {
  group('Discovery Engine Tests', () {
    late MockDiscoveryEngine discoveryEngine;

    setUp(() {
      discoveryEngine = MockDiscoveryEngine();
    });

    test('should initialize correctly', () {
      expect(discoveryEngine, isNotNull);
    });

    test('should discover mock devices', () async {
      await discoveryEngine.start();
      
      final devices = await discoveryEngine.devices.first;
      expect(devices, isNotEmpty);
      expect(devices.length, equals(2));
      expect(devices.first.name, equals('iPhone Test'));
      expect(devices.first.platform, equals('ios'));
      
      await discoveryEngine.stop();
    });

    test('should handle device properties correctly', () {
      final device = PeerDevice(
        id: 'test-device',
        name: 'Test Device',
        platform: 'android',
        batteryPercent: 90,
        signalBars: 5,
        isTrusted: true,
      );
      
      expect(device.name, equals('Test Device'));
      expect(device.platform, equals('android'));
      expect(device.batteryPercent, equals(90));
      expect(device.signalBars, equals(5));
      expect(device.isTrusted, isTrue);
    });
  });
}
