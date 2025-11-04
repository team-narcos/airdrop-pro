import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import '../discovery/discovery_engine.dart';
import '../security/crypto_service.dart';
import '../transport/transport.dart';
import '../transport/webrtc_transport.dart';
import '../transport/wifi_direct_transport.dart';
import '../transport/ble_transport.dart';

/// Simple job model (Phase 3 scaffold)
class TransferJob {
  final String id;
  final String fileName;
  final int totalBytes;
  final String peerId;
  final int priority; // higher is earlier
  final int retryCount;
  final int maxRetries;
  TransferJob({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.peerId,
    this.priority = 0,
    this.retryCount = 0,
    this.maxRetries = 3,
  });
  
  TransferJob copyWithRetry() => TransferJob(
    id: id,
    fileName: fileName,
    totalBytes: totalBytes,
    peerId: peerId,
    priority: priority,
    retryCount: retryCount + 1,
    maxRetries: maxRetries,
  );
}

/// Transfer manager coordinates discovery, transports and chunking/resume.
class TransferManager {
  final DiscoveryEngine discovery;
  final Transport primaryTransport; // e.g., WebRTC
  final List<Transport> fallbacks; // Wi‑Fi Direct, BLE
  final CryptoService crypto;

  final _progress = StreamController<TransferProgress>.broadcast();
  Stream<TransferProgress> get progress => _progress.stream;

  final _queue = <TransferJob>[];
  final _pausedJobs = <String, TransferJob>{};
  final _resumeOffsets = <String, int>{};
  final _activeTransfers = <String, _ActiveTransfer>{};
  final _retryTimers = <String, Timer>{};
  bool _isSending = false;
  Timer? _mockTimer;

  TransferManager({
    required this.discovery,
    required this.primaryTransport,
    required this.fallbacks,
    required this.crypto,
  });

  Future<void> initialize() async {
    await discovery.start();
    await primaryTransport.initialize();
    for (final t in fallbacks) {
      await t.initialize();
    }
  }

  Future<void> dispose() async {
    await discovery.stop();
    await primaryTransport.dispose();
    for (final t in fallbacks) {
      await t.dispose();
    }
    _mockTimer?.cancel();
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    await _progress.close();
  }

  /// Enqueue a job; returns the id
  String enqueue(TransferJob job) {
    _queue.add(job);
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    _progress.add(TransferProgress(
      id: job.id,
      fileName: job.fileName,
      totalBytes: job.totalBytes,
      sentBytes: 0,
      speedMbps: 0,
      eta: Duration.zero,
      state: TransferState.queued,
    ));
    _pump();
    return job.id;
  }

  /// Pause an active transfer
  void pauseTransfer(String id) {
    final active = _activeTransfers[id];
    if (active != null && active.state == TransferState.transferring) {
      active.timer?.cancel();
      _pausedJobs[id] = active.job;
      _resumeOffsets[id] = active.sentBytes;
      _activeTransfers.remove(id);
      _progress.add(TransferProgress(
        id: id,
        fileName: active.job.fileName,
        totalBytes: active.job.totalBytes,
        sentBytes: active.sentBytes,
        speedMbps: 0,
        eta: Duration.zero,
        state: TransferState.paused,
      ));
      _isSending = false;
      _pump();
    }
  }

  /// Resume a paused transfer
  void resumeTransfer(String id) {
    final job = _pausedJobs.remove(id);
    if (job != null) {
      _queue.insert(0, job); // High priority
      _pump();
    }
  }

  /// Cancel a transfer (queued, active, or paused)
  void cancelTransfer(String id) {
    // Remove from queue
    _queue.removeWhere((j) => j.id == id);
    
    // Remove from paused
    _pausedJobs.remove(id);
    
    // Cancel active transfer
    final active = _activeTransfers.remove(id);
    if (active != null) {
      active.timer?.cancel();
      _isSending = false;
    }

    // Clear resume offset
    final resume = _resumeOffsets.remove(id) ?? active?.sentBytes ?? 0;
    
    _progress.add(TransferProgress(
      id: id,
      fileName: active?.job.fileName ?? 'Unknown',
      totalBytes: active?.job.totalBytes ?? 0,
      sentBytes: resume,
      speedMbps: 0,
      eta: Duration.zero,
      state: TransferState.failed,
      error: 'Cancelled by user',
    ));
    
    _pump();
  }

  void _pump() {
    if (_isSending || _queue.isEmpty) return;
    final job = _queue.removeAt(0);
    _sendJob(job);
  }

