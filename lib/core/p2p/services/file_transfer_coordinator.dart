import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:synchronized/synchronized.dart';
import '../models/models.dart';
import 'p2p_client.dart';
import 'p2p_server.dart';
import 'chunk_transfer_engine.dart';
import 'file_chunking_service.dart';

/// Coordinates complete file transfers with metadata exchange and queue management
class FileTransferCoordinator {
  final ChunkTransferEngine _chunkEngine;
  final _uuid = const Uuid();
  final _lock = Lock();
  
  // Transfer queue
  final List<QueuedTransfer> _transferQueue = [];
  bool _isProcessingQueue = false;
  
  // Active transfers
  final Map<String, P2PTransfer> _activeTransfers = {};
  
  // Transfer streams
  final _transferUpdatesController = StreamController<P2PTransfer>.broadcast();
  
  FileTransferCoordinator({
    required ChunkTransferEngine chunkEngine,
  }) : _chunkEngine = chunkEngine;
  
  /// Stream of transfer updates
  Stream<P2PTransfer> get transferUpdates => _transferUpdatesController.stream;
  
  /// Get list of active transfers
  List<P2PTransfer> get activeTransfers => _activeTransfers.values.toList();
  
  /// Get list of queued transfers
  List<QueuedTransfer> get queuedTransfers => List.unmodifiable(_transferQueue);
  
  /// Send file(s) to a device
  Future<String> sendFiles({
    required List<String> filePaths,
    required P2PDevice device,
    required P2PClient client,
    int chunkSize = FileChunkingService.defaultChunkSize,
  }) async {
    debugPrint('[FileTransferCoordinator] Preparing to send ${filePaths.length} files');
    
    // Generate transfer ID
    final transferId = _uuid.v4();
    
    // Collect file information
    final fileInfoList = <LocalFileInfo>[];
    int totalSize = 0;
    
    for (final filePath in filePaths) {
      final fileInfo = await FileChunkingService.getFileInfo(filePath);
      fileInfoList.add(fileInfo);
      totalSize += fileInfo.size;
    }
    
    // Calculate file hashes asynchronously
    final fileHashes = await Future.wait(
      filePaths.map((path) => FileChunkingService.calculateFileHash(path)),
    );
    
    // Create transfer files
    final transferFiles = <TransferFile>[];
    for (var i = 0; i < fileInfoList.length; i++) {
      final info = fileInfoList[i];
      final fileId = _uuid.v4();
      
      transferFiles.add(TransferFile.forSending(
        id: fileId,
        name: info.name,
        path: info.path,
        size: info.size,
        mimeType: info.mimeType,
        sha256: fileHashes[i],
        chunkSize: chunkSize,
      ));
    }
    
    // Create transfer object
    final transfer = P2PTransfer.sending(
      id: transferId,
      deviceId: device.id,
      files: transferFiles,
    );
    
    // Send file offer
    final fileOfferFiles = transferFiles.map((tf) => FileInfo(
      fileId: tf.id,
      name: tf.name,
      size: tf.size,
      mimeType: tf.mimeType,
      sha256: tf.sha256,
    )).toList();
    
    await client.sendFileOffer(
      transferId: transferId,
      files: fileOfferFiles,
      totalSize: totalSize,
    );
    
    debugPrint('[FileTransferCoordinator] File offer sent, waiting for response...');
    
    // Store transfer (status: pending)
    await _lock.synchronized(() {
      _activeTransfers[transferId] = transfer;
    });
    
    _transferUpdatesController.add(transfer);
    
    return transferId;
  }
  
