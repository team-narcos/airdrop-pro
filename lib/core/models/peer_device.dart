// Peer device descriptor used across discovery and transports.
import 'package:flutter/foundation.dart';

@immutable
class PeerDevice {
  final String id;           // stable ID when available
  final String name;         // human label
  final String platform;     // ios | android | macos | windows | linux | web | unknown
  final String? ip;          // last known IP
  final int? port;           // last known port for TCP-like transports
  final double? rssi;        // signal strength hint
  final Map<String, Object?> meta; // arbitrary extras from discovery layer

  const PeerDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.ip,
    this.port,
    this.rssi,
    this.meta = const {},
  });

  PeerDevice copyWith({
    String? id,
    String? name,
    String? platform,
    String? ip,
    int? port,
    double? rssi,
    Map<String, Object?>? meta,
  }) => PeerDevice(
        id: id ?? this.id,
        name: name ?? this.name,
        platform: platform ?? this.platform,
        ip: ip ?? this.ip,
        port: port ?? this.port,
        rssi: rssi ?? this.rssi,
        meta: meta ?? this.meta,
      );
}
