import 'dart:async';
import 'package:sqflite/sqflite.dart' as sqf;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:path/path.dart' as p;
import '../../core/platform/platform_gates.dart';

class HistoryRepository {
  sqf.Database? _db;

  Future<void> initialize() async {
    if (PlatformGates.isWindows || PlatformGates.isLinux || PlatformGates.isMacOS) {
      ffi.sqfliteFfiInit();
      sqf.databaseFactory = ffi.databaseFactoryFfi;
    }
    final dbPath = await sqf.getDatabasesPath();
    _db = await sqf.openDatabase(
      p.join(dbPath, 'airdrop_history.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE transfers (
            id TEXT PRIMARY KEY,
            file_name TEXT,
            size_bytes INTEGER,
            peer_name TEXT,
            direction TEXT,
            status TEXT,
            started_at INTEGER,
            completed_at INTEGER
          )
        ''');
      },
    );
  }

  Future<void> upsert(Map<String, Object?> row) async {
    await _db!.insert('transfers', row, conflictAlgorithm: sqf.ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> recent({int limit = 100}) async {
    return _db!.query('transfers', orderBy: 'started_at DESC', limit: limit);
  }
}
