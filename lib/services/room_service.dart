import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class RoomService {
  WebSocketChannel? _channel;
  WebSocketSink? get sink => _channel?.sink;
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  
  final _messagesController = StreamController<RoomMessage>.broadcast();
  final _participantsController = StreamController<List<RoomParticipant>>.broadcast();
  final _roomStateController = StreamController<RoomState>.broadcast();
  
  Stream<RoomMessage> get messagesStream => _messagesController.stream;
  Stream<List<RoomParticipant>> get participantsStream => _participantsController.stream;
  Stream<RoomState> get roomStateStream => _roomStateController.stream;
  
  String? _roomCode;
  String? _myDeviceId;
  String? _myDeviceName;
  bool _isHost = false;
  final List<RoomParticipant> _participants = [];
  RoomSettings? _roomSettings;
  
  /// Create a new room
  Future<String> createRoom({
    required String deviceId,
    required String deviceName,
    required RoomSettings settings,
  }) async {
    _myDeviceId = deviceId;
    _myDeviceName = deviceName;
    _isHost = true;
    _roomSettings = settings;
    _roomCode = _generateRoomCode();
    
    // Start WebSocket server
    _server = await HttpServer.bind('0.0.0.0', 37778);
    _server!.transform(WebSocketTransformer()).listen(_handleClientConnection);
    
    // Add self as first participant
    final me = RoomParticipant(
      id: deviceId,
      name: deviceName,
      isHost: true,
      isReady: true,
      joinedAt: DateTime.now(),
    );
    _participants.add(me);
    _participantsController.add(_participants);
    
    _roomStateController.add(RoomState(
      code: _roomCode!,
      isActive: true,
      participantCount: 1,
      maxParticipants: settings.maxParticipants,
    ));
    
    return _roomCode!;
  }
  
  /// Join an existing room
  Future<void> joinRoom({
    required String code,
    required String ipAddress,
    required String deviceId,
    required String deviceName,
  }) async {
    _myDeviceId = deviceId;
    _myDeviceName = deviceName;
    _isHost = false;
    _roomCode = code;
    
    _channel = IOWebSocketChannel.connect(
      Uri.parse('ws://$ipAddress:37778'),
    );
    
    // Send join request
    _sendMessage({
      'type': 'join',
      'deviceId': deviceId,
      'deviceName': deviceName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Listen to messages
    _channel!.stream.listen(
      _handleServerMessage,
      onDone: () => _handleDisconnect(),
      onError: (error) => print('WebSocket error: $error'),
    );
  }
  
  void _handleClientConnection(WebSocket client) {
    _clients.add(client);
    
    client.listen(
      (message) => _handleClientMessage(client, message),
      onDone: () {
        _clients.remove(client);
        _broadcastParticipantUpdate();
      },
      onError: (error) {
        _clients.remove(client);
        print('Client error: $error');
      },
    );
  }
  
  void _handleClientMessage(WebSocket client, dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String;
      
      switch (type) {
        case 'join':
          _handleJoinRequest(client, data);
          break;
        case 'chat':
          _broadcastMessage(data);
          break;
        case 'file_offer':
          _broadcastMessage(data);
          break;
        case 'ready':
          _handleReadyUpdate(data);
          break;
        case 'leave':
          _handleLeave(data);
          break;
      }
    } catch (e) {
      print('Error handling client message: $e');
    }
  }
  
  void _handleJoinRequest(WebSocket client, Map<String, dynamic> data) {
    if (_roomSettings != null && _participants.length >= _roomSettings!.maxParticipants) {
      client.add(jsonEncode({'type': 'error', 'message': 'Room is full'}));
      client.close();
      return;
    }
    
    final participant = RoomParticipant(
      id: data['deviceId'],
      name: data['deviceName'],
      isHost: false,
      isReady: false,
      joinedAt: DateTime.now(),
    );
    
    _participants.add(participant);
    _participantsController.add(_participants);
    _broadcastParticipantUpdate();
    
    // Send welcome message to new client
    client.add(jsonEncode({
      'type': 'welcome',
      'roomCode': _roomCode,
      'participants': _participants.map((p) => p.toJson()).toList(),
    }));
  }
  
  void _handleServerMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String;
      
      switch (type) {
        case 'welcome':
          _handleWelcome(data);
          break;
        case 'participant_update':
          _handleParticipantUpdate(data);
          break;
        case 'chat':
          _handleChatMessage(data);
          break;
        case 'file_offer':
          _handleFileOffer(data);
          break;
        case 'error':
          print('Room error: ${data['message']}');
          break;
      }
    } catch (e) {
      print('Error handling server message: $e');
    }
  }
  
  void _handleWelcome(Map<String, dynamic> data) {
    _participants.clear();
    final participantsList = data['participants'] as List;
    for (final p in participantsList) {
      _participants.add(RoomParticipant.fromJson(p));
    }
    _participantsController.add(_participants);
  }
  
  void _handleParticipantUpdate(Map<String, dynamic> data) {
    _participants.clear();
    final participantsList = data['participants'] as List;
    for (final p in participantsList) {
      _participants.add(RoomParticipant.fromJson(p));
    }
    _participantsController.add(_participants);
  }
  
  void _handleChatMessage(Map<String, dynamic> data) {
    _messagesController.add(RoomMessage(
      type: RoomMessageType.chat,
      sender: data['sender'],
      content: data['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
    ));
  }
  
  void _handleFileOffer(Map<String, dynamic> data) {
    _messagesController.add(RoomMessage(
      type: RoomMessageType.fileOffer,
      sender: data['sender'],
      content: data['fileName'],
      metadata: {'fileSize': data['fileSize']},
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
    ));
  }
  
  void _handleReadyUpdate(Map<String, dynamic> data) {
    final deviceId = data['deviceId'];
    final isReady = data['isReady'] as bool;
    
    final participant = _participants.firstWhere((p) => p.id == deviceId);
    _participants[_participants.indexOf(participant)] = participant.copyWith(isReady: isReady);
    _participantsController.add(_participants);
    _broadcastParticipantUpdate();
  }
  
  void _handleLeave(Map<String, dynamic> data) {
    _participants.removeWhere((p) => p.id == data['deviceId']);
    _participantsController.add(_participants);
    _broadcastParticipantUpdate();
  }
  
  void _handleDisconnect() {
    _messagesController.add(RoomMessage(
      type: RoomMessageType.system,
      sender: 'System',
      content: 'Disconnected from room',
      timestamp: DateTime.now(),
    ));
  }
  
  void _broadcastMessage(Map<String, dynamic> data) {
    final message = jsonEncode(data);
    for (final client in _clients) {
      try {
        client.add(message);
      } catch (e) {
        print('Error broadcasting to client: $e');
      }
    }
  }
  
  void _broadcastParticipantUpdate() {
    _broadcastMessage({
      'type': 'participant_update',
      'participants': _participants.map((p) => p.toJson()).toList(),
    });
  }
  
  void _sendMessage(Map<String, dynamic> data) {
    sink?.add(jsonEncode(data));
  }
  
  /// Send chat message
  void sendChat(String message) {
    final data = {
      'type': 'chat',
      'sender': _myDeviceName,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (_isHost) {
      _broadcastMessage(data);
      _handleChatMessage(data);
    } else {
      _sendMessage(data);
    }
  }
  
  /// Share file
  void shareFile(String fileName, int fileSize) {
    final data = {
      'type': 'file_offer',
      'sender': _myDeviceName,
      'fileName': fileName,
      'fileSize': fileSize,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (_isHost) {
      _broadcastMessage(data);
      _handleFileOffer(data);
    } else {
      _sendMessage(data);
    }
  }
  
  /// Update ready status
  void setReady(bool isReady) {
    _sendMessage({
      'type': 'ready',
      'deviceId': _myDeviceId,
      'isReady': isReady,
    });
  }
  
  /// Kick participant (host only)
  void kickParticipant(String participantId) {
    if (!_isHost) return;
    
    _participants.removeWhere((p) => p.id == participantId);
    _participantsController.add(_participants);
    _broadcastParticipantUpdate();
    
    // Close WebSocket for kicked participant
    // Implementation depends on mapping participants to clients
  }
  
  /// Leave room
  Future<void> leaveRoom() async {
    _sendMessage({
      'type': 'leave',
      'deviceId': _myDeviceId,
    });
    
    await Future.delayed(const Duration(milliseconds: 100));
    await close();
  }
  
  /// Close room and cleanup
  Future<void> close() async {
    _channel?.sink.close();
    _server?.close();
    
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    
    await _messagesController.close();
    await _participantsController.close();
    await _roomStateController.close();
  }
  
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

class RoomSettings {
  final int maxParticipants;
  final int duration; // minutes
  final bool requirePassword;
  final String? password;
  
  RoomSettings({
    required this.maxParticipants,
    required this.duration,
    this.requirePassword = false,
    this.password,
  });
}

class RoomParticipant {
  final String id;
  final String name;
  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;
  
  RoomParticipant({
    required this.id,
    required this.name,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
  });
  
  RoomParticipant copyWith({
    String? id,
    String? name,
    bool? isHost,
    bool? isReady,
    DateTime? joinedAt,
  }) {
    return RoomParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isHost': isHost,
    'isReady': isReady,
    'joinedAt': joinedAt.millisecondsSinceEpoch,
  };
  
  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      id: json['id'],
      name: json['name'],
      isHost: json['isHost'] ?? false,
      isReady: json['isReady'] ?? false,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joinedAt']),
    );
  }
}

class RoomMessage {
  final RoomMessageType type;
  final String sender;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  
  RoomMessage({
    required this.type,
    required this.sender,
    required this.content,
    this.metadata,
    required this.timestamp,
  });
}

enum RoomMessageType {
  chat,
  fileOffer,
  system,
}

class RoomState {
  final String code;
  final bool isActive;
  final int participantCount;
  final int maxParticipants;
  
  RoomState({
    required this.code,
    required this.isActive,
    required this.participantCount,
    required this.maxParticipants,
  });
}
