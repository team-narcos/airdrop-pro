import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/discovery/discovery_engine.dart';
import '../core/design_system/ios18_theme.dart';
import '../providers/trusted_devices_provider.dart';

class TrustedDevicesScreen extends ConsumerWidget {
  const TrustedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustedDevices = ref.watch(trustedDevicesProvider);

    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = CupertinoColors.white.withOpacity(isDark ? 0.08 : 0.5);
    final borderColor = isDark ? iOS18Colors.glassBorderDark : iOS18Colors.glassBorder;

    return CupertinoPageScaffold(
      backgroundColor: iOS18Colors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.transparent,
        border: null,
        middle: Text('Trusted Devices', style: iOS18Typography.title2),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddDeviceDialog(context, ref),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: trustedDevices.when(
          data: (devices) {
            if (devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.device_phone_portrait,
                      size: 64,
                      color: iOS18Colors.getTextSecondary(context).withOpacity(0.5),
                    ),
                    SizedBox(height: iOS18Spacing.lg),
                    Text(
                      'No Trusted Devices',
                      style: iOS18Typography.title2.copyWith(color: iOS18Colors.getTextSecondary(context)),
                    ),
                    SizedBox(height: iOS18Spacing.sm),
                    Text(
                      'Add devices to skip pairing confirmation',
                      style: iOS18Typography.body.copyWith(color: iOS18Colors.getTextTertiary(context)),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(iOS18Spacing.lg),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return _buildDeviceCard(context, ref, device);
              },
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, WidgetRef ref, TrustedDevice device) {
    return Container(
      margin: EdgeInsets.only(bottom: iOS18Spacing.md),
      padding: EdgeInsets.all(iOS18Spacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(iOS18Spacing.radiusLG),
        border: Border.all(
          color: borderColor,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: iOS18Colors.deviceGradient,
              borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
            ),
            alignment: Alignment.center,
            child: Text(
              device.name.isNotEmpty ? device.name[0].toUpperCase() : '?',
              style: iOS18Typography.headline.copyWith(
                color: CupertinoColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: iOS18Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: iOS18Typography.bodyEmphasized.copyWith(color: iOS18Colors.getTextPrimary(context)),
                ),
                SizedBox(height: iOS18Spacing.xs / 2),
                Text(
                  device.deviceId,
                  style: iOS18Typography.caption1.copyWith(color: iOS18Colors.getTextSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: iOS18Spacing.xs / 2),
                Text(
                  'Added ${_formatDate(device.addedAt)}',
                  style: iOS18Typography.caption2.copyWith(color: iOS18Colors.getTextTertiary(context)),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _confirmRemove(context, ref, device),
            child: Icon(
              CupertinoIcons.trash,
              color: iOS18Colors.systemRed,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Trusted Device'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            const Text('Enter device ID to trust:'),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Device ID',
              style: iOS18Typography.body,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final deviceId = controller.text.trim();
              if (deviceId.isNotEmpty) {
                ref.read(trustedDevicesProvider.notifier).addDevice(
                  deviceId: deviceId,
                  name: 'Device ${deviceId.substring(0, 8)}',
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, TrustedDevice device) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Trusted Device'),
        content: Text('Remove ${device.name} from trusted devices?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(trustedDevicesProvider.notifier).removeDevice(device.deviceId);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
