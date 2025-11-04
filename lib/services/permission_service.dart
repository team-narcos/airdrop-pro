import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStorage() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted || status.isLimited;
    }
    // iOS/macOS/Windows/Linux: use standard storage permission if available
    final status = await Permission.storage.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> requestBluetooth() async {
    if (kIsWeb) return true;
    final statuses = await [
      Permission.bluetooth,
      if (Platform.isAndroid) Permission.bluetoothScan,
      if (Platform.isAndroid) Permission.bluetoothConnect,
      if (Platform.isAndroid) Permission.bluetoothAdvertise,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<bool> requestLocalNetwork() async {
    // Only relevant on iOS 14+; other platforms treat as granted
    return true;
  }
}
