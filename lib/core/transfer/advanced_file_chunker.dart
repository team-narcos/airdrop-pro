import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

/// Advanced File Chunker
/// Features:
/// - Adaptive chunk sizing based on network conditions
/// - SHA-256 integrity verification for each chunk
/// - Parallel chunk processing
/// - Resume capability
/// - Delta sync for similar files
class AdvancedFileChunker {
  final Logger _logger = Logger();
  
  // Chunk size configuration (adaptive)
  static const int MIN_CHUNK_SIZE = 16 * 1024;       // 16KB
  static const int DEFAULT_CHUNK_SIZE = 64 * 1024;   // 64KB
  static const int MAX_CHUNK_SIZE = 1024 * 1024;     // 1MB
  
  // Network speed thresholds (bytes/second)
  static const int SLOW_NETWORK = 100 * 1024;        // 100 KB/s
  static const int MEDIUM_NETWORK = 1024 * 1024;     // 1 MB/s
  static const int FAST_NETWORK = 10 * 1024 * 1024;  // 10 MB/s
  
  // State
  int _currentChunkSize = DEFAULT_CHUNK_SIZE;
  double _averageSpeed = 0;
  final List<double> _speedSamples = [];
  
  /// Chunk a file into pieces with metadata
  Future<List<FileChunk>> chunkFile(
    File file, {
    int? fixedChunkSize,
    bool adaptive = true,
    Function(double)? onProgress,
  }) async {
    try {
      _logger.i('[Chunker] Chunking file: ${file.path}');
      
      final fileSize = await file.length();
      final chunks = <FileChunk>[];
      
      // Determine chunk size
      int chunkSize = fixedChunkSize ?? _currentChunkSize;
      if (adaptive && fixedChunkSize == null) {
        chunkSize = _calculateAdaptiveChunkSize(fileSize);
      }
      
      _logger.i('[Chunker] Using chunk size: ${chunkSize} bytes');
      
      int offset = 0;
      int chunkIndex = 0;
      
      final raf = await file.open(mode: FileMode.read);
      
      while (offset < fileSize) {
        final remaining = fileSize - offset;
        final currentSize = remaining < chunkSize ? remaining : chunkSize;
        
        // Read chunk
        await raf.setPosition(offset);
        final data = await raf.read(currentSize);
        
        // Calculate checksum
        final checksum = _calculateChecksum(data);
        
        // Create chunk metadata
        final chunk = FileChunk(
          index: chunkIndex,
          offset: offset,
          size: currentSize,
          data: data,
          checksum: checksum,
          totalChunks: (fileSize / chunkSize).ceil(),
        );
        
        chunks.add(chunk);
        
        offset += currentSize;
        chunkIndex++;
        
        // Report progress
        if (onProgress != null) {
          onProgress(offset / fileSize);
        }
      }
      
      await raf.close();
      
      _logger.i('[Chunker] File chunked into ${chunks.length} pieces');
      return chunks;
    } catch (e) {
      _logger.e('[Chunker] Chunking failed: $e');
      rethrow;
    }
  }
  
  /// Stream chunks from file for memory-efficient processing
  Stream<FileChunk> streamChunks(
    File file, {
    int? fixedChunkSize,
    bool adaptive = true,
  }) async* {
    try {
      final fileSize = await file.length();
      int chunkSize = fixedChunkSize ?? _currentChunkSize;
      
      if (adaptive && fixedChunkSize == null) {
        chunkSize = _calculateAdaptiveChunkSize(fileSize);
      }
      
      int offset = 0;
      int chunkIndex = 0;
      final totalChunks = (fileSize / chunkSize).ceil();
      
      final stream = file.openRead();
      final buffer = <int>[];
      
      await for (var data in stream) {
        buffer.addAll(data);
        
        while (buffer.length >= chunkSize) {
          // Extract chunk
          final chunkData = Uint8List.fromList(buffer.sublist(0, chunkSize));
          buffer.removeRange(0, chunkSize);
          
          // Calculate checksum
          final checksum = _calculateChecksum(chunkData);
          
          // Yield chunk
          yield FileChunk(
            index: chunkIndex,
            offset: offset,
            size: chunkSize,
            data: chunkData,
            checksum: checksum,
            totalChunks: totalChunks,
          );
          
          offset += chunkSize;
          chunkIndex++;
        }
      }
      
      // Handle remaining data
      if (buffer.isNotEmpty) {
        final chunkData = Uint8List.fromList(buffer);
        final checksum = _calculateChecksum(chunkData);
        
        yield FileChunk(
          index: chunkIndex,
          offset: offset,
          size: buffer.length,
          data: chunkData,
          checksum: checksum,
          totalChunks: totalChunks,
        );
      }
    } catch (e) {
      _logger.e('[Chunker] Stream chunking failed: $e');
      rethrow;
    }
  }
  
