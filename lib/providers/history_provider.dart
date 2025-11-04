import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/transfer/transfer_manager.dart';
import '../core/platform/platform_adapter.dart';
import '../data/history/history_repository.dart';
import 'transfer_provider.dart';

class TransferRecord {
  final String id;
  final String fileName;
  final int totalBytes;
  final DateTime timestamp;
  final bool success;

  const TransferRecord({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.timestamp,
    required this.success,
  });
}

// History Repository Provider - must be async to properly initialize database
final historyRepositoryProvider = FutureProvider<HistoryRepository>((ref) async {
  final repo = HistoryRepository();
  
  // Only initialize database on supported platforms
  if (PlatformAdapter.supportsSQLite) {
    try {
      await repo.initialize();  // CRITICAL: Must await database initialization
      print('[History] Repository initialized successfully');
    } catch (e) {
      print('[History] Error initializing repository: $e');
    }
  } else {
    print('[History] SQLite not supported on this platform (web)');
  }
  
  return repo;
});

class TransferHistoryNotifier extends StateNotifier<List<TransferRecord>> {
  TransferHistoryNotifier(this.ref, this.repository) : super(const []) {
    _loadHistory();
    
    ref.listen<AsyncValue<TransferProgress>>(transferProgressProvider, (prev, next) {
      next.whenData((p) {
        if (p.state == TransferState.completed) {
          final record = TransferRecord(
            id: p.id,
            fileName: p.fileName,
            totalBytes: p.totalBytes,
            timestamp: DateTime.now(),
            success: true,
          );
          
          // Add to state
          state = [record, ...state];
          
          // Save to database
          _saveToDatabase(record);
        } else if (p.state == TransferState.failed) {
          final record = TransferRecord(
            id: p.id,
            fileName: p.fileName,
            totalBytes: p.totalBytes,
            timestamp: DateTime.now(),
            success: false,
          );
          
          // Add to state
          state = [record, ...state];
          
          // Save to database
          _saveToDatabase(record);
        }
      });
    });
  }

  final Ref ref;
  final HistoryRepository repository;
  
  Future<void> _loadHistory() async {
    if (!PlatformAdapter.supportsSQLite) {
      print('[History] History loading skipped on web platform');
      return;
    }
    
    try {
      final rows = await repository.recent(limit: 100);
      final records = rows.map((row) {
        return TransferRecord(
          id: row['id'] as String,
          fileName: row['file_name'] as String,
          totalBytes: row['size_bytes'] as int,
          timestamp: DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int),
          success: row['status'] == 'completed',
        );
      }).toList();
      
      state = records;
    } catch (e) {
      print('[History] Error loading history: $e');
    }
  }
  
  Future<void> _saveToDatabase(TransferRecord record) async {
    if (!PlatformAdapter.supportsSQLite) {
      return; // Skip database operations on web
    }
    
    try {
      await repository.upsert({
        'id': record.id,
        'file_name': record.fileName,
        'size_bytes': record.totalBytes,
        'peer_name': 'Unknown',
        'direction': 'sent',
        'status': record.success ? 'completed' : 'failed',
        'started_at': record.timestamp.millisecondsSinceEpoch,
        'completed_at': record.timestamp.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('[History] Error saving to database: $e');
    }
  }
  
  void addRecord(TransferRecord record) {
    state = [record, ...state];
    _saveToDatabase(record);
  }

  void clear() => state = const [];
}

final transferHistoryProvider = StateNotifierProvider<TransferHistoryNotifier, List<TransferRecord>>((ref) {
  // Watch the async repository and provide it when ready
  final repositoryAsync = ref.watch(historyRepositoryProvider);
  
  return repositoryAsync.when(
    data: (repository) => TransferHistoryNotifier(ref, repository),
    loading: () {
      // Return a notifier with a placeholder repository while loading
      // This ensures the UI doesn't crash while waiting for DB initialization
      print('[History] Waiting for repository to initialize...');
      final placeholderRepo = HistoryRepository();
      return TransferHistoryNotifier(ref, placeholderRepo);
    },
    error: (err, stack) {
      print('[History] Error initializing repository: $err');
      final fallbackRepo = HistoryRepository();
      return TransferHistoryNotifier(ref, fallbackRepo);
    },
  );
});
