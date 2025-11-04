import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:archive/archive.dart';
import 'advanced_transfer_protocol.dart';

/// Advanced transfer queue manager
/// Supports: Batch transfers, priority queue, auto-resume, compression
class TransferQueueManager {
  final AdvancedTransferProtocol _protocol;
  
  final _queue = Queue<TransferQueueItem>();
  final _activeTransfers = <String, TransferQueueItem>{};
  final _completedTransfers = <String, TransferQueueItem>{};
  final _failedTransfers = <String, TransferQueueItem>{};
  
  final _queueStreamController = StreamController<List<TransferQueueItem>>.broadcast();
  Stream<List<TransferQueueItem>> get queueStream => _queueStreamController.stream;
  
  final _transferUpdateController = StreamController<TransferUpdate>.broadcast();
  Stream<TransferUpdate> get transferUpdateStream => _transferUpdateController.stream;
  
  int _maxConcurrentTransfers = 3;
  bool _isProcessing = false;
  bool _autoResumeEnabled = true;
  bool _compressionEnabled = false;
  int _maxRetries = 3;
  
  TransferQueueManager(this._protocol);
  
  /// Add single file to queue
  Future<String> addFileToQueue({
    required File file,
    required String recipientAddress,
    required int recipientPort,
    TransferPriority priority = TransferPriority.normal,
    bool enableCompression = false,
  }) async {
    final item = TransferQueueItem(
      id: _generateTransferId(),
      file: file,
      recipientAddress: recipientAddress,
      recipientPort: recipientPort,
      priority: priority,
      enableCompression: enableCompression || _compressionEnabled,
      addedAt: DateTime.now(),
    );
    
    _addToQueue(item);
    return item.id;
  }
  
  /// Add batch of files to queue
  Future<List<String>> addBatchToQueue({
    required List<File> files,
    required String recipientAddress,
    required int recipientPort,
    TransferPriority priority = TransferPriority.normal,
    bool enableCompression = false,
    bool createArchive = false,
  }) async {
    final ids = <String>[];
    
    if (createArchive && files.length > 1) {
      // Create archive of all files
      final archive = await _createArchive(files);
      final archiveFile = await _saveArchive(archive);
      
      final id = await addFileToQueue(
        file: archiveFile,
        recipientAddress: recipientAddress,
        recipientPort: recipientPort,
        priority: priority,
        enableCompression: enableCompression,
      );
      
      ids.add(id);
    } else {
      // Add each file individually
      for (final file in files) {
        final id = await addFileToQueue(
          file: file,
          recipientAddress: recipientAddress,
          recipientPort: recipientPort,
          priority: priority,
          enableCompression: enableCompression,
        );
        ids.add(id);
      }
    }
    
    return ids;
  }
  
  /// Add folder to queue (recursive)
  Future<List<String>> addFolderToQueue({
    required Directory folder,
    required String recipientAddress,
    required int recipientPort,
    TransferPriority priority = TransferPriority.normal,
    bool enableCompression = false,
    bool createArchive = true,
  }) async {
    final files = await _getFolderFiles(folder);
    
    return addBatchToQueue(
      files: files,
      recipientAddress: recipientAddress,
      recipientPort: recipientPort,
      priority: priority,
      enableCompression: enableCompression,
      createArchive: createArchive,
    );
  }
  
  /// Start processing queue
  void startQueue() {
    if (_isProcessing) return;
    
    _isProcessing = true;
    print('[TransferQueue] Starting queue processing...');
    
    _processQueue();
  }
  
  /// Stop processing queue
  void stopQueue() {
    _isProcessing = false;
    print('[TransferQueue] Queue processing stopped');
  }
  
  /// Pause a specific transfer
  void pauseTransfer(String transferId) {
    final item = _activeTransfers[transferId];
    if (item != null) {
      item.status = TransferStatus.paused;
      _emitUpdate(item);
    }
  }
  
