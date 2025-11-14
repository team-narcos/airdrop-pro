import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../providers/p2p_manager_providers.dart';
import '../core/p2p/p2p.dart';

/// New ShareTab using real P2P Manager
class NewShareTab extends ConsumerStatefulWidget {
  const NewShareTab({Key? key}) : super(key: key);

  @override
  ConsumerState<NewShareTab> createState() => _NewShareTabState();
}

class _NewShareTabState extends ConsumerState<NewShareTab> {
  @override
  void initState() {
    super.initState();
    // Delay initialization until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeP2P();
    });
  }

  Future<void> _initializeP2P() async {
    try {
      // Initialize and start P2P Manager
      final notifier = ref.read(p2pManagerStateProvider.notifier);
      await notifier.initialize();
      await notifier.start();
    } catch (e) {
      debugPrint('[NewShareTab] Error initializing P2P: $e');
    }
  }

  Future<void> _pickAndShareFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Get file paths
        final filePaths = result.files
            .where((f) => f.path != null)
            .map((f) => f.path!)
            .toList();

        if (filePaths.isEmpty) {
          _showError('No valid files selected');
          return;
        }

        // Show device selection
        _showDeviceSelection(filePaths);
      }
    } catch (e) {
      _showError('Error picking files: $e');
    }
  }

  void _showDeviceSelection(List<String> filePaths) {
    final state = ref.read(p2pManagerStateProvider);
    final devices = state.discoveredDevices;

    if (devices.isEmpty) {
      _showError('No devices found. Make sure another device is running AirDrop Pro.');
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Send ${filePaths.length} file(s) to'),
        actions: devices.map((device) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendFilesToDevice(filePaths, device);
            },
            child: Row(
              children: [
                Icon(_getDeviceIcon(device.platform)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name),
                    Text(
                      device.platform,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'windows':
      case 'macos':
      case 'linux':
        return CupertinoIcons.device_laptop;
      case 'android':
      case 'ios':
        return CupertinoIcons.device_phone_portrait;
      default:
        return CupertinoIcons.device_desktop;
    }
  }

  Future<void> _sendFilesToDevice(List<String> filePaths, P2PDevice device, {int retryCount = 0}) async {
    const maxRetries = 2;
    
    try {
      // Check if connected
      final state = ref.read(p2pManagerStateProvider);
      final isConnected = state.activeConnections
          .any((c) => c.device.id == device.id);

      if (!isConnected) {
        // Connect first
        _showProgress('Connecting to ${device.name}...');
        final notifier = ref.read(p2pManagerStateProvider.notifier);
        final success = await notifier.connectToDevice(device);

        if (!success) {
          Navigator.of(context, rootNavigator: true).pop();
          
          // Offer retry if attempts remain
          if (retryCount < maxRetries) {
            _showRetryDialog(
              title: 'Connection Failed',
              message: 'Failed to connect to ${device.name}. Would you like to try again?',
              onRetry: () {
                Navigator.pop(context);
                _sendFilesToDevice(filePaths, device, retryCount: retryCount + 1);
              },
            );
          } else {
            _showError(
              'Unable to connect to ${device.name}.\n\n'
              'Please check:\n'
              '• Both devices are on the same WiFi network\n'
              '• AirDrop Pro is running on ${device.name}\n'
              '• Firewall is not blocking the connection',
            );
          }
          return;
        }
      }

      // Send files
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showProgress('Preparing files...');

      final transferId = await sendFilesToDevice(
        ref,
        filePaths: filePaths,
        device: device,
      );

      if (transferId == null) {
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showError(
          'Failed to start transfer.\n\n'
          'The device may have rejected the file or disconnected.',
        );
        return;
      }

      // Show transfer progress
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showTransferProgress(transferId, device);
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      String errorMessage = 'Transfer error: Unknown error occurred';
      
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error: Unable to reach ${device.name}.\n\n'
            'Please check your WiFi connection.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Connection timeout: ${device.name} is not responding.\n\n'
            'The device may be too far away or experiencing network issues.';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = 'Encryption error: Could not establish secure connection.\n\n'
            'Try restarting both devices.';
      } else {
        errorMessage = 'Transfer error: ${e.toString()}';
      }
      
      _showError(errorMessage);
    }
  }
  
  void _showRetryDialog({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

  void _showProgress(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 16),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferProgress(String transferId, P2PDevice device) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransferProgressDialog(
        transferId: transferId,
        device: device,
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pManagerStateProvider);
    final devices = state.discoveredDevices;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(iOS18Spacing.lg),
            child: Row(
              children: [
                Text(
                  'AirDrop Pro',
                  style: iOS18Typography.largeTitle.copyWith(
                    color: iOS18Colors.getTextPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: iOS18Spacing.sm,
                    vertical: iOS18Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (state.isRunning
                            ? const Color(0xFF30D158)
                            : Colors.orange)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: state.isRunning
                              ? const Color(0xFF30D158)
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.xs),
                      Text(
                        state.isRunning ? 'Online' : 'Starting...',
                        style: iOS18Typography.caption1.copyWith(
                          color: state.isRunning
                              ? const Color(0xFF30D158)
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Share File Button
                    GestureDetector(
                      onTap: _pickAndShareFile,
                      child: GlassmorphicCard(
                        padding: EdgeInsets.all(iOS18Spacing.xxl),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                        ).scale(0.15),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                ),
                                borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.arrow_up_doc_fill,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: iOS18Spacing.lg),
                            Text(
                              'Share File',
                              style: iOS18Typography.title2.copyWith(
                                color: iOS18Colors.getTextPrimary(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: iOS18Spacing.xs),
                            Text(
                              'Tap to select files to share',
                              style: iOS18Typography.body.copyWith(
                                color: iOS18Colors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: iOS18Spacing.xxl),

                    // Nearby Devices
                    Row(
                      children: [
                        Text(
                          'Nearby Devices',
                          style: iOS18Typography.title3.copyWith(
                            color: iOS18Colors.getTextPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: iOS18Spacing.sm),
                        if (state.isRunning && devices.isEmpty)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                iOS18Colors.getTextSecondary(context),
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: iOS18Spacing.lg),

                    // Devices List
                    if (!state.isRunning)
                      GlassmorphicCard(
                        padding: EdgeInsets.all(iOS18Spacing.xl),
                        child: Column(
                          children: [
                            const CupertinoActivityIndicator(radius: 16),
                            SizedBox(height: iOS18Spacing.md),
                            Text(
                              'Initializing P2P service...',
                              style: iOS18Typography.body.copyWith(
                                color: iOS18Colors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (devices.isEmpty)
                      GlassmorphicCard(
                        padding: EdgeInsets.all(iOS18Spacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.search,
                              size: 48,
                              color: iOS18Colors.getTextTertiary(context),
                            ),
                            SizedBox(height: iOS18Spacing.md),
                            Text(
                              'Looking for devices...',
                              style: iOS18Typography.body.copyWith(
                                color: iOS18Colors.getTextSecondary(context),
                              ),
                            ),
                            SizedBox(height: iOS18Spacing.xs),
                            Text(
                              'Make sure other devices are running AirDrop Pro',
                              style: iOS18Typography.caption1.copyWith(
                                color: iOS18Colors.getTextTertiary(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...devices.map((device) => Padding(
                            padding: EdgeInsets.only(bottom: iOS18Spacing.md),
                            child: GestureDetector(
                              onTap: () => _pickAndShareFile(),
                              child: GlassmorphicCard(
                                padding: EdgeInsets.all(iOS18Spacing.lg),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            iOS18Colors.systemBlue,
                                            iOS18Colors.systemPurple,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                                      ),
                                      child: Icon(
                                        _getDeviceIcon(device.platform),
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    SizedBox(width: iOS18Spacing.lg),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.name,
                                            style: iOS18Typography.body.copyWith(
                                              color: iOS18Colors.getTextPrimary(context),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: iOS18Spacing.xs / 2),
                                          Text(
                                            '${device.platform} • ${device.ipAddress}',
                                            style: iOS18Typography.caption1.copyWith(
                                              color: iOS18Colors.getTextSecondary(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.circle_fill,
                                      size: 12,
                                      color: const Color(0xFF30D158),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Transfer progress dialog
class TransferProgressDialog extends ConsumerWidget {
  final String transferId;
  final P2PDevice device;

  const TransferProgressDialog({
    Key? key,
    required this.transferId,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transferUpdatesProvider);

    return transfersAsync.when(
      data: (transfer) {
        if (transfer.id != transferId) {
          return const SizedBox();
        }

        final progress = transfer.progress;
        final isComplete = transfer.status == TransferStatus.completed;
        final isFailed = transfer.status == TransferStatus.failed;
        final isCancelled = transfer.status == TransferStatus.cancelled;

        if (isComplete) {
          // Auto-dismiss after showing completion
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          });
        }
        
        if (isFailed || isCancelled) {
          // Show error and allow dismissal
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFailed ? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.xmark_circle_fill,
                    size: 72,
                    color: isFailed ? const Color(0xFFFF3B30) : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isFailed ? 'Transfer Failed' : 'Transfer Cancelled',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFailed 
                        ? 'Connection lost or file transfer interrupted'
                        : 'Transfer was cancelled',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isComplete)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 72,
                    color: Color(0xFF30D158),
                  )
                else
                  const CupertinoActivityIndicator(radius: 36),
                const SizedBox(height: 16),
                Text(
                  isComplete ? 'Transfer Complete!' : 'Transferring...',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'to ${device.name}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                if (!isComplete) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF007AFF)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% • ${transfer.formattedSpeed}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
