import 'dart:typed_data';

enum TransferDirection { send, receive }
enum TransferStatus { queued, negotiating, transferring, completed, failed, cancelled }

class TransferJob {
  final String id;
  final TransferDirection direction;
  final String filename;
  final int sizeBytes;
  final String? path; // for local file path when sending
  final Uint8List? data; // optional in-memory data
  final DateTime createdAt;

  TransferStatus status;
  int transferredBytes = 0;
  String? error;
  String? transport; // chosen transport key

  TransferJob({
    required this.id,
    required this.direction,
    required this.filename,
    required this.sizeBytes,
    this.path,
    this.data,
    DateTime? createdAt,
    this.status = TransferStatus.queued,
  }) : createdAt = createdAt ?? DateTime.now();
}
