/// BLE transport placeholder used for discovery + small control messages.
import 'dart:async';
import 'dart:typed_data';
import '../platform/platform_gates.dart';
import 'transport.dart';

class BleTransport implements Transport {
  final _bytes = StreamController<Uint8List>.broadcast();
  final _state = StreamController<TransportState>.broadcast();

  @override
  Future<void> initialize() async {
    if (!(PlatformGates.isAndroid || PlatformGates.isIOS || PlatformGates.isMacOS)) return;
    _state.add(TransportState.idle);
  }

  @override
  Future<void> dispose() async {
    await _bytes.close();
    await _state.close();
  }

  @override
  Future<void> connect(String peerId) async {
    _state.add(TransportState.connecting);
    // TODO
    _state.add(TransportState.connected);
  }

  @override
  Future<void> listen() async {
    _state.add(TransportState.listening);
  }

  @override
  Future<void> send(Uint8List bytes) async {
    // TODO
  }

  @override
  Stream<Uint8List> get onBytes => _bytes.stream;

  @override
  Stream<TransportState> get onState => _state.stream;
}
