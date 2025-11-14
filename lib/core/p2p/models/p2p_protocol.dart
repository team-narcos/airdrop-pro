import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Protocol message types for P2P communication
enum MessageType {
  // Connection phase
  handshake,           // Initial connection request
  handshakeAck,        // Handshake acknowledgment
  keyExchange,         // ECDH public key exchange
  
  // Transfer phase
  fileOffer,           // Sender offers files to transfer
  fileAccept,          // Receiver accepts files
  fileReject,          // Receiver rejects files
  fileMetadata,        // File metadata (name, size, hash)
  
  // Data transfer
  chunkRequest,        // Request specific chunk
  chunkData,           // Chunk data payload
  chunkAck,            // Acknowledge chunk received
  
  // Control
  pause,               // Pause transfer
  resume,              // Resume transfer
  cancel,              // Cancel transfer
  complete,            // Transfer complete
  
  // Error handling
  error,               // Error message
  ping,                // Keep-alive ping
  pong,                // Keep-alive response
}

/// Base protocol message
@immutable
abstract class ProtocolMessage {
  final MessageType type;
  final String messageId;
  final DateTime timestamp;
  
  const ProtocolMessage({
    required this.type,
    required this.messageId,
    required this.timestamp,
  });
  
  /// Serialize message to JSON
  Map<String, dynamic> toJson();
  
  /// Serialize to bytes for network transmission
  Uint8List toBytes() {
    final json = toJson();
    final jsonString = jsonEncode(json);
    return Uint8List.fromList(utf8.encode(jsonString));
  }
  
  /// Deserialize from bytes
  static ProtocolMessage fromBytes(Uint8List bytes) {
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final type = MessageType.values[json['type'] as int];
    
    switch (type) {
      case MessageType.handshake:
        return HandshakeMessage.fromJson(json);
      case MessageType.handshakeAck:
        return HandshakeAckMessage.fromJson(json);
      case MessageType.keyExchange:
        return KeyExchangeMessage.fromJson(json);
      case MessageType.fileOffer:
        return FileOfferMessage.fromJson(json);
      case MessageType.fileAccept:
        return FileAcceptMessage.fromJson(json);
      case MessageType.fileReject:
        return FileRejectMessage.fromJson(json);
      case MessageType.fileMetadata:
        return FileMetadataMessage.fromJson(json);
      case MessageType.chunkRequest:
        return ChunkRequestMessage.fromJson(json);
      case MessageType.chunkData:
        return ChunkDataMessage.fromJson(json);
      case MessageType.chunkAck:
        return ChunkAckMessage.fromJson(json);
      case MessageType.pause:
      case MessageType.resume:
      case MessageType.cancel:
      case MessageType.complete:
        return ControlMessage.fromJson(json);
      case MessageType.error:
        return ErrorMessage.fromJson(json);
      case MessageType.ping:
      case MessageType.pong:
        return PingPongMessage.fromJson(json);
    }
  }
}

/// Handshake message - initial connection
class HandshakeMessage extends ProtocolMessage {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String version;
  final Map<String, String> capabilities;
  
  HandshakeMessage({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.version,
    required this.capabilities,
    String? messageId,
  }) : super(
    type: MessageType.handshake,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'deviceId': deviceId,
    'deviceName': deviceName,
    'platform': platform,
    'version': version,
    'capabilities': capabilities,
  };
  
  factory HandshakeMessage.fromJson(Map<String, dynamic> json) {
    return HandshakeMessage(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      platform: json['platform'] as String,
      version: json['version'] as String,
      capabilities: Map<String, String>.from(json['capabilities'] as Map),
      messageId: json['messageId'] as String,
    );
  }
}

/// Handshake acknowledgment
class HandshakeAckMessage extends ProtocolMessage {
  final String deviceId;
  final String deviceName;
  final bool accepted;
  final String? reason;
  
  HandshakeAckMessage({
    required this.deviceId,
    required this.deviceName,
    required this.accepted,
    this.reason,
    String? messageId,
  }) : super(
    type: MessageType.handshakeAck,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'deviceId': deviceId,
    'deviceName': deviceName,
    'accepted': accepted,
    if (reason != null) 'reason': reason,
  };
  
  factory HandshakeAckMessage.fromJson(Map<String, dynamic> json) {
    return HandshakeAckMessage(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      accepted: json['accepted'] as bool,
      reason: json['reason'] as String?,
      messageId: json['messageId'] as String,
    );
  }
}

/// Key exchange for encryption
class KeyExchangeMessage extends ProtocolMessage {
  final String publicKey;       // Base64 encoded ECDH public key
  final String algorithm;       // e.g., "ecdh-p256"
  
