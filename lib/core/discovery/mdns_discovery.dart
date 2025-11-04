import 'dart:async';
import '../platform/platform_gates.dart';
import 'discovery_engine.dart';

/// Simple mDNS/Bonjour stub that emits demo devices while online.
class MdnsDiscovery implements DiscoveryEngine {
  final _controller = StreamController<List<PeerDevice>>.broadcast();
  Timer? _timer;
  var _tick = 0;

  @override
  Stream<List<PeerDevice>> get devices => _controller.stream;

  @override
  Future<void> start() async {
    if (PlatformGates.isWeb) {
      _startDemo();
    } else {
      _startDemo(); // TODO: replace with real mDNS/Bonjour
    }
  }

  void _startDemo() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _tick++;
      final list = <PeerDevice>[
        PeerDevice(
          id: 'iphone-001',
          name: "John's iPhone",
          platform: 'ios',
          batteryPercent: 82,
          signalBars: 4,
        ),
        if (_tick % 3 != 0)
          PeerDevice(
            id: 'mbp-002',
            name: "Sarah's MacBook",
            platform: 'macos',
            batteryPercent: 56,
            signalBars: 3,
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
