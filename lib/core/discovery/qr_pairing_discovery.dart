import 'dart:async';
import 'discovery_engine.dart';

/// QR-based pairing discovery. In practice, scanning a QR introduces a known peer.
class QrPairingDiscovery implements DiscoveryEngine {
  final _controller = StreamController<List<PeerDevice>>.broadcast();
  final Map<String, PeerDevice> _manualPeers = {};

  @override
  Stream<List<PeerDevice>> get devices => _controller.stream;

  @override
  Future<void> start() async {
    // idle; only updates when addPeer is called
    _controller.add(const []);
  }

  @override
  Future<void> stop() async {
    await _controller.close();
  }

  /// Called after QR scan decodes an id+name+platform payload.
  void addPeer(PeerDevice device) {
    _manualPeers[device.id] = device;
    _controller.add(_manualPeers.values.toList(growable: false));
  }
}