  /// Resume a specific transfer
  void resumeTransfer(String transferId) {
    final item = _activeTransfers[transferId] ?? 
                _failedTransfers[transferId] ??
                _queue.firstWhere((i) => i.id == transferId, orElse: () => throw Exception('Transfer not found'));
    
    if (item.status == TransferStatus.paused || item.status == TransferStatus.failed) {
      item.status = TransferStatus.queued;
      item.retryCount = 0;
      
      // Move back to queue with high priority
      _queue.addFirst(item);
      _emitQueueUpdate();
      
      if (_isProcessing) {
        _processQueue();
      }
    }
  }
  
  /// Cancel a specific transfer
  void cancelTransfer(String transferId) {
    // Remove from queue
    _queue.removeWhere((item) => item.id == transferId);
    
    // Remove from active
    final activeItem = _activeTransfers.remove(transferId);
    if (activeItem != null) {
      activeItem.status = TransferStatus.cancelled;
      _emitUpdate(activeItem);
    }
    
    _emitQueueUpdate();
  }
  
  /// Clear completed transfers
  void clearCompleted() {
    _completedTransfers.clear();
    _emitQueueUpdate();
  }
  
  /// Clear failed transfers
  void clearFailed() {
    _failedTransfers.clear();
    _emitQueueUpdate();
  }
  
  /// Get queue statistics
  TransferQueueStats getStatistics() {
    return TransferQueueStats(
      queued: _queue.length,
      active: _activeTransfers.length,
      completed: _completedTransfers.length,
      failed: _failedTransfers.length,
      totalBytes: _calculateTotalBytes(),
      transferredBytes: _calculateTransferredBytes(),
    );
  }
  
  /// Add item to queue
  void _addToQueue(TransferQueueItem item) {
    // Insert based on priority
    if (item.priority == TransferPriority.high) {
      _queue.addFirst(item);
    } else {
      _queue.add(item);
    }
    
    print('[TransferQueue] Added to queue: ${item.file.path} (priority: ${item.priority.name})');
    
    _emitQueueUpdate();
    
    // Auto-start if not processing
    if (!_isProcessing) {
      startQueue();
    } else {
      _processQueue();
    }
  }
  
  /// Process queue
  Future<void> _processQueue() async {
    while (_isProcessing && _queue.isNotEmpty && _activeTransfers.length < _maxConcurrentTransfers) {
      final item = _queue.removeFirst();
      
      // Skip if paused
      if (item.status == TransferStatus.paused) {
        continue;
      }
      
      // Start transfer
      await _startTransfer(item);
    }
  }
  
  /// Start a single transfer
  Future<void> _startTransfer(TransferQueueItem item) async {
    try {
      print('[TransferQueue] Starting transfer: ${item.file.path}');
      
      item.status = TransferStatus.transferring;
      item.startedAt = DateTime.now();
      _activeTransfers[item.id] = item;
      
      _emitUpdate(item);
      _emitQueueUpdate();
      
      // Compress if enabled
      File fileToSend = item.file;
      if (item.enableCompression) {
        fileToSend = await _compressFile(item.file);
      }
      
      // Listen to transfer progress
      final progressSubscription = _protocol.progressStream.listen((progress) {
        item.progress = progress.progress;
        item.bytesTransferred = progress.bytesTransferred;
        item.speed = progress.speedBytesPerSecond;
        item.estimatedTimeRemaining = progress.estimatedTimeRemaining;
        
        _emitUpdate(item);
      });
      
      // Execute transfer
      final result = await _protocol.sendFile(
        file: fileToSend,
        recipientAddress: item.recipientAddress,
        recipientPort: item.recipientPort,
        enableResume: _autoResumeEnabled,
        enableCompression: item.enableCompression,
      );
      
      await progressSubscription.cancel();
      
      if (result.success) {
        await _handleTransferSuccess(item, result);
      } else {
        await _handleTransferFailure(item, result.error ?? 'Unknown error');
      }
      
    } catch (e) {
      print('[TransferQueue] Transfer error: $e');
      await _handleTransferFailure(item, e.toString());
    } finally {
      _activeTransfers.remove(item.id);
      
      // Continue processing queue
      if (_isProcessing) {
        _processQueue();
      }
    }
  }
  
