import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../models/models.dart';
import 'p2p_client.dart';
import 'p2p_server.dart';
import 'file_chunking_service.dart';

/// Engine for transferring file chunks with progress tracking
class ChunkTransferEngine {
  final _lock = Lock();
  
  // Active transfers
  final Map<String, _TransferSession> _activeSessions = {};
  
  // Progress callbacks
  final Map<String, void Function(ChunkTransferProgress)> _progressCallbacks = {};
  
  /// Register progress callback for a transfer
  void registerProgressCallback(
    String transferId,
    void Function(ChunkTransferProgress) callback,
  ) {
    _progressCallbacks[transferId] = callback;
  }
  
  /// Unregister progress callback
  void unregisterProgressCallback(String transferId) {
    _progressCallbacks.remove(transferId);
  }
  
  /// Send file via chunks
  Future<void> sendFile({
    required String transferId,
    required String fileId,
    required String filePath,
    required P2PClient client,
    required int chunkSize,
    int parallelChunks = 1,
  }) async {
    debugPrint('[ChunkTransfer] Starting send: $fileId');
    
    try {
      // Get file info
      final fileInfo = await FileChunkingService.getFileInfo(filePath);
      final totalChunks = FileChunkingService.calculateTotalChunks(
        fileInfo.size,
        chunkSize,
      );
      
      // Create session
      final session = _TransferSession(
        transferId: transferId,
        fileId: fileId,
        totalChunks: totalChunks,
        chunkSize: chunkSize,
        fileSize: fileInfo.size,
      );
      
      await _lock.synchronized(() {
        _activeSessions[transferId] = session;
      });
      
      // Send file metadata
      await client.sendMessage(
        FileMetadataMessage(
          transferId: transferId,
          fileId: fileId,
          chunkSize: chunkSize,
          totalChunks: totalChunks,
        ),
      );
      
      debugPrint('[ChunkTransfer] Sending $totalChunks chunks');
      
      // Send chunks
      for (int i = 0; i < totalChunks; i++) {
        // Check if cancelled
        if (session.isCancelled) {
          debugPrint('[ChunkTransfer] Transfer cancelled');
          break;
        }
        
        // Read chunk
        final chunkData = await FileChunkingService.readChunk(
          filePath: filePath,
          chunkIndex: i,
          chunkSize: chunkSize,
        );
        
        // Calculate checksum
        final checksum = FileChunkingService.calculateChunkHash(chunkData);
        
        // Send chunk
        await client.sendMessage(
          ChunkDataMessage(
            transferId: transferId,
            fileId: fileId,
            chunkIndex: i,
            data: chunkData,
            checksum: checksum,
          ),
        );
        
        // Update progress
        session.markChunkSent(i);
        _notifyProgress(transferId, session);
        
        debugPrint('[ChunkTransfer] Sent chunk $i/$totalChunks');
      }
      
      // Send completion
      await client.sendMessage(
        ControlMessage(
          type: MessageType.complete,
          transferId: transferId,
          fileId: fileId,
        ),
      );
      
      debugPrint('[ChunkTransfer] Send complete');
    } catch (e) {
      debugPrint('[ChunkTransfer] Send error: $e');
      rethrow;
    } finally {
      await _lock.synchronized(() {
        _activeSessions.remove(transferId);
      });
    }
  }
  
  /// Handle incoming chunk data
  Future<void> handleChunkData({
    required ChunkDataMessage chunk,
    required String savePath,
    required P2PServer server,
    required String deviceId,
  }) async {
    debugPrint('[ChunkTransfer] Handling chunk ${chunk.chunkIndex}');
    
    final session = _activeSessions[chunk.transferId];
    if (session == null) {
      debugPrint('[ChunkTransfer] No active session for ${chunk.transferId}');
      return;
    }
    
    session.currentDeviceId = deviceId;
    
    try {
      // Verify checksum if provided
      if (chunk.checksum != null) {
        final actualChecksum = FileChunkingService.calculateChunkHash(chunk.data);
        if (actualChecksum != chunk.checksum) {
          debugPrint('[ChunkTransfer] Checksum mismatch for chunk ${chunk.chunkIndex}');
          await server.sendMessage(
            deviceId,
            ChunkAckMessage(
              transferId: chunk.transferId,
              fileId: chunk.fileId,
              chunkIndex: chunk.chunkIndex,
              success: false,
              error: 'Checksum mismatch',
            ),
          );
          return;
        }
      }
      
      // Write chunk
      await FileChunkingService.writeChunk(
        filePath: savePath,
        chunkIndex: chunk.chunkIndex,
        chunkSize: session.chunkSize,
        data: chunk.data,
      );
      
      // Update progress
      session.markChunkReceived(chunk.chunkIndex);
      _notifyProgress(chunk.transferId, session);
      
      debugPrint('[ChunkTransfer] Received chunk ${chunk.chunkIndex}/${session.totalChunks}');
      
      // Send acknowledgment
      await server.sendMessage(
        deviceId,
        ChunkAckMessage(
          transferId: chunk.transferId,
          fileId: chunk.fileId,
          chunkIndex: chunk.chunkIndex,
          success: true,
        ),
      );
    } catch (e) {
      debugPrint('[ChunkTransfer] Error processing chunk: $e');
      await server.sendMessage(
        deviceId,
        ChunkAckMessage(
          transferId: chunk.transferId,
          fileId: chunk.fileId,
          chunkIndex: chunk.chunkIndex,
          success: false,
          error: e.toString(),
        ),
      );
    }
  }
  