  KeyExchangeMessage({
    required this.publicKey,
    this.algorithm = 'ecdh-p256',
    String? messageId,
  }) : super(
    type: MessageType.keyExchange,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'publicKey': publicKey,
    'algorithm': algorithm,
  };
  
  factory KeyExchangeMessage.fromJson(Map<String, dynamic> json) {
    return KeyExchangeMessage(
      publicKey: json['publicKey'] as String,
      algorithm: json['algorithm'] as String? ?? 'ecdh-p256',
      messageId: json['messageId'] as String,
    );
  }
}

/// File offer - sender proposes files to transfer
class FileOfferMessage extends ProtocolMessage {
  final String transferId;
  final List<FileInfo> files;
  final int totalSize;
  
  FileOfferMessage({
    required this.transferId,
    required this.files,
    required this.totalSize,
    String? messageId,
  }) : super(
    type: MessageType.fileOffer,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'transferId': transferId,
    'files': files.map((f) => f.toJson()).toList(),
    'totalSize': totalSize,
  };
  
  factory FileOfferMessage.fromJson(Map<String, dynamic> json) {
    return FileOfferMessage(
      transferId: json['transferId'] as String,
      files: (json['files'] as List).map((f) => FileInfo.fromJson(f)).toList(),
      totalSize: json['totalSize'] as int,
      messageId: json['messageId'] as String,
    );
  }
}

/// File information
@immutable
class FileInfo {
  final String fileId;
  final String name;
  final int size;
  final String mimeType;
  final String? sha256;        // Optional hash for verification
  
  const FileInfo({
    required this.fileId,
    required this.name,
    required this.size,
    required this.mimeType,
    this.sha256,
  });
  
  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'name': name,
    'size': size,
    'mimeType': mimeType,
    if (sha256 != null) 'sha256': sha256,
  };
  
  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      fileId: json['fileId'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
      mimeType: json['mimeType'] as String,
      sha256: json['sha256'] as String?,
    );
  }
}

/// File accept - receiver accepts transfer
class FileAcceptMessage extends ProtocolMessage {
  final String transferId;
  final List<String> acceptedFileIds;
  final String savePath;
  
  FileAcceptMessage({
    required this.transferId,
    required this.acceptedFileIds,
    required this.savePath,
    String? messageId,
  }) : super(
    type: MessageType.fileAccept,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'transferId': transferId,
    'acceptedFileIds': acceptedFileIds,
    'savePath': savePath,
  };
  
  factory FileAcceptMessage.fromJson(Map<String, dynamic> json) {
    return FileAcceptMessage(
      transferId: json['transferId'] as String,
      acceptedFileIds: List<String>.from(json['acceptedFileIds'] as List),
      savePath: json['savePath'] as String,
      messageId: json['messageId'] as String,
    );
  }
}

/// File reject - receiver rejects transfer
class FileRejectMessage extends ProtocolMessage {
  final String transferId;
  final String reason;
  
  FileRejectMessage({
    required this.transferId,
    required this.reason,
    String? messageId,
  }) : super(
    type: MessageType.fileReject,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'transferId': transferId,
    'reason': reason,
  };
  
  factory FileRejectMessage.fromJson(Map<String, dynamic> json) {
    return FileRejectMessage(
      transferId: json['transferId'] as String,
      reason: json['reason'] as String,
      messageId: json['messageId'] as String,
    );
  }
}

/// File metadata message
class FileMetadataMessage extends ProtocolMessage {
  final String transferId;
  final String fileId;
  final int chunkSize;
  final int totalChunks;
  final String compression;
  
  FileMetadataMessage({
    required this.transferId,
    required this.fileId,
    required this.chunkSize,
    required this.totalChunks,
    this.compression = 'none',
    String? messageId,
  }) : super(
    type: MessageType.fileMetadata,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'transferId': transferId,
    'fileId': fileId,
    'chunkSize': chunkSize,
    'totalChunks': totalChunks,
    'compression': compression,
  };
  
  factory FileMetadataMessage.fromJson(Map<String, dynamic> json) {
    return FileMetadataMessage(
      transferId: json['transferId'] as String,
      fileId: json['fileId'] as String,
      chunkSize: json['chunkSize'] as int,
      totalChunks: json['totalChunks'] as int,
      compression: json['compression'] as String? ?? 'none',
      messageId: json['messageId'] as String,
    );
  }
}

/// Chunk request - receiver requests specific chunk
class ChunkRequestMessage extends ProtocolMessage {
  final String transferId;
  final String fileId;
  final int chunkIndex;
  