  /// Handle file offer acceptance
  Future<void> handleFileAccepted({
    required String transferId,
    required List<String> acceptedFileIds,
    required P2PClient client,
  }) async {
    debugPrint('[FileTransferCoordinator] Transfer $transferId accepted');
    
    final transfer = _activeTransfers[transferId];
    if (transfer == null) {
      debugPrint('[FileTransferCoordinator] Transfer not found: $transferId');
      return;
    }
    
    // Filter accepted files
    final acceptedFiles = transfer.files
        .where((f) => acceptedFileIds.contains(f.id))
        .toList();
    
    if (acceptedFiles.isEmpty) {
      debugPrint('[FileTransferCoordinator] No files accepted');
      return;
    }
    
    // Update transfer status
    final updatedTransfer = transfer.copyWith(
      status: TransferStatus.connecting,
      files: acceptedFiles,
      startedAt: DateTime.now(),
    );
    
    await _lock.synchronized(() {
      _activeTransfers[transferId] = updatedTransfer;
    });
    
    _transferUpdatesController.add(updatedTransfer);
    
    // Queue file transfers
    for (final file in acceptedFiles) {
      _queueTransfer(QueuedTransfer(
        transferId: transferId,
        fileId: file.id,
        filePath: file.path,
        client: client,
        direction: TransferDirection.sending,
      ));
    }
    
    // Start processing queue
    _processQueue();
  }
  
  /// Handle incoming file offer
  Future<void> handleFileOffer({
    required FileOfferMessage offer,
    required P2PDevice fromDevice,
    required P2PServer server,
    required Future<bool> Function(FileOfferMessage) shouldAccept,
    required Future<String> Function() getSavePath,
  }) async {
    debugPrint('[FileTransferCoordinator] Received file offer from ${fromDevice.name}');
    
    // Ask user if they want to accept
    final accept = await shouldAccept(offer);
    
    if (!accept) {
      debugPrint('[FileTransferCoordinator] File offer rejected');
      await server.sendMessage(
        fromDevice.id,
        FileRejectMessage(
          transferId: offer.transferId,
          reason: 'User declined',
        ),
      );
      return;
    }
    
    // Get save location
    final savePath = await getSavePath();
    
    // Accept all files
    final acceptedFileIds = offer.files.map((f) => f.fileId).toList();
    
    await server.sendMessage(
      fromDevice.id,
      FileAcceptMessage(
        transferId: offer.transferId,
        acceptedFileIds: acceptedFileIds,
        savePath: savePath,
      ),
    );
    
    // Create transfer files
    final transferFiles = offer.files.map((fileInfo) {
      return TransferFile.forReceiving(
        id: fileInfo.fileId,
        name: fileInfo.name,
        savePath: '$savePath/${fileInfo.name}',
        size: fileInfo.size,
        mimeType: fileInfo.mimeType,
        sha256: fileInfo.sha256,
      );
    }).toList();
    
    // Create transfer object
    final transfer = P2PTransfer.receiving(
      id: offer.transferId,
      deviceId: fromDevice.id,
      files: transferFiles,
    ).copyWith(
      status: TransferStatus.accepted,
      startedAt: DateTime.now(),
    );
    
    await _lock.synchronized(() {
      _activeTransfers[offer.transferId] = transfer;
    });
    
    _transferUpdatesController.add(transfer);
    
    debugPrint('[FileTransferCoordinator] File offer accepted, ready to receive');
  }
  
  /// Queue a transfer
  void _queueTransfer(QueuedTransfer transfer) {
    _transferQueue.add(transfer);
    debugPrint('[FileTransferCoordinator] Queued transfer: ${transfer.fileId}');
  }
  
  /// Process transfer queue
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    
    await _lock.synchronized(() {
      _isProcessingQueue = true;
    });
    
