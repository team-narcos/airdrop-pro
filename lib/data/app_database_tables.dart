import 'package:drift/drift.dart';
import 'app_database.dart';

class $TrustedDevicesTable extends TrustedDevices with TableInfo<$TrustedDevicesTable, TrustedDeviceRecord> {
  $TrustedDevicesTable(this.attachedDatabase);
  
  final GeneratedDatabase attachedDatabase;
  
  @override
  List<GeneratedColumn> get $columns => [deviceId, name, addedAt];
  
  @override
  String get aliasedName => actualTableName;
  
  @override
  String get actualTableName => 'trusted_devices';
  
  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  
  @override
  TrustedDeviceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    return TrustedDeviceRecord(
      deviceId: data['device_id'],
      name: data['name'],
      addedAt: DateTime.parse(data['added_at']),
    );
  }
  
  @override
  $TrustedDevicesTable createAlias(String alias) {
    return $TrustedDevicesTable(attachedDatabase);
  }
}

class $TransferHistoryTable extends TransferHistory with TableInfo<$TransferHistoryTable, TransferHistoryRecord> {
  $TransferHistoryTable(this.attachedDatabase);
  
  final GeneratedDatabase attachedDatabase;
  
  @override
  List<GeneratedColumn> get $columns => [id, fileName, totalBytes, timestamp, success, peerId];
  
  @override
  String get aliasedName => actualTableName;
  
  @override
  String get actualTableName => 'transfer_history';
  
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  
  @override
  TransferHistoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    return TransferHistoryRecord(
      id: data['id'],
      fileName: data['file_name'],
      totalBytes: data['total_bytes'],
      timestamp: DateTime.parse(data['timestamp']),
      success: data['success'] == 1,
      peerId: data['peer_id'],
    );
  }
  
  @override
  $TransferHistoryTable createAlias(String alias) {
    return $TransferHistoryTable(attachedDatabase);
  }
}

class TrustedDeviceRecord {
  final String deviceId;
  final String name;
  final DateTime addedAt;
  
  TrustedDeviceRecord({
    required this.deviceId,
    required this.name,
    required this.addedAt,
  });
}

class TransferHistoryRecord {
  final String id;
  final String fileName;
  final int totalBytes;
  final DateTime timestamp;
  final bool success;
  final String peerId;
  
  TransferHistoryRecord({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.timestamp,
    required this.success,
    required this.peerId,
  });
}
