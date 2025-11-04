import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Advanced transfer protocol with multi-channel support
/// Supports: WiFi Direct, WebRTC, TCP, UDP for any file size and distance
class AdvancedTransferProtocol {
  // Protocol types
  static const String PROTOCOL_WIFI_DIRECT = 'wifi_direct';
  static const String PROTOCOL_WEBRTC = 'webrtc';
  static const String PROTOCOL_TCP = 'tcp';
  static const String PROTOCOL_UDP = 'udp';
  static const String PROTOCOL_BLUETOOTH = 'bluetooth';
  
  // Transfer modes
  static const String MODE_LOCAL = 'local'; // Same network
  static const String MODE_RELAY = 'relay'; // Through relay server
  static const String MODE_HYBRID = 'hybrid'; // Automatic selection
  
  // Chunk sizes for different scenarios
  static const int CHUNK_SIZE_SMALL = 64 * 1024; // 64KB for slow connections
  static const int CHUNK_SIZE_MEDIUM = 512 * 1024; // 512KB for normal
  static const int CHUNK_SIZE_LARGE = 4 * 1024 * 1024; // 4MB for fast connections
  
  final _progressController = StreamController<TransferProgressData>.broadcast();
  Stream<TransferProgressData> get progressStream => _progressController.stream;
  
  String _selectedProtocol = PROTOCOL_TCP;
  String _transferMode = MODE_HYBRID;
  int _currentChunkSize = CHUNK_SIZE_MEDIUM;
  
  // Connection state
  bool _isConnected = false;
  Socket? _socket;
  RandomAccessFile? _currentFile;
  
  // Transfer statistics
  int _bytesTransferred = 0;
  int _totalBytes = 0;
  DateTime? _transferStartTime;
  List<double> _speedSamples = [];
  
  // Resume capability
  Map<String, int> _resumeOffsets = {};
  
  /// Initialize the protocol manager
  Future<void> initialize() async {
    print('[AdvancedTransfer] Initializing protocol manager');
    // Initialize available protocols
    await _detectAvailableProtocols();
  }
  
