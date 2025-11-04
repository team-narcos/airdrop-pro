import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'notification_service.dart';
import '../data/history/history_repository.dart';

class TcpTransferService {
  static const int TRANSFER_PORT = 37777;
  static const int CHUNK_SIZE = 1024 * 64; // 64KB chunks
  static const int ACK_TIMEOUT_SECONDS = 5;
  
  ServerSocket? _serverSocket;
  Socket? _clientSocket;
  bool _isRunning = false;
  HistoryRepository? _historyRepo;
  
  final _transferProgressController = StreamController<TransferProgress>.broadcast();
  Stream<TransferProgress> get transferProgressStream => _transferProgressController.stream;
  
  void setHistoryRepository(HistoryRepository repo) {
    _historyRepo = repo;
  }
  
  // Start TCP server for receiving files
  Future<void> startServer() async {
    if (_isRunning) return;
    
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, TRANSFER_PORT);
      _isRunning = true;
      print('[TCP Transfer] Server started on port $TRANSFER_PORT');
      
      _serverSocket!.listen((Socket client) {
        print('[TCP Transfer] Client connected: ${client.remoteAddress.address}');
        _handleClient(client);
      });
    } catch (e) {
      print('[TCP Transfer] Failed to start server: $e');
      throw Exception('Failed to start transfer server: $e');
    }
  }
  
  // Stop TCP server
  Future<void> stopServer() async {
    _isRunning = false;
    await _serverSocket?.close();
    _serverSocket = null;
    print('[TCP Transfer] Server stopped');
  }
  
  // Handle incoming client connection
  Future<void> _handleClient(Socket client) async {
    print('[TCP Transfer] ===== NEW CLIENT CONNECTION =====');
    print('[TCP Transfer] Client IP: ${client.remoteAddress.address}');
    print('[TCP Transfer] Client Port: ${client.remotePort}');
    
    // Create a single buffer and subscription to read all data
    final buffer = <int>[];
    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    try {
      // Listen to socket once and accumulate all data
      subscription = client.listen(
        (data) {
          buffer.addAll(data);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        cancelOnError: true,
      );
      
      // Step 1: Wait for metadata length (4 bytes)
      print('[TCP Transfer] Step 1: Waiting for metadata length (4 bytes)...');
      await _waitForBytes(buffer, 4, completer);
      final metadataLength = _bytesToInt(buffer.sublist(0, 4));
      print('[TCP Transfer] ✓ Metadata length: $metadataLength bytes');
      
      // Step 2: Wait for metadata
      print('[TCP Transfer] Step 2: Waiting for metadata ($metadataLength bytes)...');
      await _waitForBytes(buffer, 4 + metadataLength, completer);
      final metadataBytes = buffer.sublist(4, 4 + metadataLength);
      final metadataJson = utf8.decode(metadataBytes);
      print('[TCP Transfer] ✓ Metadata JSON: $metadataJson');
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      print('[TCP Transfer] ✓ Metadata parsed successfully');
      
      final fileName = metadata['fileName'] as String;
      final fileSize = metadata['fileSize'] as int;
      final fileHash = metadata['fileHash'] as String;
      
      print('[TCP Transfer] Metadata - fileName: $fileName, fileSize: $fileSize bytes');
      
      // Get save directory - use external storage for FileProvider compatibility
      Directory? dir;
      try {
        // Try external storage first (works with FileProvider)
        if (Platform.isAndroid) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            dir = Directory('${externalDir.path}/ReceivedFiles');
          }
        }
        // Fallback to documents directory for iOS/other platforms
        if (dir == null) {
          final docDir = await getApplicationDocumentsDirectory();
          dir = Directory('${docDir.path}/ReceivedFiles');
        }
      } catch (e) {
        print('[TCP Transfer] Error getting storage directory: $e');
        final docDir = await getApplicationDocumentsDirectory();
        dir = Directory('${docDir.path}/ReceivedFiles');
      }
      
      final receivedDir = dir;
      print('[TCP Transfer] Using storage directory: ${receivedDir.path}');
      
      if (!await receivedDir.exists()) {
        await receivedDir.create(recursive: true);
        print('[TCP Transfer] Created directory: ${receivedDir.path}');
      }
      
      // Create unique filename if exists
      var filePath = '${receivedDir.path}/$fileName';
      var counter = 1;
      while (await File(filePath).exists()) {
        final nameParts = fileName.split('.');
        final name = nameParts.length > 1
            ? nameParts.sublist(0, nameParts.length - 1).join('.')
            : fileName;
        final ext = nameParts.length > 1 ? nameParts.last : '';
        filePath = '${receivedDir.path}/$name($counter)${ext.isNotEmpty ? '.$ext' : ''}';
        counter++;
      }
      
      // Step 3: Wait for file data
      print('[TCP Transfer] Step 3: Ready to receive file data');
      print('[TCP Transfer] File path: $filePath');
      final file = File(filePath);
      
      final totalExpected = 4 + metadataLength + fileSize;
      print('[TCP Transfer] Waiting for $fileSize bytes of file data...');
      print('[TCP Transfer] Total expected: $totalExpected bytes');
      
      await _waitForBytes(buffer, totalExpected, completer).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print('[TCP Transfer] ✗ TIMEOUT! Got ${buffer.length}/$totalExpected bytes');
          throw TimeoutException('Timeout receiving file data');
        },
      );
      
      // Extract file bytes from buffer
      final fileBytes = buffer.sublist(4 + metadataLength, totalExpected);
      print('[TCP Transfer] ✓ Received all ${fileBytes.length} bytes!');
      print('[TCP Transfer] Writing to disk...');
      
      // Cancel subscription now that we have all data
      await subscription.cancel();
      
      // Write all data at once
      await file.writeAsBytes(fileBytes, flush: true);
      print('[TCP Transfer] ✓ File written and flushed to disk');
      print('[TCP Transfer] File size on disk: ${await file.length()} bytes');
      
      // Small delay to ensure file system syncs
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('[TCP Transfer] File write completed. Verifying...');
      
      // Check actual file size
      final actualSize = await file.length();
      print('[TCP Transfer] Expected size: $fileSize, Actual size: $actualSize');
      print('[TCP Transfer] File exists: ${await file.exists()}');
      print('[TCP Transfer] File absolute path: ${file.absolute.path}');
      
      if (actualSize == 0) {
        print('[TCP Transfer] ERROR: File is empty after write!');
        print('[TCP Transfer] ERROR: Expected $fileSize bytes but file has 0 bytes');
        print('[TCP Transfer] ERROR: Received bytes length: ${fileBytes.length}');
        throw Exception('File is empty! No data was received. Expected $fileSize bytes but file has 0 bytes.');
      }
      
      if (actualSize != fileSize) {
        print('[TCP Transfer] WARNING: Size mismatch! Expected $fileSize, got $actualSize');
      }
      
      // Verify hash
      final receivedHash = await _computeFileHash(filePath);
      if (receivedHash != fileHash) {
        await file.delete();
        throw Exception('File hash mismatch - file corrupted');
      }
      
      print('[TCP Transfer] ===== FILE RECEIVED SUCCESSFULLY =====');
      print('[TCP Transfer] File: $fileName');
      print('[TCP Transfer] Size: $fileSize bytes');
      print('[TCP Transfer] Path: $filePath');
      print('[TCP Transfer] ===========================================');
      
      _transferProgressController.add(TransferProgress(
        fileName: fileName,
        progress: 100,
        bytesTransferred: fileSize,
        totalBytes: fileSize,
        isComplete: true,
        filePath: filePath,
      ));
      
      // Save to history
      if (_historyRepo != null) {
        try {
          await _historyRepo!.upsert({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'file_name': fileName,
            'size_bytes': fileSize,
            'peer_name': client.remoteAddress.address,
            'direction': 'received',
            'status': 'completed',
            'started_at': DateTime.now().millisecondsSinceEpoch,
            'completed_at': DateTime.now().millisecondsSinceEpoch,
          });
        } catch (e) {
          print('[TCP Transfer] Error saving to history: $e');
        }
      }
      
      // Show notification
      NotificationService().showFileReceived(fileName, filePath);
      
    } catch (e, stackTrace) {
      print('[TCP Transfer] ✗✗✗ ERROR HANDLING CLIENT ✗✗✗');
      print('[TCP Transfer] Error: $e');
      print('[TCP Transfer] Stack trace: $stackTrace');
      _transferProgressController.addError(e);
      try {
        await subscription.cancel();
      } catch (_) {}
    } finally {
      print('[TCP Transfer] Closing client connection');
      await client.close();
      print('[TCP Transfer] ===== CONNECTION CLOSED =====');
    }
  }
  
  // Helper to wait for buffer to have enough bytes
  Future<void> _waitForBytes(List<int> buffer, int requiredBytes, Completer completer) async {
    while (buffer.length < requiredBytes && !completer.isCompleted) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    if (completer.isCompleted && buffer.length < requiredBytes) {
      throw Exception('Connection closed before receiving $requiredBytes bytes (got ${buffer.length})');
    }
  }
  
  
  // Send file to remote device
  Future<void> sendFile(String ipAddress, File file) async {
    StreamSubscription? subscription;
    
    try {
      print('[TCP Transfer SENDER] ===== STARTING FILE SEND =====');
      print('[TCP Transfer SENDER] Target IP: $ipAddress');
      print('[TCP Transfer SENDER] Target Port: $TRANSFER_PORT');
      print('[TCP Transfer SENDER] Connecting...');
      
      final startTime = DateTime.now();
      
      _clientSocket = await Socket.connect(
        ipAddress,
        TRANSFER_PORT,
        timeout: const Duration(seconds: 10),
      );
      print('[TCP Transfer SENDER] ✓ Connected! Socket: ${_clientSocket!.remoteAddress.address}:${_clientSocket!.remotePort}');
      
      final fileName = file.path.split(Platform.pathSeparator).last;
      final fileSize = await file.length();
      print('[TCP Transfer SENDER] File: $fileName');
      print('[TCP Transfer SENDER] Size: $fileSize bytes');
      print('[TCP Transfer SENDER] Computing hash...');
      final fileHash = await _computeFileHash(file.path);
      print('[TCP Transfer SENDER] ✓ Hash: ${fileHash.substring(0, 16)}...');
      
      // Send metadata
      final metadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'fileHash': fileHash,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final metadataJson = jsonEncode(metadata);
      final metadataLength = metadataJson.length;
      
      // Send metadata length (4 bytes) + metadata
      print('[TCP Transfer SENDER] Step 1: Sending metadata length ($metadataLength bytes)...');
      _clientSocket!.add(_intToBytes(metadataLength));
      _clientSocket!.add(utf8.encode(metadataJson));
      await _clientSocket!.flush();
      print('[TCP Transfer SENDER] ✓ Metadata sent');
      
      // Small delay to ensure receiver gets metadata first
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Send file data
      print('[TCP Transfer SENDER] Step 2: Reading file from disk...');
      final fileBytes = await file.readAsBytes();
      print('[TCP Transfer SENDER] ✓ Read ${fileBytes.length} bytes from file');
      
      if (fileBytes.isEmpty) {
        throw Exception('File is empty on sender side!');
      }
      
      if (fileBytes.length != fileSize) {
        print('[TCP Transfer] WARNING: File size mismatch on sender! Expected $fileSize, got ${fileBytes.length}');
      }
      
      print('[TCP Transfer SENDER] Step 3: Sending ${fileBytes.length} bytes...');
      _clientSocket!.add(fileBytes);
      await _clientSocket!.flush();
      print('[TCP Transfer SENDER] ✓ File data sent and flushed to socket');
      
      // Give adequate time for data to be transmitted over network
      await Future.delayed(const Duration(seconds: 1));
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('[TCP Transfer SENDER] ===== FILE SENT SUCCESSFULLY =====');
      print('[TCP Transfer SENDER] Duration: ${duration.inMilliseconds}ms');
      print('[TCP Transfer SENDER] Speed: ${(fileSize / duration.inMilliseconds * 1000 / 1024 / 1024).toStringAsFixed(2)} MB/s');
      print('[TCP Transfer SENDER] ==========================================');
      _transferProgressController.add(TransferProgress(
        fileName: fileName,
        progress: 100,
        bytesTransferred: fileSize,
        totalBytes: fileSize,
        isComplete: true,
      ));
      
      // Save to history
      if (_historyRepo != null) {
        try {
          await _historyRepo!.upsert({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'file_name': fileName,
            'size_bytes': fileSize,
            'peer_name': ipAddress,
            'direction': 'sent',
            'status': 'completed',
            'started_at': DateTime.now().millisecondsSinceEpoch,
            'completed_at': DateTime.now().millisecondsSinceEpoch,
          });
        } catch (e) {
          print('[TCP Transfer] Error saving to history: $e');
        }
      }
      
      // Show notification
      NotificationService().showTransferComplete(fileName);
      
    } catch (e, stackTrace) {
      print('[TCP Transfer SENDER] ✗✗✗ ERROR SENDING FILE ✗✗✗');
      print('[TCP Transfer SENDER] Error: $e');
      print('[TCP Transfer SENDER] Stack: $stackTrace');
      _transferProgressController.addError(e);
      rethrow;
    } finally {
      print('[TCP Transfer SENDER] Closing socket...');
      await subscription?.cancel();
      await _clientSocket?.close();
      _clientSocket = null;
      print('[TCP Transfer SENDER] ===== SEND COMPLETE =====');
    }
  }
  
  
  // Compute SHA-256 hash of file
  Future<String> _computeFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Convert int to 4 bytes
  Uint8List _intToBytes(int value) {
    final bytes = Uint8List(4);
    bytes[0] = (value >> 24) & 0xFF;
    bytes[1] = (value >> 16) & 0xFF;
    bytes[2] = (value >> 8) & 0xFF;
    bytes[3] = value & 0xFF;
    return bytes;
  }
  
  // Convert 4 bytes to int
  int _bytesToInt(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }
  
  void dispose() {
    _transferProgressController.close();
    stopServer();
  }
}

class TransferProgress {
  final String fileName;
  final int progress; // 0-100
  final int bytesTransferred;
  final int totalBytes;
  final bool isComplete;
  final String? filePath;
  
  TransferProgress({
    required this.fileName,
    required this.progress,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.isComplete,
    this.filePath,
  });
}
