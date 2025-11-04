/// Wi‑Fi Direct transport placeholder (Android-specific)
/// On other platforms this will be a no-op.
import 'dart:async';
import 'dart:typed_data';
import '../platform/platform_gates.dart';
import 'transport.dart';

class WifiDirectTransport implements Transport {
  final _bytes = StreamController<Uint8List>.broadcast();
  final _state = StreamController<TransportState>.broadcast();

  @override
  Future<void> initialize() async {
    if (!PlatformGates.isAndroid) return; // TODO: initialize Wifi P2P plugin
    _state.add(TransportState.idle);
  }

  @override
  Future<void> dispose() async {
    await _bytes.close();
    await _state.close();
  }

  @override
  Future<void> connect(String peerId) async {
    if (!PlatformGates.isAndroid) return;
    _state.add(TransportState.connecting);
    // TODO: connect to peer
    _state.add(TransportState.connected);
  }

  @override
  Future<void> listen() async {
    if (!PlatformGates.isAndroid) return;
    _state.add(TransportState.listening);
    // TODO: start discovery/listen for connections
  }

  @override
  Future<void> send(Uint8List bytes) async {
    if (!PlatformGates.isAndroid) return;
    // TODO: send over socket
  }

  @override
  Stream<Uint8List> get onBytes => _bytes.stream;

  @override
  Stream<TransportState> get onState => _state.stream;
}
