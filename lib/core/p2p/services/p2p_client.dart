import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../models/models.dart';

/// TCP client for connecting to P2P devices
class P2PClient {
  Socket? _socket;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  
  final _sendLock = Lock();
  final _messageBuffer = <int>[];
  int? _expectedMessageLength;
  
  // Connection info
  String? _deviceId;
  String? _remoteAddress;
  int? _remotePort;
  
  // Callbacks
  final void Function()? onConnected;
  final void Function(ProtocolMessage message)? onMessageReceived;
  final void Function()? onDisconnected;
  final void Function(String error)? onError;
  
  P2PClient({
    this.onConnected,
    this.onMessageReceived,
    this.onDisconnected,
    this.onError,
  });
  
  /// Check if client is connected
  bool get isConnected => _isConnected;
  
  /// Get connected device ID
  String? get deviceId => _deviceId;
  
  /// Get remote address
  String? get remoteAddress => _remoteAddress;
  
  /// Connect to a device
  Future<bool> connect(P2PDevice device, {Duration timeout = const Duration(seconds: 10)}) async {
    if (_isConnected) {
      debugPrint('[P2PClient] Already connected');
      return false;
    }
    
    try {
      debugPrint('[P2PClient] Connecting to ${device.name} at ${device.ipAddress}:${device.port}');
      
      _deviceId = device.id;
      _remoteAddress = device.ipAddress;
      _remotePort = device.port;
      
      // Connect with timeout
      _socket = await Socket.connect(
        device.ipAddress,
        device.port,
        timeout: timeout,
      );
      
      _isConnected = true;
      
      // Set socket options
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      
      // Start listening for messages
      _subscription = _socket!.listen(
        _handleData,
        onError: (error) {
          debugPrint('[P2PClient] Socket error: $error');
          onError?.call(error.toString());
          disconnect();
        },
        onDone: () {
          debugPrint('[P2PClient] Connection closed');
          disconnect();
        },
      );
      
      debugPrint('[P2PClient] Connected to ${device.name}');
      onConnected?.call();
      
      return true;
    } catch (e) {
      debugPrint('[P2PClient] Failed to connect: $e');
      _isConnected = false;
      _socket = null;
      onError?.call(e.toString());
      return false;
    }
  }
  
  /// Disconnect from device
  Future<void> disconnect() async {
    if (!_isConnected) return;
    
    _isConnected = false;
    
    // Cancel subscription
    await _subscription?.cancel();
    _subscription = null;
    
    // Close socket
    try {
      await _socket?.close();
    } catch (e) {
      debugPrint('[P2PClient] Error closing socket: $e');
    }
    
    _socket = null;
    _messageBuffer.clear();
    _expectedMessageLength = null;
    
    debugPrint('[P2PClient] Disconnected from $_remoteAddress:$_remotePort');
    onDisconnected?.call();
  }
  
  /// Handle incoming data with length-prefix protocol
  void _handleData(Uint8List data) {
    try {
      // Add data to buffer
      _messageBuffer.addAll(data);
      
      // Process complete messages
      while (_processNextMessage()) {
        // Keep processing until no complete messages remain
      }
    } catch (e) {
      debugPrint('[P2PClient] Error handling data: $e');
      onError?.call(e.toString());
    }
  }
  
  /// Process next complete message from buffer
  bool _processNextMessage() {
    // Read length prefix if not yet read
    if (_expectedMessageLength == null) {
      if (_messageBuffer.length < 4) {
        // Not enough data for length prefix
        return false;
      }
      
      // Read 4-byte length prefix (big-endian)
      final lengthBytes = Uint8List.fromList(_messageBuffer.sublist(0, 4));
      _expectedMessageLength = lengthBytes.buffer.asByteData().getUint32(0, Endian.big);
      _messageBuffer.removeRange(0, 4);
    }
    
    // Check if we have complete message
    if (_messageBuffer.length < _expectedMessageLength!) {
      // Not enough data yet
      return false;
    }
    
    // Extract message
    final messageBytes = Uint8List.fromList(
      _messageBuffer.sublist(0, _expectedMessageLength!),
    );
    _messageBuffer.removeRange(0, _expectedMessageLength!);
    _expectedMessageLength = null;
    
    // Parse and deliver message
    try {
      final message = ProtocolMessage.fromBytes(messageBytes);
      onMessageReceived?.call(message);
    } catch (e) {
      debugPrint('[P2PClient] Error parsing message: $e');
      onError?.call(e.toString());
    }
    
    return true; // Processed a message, check for more
  }
  
  /// Send message to connected device
  Future<bool> sendMessage(ProtocolMessage message) async {
    if (!_isConnected || _socket == null) {
      debugPrint('[P2PClient] Not connected');
      return false;
    }
    
    return await _sendLock.synchronized(() async {
      try {
        final data = message.toBytes();
        
        // Send length prefix (4 bytes, big-endian)
        final length = data.length;
        final lengthBytes = Uint8List(4)
          ..buffer.asByteData().setUint32(0, length, Endian.big);
        
        _socket!.add(lengthBytes);
        _socket!.add(data);
        await _socket!.flush();
        
        debugPrint('[P2PClient] Sent message: ${message.type}');
        return true;
      } catch (e) {
        debugPrint('[P2PClient] Error sending message: $e');
        onError?.call(e.toString());
        return false;
      }
    });
  }
  
  /// Send handshake message
  Future<bool> sendHandshake({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String version,
    required Map<String, String> capabilities,
  }) async {
    final handshake = HandshakeMessage(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      version: version,
      capabilities: capabilities,
    );
    
    return await sendMessage(handshake);
  }
  
  /// Send handshake acknowledgment
  Future<bool> sendHandshakeAck({
    required String deviceId,
    required String deviceName,
    required bool accepted,
    String? reason,
  }) async {
    final ack = HandshakeAckMessage(
      deviceId: deviceId,
      deviceName: deviceName,
      accepted: accepted,
      reason: reason,
    );
    
    return await sendMessage(ack);
  }
  
  /// Send file offer
  Future<bool> sendFileOffer({
    required String transferId,
    required List<FileInfo> files,
    required int totalSize,
  }) async {
    final offer = FileOfferMessage(
      transferId: transferId,
      files: files,
      totalSize: totalSize,
    );
    
    return await sendMessage(offer);
  }
  
  /// Send file accept
  Future<bool> sendFileAccept({
    required String transferId,
    required List<String> acceptedFileIds,
    required String savePath,
  }) async {
    final accept = FileAcceptMessage(
      transferId: transferId,
      acceptedFileIds: acceptedFileIds,
      savePath: savePath,
    );
    
    return await sendMessage(accept);
  }
  
  /// Send file reject
  Future<bool> sendFileReject({
    required String transferId,
    required String reason,
  }) async {
    final reject = FileRejectMessage(
      transferId: transferId,
      reason: reason,
    );
    
    return await sendMessage(reject);
  }
  
  /// Send ping
  Future<bool> sendPing() async {
    final ping = PingPongMessage(type: MessageType.ping);
    return await sendMessage(ping);
  }
  
  /// Send pong
  Future<bool> sendPong() async {
    final pong = PingPongMessage(type: MessageType.pong);
    return await sendMessage(pong);
  }
  
  /// Send error message
  Future<bool> sendError({
    required String code,
    required String message,
    String? transferId,
  }) async {
    final error = ErrorMessage(
      code: code,
      message: message,
      transferId: transferId,
    );
    
    return await sendMessage(error);
  }
}