  /// Phase 3: mock data-path sending with protocol selection heuristic.
  Future<void> _sendJob(TransferJob job) async {
    _isSending = true;
    // Heuristic: choose transport by total size
    final mb = job.totalBytes / (1024 * 1024);
    double speedMbps;
    Transport chosen;
    if (mb > 500) {
      chosen = fallbacks.firstWhere((t) => t is WifiDirectTransport, orElse: () => primaryTransport);
      speedMbps = 60; // mock Wi‑Fi Direct
    } else if (mb > 50) {
      chosen = primaryTransport; // WebRTC
      speedMbps = 25;
    } else {
      chosen = fallbacks.firstWhere((t) => t is BleTransport, orElse: () => primaryTransport);
      speedMbps = 1.0; // BLE control path
    }

    _progress.add(TransferProgress(
      id: job.id,
      fileName: job.fileName,
      totalBytes: job.totalBytes,
      sentBytes: 0,
      speedMbps: speedMbps,
      eta: Duration(seconds: max(1, (mb / speedMbps).round())),
      state: TransferState.negotiating,
    ));

    // Simulate transfer with retry logic
    int sent = _resumeOffsets.remove(job.id) ?? 0;
    final chunkBytes = (speedMbps * 1024 * 1024 / 10).round(); // 10 ticks/sec
    _mockTimer?.cancel();
    
    final timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      sent += chunkBytes;
      if (sent > job.totalBytes) sent = job.totalBytes;
      final remaining = job.totalBytes - sent;
      final etaSec = remaining / (speedMbps * 1024 * 1024);
      
      final state = sent >= job.totalBytes ? TransferState.completed : TransferState.transferring;
      
      _activeTransfers[job.id] = _ActiveTransfer(
        job: job,
        timer: t,
        sentBytes: sent,
        state: state,
      );
      
      _progress.add(TransferProgress(
        id: job.id,
        fileName: job.fileName,
        totalBytes: job.totalBytes,
        sentBytes: sent,
        speedMbps: speedMbps,
        eta: Duration(milliseconds: max(0, (etaSec * 1000).round())),
        state: state,
      ));
      
      if (sent >= job.totalBytes) {
        t.cancel();
        _activeTransfers.remove(job.id);
        _resumeOffsets.remove(job.id);
        _isSending = false;
        _pump();
      }
    });
    
    // Simulate random failures for retry testing (10% chance)
    if (Random().nextDouble() < 0.1 && job.retryCount < job.maxRetries) {
      await Future.delayed(Duration(milliseconds: Random().nextInt(2000) + 500));
      timer.cancel();
      _activeTransfers.remove(job.id);
      _handleTransferFailure(job, 'Network timeout');
      return;
    }
    
    _mockTimer = timer;
  }
  
  void _handleTransferFailure(TransferJob job, String error) {
    if (job.retryCount >= job.maxRetries) {
      // Max retries exceeded
      _progress.add(TransferProgress(
        id: job.id,
        fileName: job.fileName,
        totalBytes: job.totalBytes,
        sentBytes: _resumeOffsets[job.id] ?? 0,
        speedMbps: 0,
        eta: Duration.zero,
        state: TransferState.failed,
        error: '$error (max retries exceeded)',
        retryCount: job.retryCount,
      ));
      _isSending = false;
      _pump();
      return;
    }
    
    // Exponential backoff: 2^retryCount seconds
    final backoffSeconds = pow(2, job.retryCount).toInt();
    _progress.add(TransferProgress(
      id: job.id,
      fileName: job.fileName,
      totalBytes: job.totalBytes,
      sentBytes: _resumeOffsets[job.id] ?? 0,
      speedMbps: 0,
      eta: Duration(seconds: backoffSeconds),
      state: TransferState.failed,
      error: '$error (retrying in ${backoffSeconds}s)',
      retryCount: job.retryCount,
    ));
    
    // Schedule retry
    _retryTimers[job.id]?.cancel();
    _retryTimers[job.id] = Timer(Duration(seconds: backoffSeconds), () {
      _retryTimers.remove(job.id);
      final retryJob = job.copyWithRetry();
      _queue.insert(0, retryJob);
      _isSending = false;
      _pump();
    });
  }
}

class TransferProgress {
  final String id;
  final String fileName;
  final int totalBytes;
  final int sentBytes;
  final double speedMbps;
  final Duration eta;
  final TransferState state;
  final String? error;
  final int retryCount;

  TransferProgress({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.sentBytes,
    required this.speedMbps,
    required this.eta,
    required this.state,
    this.error,
    this.retryCount = 0,
  });
  
  double get progress => totalBytes > 0 ? sentBytes / totalBytes : 0.0;
}

enum TransferState { queued, negotiating, transferring, paused, completed, failed }

class _ActiveTransfer {
  final TransferJob job;
  final Timer? timer;
  final int sentBytes;
  final TransferState state;
  
  _ActiveTransfer({
    required this.job,
    this.timer,
    required this.sentBytes,
    required this.state,
  });
}