  /// Handle successful transfer
  Future<void> _handleTransferSuccess(TransferQueueItem item, TransferResult result) async {
    print('[TransferQueue] Transfer completed: ${item.file.path}');
    
    item.status = TransferStatus.completed;
    item.completedAt = DateTime.now();
    item.progress = 100.0;
    
    _completedTransfers[item.id] = item;
    
    _emitUpdate(item);
    _emitQueueUpdate();
    
    // Notify completion
    _transferUpdateController.add(TransferUpdate(
      transferId: item.id,
      type: TransferUpdateType.completed,
      message: 'Transfer completed successfully',
    ));
  }
  
  /// Handle failed transfer
  Future<void> _handleTransferFailure(TransferQueueItem item, String error) async {
    print('[TransferQueue] Transfer failed: ${item.file.path} - $error');
    
    item.retryCount++;
    
    // Retry if enabled
    if (item.retryCount < _maxRetries && _autoResumeEnabled) {
      print('[TransferQueue] Retrying transfer (${item.retryCount}/$_maxRetries)');
      
      item.status = TransferStatus.retrying;
      _emitUpdate(item);
      
      // Add back to queue with high priority
      await Future.delayed(Duration(seconds: 2 * item.retryCount));
      
      if (_isProcessing) {
        _queue.addFirst(item);
        _processQueue();
      }
    } else {
      // Mark as failed
      item.status = TransferStatus.failed;
      item.error = error;
      
      _failedTransfers[item.id] = item;
      
      _emitUpdate(item);
      _emitQueueUpdate();
      
      // Notify failure
      _transferUpdateController.add(TransferUpdate(
        transferId: item.id,
        type: TransferUpdateType.failed,
        message: error,
      ));
    }
  }
  
  /// Create archive from files
  Future<Archive> _createArchive(List<File> files) async {
    final archive = Archive();
    
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split(Platform.pathSeparator).last;
      
      archive.addFile(ArchiveFile(
        fileName,
        bytes.length,
        bytes,
      ));
    }
    
    return archive;
  }
  
  /// Save archive to temporary file
  Future<File> _saveArchive(Archive archive) async {
    final encoder = ZipEncoder();
    final zipBytes = encoder.encode(archive);
    
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archiveFile = File('${tempDir.path}/transfer_$timestamp.zip');
    
    await archiveFile.writeAsBytes(zipBytes!);
    
    return archiveFile;
  }
  
  /// Get all files in a folder recursively
  Future<List<File>> _getFolderFiles(Directory folder) async {
    final files = <File>[];
    
    await for (final entity in folder.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    
    return files;
  }
  
  /// Compress a file
  Future<File> _compressFile(File file) async {
    // Simple compression using gzip
    final bytes = await file.readAsBytes();
    final compressed = GZipEncoder().encode(bytes);
    
    final tempDir = Directory.systemTemp;
    final compressedFile = File('${tempDir.path}/${file.path.split(Platform.pathSeparator).last}.gz');
    
    await compressedFile.writeAsBytes(compressed!);
    
    return compressedFile;
  }
  
  /// Calculate total bytes in queue
  int _calculateTotalBytes() {
    int total = 0;
    
    for (final item in _queue) {
      total += item.file.lengthSync();
    }
    
    for (final item in _activeTransfers.values) {
      total += item.file.lengthSync();
    }
    
    return total;
  }
  
  /// Calculate transferred bytes
  int _calculateTransferredBytes() {
    int total = 0;
    
    for (final item in _activeTransfers.values) {
      total += item.bytesTransferred;
    }
    
    for (final item in _completedTransfers.values) {
      total += item.file.lengthSync();
    }
    
    return total;
  }
  
  /// Emit queue update
  void _emitQueueUpdate() {
    final allItems = [
      ..._queue,
      ..._activeTransfers.values,
      ..._completedTransfers.values,
      ..._failedTransfers.values,
    ];
    
    _queueStreamController.add(allItems);
  }
  
  /// Emit single item update
  void _emitUpdate(TransferQueueItem item) {
    _transferUpdateController.add(TransferUpdate(
      transferId: item.id,
      type: TransferUpdateType.progress,
      progress: item.progress,
      speed: item.speed,
      eta: item.estimatedTimeRemaining,
    ));
  }
  
  /// Generate transfer ID
  String _generateTransferId() {
    return 'transfer-${DateTime.now().millisecondsSinceEpoch}-${_queue.length}';
  }
  
  /// Configure queue settings
  void configureQueue({
    int? maxConcurrentTransfers,
    bool? autoResumeEnabled,
    bool? compressionEnabled,
    int? maxRetries,
  }) {
    if (maxConcurrentTransfers != null) {
      _maxConcurrentTransfers = maxConcurrentTransfers;
    }
    if (autoResumeEnabled != null) {
      _autoResumeEnabled = autoResumeEnabled;
    }
    if (compressionEnabled != null) {
      _compressionEnabled = compressionEnabled;
    }
    if (maxRetries != null) {
      _maxRetries = maxRetries;
    }
    
    print('[TransferQueue] Configuration updated');
  }
  
  /// Dispose resources
  void dispose() {
    stopQueue();
    _queueStreamController.close();
    _transferUpdateController.close();
  }
}