    try {
      while (_transferQueue.isNotEmpty) {
        final queued = _transferQueue.removeAt(0);
        
        try {
          await _executeTransfer(queued);
        } catch (e) {
          debugPrint('[FileTransferCoordinator] Transfer failed: $e');
          _handleTransferError(queued.transferId, queued.fileId, e.toString());
        }
      }
    } finally {
      await _lock.synchronized(() {
        _isProcessingQueue = false;
      });
    }
  }
  
  /// Execute a single file transfer
  Future<void> _executeTransfer(QueuedTransfer queued) async {
    debugPrint('[FileTransferCoordinator] Executing transfer: ${queued.fileId}');
    
    final transfer = _activeTransfers[queued.transferId];
    if (transfer == null) return;
    
    // Update transfer status
    final updatedTransfer = transfer.copyWith(
      status: TransferStatus.transferring,
    );
    
    await _lock.synchronized(() {
      _activeTransfers[queued.transferId] = updatedTransfer;
    });
    
    _transferUpdatesController.add(updatedTransfer);
    
    // Register progress callback
    _chunkEngine.registerProgressCallback(
      queued.transferId,
      (progress) => _handleProgress(queued.transferId, progress),
    );
    
    try {
      if (queued.direction == TransferDirection.sending) {
        // Send file
        await _chunkEngine.sendFile(
          transferId: queued.transferId,
          fileId: queued.fileId,
          filePath: queued.filePath,
          client: queued.client!,
          chunkSize: FileChunkingService.defaultChunkSize,
        );
      } else {
        // Receive file handled by chunk engine listening to messages
        // This path is triggered by incoming chunks
      }
      
      // Mark file as complete
      _handleFileComplete(queued.transferId, queued.fileId);
    } finally {
      _chunkEngine.unregisterProgressCallback(queued.transferId);
    }
  }
  
  /// Handle transfer progress update
  void _handleProgress(String transferId, ChunkTransferProgress progress) {
    final transfer = _activeTransfers[transferId];
    if (transfer == null) return;
    
    // Update file progress
    final updatedFiles = transfer.files.map((file) {
      if (file.id == progress.fileId) {
        return file.copyWith(
          bytesTransferred: progress.bytesTransferred,
        );
      }
      return file;
    }).toList();
    
    final updatedTransfer = transfer.copyWith(files: updatedFiles);
    
    _activeTransfers[transferId] = updatedTransfer;
    _transferUpdatesController.add(updatedTransfer);
  }
  
  /// Handle file completion
  void _handleFileComplete(String transferId, String fileId) {
    final transfer = _activeTransfers[transferId];
    if (transfer == null) return;
    
    // Mark file as complete
    final updatedFiles = transfer.files.map((file) {
      if (file.id == fileId) {
        return file.copyWith(
          status: TransferStatus.completed,
          completedAt: DateTime.now(),
        );
      }
      return file;
    }).toList();
    
    // Check if all files are complete
    final allComplete = updatedFiles.every((f) => f.status == TransferStatus.completed);
    
    final updatedTransfer = transfer.copyWith(
      files: updatedFiles,
      status: allComplete ? TransferStatus.completed : transfer.status,
      completedAt: allComplete ? DateTime.now() : null,
    );
    
    _activeTransfers[transferId] = updatedTransfer;
    _transferUpdatesController.add(updatedTransfer);
    
    debugPrint('[FileTransferCoordinator] File complete: $fileId (all=$allComplete)');
  }
  
  /// Handle transfer error
  void _handleTransferError(String transferId, String fileId, String error) {
    final transfer = _activeTransfers[transferId];
    if (transfer == null) return;
    
    final updatedTransfer = transfer.copyWith(
      status: TransferStatus.failed,
      errorMessage: error,
    );
    
    _activeTransfers[transferId] = updatedTransfer;
    _transferUpdatesController.add(updatedTransfer);
    
    debugPrint('[FileTransferCoordinator] Transfer error: $error');
  }
  
  /// Cancel transfer
  Future<void> cancelTransfer(String transferId) async {
    debugPrint('[FileTransferCoordinator] Cancelling transfer: $transferId');
    
    // Remove from queue
    _transferQueue.removeWhere((t) => t.transferId == transferId);
    
    // Cancel active transfer
    await _chunkEngine.cancelTransfer(transferId);
    
    // Update status
    final transfer = _activeTransfers[transferId];
    if (transfer != null) {
      final updatedTransfer = transfer.copyWith(
        status: TransferStatus.cancelled,
      );
      
      _activeTransfers[transferId] = updatedTransfer;
      _transferUpdatesController.add(updatedTransfer);
    }
  }
  
  /// Remove completed transfer
  void removeTransfer(String transferId) {
    _activeTransfers.remove(transferId);
  }
  
  /// Dispose coordinator
  void dispose() {
    _transferUpdatesController.close();
    _activeTransfers.clear();
    _transferQueue.clear();
  }
}

/// Queued transfer item
class QueuedTransfer {
  final String transferId;
  final String fileId;
  final String filePath;
  final P2PClient? client;
  final P2PServer? server;
  final TransferDirection direction;
  
  const QueuedTransfer({
    required this.transferId,
    required this.fileId,
    required this.filePath,
    this.client,
    this.server,
    required this.direction,
  });
}