  ChunkRequestMessage({
    required this.transferId,
    required this.fileId,
    required this.chunkIndex,
    String? messageId,
  }) : super(
    type: MessageType.chunkRequest,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'transferId': transferId,
    'fileId': fileId,
    'chunkIndex': chunkIndex,
  };
  
  factory ChunkRequestMessage.fromJson(Map<String, dynamic> json) {
    return ChunkRequestMessage(
      transferId: json['transferId'] as String,
      fileId: json['fileId'] as String,
      chunkIndex: json['chunkIndex'] as int,
      messageId: json['messageId'] as String,
    );
  }
}

/// Chunk data - actual file chunk payload
class ChunkDataMessage extends ProtocolMessage {
  final String transferId;
  final String fileId;
  final int chunkIndex;
  final Uint8List data;
  final String? checksum;      // Optional SHA256 of chunk
  
  ChunkDataMessage({
    required this.transferId,
    required this.fileId,
    required this.chunkIndex,
    required this.data,
    this.checksum,
    String? messageId,
  }) : super(
    type: MessageType.chunkData,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'transferId': transferId,
    'fileId': fileId,
    'chunkIndex': chunkIndex,
    'data': base64Encode(data),
    if (checksum != null) 'checksum': checksum,
  };
  
  factory ChunkDataMessage.fromJson(Map<String, dynamic> json) {
    return ChunkDataMessage(
      transferId: json['transferId'] as String,
      fileId: json['fileId'] as String,
      chunkIndex: json['chunkIndex'] as int,
      data: base64Decode(json['data'] as String),
      checksum: json['checksum'] as String?,
      messageId: json['messageId'] as String,
    );
  }
}

/// Chunk acknowledgment
class ChunkAckMessage extends ProtocolMessage {
  final String transferId;
  final String fileId;
  final int chunkIndex;
  final bool success;
  final String? error;
  
  ChunkAckMessage({
    required this.transferId,
    required this.fileId,
    required this.chunkIndex,
    required this.success,
    this.error,
    String? messageId,
  }) : super(
    type: MessageType.chunkAck,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'transferId': transferId,
    'fileId': fileId,
    'chunkIndex': chunkIndex,
    'success': success,
    if (error != null) 'error': error,
  };
  
  factory ChunkAckMessage.fromJson(Map<String, dynamic> json) {
    return ChunkAckMessage(
      transferId: json['transferId'] as String,
      fileId: json['fileId'] as String,
      chunkIndex: json['chunkIndex'] as int,
      success: json['success'] as bool,
      error: json['error'] as String?,
      messageId: json['messageId'] as String,
    );
  }
}

/// Control message (pause, resume, cancel, complete)
class ControlMessage extends ProtocolMessage {
  final String transferId;
  final String? fileId;
  
  ControlMessage({
    required MessageType type,
    required this.transferId,
    this.fileId,
    String? messageId,
  }) : assert(
    type == MessageType.pause ||
    type == MessageType.resume ||
    type == MessageType.cancel ||
    type == MessageType.complete,
    'Invalid control message type'
  ), super(
    type: type,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'transferId': transferId,
    if (fileId != null) 'fileId': fileId,
  };
  
  factory ControlMessage.fromJson(Map<String, dynamic> json) {
    return ControlMessage(
      type: MessageType.values[json['type'] as int],
      transferId: json['transferId'] as String,
      fileId: json['fileId'] as String?,
      messageId: json['messageId'] as String,
    );
  }
}

/// Error message
class ErrorMessage extends ProtocolMessage {
  final String code;
  final String message;
  final String? transferId;
  
  ErrorMessage({
    required this.code,
    required this.message,
    this.transferId,
    String? messageId,
  }) : super(
    type: MessageType.error,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
    'code': code,
    'message': message,
    if (transferId != null) 'transferId': transferId,
  };
  
  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      code: json['code'] as String,
      message: json['message'] as String,
      transferId: json['transferId'] as String?,
      messageId: json['messageId'] as String,
    );
  }
}

/// Ping/Pong keep-alive message
class PingPongMessage extends ProtocolMessage {
  PingPongMessage({
    required MessageType type,
    String? messageId,
  }) : assert(
    type == MessageType.ping || type == MessageType.pong,
    'Must be ping or pong'
  ), super(
    type: type,
    messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.now(),
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'messageId': messageId,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory PingPongMessage.fromJson(Map<String, dynamic> json) {
    return PingPongMessage(
      type: MessageType.values[json['type'] as int],
      messageId: json['messageId'] as String,
    );
  }
}