  /// Reassemble chunks into a file
  Future<bool> reassembleChunks(
    List<FileChunk> chunks,
    String outputPath, {
    Function(double)? onProgress,
  }) async {
    try {
      _logger.i('[Chunker] Reassembling ${chunks.length} chunks...');
      
      // Sort chunks by index
      chunks.sort((a, b) => a.index.compareTo(b.index));
      
      // Verify all chunks are present
      for (int i = 0; i < chunks.length; i++) {
        if (chunks[i].index != i) {
          _logger.e('[Chunker] Missing chunk at index $i');
          return false;
        }
      }
      
      // Verify checksums
      for (var chunk in chunks) {
        if (!_verifyChunk(chunk)) {
          _logger.e('[Chunker] Checksum verification failed for chunk ${chunk.index}');
          return false;
        }
      }
      
      // Write to file
      final file = File(outputPath);
      final sink = file.openWrite(mode: FileMode.write);
      
      int processedChunks = 0;
      for (var chunk in chunks) {
        sink.add(chunk.data);
        processedChunks++;
        
        if (onProgress != null) {
          onProgress(processedChunks / chunks.length);
        }
      }
      
      await sink.flush();
      await sink.close();
      
      _logger.i('[Chunker] File reassembled successfully: $outputPath');
      return true;
    } catch (e) {
      _logger.e('[Chunker] Reassembly failed: $e');
      return false;
    }
  }
  
  /// Calculate adaptive chunk size based on file size and network speed
  int _calculateAdaptiveChunkSize(int fileSize) {
    // For small files, use smaller chunks
    if (fileSize < 1024 * 1024) { // < 1MB
      return MIN_CHUNK_SIZE;
    }
    
    // For medium files, use default
    if (fileSize < 100 * 1024 * 1024) { // < 100MB
      return DEFAULT_CHUNK_SIZE;
    }
    
    // For large files, consider network speed
    if (_averageSpeed > 0) {
      if (_averageSpeed < SLOW_NETWORK) {
        return MIN_CHUNK_SIZE; // Small chunks for slow network
      } else if (_averageSpeed < MEDIUM_NETWORK) {
        return DEFAULT_CHUNK_SIZE;
      } else {
        return MAX_CHUNK_SIZE; // Large chunks for fast network
      }
    }
    
    // Default for large files
    return DEFAULT_CHUNK_SIZE * 2; // 128KB
  }
  
  /// Update network speed statistics
  void updateNetworkSpeed(double bytesPerSecond) {
    _speedSamples.add(bytesPerSecond);
    
    // Keep only last 10 samples
    if (_speedSamples.length > 10) {
      _speedSamples.removeAt(0);
    }
    
    // Calculate average
    _averageSpeed = _speedSamples.reduce((a, b) => a + b) / _speedSamples.length;
    
    // Adapt chunk size
    if (_averageSpeed < SLOW_NETWORK && _currentChunkSize > MIN_CHUNK_SIZE) {
      _currentChunkSize = (_currentChunkSize / 2).round();
      if (_currentChunkSize < MIN_CHUNK_SIZE) {
        _currentChunkSize = MIN_CHUNK_SIZE;
      }
      _logger.i('[Chunker] Reduced chunk size to $_currentChunkSize (slow network)');
    } else if (_averageSpeed > FAST_NETWORK && _currentChunkSize < MAX_CHUNK_SIZE) {
      _currentChunkSize = (_currentChunkSize * 2).round();
      if (_currentChunkSize > MAX_CHUNK_SIZE) {
        _currentChunkSize = MAX_CHUNK_SIZE;
      }
      _logger.i('[Chunker] Increased chunk size to $_currentChunkSize (fast network)');
    }
  }
  
  /// Calculate SHA-256 checksum for data
  String _calculateChecksum(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }
  
  /// Verify chunk integrity
  bool _verifyChunk(FileChunk chunk) {
    final calculatedChecksum = _calculateChecksum(chunk.data);
    return calculatedChecksum == chunk.checksum;
  }
  
