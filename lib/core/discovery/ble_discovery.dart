import 'dart:async';
import '../platform/platform_gates.dart';
import 'discovery_engine.dart';

/// BLE discovery stub (simulated); real impl would scan advertisements and map to PeerDevice
class BleDiscovery implements DiscoveryEngine {
  final _controller = StreamController<List<PeerDevice>>.broadcast();
  Timer? _timer;
  int _pulse = 0;

  @override
  Stream<List<PeerDevice>> get devices => _controller.stream;

  @override
  Future<void> start() async {
    if (!(PlatformGates.isAndroid || PlatformGates.isIOS || PlatformGates.isMacOS)) {
      // Not supported; emit empty periodically to keep pipeline alive
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _controller.add(const []));
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pulse++;
      final list = <PeerDevice>[
        if (_pulse % 2 == 0)
          PeerDevice(
            id: 'android-ble-01',
            name: 'Pixel BLE',
            platform: 'android',
            batteryPercent: 74,
            signalBars: 2 + (_pulse % 3),
          ),
      ];
      _controller.add(list);
    });
  }

  @override
  Future<void> stop() async {
    await _controller.close();
    _timer?.cancel();
  }
}
