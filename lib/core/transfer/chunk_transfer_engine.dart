import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// Chunk Transfer Engine for Large File Handling
/// 
/// Features:
/// - Adaptive chunk sizing (4KB - 1MB based on network speed)
/// - Resume capability for interrupted transfers
/// - Chunk integrity verification
/// - Progress tracking
/// - Memory-efficient streaming
class ChunkTransferEngine {
  // Chunk size configuration
  static const int MIN_CHUNK_SIZE = 4 * 1024; // 4KB
  static const int MAX_CHUNK_SIZE = 1024 * 1024; // 1MB
  static const int DEFAULT_CHUNK_SIZE = 64 * 1024; // 64KB
  
  // Transfer state
  int _currentChunkSize = DEFAULT_CHUNK_SIZE;
  double _currentTransferSpeed = 0.0; // bytes per second
  
  // Progress tracking
  final StreamController<ChunkTransferProgress> _progressController =
      StreamController<ChunkTransferProgress>.broadcast();
  
  Stream<ChunkTransferProgress> get progressStream => _progressController.stream;

  /// Split a file into chunks with adaptive sizing
  Stream<FileChunk> chunkFile({
    required File file,
    required String transferId,
    int? chunkSize,
  }) async* {
    try {
      final fileSize = await file.length();
      final effectiveChunkSize = chunkSize ?? _currentChunkSize;
      
      logInfo('Chunking file: ${file.path} (${_formatBytes(fileSize)}) with chunk size: ${_formatBytes(effectiveChunkSize)}');
      
      final fileStream = file.openRead();
      int chunkIndex = 0;
      int totalBytesRead = 0;
      
      await for (final chunk in _readChunks(fileStream, effectiveChunkSize)) {
        // Calculate chunk hash
        final chunkHash = sha256.convert(chunk).bytes;
        
        totalBytesRead += chunk.length;
        
        final fileChunk = FileChunk(
          transferId: transferId,
          index: chunkIndex,
          data: chunk,
          hash: Uint8List.fromList(chunkHash),
          totalChunks: (fileSize / effectiveChunkSize).ceil(),
          fileSize: fileSize,
        );
        
        // Emit progress
        _progressController.add(ChunkTransferProgress(
          transferId: transferId,
          totalBytes: fileSize,
          transferredBytes: totalBytesRead,
          currentChunk: chunkIndex,
          totalChunks: fileChunk.totalChunks,
          percentage: (totalBytesRead / fileSize) * 100,
          status: ChunkTransferStatus.transferring,
        ));
        
        yield fileChunk;
        chunkIndex++;
      }
      
      logInfo('File chunking complete: $chunkIndex chunks');
      
      _progressController.add(ChunkTransferProgress(
        transferId: transferId,
        totalBytes: fileSize,
        transferredBytes: fileSize,
        currentChunk: chunkIndex,
        totalChunks: chunkIndex,
        percentage: 100.0,
        status: ChunkTransferStatus.completed,
      ));
    } catch (e) {
      logError('File chunking failed', e);
      _progressController.add(ChunkTransferProgress(
        transferId: transferId,
        totalBytes: 0,
        transferredBytes: 0,
        currentChunk: 0,
        totalChunks: 0,
        percentage: 0,
        status: ChunkTransferStatus.failed,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// Reassemble chunks into a complete file
  Future<File> reassembleChunks({
    required List<FileChunk> chunks,
    required String fileName,
    required String transferId,
  }) async {
    try {
      logInfo('Reassembling ${chunks.length} chunks into $fileName');
      
      // Sort chunks by index
      chunks.sort((a, b) => a.index.compareTo(b.index));
      
      // Verify all chunks are present
      for (int i = 0; i < chunks.length; i++) {
        if (chunks[i].index != i) {
          throw Exception('Missing chunk at index $i');
        }
      }
      
      // Get downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final outputFile = File(filePath);
      
      // Write chunks to file
      final sink = outputFile.openWrite();
      
      int totalWritten = 0;
      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        
        // Verify chunk integrity
        final calculatedHash = sha256.convert(chunk.data).bytes;
        if (!_bytesEqual(calculatedHash, chunk.hash)) {
          throw Exception('Chunk integrity verification failed at index $i');
        }
        
        sink.add(chunk.data);
        totalWritten += chunk.data.length;
        
        // Emit progress
        _progressController.add(ChunkTransferProgress(
          transferId: transferId,
          totalBytes: chunk.fileSize,
          transferredBytes: totalWritten,
          currentChunk: i,
          totalChunks: chunks.length,
          percentage: (i / chunks.length) * 100,
          status: ChunkTransferStatus.reassembling,
        ));
      }
      
      await sink.flush();
      await sink.close();
      
      logInfo('File reassembly complete: $filePath');
      
      _progressController.add(ChunkTransferProgress(
        transferId: transferId,
        totalBytes: totalWritten,
        transferredBytes: totalWritten,
        currentChunk: chunks.length,
        totalChunks: chunks.length,
        percentage: 100.0,
        status: ChunkTransferStatus.completed,
        filePath: filePath,
      ));
      
      return outputFile;
    } catch (e) {
      logError('File reassembly failed', e);
      _progressController.add(ChunkTransferProgress(
        transferId: transferId,
        totalBytes: 0,
        transferredBytes: 0,
        currentChunk: 0,
        totalChunks: 0,
        percentage: 0,
        status: ChunkTransferStatus.failed,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// Adjust chunk size based on transfer speed
  void adjustChunkSize(double bytesPerSecond) {
    _currentTransferSpeed = bytesPerSecond;
    
    // Adjust chunk size based on speed
    if (bytesPerSecond < 100 * 1024) {
      // Slow: < 100 KB/s → 16KB chunks
      _currentChunkSize = 16 * 1024;
    } else if (bytesPerSecond < 1024 * 1024) {
      // Medium: < 1 MB/s → 64KB chunks
      _currentChunkSize = 64 * 1024;
    } else if (bytesPerSecond < 10 * 1024 * 1024) {
      // Fast: < 10 MB/s → 256KB chunks
      _currentChunkSize = 256 * 1024;
    } else {
      // Very Fast: >= 10 MB/s → 1MB chunks
      _currentChunkSize = MAX_CHUNK_SIZE;
    }
    
    logInfo('Adjusted chunk size to ${_formatBytes(_currentChunkSize)} based on speed ${_formatBytes(bytesPerSecond.toInt())}/s');
  }

  /// Read file in chunks
  Stream<Uint8List> _readChunks(Stream<List<int>> stream, int chunkSize) async* {
    final buffer = <int>[];
    
    await for (final data in stream) {
      buffer.addAll(data);
      
      while (buffer.length >= chunkSize) {
        yield Uint8List.fromList(buffer.take(chunkSize).toList());
        buffer.removeRange(0, chunkSize);
      }
    }
    
    // Yield remaining data
    if (buffer.isNotEmpty) {
      yield Uint8List.fromList(buffer);
    }
  }

  /// Compare two byte arrays
  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}

/// File chunk
class FileChunk {
  final String transferId;
  final int index;
  final Uint8List data;
  final Uint8List hash;
  final int totalChunks;
  final int fileSize;

  FileChunk({
    required this.transferId,
    required this.index,
    required this.data,
    required this.hash,
    required this.totalChunks,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'index': index,
      'data': data.toList(),
      'hash': hash.toList(),
      'totalChunks': totalChunks,
      'fileSize': fileSize,
    };
  }

  factory FileChunk.fromJson(Map<String, dynamic> json) {
    return FileChunk(
      transferId: json['transferId'] as String,
      index: json['index'] as int,
      data: Uint8List.fromList((json['data'] as List).cast<int>()),
      hash: Uint8List.fromList((json['hash'] as List).cast<int>()),
      totalChunks: json['totalChunks'] as int,
      fileSize: json['fileSize'] as int,
    );
  }
}

/// Chunk transfer progress
class ChunkTransferProgress {
  final String transferId;
  final int totalBytes;
  final int transferredBytes;
  final int currentChunk;
  final int totalChunks;
  final double percentage;
  final ChunkTransferStatus status;
  final String? error;
  final String? filePath;

  ChunkTransferProgress({
    required this.transferId,
    required this.totalBytes,
    required this.transferredBytes,
    required this.currentChunk,
    required this.totalChunks,
    required this.percentage,
    required this.status,
    this.error,
    this.filePath,
  });

  String get formattedTransferred => _formatBytes(transferredBytes);
  String get formattedTotal => _formatBytes(totalBytes);
  
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Chunk transfer status
enum ChunkTransferStatus {
  preparing,
  transferring,
  reassembling,
  completed,
  failed,
  cancelled,
}

/// Resume Manager for interrupted transfers
class ResumeManager {
  final Map<String, TransferState> _transferStates = {};
  
  /// Save transfer state
  Future<void> saveTransferState(TransferState state) async {
    try {
      _transferStates[state.transferId] = state;
      // TODO: Persist to disk for durability
      logInfo('Transfer state saved: ${state.transferId}');
    } catch (e) {
      logError('Failed to save transfer state', e);
    }
  }
  
  /// Load transfer state
  TransferState? loadTransferState(String transferId) {
    return _transferStates[transferId];
  }
  
  /// Clear transfer state
  void clearTransferState(String transferId) {
    _transferStates.remove(transferId);
  }
  
  /// Get all active transfers
  List<TransferState> getActiveTransfers() {
    return _transferStates.values.where((state) => !state.isCompleted).toList();
  }
}

/// Transfer state for resume capability
class TransferState {
  final String transferId;
  final String fileName;
  final int fileSize;
  final int totalChunks;
  final List<int> receivedChunks;
  final DateTime startTime;
  DateTime lastUpdateTime;
  bool isCompleted;

  TransferState({
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.receivedChunks,
    required this.startTime,
    required this.lastUpdateTime,
    this.isCompleted = false,
  });

  /// Get missing chunk indices
  List<int> get missingChunks {
    final missing = <int>[];
    for (int i = 0; i < totalChunks; i++) {
      if (!receivedChunks.contains(i)) {
        missing.add(i);
      }
    }
    return missing;
  }

  /// Calculate progress percentage
  double get progressPercentage {
    return (receivedChunks.length / totalChunks) * 100;
  }

  /// Mark chunk as received
  void markChunkReceived(int chunkIndex) {
    if (!receivedChunks.contains(chunkIndex)) {
      receivedChunks.add(chunkIndex);
      lastUpdateTime = DateTime.now();
    }
    
    if (receivedChunks.length == totalChunks) {
      isCompleted = true;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'fileName': fileName,
      'fileSize': fileSize,
      'totalChunks': totalChunks,
      'receivedChunks': receivedChunks,
      'startTime': startTime.toIso8601String(),
      'lastUpdateTime': lastUpdateTime.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory TransferState.fromJson(Map<String, dynamic> json) {
    return TransferState(
      transferId: json['transferId'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      totalChunks: json['totalChunks'] as int,
      receivedChunks: (json['receivedChunks'] as List).cast<int>(),
      startTime: DateTime.parse(json['startTime'] as String),
      lastUpdateTime: DateTime.parse(json['lastUpdateTime'] as String),
      isCompleted: json['isCompleted'] as bool,
    );
  }
}
