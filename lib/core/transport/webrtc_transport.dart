import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import '../platform/platform_gates.dart';
import 'transport.dart';

/// WebRTC data channel transport (stubbed for platforms without support)
class WebRtcTransport implements Transport {
  final _bytes = StreamController<Uint8List>.broadcast();
  final _state = StreamController<TransportState>.broadcast();
  webrtc.RTCPeerConnection? _pc;
  webrtc.RTCDataChannel? _dc;

  @override
  Future<void> initialize() async {
    if (PlatformGates.isWeb || PlatformGates.isAndroid || PlatformGates.isIOS || PlatformGates.isWindows || PlatformGates.isMacOS || PlatformGates.isLinux) {
      _state.add(TransportState.idle);
      // NOTE: full implementation omitted in scaffold; will create peer configs, ICE, etc.
      return;
    }
  }

  @override
  Future<void> dispose() async {
    await _dc?.close();
    await _pc?.close();
    await _bytes.close();
    await _state.close();
  }

  @override
  Future<void> connect(String peerId) async {
    _state.add(TransportState.connecting);
    // TODO: implement signalling + SDP exchange via local discovery channel
    _state.add(TransportState.connected);
  }

  @override
  Future<void> listen() async {
    _state.add(TransportState.listening);
    // TODO: await incoming SDP via signalling
  }

  @override
  Future<void> send(Uint8List bytes) async {
    // TODO: _dc?.send(webrtc.RTCDataChannelMessage.fromBinary(bytes));
  }

  @override
  Stream<Uint8List> get onBytes => _bytes.stream;

  @override
  Stream<TransportState> get onState => _state.stream;
}
