import 'dart:async';
import 'discovery_engine.dart';

/// Central device registry that merges discovery updates with TTL expiry.
class DeviceRegistry {
  final List<DiscoveryEngine> engines;
  final Duration ttl;
  final _devices = <String, _TimedDevice>{};
  final _controller = StreamController<List<PeerDevice>>.broadcast();
  final List<StreamSubscription> _subs = [];

  DeviceRegistry(this.engines, {this.ttl = const Duration(seconds: 20)});

  Stream<List<PeerDevice>> get devices => _controller.stream;

  Future<void> start() async {
    for (final e in engines) {
      await e.start();
      _subs.add(e.devices.listen(_ingest));
    }
    // Eviction timer
    _subs.add(Stream.periodic(const Duration(seconds: 2)).listen((_) => _evict()));
  }

  Future<void> stop() async {
    for (final s in _subs) { await s.cancel(); }
    for (final e in engines) { await e.stop(); }
    await _controller.close();
  }

  void _ingest(List<PeerDevice> list) {
    final now = DateTime.now();
    for (final d in list) {
      _devices[d.id] = _TimedDevice(d, now);
    }
    _emit();
  }

  void _evict() {
    final now = DateTime.now();
    _devices.removeWhere((_, v) => now.difference(v.seenAt) > ttl);
    _emit();
  }

  void _emit() {
    _controller.add(_devices.values.map((e) => e.device).toList(growable: false));
  }
}

class _TimedDevice {
  final PeerDevice device;
  final DateTime seenAt;
  _TimedDevice(this.device, this.seenAt);
}
