// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TrustedDevicesTable extends TrustedDevices
    with TableInfo<$TrustedDevicesTable, TrustedDeviceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrustedDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [deviceId, name, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trusted_devices';
  @override
  VerificationContext validateIntegrity(
      Insertable<TrustedDeviceRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  TrustedDeviceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrustedDeviceRecord(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $TrustedDevicesTable createAlias(String alias) {
    return $TrustedDevicesTable(attachedDatabase, alias);
  }
}

class TrustedDeviceRecord extends DataClass
    implements Insertable<TrustedDeviceRecord> {
  final String deviceId;
  final String name;
  final DateTime addedAt;
  const TrustedDeviceRecord(
      {required this.deviceId, required this.name, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['name'] = Variable<String>(name);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  TrustedDevicesCompanion toCompanion(bool nullToAbsent) {
    return TrustedDevicesCompanion(
      deviceId: Value(deviceId),
      name: Value(name),
      addedAt: Value(addedAt),
    );
  }

  factory TrustedDeviceRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrustedDeviceRecord(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      name: serializer.fromJson<String>(json['name']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'name': serializer.toJson<String>(name),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  TrustedDeviceRecord copyWith(
          {String? deviceId, String? name, DateTime? addedAt}) =>
      TrustedDeviceRecord(
        deviceId: deviceId ?? this.deviceId,
        name: name ?? this.name,
        addedAt: addedAt ?? this.addedAt,
      );
  @override
  String toString() {
    return (StringBuffer('TrustedDeviceRecord(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, name, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrustedDeviceRecord &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          other.addedAt == this.addedAt);
}

class TrustedDevicesCompanion extends UpdateCompanion<TrustedDeviceRecord> {
  final Value<String> deviceId;
  final Value<String> name;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const TrustedDevicesCompanion({
    this.deviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrustedDevicesCompanion.insert({
    required String deviceId,
    required String name,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        name = Value(name),
        addedAt = Value(addedAt);
  static Insertable<TrustedDeviceRecord> custom({
    Expression<String>? deviceId,
    Expression<String>? name,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (name != null) 'name': name,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrustedDevicesCompanion copyWith(
      {Value<String>? deviceId,
      Value<String>? name,
      Value<DateTime>? addedAt,
      Value<int>? rowid}) {
    return TrustedDevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrustedDevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransferHistoryTable extends TransferHistory
    with TableInfo<$TransferHistoryTable, TransferHistoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _successMeta =
      const VerificationMeta('success');
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
      'success', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("success" IN (0, 1))'));
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
      'peer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, fileName, totalBytes, timestamp, success, peerId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransferHistoryRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('success')) {
      context.handle(_successMeta,
          success.isAcceptableOrUnknown(data['success']!, _successMeta));
    } else if (isInserting) {
      context.missing(_successMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(_peerIdMeta,
          peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta));
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferHistoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferHistoryRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      success: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}success'])!,
      peerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_id'])!,
    );
  }

  @override
  $TransferHistoryTable createAlias(String alias) {
    return $TransferHistoryTable(attachedDatabase, alias);
  }
}

class TransferHistoryRecord extends DataClass
    implements Insertable<TransferHistoryRecord> {
  final String id;
  final String fileName;
  final int totalBytes;
  final DateTime timestamp;
  final bool success;
  final String peerId;
  const TransferHistoryRecord(
      {required this.id,
      required this.fileName,
      required this.totalBytes,
      required this.timestamp,
      required this.success,
      required this.peerId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_name'] = Variable<String>(fileName);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['success'] = Variable<bool>(success);
    map['peer_id'] = Variable<String>(peerId);
    return map;
  }

  TransferHistoryCompanion toCompanion(bool nullToAbsent) {
    return TransferHistoryCompanion(
      id: Value(id),
      fileName: Value(fileName),
      totalBytes: Value(totalBytes),
      timestamp: Value(timestamp),
      success: Value(success),
      peerId: Value(peerId),
    );
  }

  factory TransferHistoryRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferHistoryRecord(
      id: serializer.fromJson<String>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      success: serializer.fromJson<bool>(json['success']),
      peerId: serializer.fromJson<String>(json['peerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fileName': serializer.toJson<String>(fileName),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'success': serializer.toJson<bool>(success),
      'peerId': serializer.toJson<String>(peerId),
    };
  }

  TransferHistoryRecord copyWith(
          {String? id,
          String? fileName,
          int? totalBytes,
          DateTime? timestamp,
          bool? success,
          String? peerId}) =>
      TransferHistoryRecord(
        id: id ?? this.id,
        fileName: fileName ?? this.fileName,
        totalBytes: totalBytes ?? this.totalBytes,
        timestamp: timestamp ?? this.timestamp,
        success: success ?? this.success,
        peerId: peerId ?? this.peerId,
      );
  @override
  String toString() {
    return (StringBuffer('TransferHistoryRecord(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('timestamp: $timestamp, ')
          ..write('success: $success, ')
          ..write('peerId: $peerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fileName, totalBytes, timestamp, success, peerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferHistoryRecord &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.totalBytes == this.totalBytes &&
          other.timestamp == this.timestamp &&
          other.success == this.success &&
          other.peerId == this.peerId);
}

class TransferHistoryCompanion extends UpdateCompanion<TransferHistoryRecord> {
  final Value<String> id;
  final Value<String> fileName;
  final Value<int> totalBytes;
  final Value<DateTime> timestamp;
  final Value<bool> success;
  final Value<String> peerId;
  final Value<int> rowid;
  const TransferHistoryCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.success = const Value.absent(),
    this.peerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferHistoryCompanion.insert({
    required String id,
    required String fileName,
    required int totalBytes,
    required DateTime timestamp,
    required bool success,
    required String peerId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fileName = Value(fileName),
        totalBytes = Value(totalBytes),
        timestamp = Value(timestamp),
        success = Value(success),
        peerId = Value(peerId);
  static Insertable<TransferHistoryRecord> custom({
    Expression<String>? id,
    Expression<String>? fileName,
    Expression<int>? totalBytes,
    Expression<DateTime>? timestamp,
    Expression<bool>? success,
    Expression<String>? peerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (timestamp != null) 'timestamp': timestamp,
      if (success != null) 'success': success,
      if (peerId != null) 'peer_id': peerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferHistoryCompanion copyWith(
      {Value<String>? id,
      Value<String>? fileName,
      Value<int>? totalBytes,
      Value<DateTime>? timestamp,
      Value<bool>? success,
      Value<String>? peerId,
      Value<int>? rowid}) {
    return TransferHistoryCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      timestamp: timestamp ?? this.timestamp,
      success: success ?? this.success,
      peerId: peerId ?? this.peerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('timestamp: $timestamp, ')
          ..write('success: $success, ')
          ..write('peerId: $peerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $TrustedDevicesTable trustedDevices = $TrustedDevicesTable(this);
  late final $TransferHistoryTable transferHistory =
      $TransferHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [trustedDevices, transferHistory];
}