  /// Cancel transfer
  Future<void> cancelTransfer(String transferId) async {
    await _lock.synchronized(() {
      final session = _activeSessions[transferId];
      if (session != null) {
        session.cancel();
      }
    });
  }
  
  /// Get transfer progress
  ChunkTransferProgress? getProgress(String transferId) {
    final session = _activeSessions[transferId];
    if (session == null) return null;
    
    return ChunkTransferProgress(
      transferId: transferId,
      fileId: session.fileId,
      totalChunks: session.totalChunks,
      chunksCompleted: session.chunksCompleted,
      bytesTransferred: session.bytesTransferred,
      totalBytes: session.fileSize,
      speed: session.speed,
      progress: session.progress,
    );
  }
  
  /// Notify progress callback
  void _notifyProgress(String transferId, _TransferSession session) {
    final callback = _progressCallbacks[transferId];
    if (callback != null) {
      callback(ChunkTransferProgress(
        transferId: transferId,
        fileId: session.fileId,
        totalChunks: session.totalChunks,
        chunksCompleted: session.chunksCompleted,
        bytesTransferred: session.bytesTransferred,
        totalBytes: session.fileSize,
        speed: session.speed,
        progress: session.progress,
      ));
    }
  }
  
  /// Dispose engine
  void dispose() {
    _activeSessions.clear();
    _progressCallbacks.clear();
  }
}

/// Transfer session for tracking progress
class _TransferSession {
  final String transferId;
  final String fileId;
  final int totalChunks;
  final int chunkSize;
  final int fileSize;
  
  final Set<int> _completedChunks = {};
  DateTime? _startTime;
  DateTime? _lastUpdateTime;
  int _bytesAtLastUpdate = 0;
  double _currentSpeed = 0.0;
  bool _isCancelled = false;
  String? currentDeviceId;
  
  _TransferSession({
    required this.transferId,
    required this.fileId,
    required this.totalChunks,
    required this.chunkSize,
    required this.fileSize,
  }) {
    _startTime = DateTime.now();
    _lastUpdateTime = _startTime;
  }
  
  void markChunkSent(int index) {
    _completedChunks.add(index);
    _updateSpeed();
  }
  
  void markChunkReceived(int index) {
    _completedChunks.add(index);
    _updateSpeed();
  }
  
  void _updateSpeed() {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastUpdateTime!).inMilliseconds / 1000.0;
    
    if (timeDiff > 0) {
      final bytesDiff = bytesTransferred - _bytesAtLastUpdate;
      _currentSpeed = bytesDiff / timeDiff;
      
      _lastUpdateTime = now;
      _bytesAtLastUpdate = bytesTransferred;
    }
  }
  
  void cancel() {
    _isCancelled = true;
  }
  
  bool get isCancelled => _isCancelled;
  
  int get chunksCompleted => _completedChunks.length;
  
  int get bytesTransferred => chunksCompleted * chunkSize;
  
  double get progress => totalChunks > 0 ? chunksCompleted / totalChunks : 0.0;
  
  double get speed => _currentSpeed;
  
  Duration? get elapsed => _startTime != null
      ? DateTime.now().difference(_startTime!)
      : null;
}

/// Chunk transfer progress model
class ChunkTransferProgress {
  final String transferId;
  final String fileId;
  final int totalChunks;
  final int chunksCompleted;
  final int bytesTransferred;
  final int totalBytes;
  final double speed; // bytes per second
  final double progress; // 0.0 to 1.0
  
  const ChunkTransferProgress({
    required this.transferId,
    required this.fileId,
    required this.totalChunks,
    required this.chunksCompleted,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.speed,
    required this.progress,
  });
  
  /// Get formatted speed
  String get formattedSpeed {
    if (speed < 1024) return '${speed.toStringAsFixed(0)} B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
  
  /// Get estimated time remaining
  Duration? get estimatedTimeRemaining {
    if (speed == 0) return null;
    final remainingBytes = totalBytes - bytesTransferred;
    return Duration(seconds: (remainingBytes / speed).ceil());
  }
}
