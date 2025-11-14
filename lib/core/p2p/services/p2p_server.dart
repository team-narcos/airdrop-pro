import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../models/models.dart';

/// TCP server for receiving P2P connections
class P2PServer {
  ServerSocket? _serverSocket;
  int? _port;
  bool _isRunning = false;
  
  // Connected clients
  final Map<String, _ClientConnection> _clients = {};
  final _lock = Lock();
  
  // Callbacks
  final void Function(Socket socket, String deviceId)? onClientConnected;
  final void Function(String deviceId, ProtocolMessage message)? onMessageReceived;
  final void Function(String deviceId)? onClientDisconnected;
  final void Function(String error)? onError;
  
  P2PServer({
    this.onClientConnected,
    this.onMessageReceived,
    this.onClientDisconnected,
    this.onError,
  });
  
  /// Check if server is running
  bool get isRunning => _isRunning;
  
  /// Get server port
  int? get port => _port;
  
  /// Get list of connected client device IDs
  List<String> get connectedClients => _clients.keys.toList();
  
  /// Start the server on a dynamic port
  Future<int> start({int port = 0}) async {
    if (_isRunning) {
      debugPrint('[P2PServer] Server already running on port $_port');
      return _port!;
    }
    
    try {
      // Bind to any available address on specified port (0 = dynamic)
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
        shared: false,
      );
      
      _port = _serverSocket!.port;
      _isRunning = true;
      
      debugPrint('[P2PServer] Server started on port $_port');
      
      // Listen for incoming connections
      _serverSocket!.listen(
        _handleClient,
        onError: (error) {
          debugPrint('[P2PServer] Server error: $error');
          onError?.call(error.toString());
        },
        onDone: () {
          debugPrint('[P2PServer] Server closed');
          _isRunning = false;
        },
      );
      
      return _port!;
    } catch (e) {
      debugPrint('[P2PServer] Failed to start server: $e');
      _isRunning = false;
      rethrow;
    }
  }
  
  /// Stop the server
  Future<void> stop() async {
    if (!_isRunning) return;
    
    _isRunning = false;
    
    // Close all client connections
    await _lock.synchronized(() async {
      for (final client in _clients.values) {
        await client.close();
      }
      _clients.clear();
    });
    
    // Close server socket
    await _serverSocket?.close();
    _serverSocket = null;
    _port = null;
    
    debugPrint('[P2PServer] Server stopped');
  }
  
  /// Handle new client connection
  void _handleClient(Socket socket) async {
    final remoteAddress = socket.remoteAddress.address;
    final remotePort = socket.remotePort;
    
    debugPrint('[P2PServer] New client connected: $remoteAddress:$remotePort');
    
    try {
      // Create client connection handler
      final client = _ClientConnection(
        socket: socket,
        onMessage: (deviceId, message) {
          onMessageReceived?.call(deviceId, message);
        },
        onDisconnected: (deviceId) {
          _removeClient(deviceId);
          onClientDisconnected?.call(deviceId);
        },
      );
      
      // Wait for initial handshake to get device ID
      // For now, use temporary ID until handshake completes
      final tempId = '$remoteAddress:$remotePort';
      
      await _lock.synchronized(() {
        _clients[tempId] = client;
      });
      
      // Start listening for messages
      client.listen();
      
      // Notify callback
      onClientConnected?.call(socket, tempId);
      
    } catch (e) {
      debugPrint('[P2PServer] Error handling client: $e');
      socket.close();
      onError?.call(e.toString());
    }
  }
  
  /// Remove client from connected list
  void _removeClient(String deviceId) async {
    await _lock.synchronized(() {
      _clients.remove(deviceId);
    });
    debugPrint('[P2PServer] Removed client: $deviceId');
  }
  
  /// Update client ID after handshake
  Future<void> updateClientId(String oldId, String newId) async {
    await _lock.synchronized(() {
      final client = _clients.remove(oldId);
      if (client != null) {
        client.deviceId = newId;
        _clients[newId] = client;
        debugPrint('[P2PServer] Updated client ID: $oldId -> $newId');
      }
    });
  }
  
  /// Send message to a specific client
  Future<bool> sendMessage(String deviceId, ProtocolMessage message) async {
    final client = _clients[deviceId];
    if (client == null) {
      debugPrint('[P2PServer] Client not found: $deviceId');
      return false;
    }
    
    try {
      await client.sendMessage(message);
      return true;
    } catch (e) {
      debugPrint('[P2PServer] Error sending message to $deviceId: $e');
      return false;
    }
  }
  
  /// Disconnect a client
  Future<void> disconnectClient(String deviceId) async {
    final client = _clients[deviceId];
    if (client != null) {
      await client.close();
      _removeClient(deviceId);
    }
  }
}

/// Internal client connection handler
class _ClientConnection {
  final Socket socket;
  final void Function(String deviceId, ProtocolMessage message) onMessage;
  final void Function(String deviceId) onDisconnected;
  
  String deviceId;
  final _sendLock = Lock();
  StreamSubscription? _subscription;
  
  _ClientConnection({
    required this.socket,
    required this.onMessage,
    required this.onDisconnected,
  }) : deviceId = '${socket.remoteAddress.address}:${socket.remotePort}';
  
  /// Start listening for messages
  void listen() {
    _subscription = socket.listen(
      _handleData,
      onError: (error) {
        debugPrint('[ClientConnection] Socket error: $error');
        close();
      },
      onDone: () {
        debugPrint('[ClientConnection] Socket closed: $deviceId');
        close();
      },
    );
  }
  
  /// Handle incoming data
  void _handleData(Uint8List data) {
    try {
      // Parse protocol message
      final message = ProtocolMessage.fromBytes(data);
      onMessage(deviceId, message);
    } catch (e) {
      debugPrint('[ClientConnection] Error parsing message: $e');
    }
  }
  
  /// Send message to client
  Future<void> sendMessage(ProtocolMessage message) async {
    await _sendLock.synchronized(() async {
      try {
        final data = message.toBytes();
        
        // Send length prefix (4 bytes, big-endian)
        final length = data.length;
        final lengthBytes = Uint8List(4)
          ..buffer.asByteData().setUint32(0, length, Endian.big);
        
        socket.add(lengthBytes);
        socket.add(data);
        await socket.flush();
        
        debugPrint('[ClientConnection] Sent message to $deviceId: ${message.type}');
      } catch (e) {
        debugPrint('[ClientConnection] Error sending message: $e');
        rethrow;
      }
    });
  }
  
  /// Close connection
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    
    try {
      await socket.close();
    } catch (e) {
      debugPrint('[ClientConnection] Error closing socket: $e');
    }
    
    onDisconnected(deviceId);
  }
}
