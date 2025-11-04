import 'dart:typed_data';

/// Abstract transport definition for pluggable P2P transports
/// (WebRTC, Wi‑Fi Direct, BLE)
abstract class Transport {
  Future<void> initialize();
  Future<void> dispose();

  /// Connect to remote peer by ID/address.
  Future<void> connect(String peerId);

  /// Listen for incoming connections.
  Future<void> listen();

  /// Send a binary chunk. Upper layer handles chunking.
  Future<void> send(Uint8List bytes);

  /// Stream of bytes received from peer.
  Stream<Uint8List> get onBytes;

  /// Emits connection state changes.
  Stream<TransportState> get onState;
}

enum TransportState { idle, listening, connecting, connected, closed, error }
