import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/transfer_provider.dart';
import '../core/discovery/discovery_engine.dart';

class QrPairScreen extends ConsumerWidget {
  const QrPairScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scan QR to Pair'),
      ),
      child: SafeArea(
        child: MobileScanner(
          onDetect: (capture) {
            if (capture.barcodes.isEmpty) return;
            final code = capture.barcodes.first.rawValue;
            if (code == null) return;
            try {
              final map = json.decode(code) as Map<String, dynamic>;
final peer = PeerDevice(
                id: map['id'] as String,
                name: map['name'] as String,
                platform: map['platform'] as String? ?? 'unknown',
                batteryPercent: 0,
                signalBars: 0,
                ipAddress: map['ipAddress'] as String?,
                port: (map['port'] is int)
                    ? map['port'] as int
                    : int.tryParse(map['port']?.toString() ?? ''),
              );
              ref.read(transferServiceProvider).addManualPeer(peer);
              Navigator.of(context).pop();
            } catch (_) {}
          },
        ),
      ),
    );
  }
}
