import 'dart:async';

/// Device model used across discovery and transfers
class PeerDevice {
  final String id;
  final String name;
  final String platform; // android, ios, windows, macos, linux, web
  final int batteryPercent;
  final int signalBars; // 0..5
  final bool isTrusted;
  final String? ipAddress;
  final int? port;
  final bool isOnline;

  PeerDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.batteryPercent = 0,
    this.signalBars = 0,
    this.isTrusted = false,
    this.ipAddress,
    this.port,
    this.isOnline = true,
  });
}

/// Discovery engine abstraction.
abstract class DiscoveryEngine {
  Future<void> start();
  Future<void> stop();
  Stream<List<PeerDevice>> get devices; // continuous list updates
}

/// Composite discovery engine that merges multiple underlying strategies
class CompositeDiscoveryEngine implements DiscoveryEngine {
  final List<DiscoveryEngine> _engines;
  final _controller = StreamController<List<PeerDevice>>.broadcast();
  StreamSubscription? _sub;

  CompositeDiscoveryEngine(this._engines);

  @override
  Stream<List<PeerDevice>> get devices => _controller.stream;

  @override
  Future<void> start() async {
    final merged = <PeerDevice>[];
    await Future.wait(_engines.map((e) async {
      await e.start();
      e.devices.listen((list) {
        // naive merge by id
        for (final d in list) {
          final idx = merged.indexWhere((m) => m.id == d.id);
          if (idx >= 0) merged[idx] = d; else merged.add(d);
        }
        _controller.add(List.unmodifiable(merged));
      });
    }));
  }

  @override
  Future<void> stop() async {
    await Future.wait(_engines.map((e) => e.stop()));
    await _sub?.cancel();
  }
}
