import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/ios18_theme.dart';
import '../../providers/trusted_devices_provider.dart';

class PairingRequestDialog extends ConsumerWidget {
  final String deviceId;
  final String deviceName;
  final String fileName;
  final int fileCount;

  const PairingRequestDialog({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.fileName,
    this.fileCount = 1,
  });

  static Future<PairingResponse?> show({
    required BuildContext context,
    required String deviceId,
    required String deviceName,
    required String fileName,
    int fileCount = 1,
  }) {
    return showCupertinoDialog<PairingResponse>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PairingRequestDialog(
        deviceId: deviceId,
        deviceName: deviceName,
        fileName: fileName,
        fileCount: fileCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoAlertDialog(
      title: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: iOS18Colors.deviceGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              deviceName.isNotEmpty ? deviceName[0].toUpperCase() : '?',
              style: iOS18Typography.largeTitle.copyWith(
                color: CupertinoColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"$deviceName" wants to share',
            style: iOS18Typography.headline,
          ),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            fileCount == 1
                ? fileName
                : '$fileCount files starting with \"$fileName\"',
            style: iOS18Typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: 16,
                  color: iOS18Colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'This device is not in your trusted list',
                    style: iOS18Typography.caption1.copyWith(
                      color: iOS18Colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, PairingResponse.deny),
          child: const Text('Decline'),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, PairingResponse.accept),
          child: const Text('Accept'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () async {
            await ref.read(trustedDevicesProvider.notifier).addDevice(
              deviceId: deviceId,
              name: deviceName,
            );
            if (context.mounted) {
              Navigator.pop(context, PairingResponse.acceptAndTrust);
            }
          },
          child: const Text('Accept & Trust'),
        ),
      ],
    );
  }
}

enum PairingResponse {
  accept,
  acceptAndTrust,
  deny,
}
