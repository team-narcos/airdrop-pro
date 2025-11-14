import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import 'mdns_discovery_service.dart';
import 'p2p_server.dart';
import 'p2p_client.dart';
import 'handshake_service.dart';
import 'crypto_service.dart';
import 'chunk_transfer_engine.dart';
import 'file_transfer_coordinator.dart';

/// Main P2P Manager
/// 
/// Orchestrates device discovery, connections, and file transfers
class P2PManager {
  // Services
  late final MDNSDiscoveryService _discoveryService;
  late final P2PServer _server;
  late final HandshakeService _handshakeService;
  late final CryptoService _cryptoService;
  late final ChunkTransferEngine _chunkEngine;
  late final FileTransferCoordinator _fileCoordinator;
  
  // Device info
  late String _deviceId;
  late String _deviceName;
  late String _platform;
  late DeviceCapabilities _capabilities;
  
  // Connections
  final Map<String, P2PClient> _clients = {};
  final Map<String, DeviceConnection> _connections = {};
  final _connectionsController = StreamController<List<DeviceConnection>>.broadcast();
  
  // State
  bool _isInitialized = false;
  bool _isRunning = false;
  
  // Connection health monitoring
  Timer? _healthCheckTimer;
  final _connectionHealthMonitor = <String, DateTime>{};
  
  P2PManager();
  
  /// Stream of active connections
  Stream<List<DeviceConnection>> get connectionsStream => _connectionsController.stream;
  
  /// Stream of discovered devices
  Stream<List<P2PDevice>> get devicesStream => _discoveryService.devicesStream;
  
  /// Get list of discovered devices
  List<P2PDevice> get discoveredDevices => _discoveryService.devices;
  
  /// Get list of active connections
  List<DeviceConnection> get connections => _connections.values.toList();
  
  /// Check if manager is running
  bool get isRunning => _isRunning;
  
  /// Get this device's ID
  String get deviceId => _deviceId;
  
  /// Get this device's name
  String get deviceName => _deviceName;
  
  /// Get file transfer coordinator
  FileTransferCoordinator get fileCoordinator => _fileCoordinator;
  
  /// Get chunk transfer engine
  ChunkTransferEngine get chunkEngine => _chunkEngine;
  