/// Transfer queue item
class TransferQueueItem {
  final String id;
  final File file;
  final String recipientAddress;
  final int recipientPort;
  final TransferPriority priority;
  final bool enableCompression;
  final DateTime addedAt;
  
  TransferStatus status;
  DateTime? startedAt;
  DateTime? completedAt;
  double progress;
  int bytesTransferred;
  double speed;
  Duration? estimatedTimeRemaining;
  int retryCount;
  String? error;
  
  TransferQueueItem({
    required this.id,
    required this.file,
    required this.recipientAddress,
    required this.recipientPort,
    required this.priority,
    required this.enableCompression,
    required this.addedAt,
    this.status = TransferStatus.queued,
    this.startedAt,
    this.completedAt,
    this.progress = 0.0,
    this.bytesTransferred = 0,
    this.speed = 0.0,
    this.estimatedTimeRemaining,
    this.retryCount = 0,
    this.error,
  });
  
  String get fileName => file.path.split(Platform.pathSeparator).last;
  
  int get fileSize => file.lengthSync();
  
  String get fileSizeFormatted {
    final bytes = fileSize;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  String get speedFormatted {
    final mbps = (speed * 8) / (1024 * 1024);
    if (mbps < 1) {
      final kbps = (speed * 8) / 1024;
      return '${kbps.toStringAsFixed(1)} Kbps';
    }
    return '${mbps.toStringAsFixed(2)} Mbps';
  }
  
  String get etaFormatted {
    if (estimatedTimeRemaining == null) return '--';
    
    final eta = estimatedTimeRemaining!;
    if (eta.inSeconds < 60) {
      return '${eta.inSeconds}s';
    } else if (eta.inMinutes < 60) {
      return '${eta.inMinutes}m ${eta.inSeconds % 60}s';
    } else {
      return '${eta.inHours}h ${eta.inMinutes % 60}m';
    }
  }
}

/// Transfer priority
enum TransferPriority {
  low,
  normal,
  high,
}

/// Transfer status
enum TransferStatus {
  queued,
  transferring,
  paused,
  completed,
  failed,
  cancelled,
  retrying,
}

/// Transfer update
class TransferUpdate {
  final String transferId;
  final TransferUpdateType type;
  final double? progress;
  final double? speed;
  final Duration? eta;
  final String? message;
  
  TransferUpdate({
    required this.transferId,
    required this.type,
    this.progress,
    this.speed,
    this.eta,
    this.message,
  });
}

/// Transfer update type
enum TransferUpdateType {
  progress,
  completed,
  failed,
  paused,
  resumed,
  cancelled,
}

/// Transfer queue statistics
class TransferQueueStats {
  final int queued;
  final int active;
  final int completed;
  final int failed;
  final int totalBytes;
  final int transferredBytes;
  
  TransferQueueStats({
    required this.queued,
    required this.active,
    required this.completed,
    required this.failed,
    required this.totalBytes,
    required this.transferredBytes,
  });
  
  double get overallProgress {
    if (totalBytes == 0) return 0;
    return (transferredBytes / totalBytes * 100).clamp(0, 100);
  }
  
  int get totalTransfers => queued + active + completed + failed;
}
