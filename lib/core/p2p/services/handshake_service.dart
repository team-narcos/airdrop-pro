import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'p2p_client.dart';

/// Handshake protocol service
/// 
/// Manages the initial connection handshake between devices including:
/// - Device identification
/// - Capability negotiation
/// - Connection acceptance/rejection
class HandshakeService {
  static const Duration _handshakeTimeout = Duration(seconds: 10);
  
  final String _deviceId;
  final String _deviceName;
  final String _platform;
  final DeviceCapabilities _capabilities;
  
  // Pending handshakes
  final Map<String, Completer<HandshakeResult>> _pendingHandshakes = {};
  
  HandshakeService({
    required String deviceId,
    required String deviceName,
    required String platform,
    required DeviceCapabilities capabilities,
  })  : _deviceId = deviceId,
        _deviceName = deviceName,
        _platform = platform,
        _capabilities = capabilities;
  
  /// Initiate handshake as client (connecting to another device)
  Future<HandshakeResult> initiateHandshake(P2PClient client) async {
    if (!client.isConnected) {
      return HandshakeResult.failed('Not connected');
    }
    
    debugPrint('[Handshake] Initiating handshake');
    
    final completer = Completer<HandshakeResult>();
    final handshakeId = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingHandshakes[handshakeId] = completer;
    
    try {
      // Send handshake message
      final success = await client.sendHandshake(
        deviceId: _deviceId,
        deviceName: _deviceName,
        platform: _platform,
        version: _capabilities.appVersion,
        capabilities: _capabilities.toMap(),
      );
      
      if (!success) {
        _pendingHandshakes.remove(handshakeId);
        return HandshakeResult.failed('Failed to send handshake');
      }
      
      // Wait for response with timeout
      final result = await completer.future.timeout(
        _handshakeTimeout,
        onTimeout: () {
          _pendingHandshakes.remove(handshakeId);
          return HandshakeResult.failed('Handshake timeout');
        },
      );
      
      return result;
    } catch (e) {
      _pendingHandshakes.remove(handshakeId);
      debugPrint('[Handshake] Error during handshake: $e');
      return HandshakeResult.failed(e.toString());
    }
  }
  
  /// Handle incoming handshake message (as server)
  Future<HandshakeResponse> handleHandshakeRequest(
    HandshakeMessage message,
    Future<bool> Function(String deviceId, String deviceName) shouldAccept,
  ) async {
    debugPrint('[Handshake] Received handshake from ${message.deviceName}');
    
    try {
      // Parse remote capabilities
      final remoteCapabilities = DeviceCapabilities.fromMap(message.capabilities);
      
      // Ask if we should accept this connection
      final accept = await shouldAccept(message.deviceId, message.deviceName);
      
      if (!accept) {
        debugPrint('[Handshake] Rejected connection from ${message.deviceName}');
        return const HandshakeResponse(
          accepted: false,
          reason: 'Connection rejected by user',
          remoteDevice: null,
          negotiatedCapabilities: null,
        );
      }
      
      // Negotiate capabilities
      final negotiated = _negotiateCapabilities(remoteCapabilities);
      
      // Create device object
      final device = P2PDevice(
        id: message.deviceId,
        name: message.deviceName,
        platform: message.platform,
        ipAddress: '', // Will be set by caller
        port: 0, // Will be set by caller
        lastSeen: DateTime.now(),
        isConnected: true,
        capabilities: remoteCapabilities,
      );
      
      debugPrint('[Handshake] Accepted connection from ${message.deviceName}');
      
      return HandshakeResponse(
        accepted: true,
        remoteDevice: device,
        negotiatedCapabilities: negotiated,
      );
    } catch (e) {
      debugPrint('[Handshake] Error handling handshake: $e');
      return HandshakeResponse(
        accepted: false,
        reason: 'Handshake error: $e',
        remoteDevice: null,
        negotiatedCapabilities: null,
      );
    }
  }
  
  /// Handle handshake acknowledgment (as client)
  void handleHandshakeAck(HandshakeAckMessage message) {
    debugPrint('[Handshake] Received handshake ack: accepted=${message.accepted}');
    
    // Find pending handshake
    // For simplicity, complete the first pending one (in production, match by connection ID)
    if (_pendingHandshakes.isNotEmpty) {
      final completer = _pendingHandshakes.values.first;
      _pendingHandshakes.clear();
      
      if (message.accepted) {
        completer.complete(HandshakeResult.success(
          deviceId: message.deviceId,
          deviceName: message.deviceName,
        ));
      } else {
        completer.complete(HandshakeResult.failed(
          message.reason ?? 'Connection rejected',
        ));
      }
    }
  }
  
  /// Negotiate capabilities between devices
  NegotiatedCapabilities _negotiateCapabilities(DeviceCapabilities remote) {
    return NegotiatedCapabilities(
      chunkSize: _capabilities.getOptimalChunkSize(remote),
      compression: _capabilities.getCommonCompression(remote),
      encryption: _capabilities.encryption && remote.encryption,
      resumeSupport: _capabilities.resumeSupport && remote.resumeSupport,
      parallelStreams: _capabilities.parallelStreams < remote.parallelStreams
          ? _capabilities.parallelStreams
          : remote.parallelStreams,
    );
  }
  
  /// Clean up pending handshakes
  void dispose() {
    for (final completer in _pendingHandshakes.values) {
      if (!completer.isCompleted) {
        completer.complete(HandshakeResult.failed('Service disposed'));
      }
    }
    _pendingHandshakes.clear();
  }
}

/// Result of a handshake attempt
class HandshakeResult {
  final bool success;
  final String? deviceId;
  final String? deviceName;
  final String? errorMessage;
  
  const HandshakeResult._({
    required this.success,
    this.deviceId,
    this.deviceName,
    this.errorMessage,
  });
  
  factory HandshakeResult.success({
    required String deviceId,
    required String deviceName,
  }) {
    return HandshakeResult._(
      success: true,
      deviceId: deviceId,
      deviceName: deviceName,
    );
  }
  
  factory HandshakeResult.failed(String error) {
    return HandshakeResult._(
      success: false,
      errorMessage: error,
    );
  }
}

/// Response to a handshake request
class HandshakeResponse {
  final bool accepted;
  final String? reason;
  final P2PDevice? remoteDevice;
  final NegotiatedCapabilities? negotiatedCapabilities;
  
  const HandshakeResponse({
    required this.accepted,
    this.reason,
    this.remoteDevice,
    this.negotiatedCapabilities,
  });
}

/// Negotiated capabilities between two devices
class NegotiatedCapabilities {
  final int chunkSize;
  final String compression;
  final bool encryption;
  final bool resumeSupport;
  final int parallelStreams;
  
  const NegotiatedCapabilities({
    required this.chunkSize,
    required this.compression,
    required this.encryption,
    required this.resumeSupport,
    required this.parallelStreams,
  });
  
  @override
  String toString() {
    return 'NegotiatedCapabilities(chunk: $chunkSize, compression: $compression, '
        'encrypted: $encryption, resume: $resumeSupport, streams: $parallelStreams)';
  }
}