  /// Initialize the P2P manager
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[P2PManager] Already initialized');
      return;
    }
    
    debugPrint('[P2PManager] Initializing...');
    
    try {
      // Get device info
      await _initializeDeviceInfo();
      
      // Create services
      _capabilities = DeviceCapabilities.defaults();
      
      _discoveryService = MDNSDiscoveryService();
      
      _handshakeService = HandshakeService(
        deviceId: _deviceId,
        deviceName: _deviceName,
        platform: _platform,
        capabilities: _capabilities,
      );
      
      _cryptoService = CryptoService();
      _chunkEngine = ChunkTransferEngine();
      _fileCoordinator = FileTransferCoordinator(
        chunkEngine: _chunkEngine,
      );
      
      _server = P2PServer(
        onClientConnected: _handleIncomingConnection,
        onMessageReceived: _handleMessage,
        onClientDisconnected: _handleDisconnection,
        onError: (error) => debugPrint('[P2PManager] Server error: $error'),
      );
      
      _isInitialized = true;
      debugPrint('[P2PManager] Initialized successfully');
    } catch (e) {
      debugPrint('[P2PManager] Initialization failed: $e');
      rethrow;
    }
  }
  
  /// Start the P2P manager
  Future<void> start() async {
    if (!_isInitialized) {
      throw StateError('P2PManager not initialized. Call initialize() first.');
    }
    
    if (_isRunning) {
      debugPrint('[P2PManager] Already running');
      return;
    }
    
    debugPrint('[P2PManager] Starting...');
    
    try {
      // Start TCP server
      final port = await _server.start();
      debugPrint('[P2PManager] Server started on port $port');
      
      // Initialize and start mDNS discovery
      await _discoveryService.initialize(
        deviceName: _deviceName,
        port: port,
      );
      await _discoveryService.startDiscovery();
      
      // Start connection health monitoring
      _startHealthMonitoring();
      
      _isRunning = true;
      debugPrint('[P2PManager] Started successfully');
    } catch (e) {
      debugPrint('[P2PManager] Failed to start: $e');
      rethrow;
    }
  }
  
  /// Stop the P2P manager
  Future<void> stop() async {
    if (!_isRunning) return;
    
    debugPrint('[P2PManager] Stopping...');
    
    _isRunning = false;
    
    // Stop health monitoring
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _connectionHealthMonitor.clear();
    
    // Stop discovery
    await _discoveryService.stopDiscovery();
    
    // Disconnect all clients
    for (final client in _clients.values) {
      await client.disconnect();
    }
    _clients.clear();
    
    // Stop server
    await _server.stop();
    
    // Clear connections
    _connections.clear();
    _connectionsController.add([]);
    
    debugPrint('[P2PManager] Stopped');
  }
  
  /// Connect to a discovered device
  Future<bool> connectToDevice(P2PDevice device) async {
    if (!_isRunning) {
      debugPrint('[P2PManager] Cannot connect: manager not running');
      return false;
    }
    
    if (_connections.containsKey(device.id)) {
      debugPrint('[P2PManager] Already connected to ${device.name}');
      return true;
    }
    
    debugPrint('[P2PManager] Connecting to ${device.name}...');
    
    try {
      // Create client
      final client = P2PClient(
        onConnected: () {
          debugPrint('[P2PManager] Connected to ${device.name}');
        },
        onMessageReceived: (message) {
          _handleMessage(device.id, message);
        },
        onDisconnected: () {
          _handleDisconnection(device.id);
        },
        onError: (error) {
          debugPrint('[P2PManager] Client error: $error');
        },
      );
      
      // Connect
      final connected = await client.connect(device);
      if (!connected) {
        debugPrint('[P2PManager] Failed to connect to ${device.name}');
        return false;
      }
      
      _clients[device.id] = client;
      
      // Perform handshake
      final handshakeResult = await _handshakeService.initiateHandshake(client);
      
      if (!handshakeResult.success) {
        debugPrint('[P2PManager] Handshake failed: ${handshakeResult.errorMessage}');
        await client.disconnect();
        _clients.remove(device.id);
        return false;
      }
      
      // Perform ECDH key exchange for encryption
      try {
        await _cryptoService.generateKeyPair();
        final publicKey = _cryptoService.getPublicKeyBase64();
        
        // Send key exchange message
        await client.sendMessage(
          KeyExchangeMessage(publicKey: publicKey),
        );
        
        debugPrint('[P2PManager] Key exchange initiated');
      } catch (e) {
        debugPrint('[P2PManager] Key exchange failed: $e');
        // Continue without encryption
      }
      
      // Create connection
      final connection = DeviceConnection(
        device: device.copyWith(isConnected: true),
        status: DeviceStatus.ready,
        connectedAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      
      _connections[device.id] = connection;
      _connectionsController.add(connections);
      
      debugPrint('[P2PManager] Successfully connected to ${device.name}');
      return true;
    } catch (e) {
      debugPrint('[P2PManager] Error connecting to ${device.name}: $e');
      return false;
    }
  }
  
  /// Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    final client = _clients[deviceId];
    if (client != null) {
      await client.disconnect();
      _clients.remove(deviceId);
    }
    
    _connections.remove(deviceId);
    _connectionsController.add(connections);
    
    debugPrint('[P2PManager] Disconnected from device: $deviceId');
  }
  
  /// Send files to a connected device
  Future<String> sendFiles({
    required List<String> filePaths,
    required P2PDevice device,
  }) async {
    debugPrint('[P2PManager] Sending ${filePaths.length} files to ${device.name}');
    
    final client = _clients[device.id];
    if (client == null) {
      throw Exception('Device not connected');
    }
    
    return await _fileCoordinator.sendFiles(
      filePaths: filePaths,
      device: device,
      client: client,
    );
  }
  
  /// Handle incoming connection
  void _handleIncomingConnection(Socket socket, String tempId) async {
    debugPrint('[P2PManager] Incoming connection: $tempId');
    
    // Wait for handshake message
    // The handshake will be handled in _handleMessage
  }
  
  /// Handle incoming message
  void _handleMessage(String deviceId, ProtocolMessage message) async {
    debugPrint('[P2PManager] Received message from $deviceId: ${message.type}');
    
    // Update connection activity
    final connection = _connections[deviceId];
    if (connection != null) {
      _connections[deviceId] = connection.updateActivity();
    }
    
    switch (message.type) {
      case MessageType.handshake:
        await _handleHandshakeMessage(deviceId, message as HandshakeMessage);
        break;
        
      case MessageType.handshakeAck:
        _handshakeService.handleHandshakeAck(message as HandshakeAckMessage);
        break;
      
      case MessageType.keyExchange:
        await _handleKeyExchange(deviceId, message as KeyExchangeMessage);
        break;
        
      case MessageType.ping:
        // Respond with pong
        final client = _clients[deviceId];
        await client?.sendPong();
        break;
        
      case MessageType.pong:
        // Keep-alive received - update health monitor
        _connectionHealthMonitor[deviceId] = DateTime.now();
        break;
        
      case MessageType.fileOffer:
        await _handleFileOffer(deviceId, message as FileOfferMessage);
        break;
        
      case MessageType.error:
        final error = message as ErrorMessage;
        debugPrint('[P2PManager] Error from $deviceId: ${error.message}');
        break;
        
      default:
        debugPrint('[P2PManager] Unhandled message type: ${message.type}');
    }
  }
  
  /// Handle handshake message from incoming connection
  Future<void> _handleHandshakeMessage(String tempId, HandshakeMessage message) async {
    // Auto-accept for now (in production, show user prompt)
    final response = await _handshakeService.handleHandshakeRequest(
      message,
      (deviceId, deviceName) async {
        // TODO: Show user confirmation dialog
        debugPrint('[P2PManager] Auto-accepting connection from $deviceName');
        return true;
      },
    );
    
    // Send response
    final success = await _server.sendMessage(
      tempId,
      HandshakeAckMessage(
        deviceId: _deviceId,
        deviceName: _deviceName,
        accepted: response.accepted,
        reason: response.reason,
      ),
    );
    
    if (!success) {
      debugPrint('[P2PManager] Failed to send handshake ack');
      await _server.disconnectClient(tempId);
      return;
    }
    
    if (!response.accepted) {
      debugPrint('[P2PManager] Connection rejected');
      await _server.disconnectClient(tempId);
      return;
    }
    
    // Update client ID
    await _server.updateClientId(tempId, message.deviceId);
    
    // Create connection
    if (response.remoteDevice != null) {
      final connection = DeviceConnection(
        device: response.remoteDevice!,
        status: DeviceStatus.ready,
        connectedAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      
      _connections[message.deviceId] = connection;
      _connectionsController.add(connections);
      
      debugPrint('[P2PManager] Connection established with ${message.deviceName}');
    }
  }
  
  /// Handle disconnection
  void _handleDisconnection(String deviceId) {
    debugPrint('[P2PManager] Device disconnected: $deviceId');
    
    _clients.remove(deviceId);
    _connections.remove(deviceId);
    _connectionsController.add(connections);
  }
  
  /// Handle key exchange message
  Future<void> _handleKeyExchange(String deviceId, KeyExchangeMessage message) async {
    debugPrint('[P2PManager] Received key exchange from $deviceId');
    
    try {
      // If we haven't generated our keys yet, do it now
      try {
        _cryptoService.getPublicKeyBase64();
      } catch (_) {
        await _cryptoService.generateKeyPair();
      }
      
      // Perform key exchange with peer's public key
      await _cryptoService.performKeyExchange(message.publicKey);
      
      // Update connection to mark as encrypted
      final connection = _connections[deviceId];
      if (connection != null) {
        _connections[deviceId] = connection.copyWith(isEncrypted: true);
        _connectionsController.add(connections);
      }
      
      debugPrint('[P2PManager] Key exchange complete with $deviceId');
    } catch (e) {
      debugPrint('[P2PManager] Key exchange error: $e');
    }
  }
  
  /// Handle incoming file offer
  Future<void> _handleFileOffer(String deviceId, FileOfferMessage offer) async {
    debugPrint('[P2PManager] Received file offer from $deviceId');
    
    final connection = _connections[deviceId];
    if (connection == null) {
      debugPrint('[P2PManager] Connection not found for $deviceId');
      return;
    }
    
    try {
      await _fileCoordinator.handleFileOffer(
        offer: offer,
        fromDevice: connection.device,
        server: _server,
        shouldAccept: (offer) async {
          // Auto-accept for now (in production, show user prompt)
          debugPrint('[P2PManager] Auto-accepting file offer: ${offer.files.length} files');
          return true;
        },
        getSavePath: () async {
          // Get Downloads directory
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            final downloadsDir = await getDownloadsDirectory();
            if (downloadsDir != null) {
              return downloadsDir.path;
            }
          }
          // Fallback to app documents
          final appDir = await getApplicationDocumentsDirectory();
          return appDir.path;
        },
      );
      
      debugPrint('[P2PManager] File offer accepted');
    } catch (e) {
      debugPrint('[P2PManager] Error handling file offer: $e');
    }
  }
  
  /// Initialize device information
  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        _deviceName = info.computerName;
        _platform = 'windows';
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        _deviceName = info.computerName;
        _platform = 'macos';
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        _deviceName = info.name;
        _platform = 'linux';
      } else if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _deviceName = info.model;
        _platform = 'android';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        _deviceName = info.name;
        _platform = 'ios';
      } else {
        _deviceName = 'Unknown Device';
        _platform = 'unknown';
      }
      
      // Generate device ID (in production, this should be persistent)
      _deviceId = '${_platform}_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('[P2PManager] Device: $_deviceName ($_platform) ID: $_deviceId');
    } catch (e) {
      debugPrint('[P2PManager] Error getting device info: $e');
      _deviceName = 'AirDrop Pro Device';
      _platform = 'unknown';
      _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// Start connection health monitoring
  void _startHealthMonitoring() {
    // Check connections every 30 seconds
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      
      debugPrint('[P2PManager] Running connection health check...');
      final now = DateTime.now();
      final staleConnections = <String>[];
      
      // Check each connection
      for (final entry in _connections.entries) {
        final deviceId = entry.key;
        final connection = entry.value;
        
        // Check if connection has been inactive for too long (60 seconds)
        final lastActivity = connection.lastActivity;
        final inactiveDuration = lastActivity != null 
            ? now.difference(lastActivity)
            : Duration.zero;
        
        if (inactiveDuration.inSeconds > 60) {
          debugPrint('[P2PManager] Connection to $deviceId is stale');
          staleConnections.add(deviceId);
          continue;
        }
        
        // Send ping to check if connection is alive
        final client = _clients[deviceId];
        if (client != null) {
          try {
            await client.sendPing();
            _connectionHealthMonitor[deviceId] = now;
          } catch (e) {
            debugPrint('[P2PManager] Failed to ping $deviceId: $e');
            staleConnections.add(deviceId);
          }
        }
      }
      
      // Clean up stale connections
      for (final deviceId in staleConnections) {
        debugPrint('[P2PManager] Cleaning up stale connection: $deviceId');
        _handleDisconnection(deviceId);
      }
    });
    
    debugPrint('[P2PManager] Connection health monitoring started');
  }
  
  /// Dispose resources
  void dispose() {
    stop();
    _discoveryService.dispose();
    _handshakeService.dispose();
    _cryptoService.dispose();
    _chunkEngine.dispose();
    _fileCoordinator.dispose();
    _connectionsController.close();
  }
}