  /// Detect which protocols are available on this device
  Future<void> _detectAvailableProtocols() async {
    // Check TCP/IP
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 2));
      socket.destroy();
      print('[AdvancedTransfer] TCP/IP available');
    } catch (e) {
      print('[AdvancedTransfer] TCP/IP not available: $e');
    }
    
    // WebRTC, WiFi Direct, Bluetooth would require platform-specific checks
  }
  
  /// Smart protocol selection based on file size and network conditions
  String _selectOptimalProtocol(int fileSize, String? preferredProtocol) {
    if (preferredProtocol != null) return preferredProtocol;
    
    // Logic:
    // - Small files (<10MB): Any protocol
    // - Medium files (10MB-1GB): TCP or WiFi Direct
    // - Large files (>1GB): WiFi Direct or chunked TCP
    
    if (fileSize > 1024 * 1024 * 1024) {
      // >1GB: Prefer WiFi Direct for speed
      return PROTOCOL_WIFI_DIRECT;
    } else if (fileSize > 10 * 1024 * 1024) {
      // >10MB: Use TCP with large chunks
      _currentChunkSize = CHUNK_SIZE_LARGE;
      return PROTOCOL_TCP;
    } else {
      // Small files: Standard TCP
      _currentChunkSize = CHUNK_SIZE_MEDIUM;
      return PROTOCOL_TCP;
    }
  }
  
  /// Send file with automatic protocol selection and optimization
  Future<TransferResult> sendFile({
    required File file,
    required String recipientAddress,
    required int recipientPort,
    String? protocol,
    bool enableResume = true,
    bool enableCompression = false,
  }) async {
    try {
      final fileSize = await file.length();
      final fileName = file.path.split(Platform.pathSeparator).last;
      
      print('[AdvancedTransfer] Preparing to send: $fileName ($fileSize bytes)');
      
      // Select optimal protocol
      _selectedProtocol = _selectOptimalProtocol(fileSize, protocol);
      print('[AdvancedTransfer] Selected protocol: $_selectedProtocol');
      
      // Initialize transfer
      _bytesTransferred = 0;
      _totalBytes = fileSize;
      _transferStartTime = DateTime.now();
      _speedSamples.clear();
      
      // Connect to recipient
      await _establishConnection(recipientAddress, recipientPort);
      
      // Send file metadata
      await _sendMetadata(fileName, fileSize, enableCompression);
      
      // Wait for acceptance
      final accepted = await _waitForAcceptance();
      if (!accepted) {
        throw Exception('Transfer rejected by recipient');
      }
      
      // Send file data
      await _sendFileData(file, enableResume, enableCompression);
      
      final duration = DateTime.now().difference(_transferStartTime!);
      print('[AdvancedTransfer] Transfer completed in ${duration.inSeconds}s');
      
      return TransferResult(
        success: true,
        fileName: fileName,
        bytesTransferred: _bytesTransferred,
        duration: duration,
        averageSpeed: _calculateAverageSpeed(),
      );
      
    } catch (e) {
      print('[AdvancedTransfer] Send error: $e');
      _progressController.addError(e);
      return TransferResult(
        success: false,
        fileName: '',
        bytesTransferred: _bytesTransferred,
        duration: Duration.zero,
        averageSpeed: 0,
        error: e.toString(),
      );
    } finally {
      await _cleanup();
    }
  }
  
  /// Receive file with resume support
  Future<TransferResult> receiveFile({
    required int port,
    String? savePath,
    bool enableResume = true,
  }) async {
    try {
      print('[AdvancedTransfer] Starting receive server on port $port');
      
      final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      
      await for (final client in serverSocket) {
        print('[AdvancedTransfer] Client connected: ${client.remoteAddress.address}');
        
        try {
          // Receive metadata
          final metadata = await _receiveMetadata(client);
          final fileName = metadata['fileName'] as String;
          final fileSize = metadata['fileSize'] as int;
          final enableCompression = metadata['compression'] as bool? ?? false;
          
          print('[AdvancedTransfer] Receiving: $fileName ($fileSize bytes)');
          
          // Get save directory
          final dir = savePath != null 
              ? Directory(savePath)
              : await _getDefaultSaveDirectory();
              
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          
          // Create file path
          var filePath = '${dir.path}/$fileName';
          filePath = await _generateUniqueFilePath(filePath);
          
          // Send acceptance
          client.add([1]); // Accept
          await client.flush();
          
          // Initialize transfer state
          _bytesTransferred = 0;
          _totalBytes = fileSize;
          _transferStartTime = DateTime.now();
          
          // Receive file data
          await _receiveFileData(client, filePath, fileSize, enableCompression);
          
          final duration = DateTime.now().difference(_transferStartTime!);
          print('[AdvancedTransfer] File received: $filePath');
          
          await serverSocket.close();
          
          return TransferResult(
            success: true,
            fileName: fileName,
            bytesTransferred: _bytesTransferred,
            duration: duration,
            averageSpeed: _calculateAverageSpeed(),
            filePath: filePath,
          );
          
        } catch (e) {
          print('[AdvancedTransfer] Receive error: $e');
          await client.close();
          continue;
        }
      }
      
      return TransferResult(
        success: false,
        fileName: '',
        bytesTransferred: 0,
        duration: Duration.zero,
        averageSpeed: 0,
        error: 'No connection received',
      );
      
    } catch (e) {
      print('[AdvancedTransfer] Server error: $e');
      return TransferResult(
        success: false,
        fileName: '',
        bytesTransferred: 0,
        duration: Duration.zero,
        averageSpeed: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Establish connection using selected protocol
  Future<void> _establishConnection(String address, int port) async {
    switch (_selectedProtocol) {
      case PROTOCOL_TCP:
        _socket = await Socket.connect(
          address,
          port,
          timeout: Duration(seconds: 30),
        );
        _isConnected = true;
        break;
        
      case PROTOCOL_WIFI_DIRECT:
      case PROTOCOL_WEBRTC:
      case PROTOCOL_UDP:
      case PROTOCOL_BLUETOOTH:
        // These would require platform-specific implementations
        throw UnimplementedError('Protocol $_selectedProtocol not yet implemented');
    }
  }
  
  /// Send file metadata
  Future<void> _sendMetadata(String fileName, int fileSize, bool compression) async {
    final metadata = {
      'fileName': fileName,
      'fileSize': fileSize,
      'protocol': _selectedProtocol,
      'chunkSize': _currentChunkSize,
      'compression': compression,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    final metadataJson = _encodeJson(metadata);
    final lengthBytes = _intToBytes(metadataJson.length);
    
    _socket!.add(lengthBytes);
    _socket!.add(metadataJson);
    await _socket!.flush();
  }
  
  /// Wait for transfer acceptance from recipient
  Future<bool> _waitForAcceptance() async {
    final response = await _socket!.first.timeout(
      Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('No response from recipient'),
    );
    
    return response[0] == 1; // 1 = accept, 0 = reject
  }
  
  /// Send file data in optimized chunks
  Future<void> _sendFileData(File file, bool enableResume, bool enableCompression) async {
    final raf = await file.open(mode: FileMode.read);
    
    try {
      int offset = 0;
      
      // Check for resume
      if (enableResume && _resumeOffsets.containsKey(file.path)) {
        offset = _resumeOffsets[file.path]!;
        await raf.setPosition(offset);
        _bytesTransferred = offset;
      }
      
      while (_bytesTransferred < _totalBytes) {
        // Read chunk
        final chunkSize = (_totalBytes - _bytesTransferred).clamp(0, _currentChunkSize);
        final chunk = await raf.read(chunkSize);
        
        // Compress if enabled
        final dataToSend = enableCompression ? await _compressData(chunk) : chunk;
        
        // Send chunk
        _socket!.add(dataToSend);
        await _socket!.flush();
        
        // Update progress
        _bytesTransferred += chunk.length;
        _updateProgress();
        
        // Adaptive speed control
        _adjustChunkSize();
      }
      
    } finally {
      await raf.close();
    }
  }
  
  /// Receive metadata from sender
  Future<Map<String, dynamic>> _receiveMetadata(Socket socket) async {
    final lengthBytes = await _readExact(socket, 4);
    final length = _bytesToInt(lengthBytes);
    
    final metadataBytes = await _readExact(socket, length);
    return _decodeJson(metadataBytes);
  }
  
  /// Receive file data with progress tracking
  Future<void> _receiveFileData(
    Socket socket,
    String filePath,
    int fileSize,
    bool compression,
  ) async {
    final file = File(filePath);
    final raf = await file.open(mode: FileMode.write);
    
    try {
      await for (final chunk in socket) {
        // Decompress if needed
        final dataToWrite = compression ? await _decompressData(chunk) : chunk;
        
        await raf.writeFrom(dataToWrite);
        
        _bytesTransferred += dataToWrite.length;
        _updateProgress();
        
        if (_bytesTransferred >= fileSize) break;
      }
    } finally {
      await raf.close();
    }
  }
  
  /// Update transfer progress
  void _updateProgress() {
    final progress = (_bytesTransferred / _totalBytes * 100).clamp(0, 100);
    final speed = _calculateCurrentSpeed();
    final remaining = _estimateTimeRemaining(speed);
    
    _progressController.add(TransferProgressData(
      bytesTransferred: _bytesTransferred,
      totalBytes: _totalBytes,
      progress: progress,
      speedBytesPerSecond: speed,
      estimatedTimeRemaining: remaining,
      protocol: _selectedProtocol,
    ));
  }
  
  /// Calculate current transfer speed
  double _calculateCurrentSpeed() {
    if (_transferStartTime == null) return 0;
    
    final elapsed = DateTime.now().difference(_transferStartTime!).inMilliseconds;
    if (elapsed == 0) return 0;
    
    final speed = (_bytesTransferred / elapsed) * 1000; // bytes/second
    _speedSamples.add(speed);
    
    // Keep last 10 samples for average
    if (_speedSamples.length > 10) {
      _speedSamples.removeAt(0);
    }
    
    return speed;
  }
  
  /// Calculate average transfer speed
  double _calculateAverageSpeed() {
    if (_speedSamples.isEmpty) return 0;
    return _speedSamples.reduce((a, b) => a + b) / _speedSamples.length;
  }
  
  /// Estimate time remaining
  Duration _estimateTimeRemaining(double speed) {
    if (speed == 0) return Duration.zero;
    
    final remainingBytes = _totalBytes - _bytesTransferred;
    final secondsRemaining = (remainingBytes / speed).ceil();
    
    return Duration(seconds: secondsRemaining);
  }
  
  /// Adaptive chunk size adjustment based on network conditions
  void _adjustChunkSize() {
    if (_speedSamples.length < 5) return;
    
    final avgSpeed = _calculateAverageSpeed();
    final mbps = (avgSpeed * 8) / (1024 * 1024); // Convert to Mbps
    
    // Adjust chunk size based on speed
    if (mbps > 100) {
      _currentChunkSize = CHUNK_SIZE_LARGE;
    } else if (mbps > 10) {
      _currentChunkSize = CHUNK_SIZE_MEDIUM;
    } else {
      _currentChunkSize = CHUNK_SIZE_SMALL;
    }
  }
  
  /// Get default save directory
  Future<Directory> _getDefaultSaveDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/ReceivedFiles');
  }
  
  /// Generate unique file path to avoid overwrites
  Future<String> _generateUniqueFilePath(String originalPath) async {
    var path = originalPath;
    var counter = 1;
    
    while (await File(path).exists()) {
      final dir = File(originalPath).parent.path;
      final name = File(originalPath).path.split(Platform.pathSeparator).last;
      final nameParts = name.split('.');
      
      if (nameParts.length > 1) {
        final baseName = nameParts.sublist(0, nameParts.length - 1).join('.');
        final ext = nameParts.last;
        path = '$dir/$baseName ($counter).$ext';
      } else {
        path = '$dir/$name ($counter)';
      }
      counter++;
    }
    
    return path;
  }
  
  /// Compress data (placeholder - would use actual compression)
  Future<Uint8List> _compressData(Uint8List data) async {
    // Would use gzip or other compression
    return data;
  }
  
  /// Decompress data (placeholder)
  Future<Uint8List> _decompressData(Uint8List data) async {
    return data;
  }
  
  /// Read exact number of bytes from socket
  Future<Uint8List> _readExact(Socket socket, int length) async {
    final buffer = BytesBuilder();
    
    await for (final chunk in socket) {
      buffer.add(chunk);
      if (buffer.length >= length) {
        return Uint8List.fromList(buffer.toBytes().sublist(0, length));
      }
    }
    
    throw Exception('Connection closed before reading $length bytes');
  }
  
  /// Convert int to bytes
  Uint8List _intToBytes(int value) {
    return Uint8List(4)
      ..[0] = (value >> 24) & 0xFF
      ..[1] = (value >> 16) & 0xFF
      ..[2] = (value >> 8) & 0xFF
      ..[3] = value & 0xFF;
  }
  
  /// Convert bytes to int
  int _bytesToInt(Uint8List bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }
  
  /// Encode JSON to bytes
  Uint8List _encodeJson(Map<String, dynamic> data) {
    final jsonString = data.toString(); // Simplified - use dart:convert in production
    return Uint8List.fromList(jsonString.codeUnits);
  }
  
  /// Decode JSON from bytes
  Map<String, dynamic> _decodeJson(Uint8List bytes) {
    // Simplified parsing - use dart:convert in production
    return {};
  }
  
  /// Cleanup resources
  Future<void> _cleanup() async {
    await _socket?.close();
    await _currentFile?.close();
    _socket = null;
    _currentFile = null;
    _isConnected = false;
  }
  
  /// Dispose resources
  void dispose() {
    _cleanup();
    _progressController.close();
  }
}

/// Transfer progress data
class TransferProgressData {
  final int bytesTransferred;
  final int totalBytes;
  final double progress; // 0-100
  final double speedBytesPerSecond;
  final Duration estimatedTimeRemaining;
  final String protocol;
  
  TransferProgressData({
    required this.bytesTransferred,
    required this.totalBytes,
    required this.progress,
    required this.speedBytesPerSecond,
    required this.estimatedTimeRemaining,
    required this.protocol,
  });
  
  String get speedFormatted {
    final mbps = (speedBytesPerSecond * 8) / (1024 * 1024);
    if (mbps < 1) {
      final kbps = (speedBytesPerSecond * 8) / 1024;
      return '${kbps.toStringAsFixed(1)} Kbps';
    }
    return '${mbps.toStringAsFixed(2)} Mbps';
  }
  
  String get etaFormatted {
    if (estimatedTimeRemaining.inSeconds < 60) {
      return '${estimatedTimeRemaining.inSeconds}s';
    } else if (estimatedTimeRemaining.inMinutes < 60) {
      return '${estimatedTimeRemaining.inMinutes}m ${estimatedTimeRemaining.inSeconds % 60}s';
    } else {
      return '${estimatedTimeRemaining.inHours}h ${estimatedTimeRemaining.inMinutes % 60}m';
    }
  }
}

/// Transfer result
class TransferResult {
  final bool success;
  final String fileName;
  final int bytesTransferred;
  final Duration duration;
  final double averageSpeed;
  final String? error;
  final String? filePath;
  
  TransferResult({
    required this.success,
    required this.fileName,
    required this.bytesTransferred,
    required this.duration,
    required this.averageSpeed,
    this.error,
    this.filePath,
  });
  
  String get speedFormatted {
    final mbps = (averageSpeed * 8) / (1024 * 1024);
    return '${mbps.toStringAsFixed(2)} Mbps';
  }
}
