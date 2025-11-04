import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/ios18_theme.dart';
import '../providers/history_provider.dart';

class TransferHistoryDetailScreen extends ConsumerWidget {
  final TransferRecord record;

  const TransferHistoryDetailScreen({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = CupertinoColors.white.withOpacity(isDark ? 0.08 : 0.5);
    final borderColor = isDark ? iOS18Colors.glassBorderDark : iOS18Colors.glassBorder;

    return CupertinoPageScaffold(
      backgroundColor: iOS18Colors.backgroundPrimary,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.transparent,
        border: null,
        middle: Text('Transfer Details'),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(iOS18Spacing.lg),
          children: [
            _buildStatusCard(),
            SizedBox(height: iOS18Spacing.lg),
            _buildFileInfoCard(),
            SizedBox(height: iOS18Spacing.lg),
            _buildDeviceInfoCard(),
            SizedBox(height: iOS18Spacing.lg),
            _buildTimestampCard(),
            if (!record.success) ...[
              SizedBox(height: iOS18Spacing.lg),
              _buildRetryButton(ref),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(iOS18Spacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(iOS18Spacing.radiusLG),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: record.success
                  ? iOS18Colors.systemGreen.withOpacity(0.1)
                  : iOS18Colors.systemRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              record.success ? CupertinoIcons.checkmark_alt : CupertinoIcons.xmark,
              size: 40,
              color: record.success ? iOS18Colors.systemGreen : iOS18Colors.systemRed,
            ),
          ),
          SizedBox(height: iOS18Spacing.md),
          Text(
            record.success ? 'Transfer Completed' : 'Transfer Failed',
            style: iOS18Typography.title2.copyWith(
              color: record.success ? iOS18Colors.systemGreen : iOS18Colors.systemRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfoCard() {
    return _buildInfoCard(
      title: 'File Information',
      items: [
        _InfoItem(
          icon: CupertinoIcons.doc,
          label: 'File Name',
          value: record.fileName,
        ),
        _InfoItem(
          icon: CupertinoIcons.folder,
          label: 'File Size',
          value: _formatBytes(record.totalBytes),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard() {
    return _buildInfoCard(
      title: 'Device Information',
      items: [
        _InfoItem(
          icon: CupertinoIcons.device_phone_portrait,
          label: 'Device ID',
          value: record.id,
        ),
      ],
    );
  }

  Widget _buildTimestampCard() {
    return _buildInfoCard(
      title: 'Transfer Time',
      items: [
        _InfoItem(
          icon: CupertinoIcons.clock,
          label: 'Timestamp',
          value: _formatTimestamp(record.timestamp),
        ),
        _InfoItem(
          icon: CupertinoIcons.calendar,
          label: 'Date',
          value: _formatDate(record.timestamp),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<_InfoItem> items}) {
    return Container(
      padding: EdgeInsets.all(iOS18Spacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(iOS18Spacing.radiusLG),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: iOS18Typography.headline.copyWith(color: iOS18Colors.getTextPrimary(context)),
          ),
          SizedBox(height: iOS18Spacing.md),
          ...items.map((item) => _buildInfoRow(item)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: iOS18Spacing.sm),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: iOS18Colors.systemBlue),
          SizedBox(width: iOS18Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: iOS18Typography.caption1.copyWith(color: iOS18Colors.getTextSecondary(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: iOS18Typography.body.copyWith(color: iOS18Colors.getTextPrimary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(WidgetRef ref) {
    return CupertinoButton.filled(
      onPressed: () {
        // TODO: Implement retry logic
      },
      child: const Text('Retry Transfer'),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({required this.icon, required this.label, required this.value});
}