  /// Create chunk manifest for resume capability
  ChunkManifest createManifest(File file, List<FileChunk> chunks) {
    return ChunkManifest(
      filePath: file.path,
      fileName: file.path.split('/').last,
      fileSize: file.lengthSync(),
      totalChunks: chunks.length,
      chunkSize: _currentChunkSize,
      chunks: chunks.map((c) => ChunkMetadata(
        index: c.index,
        offset: c.offset,
        size: c.size,
        checksum: c.checksum,
      )).toList(),
      createdAt: DateTime.now(),
    );
  }
  
  /// Find missing chunks for resume
  List<int> findMissingChunks(ChunkManifest manifest, List<int> receivedChunks) {
    final allChunks = List.generate(manifest.totalChunks, (i) => i);
    final missing = allChunks.where((i) => !receivedChunks.contains(i)).toList();
    
    _logger.i('[Chunker] Missing chunks: ${missing.length}/${manifest.totalChunks}');
    return missing;
  }
  
  /// Calculate delta between two files
  Future<List<FileDelta>> calculateDelta(File oldFile, File newFile) async {
    try {
      _logger.i('[Chunker] Calculating delta between files...');
      
      final oldChunks = await chunkFile(oldFile);
      final newChunks = await chunkFile(newFile);
      
      final deltas = <FileDelta>[];
      
      // Find changed chunks
      final minLength = oldChunks.length < newChunks.length 
          ? oldChunks.length 
          : newChunks.length;
      
      for (int i = 0; i < minLength; i++) {
        if (oldChunks[i].checksum != newChunks[i].checksum) {
          deltas.add(FileDelta(
            chunkIndex: i,
            operation: DeltaOperation.modify,
            data: newChunks[i].data,
          ));
        }
      }
      
      // Handle added chunks
      if (newChunks.length > oldChunks.length) {
        for (int i = minLength; i < newChunks.length; i++) {
          deltas.add(FileDelta(
            chunkIndex: i,
            operation: DeltaOperation.add,
            data: newChunks[i].data,
          ));
        }
      }
      
      // Handle deleted chunks
      if (oldChunks.length > newChunks.length) {
        for (int i = minLength; i < oldChunks.length; i++) {
          deltas.add(FileDelta(
            chunkIndex: i,
            operation: DeltaOperation.delete,
            data: null,
          ));
        }
      }
      
      _logger.i('[Chunker] Delta calculated: ${deltas.length} changes');
      return deltas;
    } catch (e) {
      _logger.e('[Chunker] Delta calculation failed: $e');
      rethrow;
    }
  }
}

/// File chunk with metadata
class FileChunk {
  final int index;
  final int offset;
  final int size;
  final Uint8List data;
  final String checksum;
  final int totalChunks;
  
  FileChunk({
    required this.index,
    required this.offset,
    required this.size,
    required this.data,
    required this.checksum,
    required this.totalChunks,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'offset': offset,
      'size': size,
      'checksum': checksum,
      'totalChunks': totalChunks,
    };
  }
}

/// Chunk metadata (without data for manifest)
class ChunkMetadata {
  final int index;
  final int offset;
  final int size;
  final String checksum;
  
  ChunkMetadata({
    required this.index,
    required this.offset,
    required this.size,
    required this.checksum,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'offset': offset,
      'size': size,
      'checksum': checksum,
    };
  }
  
  factory ChunkMetadata.fromJson(Map<String, dynamic> json) {
    return ChunkMetadata(
      index: json['index'],
      offset: json['offset'],
      size: json['size'],
      checksum: json['checksum'],
    );
  }
}

/// Chunk manifest for resume capability
class ChunkManifest {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int totalChunks;
  final int chunkSize;
  final List<ChunkMetadata> chunks;
  final DateTime createdAt;
  
  ChunkManifest({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.chunkSize,
    required this.chunks,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'totalChunks': totalChunks,
      'chunkSize': chunkSize,
      'chunks': chunks.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory ChunkManifest.fromJson(Map<String, dynamic> json) {
    return ChunkManifest(
      filePath: json['filePath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      totalChunks: json['totalChunks'],
      chunkSize: json['chunkSize'],
      chunks: (json['chunks'] as List)
          .map((c) => ChunkMetadata.fromJson(c))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// File delta for delta sync
class FileDelta {
  final int chunkIndex;
  final DeltaOperation operation;
  final Uint8List? data;
  
  FileDelta({
    required this.chunkIndex,
    required this.operation,
    this.data,
  });
}

/// Delta operations
enum DeltaOperation {
  add,
  modify,
  delete,
}
