import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class BackgroundService {
  static const _channel = MethodChannel('airdrop_app/background');

  Future<void> init() async {
    // No-op for non-Android
  }

  Future<void> startForeground({String title = 'AirDrop', String content = 'Running'}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startForeground', {
        'title': title,
        'content': content,
      });
    } catch (_) {
      // Ignore if native side not implemented
    }
  }

  Future<void> stopForeground() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopForeground');
    } catch (_) {}
  }
}
