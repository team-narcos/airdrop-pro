import 'package:drift/drift.dart';
import 'package:drift/web.dart' as drift_web;
import 'package:drift/native.dart' as drift_native;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// part 'app_database.g.dart'; // Skipped due to Dart 3.2 incompatibility
import 'app_database_tables.dart';

@DataClassName('TrustedDeviceRecord')
class TrustedDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get name => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

@DataClassName('TransferHistoryRecord')
class TransferHistory extends Table {
  TextColumn get id => text()();
  TextColumn get fileName => text()();
  IntColumn get totalBytes => integer()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get success => boolean()();
  TextColumn get peerId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [TrustedDevices, TransferHistory])
class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(kIsWeb ? _openWeb() : _openNative());

  @override
  int get schemaVersion => 1;
  
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => [
    trustedDevices,
    transferHistory,
  ];
  
  late final $TrustedDevicesTable trustedDevices = $TrustedDevicesTable(this);
  late final $TransferHistoryTable transferHistory = $TransferHistoryTable(this);

  // Trusted devices methods
  Future<List<TrustedDeviceRecord>> getAllTrustedDevices() => select(trustedDevices).get();

  Future<void> addTrustedDevice({required String deviceId, required String name}) {
    return into(trustedDevices).insertOnConflictUpdate(
      TrustedDevicesCompanion.insert(
        deviceId: deviceId,
        name: name,
        addedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeTrustedDevice(String deviceId) {
    return (delete(trustedDevices)..where((t) => t.deviceId.equals(deviceId))).go();
  }

  Future<bool> isDeviceTrusted(String deviceId) async {
    final query = select(trustedDevices)..where((t) => t.deviceId.equals(deviceId));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  // Transfer history methods
  Future<List<TransferHistoryRecord>> getAllTransferHistory() {
    return (select(transferHistory)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).get();
  }

  Future<void> addTransferHistory({
    required String id,
    required String fileName,
    required int totalBytes,
    required bool success,
    required String peerId,
  }) {
    return into(transferHistory).insert(
      TransferHistoryCompanion.insert(
        id: id,
        fileName: fileName,
        totalBytes: totalBytes,
        timestamp: DateTime.now(),
        success: success,
        peerId: peerId,
      ),
    );
  }

  Future<void> clearTransferHistory() => delete(transferHistory).go();
}

QueryExecutor _openWeb() {
  return drift_web.WebDatabase.withStorage(
    drift_web.DriftWebStorage.indexedDbIfSupported('airdrop_db'),
  );
}

QueryExecutor _openNative() {
  return drift_native.LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'airdrop.sqlite');
    return drift_native.NativeDatabase.createInBackground(dbPath);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
