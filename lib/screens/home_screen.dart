import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/widgets/premium_bottom_nav.dart';
import '../core/widgets/animated_gradient_background.dart';
import '../core/widgets/glassmorphic_header.dart';
import '../providers/services_providers.dart';
import 'files_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/p2p_providers.dart';
import '../core/permissions/permission_helper.dart';
import 'dart:ui';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ShareTab(),
    const FilesScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: AnimatedGradientBackground(
        child: Stack(
          children: [
            // Main content
            _screens[_selectedIndex],
          // Premium bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PremiumBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                PremiumBottomNavItem(
                  icon: CupertinoIcons.arrow_up_doc,
                  label: 'Share',
                ),
                PremiumBottomNavItem(
                  icon: CustomNavIcons.files,
                  label: 'Files',
                ),
                PremiumBottomNavItem(
                  icon: CustomNavIcons.history,
                  label: 'History',
                ),
                PremiumBottomNavItem(
                  icon: CustomNavIcons.settings,
                  label: 'Settings',
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class ShareTab extends ConsumerStatefulWidget {
  const ShareTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends ConsumerState<ShareTab>
    with TickerProviderStateMixin {
  bool _isDiscovering = false;
  List<DiscoveredDevice> _nearbyDevices = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Listen to device discovery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(nearbyDevicesStreamProvider, (previous, next) {
        next.whenData((devices) {
          print('[Discovery] Found ${devices.length} devices');
          if (mounted) {
            setState(() {
              _nearbyDevices = devices.map((d) {
                return DiscoveredDevice(
                  id: d.id,
                  name: d.name,
                  type: DeviceType.phone,
                  distance: d.estimatedDistance,
                  signalStrength: d.signalStrength,
                );
              }).toList();
            });
          }
        });
      });
    });
    
    // Auto-start discovery
    _startDiscovery();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
    });
    _pulseController.repeat(reverse: true);
    
    try {
      // Request permissions first
      print('[Discovery] Requesting permissions...');
      final hasPermissions = await PermissionHelper.requestP2PPermissions();
      
      if (!hasPermissions) {
        print('[Discovery] Permissions denied');
        if (mounted) {
          _showPermissionDialog();
          setState(() {
            _isDiscovering = false;
          });
        }
        return;
      }
      
      print('[Discovery] Permissions granted');
      
      // Start real P2P discovery
      print('[Discovery] Starting device discovery...');
      await ref.read(discoveryNotifierProvider.notifier).startDiscovery();
      print('[Discovery] Discovery started successfully');
      
    } catch (e) {
      print('[Discovery] Error starting discovery: $e');
      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });
      }
    }
  }
  
  void _showPermissionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'AirDrop Pro needs Location and Bluetooth permissions to discover nearby devices. '
          'WiFi Direct requires Location permission even though it works offline.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Open Settings'),
            onPressed: () async {
              Navigator.pop(context);
              await PermissionHelper.openSettings();
            },
          ),
        ],
      ),
    );
  }

  void _stopDiscovery() {
    setState(() {
      _isDiscovering = false;
      _nearbyDevices = [];
    });
    _pulseController.stop();
  }

  Future<void> _pickAndShareFile() async {
    try {
      HapticFeedback.mediumImpact();
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        // TODO: Show device selection and transfer
        _showDeviceSelection(result.files.first);
      }
    } catch (e) {
      // Handle error
    }
  }

  void _showDeviceSelection(PlatformFile file) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Send "${file.name}" to'),
        actions: _nearbyDevices.map((device) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendFileToDevice(file, device);
            },
            child: Text(device.name),
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

  Future<void> _sendFileToDevice(PlatformFile file, DiscoveredDevice device) async {
    HapticFeedback.mediumImpact();
    
    // Show transfer progress with real-time updates
    _showEnhancedTransferProgress(file, device);
    
    try {
      // Get devices from discovery
      final discoveryState = ref.read(discoveryNotifierProvider);
      final unifiedDevice = discoveryState.devices.firstWhere(
        (d) => d.id == device.id || d.name == device.name,
        orElse: () => throw Exception('Device not found'),
      );
      
      // Start actual P2P file transfer
      final transferNotifier = ref.read(transferNotifierProvider.notifier);
      await transferNotifier.sendFile(
        device: unifiedDevice,
        filePath: file.path ?? '',
        fileName: file.name,
        fileSize: file.size,
      );
      
      // Show completion notification
      _showTransferCompleteNotification(file.name, device.name, file.size);
    } catch (e) {
      // Show error
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorDialog('Transfer failed: $e');
    }
  }
  
  void _showEnhancedTransferProgress(PlatformFile file, DiscoveredDevice device) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final transferState = ref.watch(transferNotifierProvider);
                final progress = transferState.progress;
                final bytesTransferred = transferState.bytesTransferred ?? 0;
                final totalBytes = file.size;
                final speed = transferState.speed ?? 0.0; // bytes per second
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // File icon/preview
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: _getFileGradient(file.extension ?? ''),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getFileIcon(file.extension ?? ''),
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: iOS18Spacing.lg),
                    
                    // File name
                    Text(
                      file.name,
                      style: iOS18Typography.headline.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: iOS18Spacing.xs),
                    
                    // Device name
                    Text(
                      'Sending to ${device.name}',
                      style: iOS18Typography.body.copyWith(
                        color: iOS18Colors.getTextSecondary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: iOS18Spacing.xl),
                    
                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: iOS18Colors.getTextTertiary(context).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: iOS18Spacing.md),
                    
                    // Percentage and stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: iOS18Typography.title3.copyWith(
                            color: iOS18Colors.getTextPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatBytes(bytesTransferred)} / ${_formatBytes(totalBytes)}',
                          style: iOS18Typography.caption1.copyWith(
                            color: iOS18Colors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: iOS18Spacing.xs),
                    
                    // Transfer speed
                    if (speed > 0)
                      Text(
                        '${_formatSpeed(speed)}/s • ${_formatTimeRemaining((totalBytes - bytesTransferred).toInt(), speed)}',
                        style: iOS18Typography.caption2.copyWith(
                          color: iOS18Colors.getTextTertiary(context),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return CupertinoIcons.photo;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return CupertinoIcons.videocam;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'flac':
        return CupertinoIcons.music_note;
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'zip':
      case 'rar':
      case '7z':
        return CupertinoIcons.archivebox;
      default:
        return CupertinoIcons.doc;
    }
  }
  
  LinearGradient _getFileGradient(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF9500)]);
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return const LinearGradient(colors: [Color(0xFF5856D6), Color(0xFFAF52DE)]);
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'flac':
        return const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFAF52DE)]);
      case 'pdf':
        return const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)]);
      case 'zip':
      case 'rar':
      case '7z':
        return const LinearGradient(colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)]);
      default:
        return const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF5856D6)]);
    }
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  String _formatSpeed(double bytesPerSecond) {
    return _formatBytes(bytesPerSecond.toInt());
  }
  
  String _formatTimeRemaining(int bytesLeft, double speed) {
    if (speed == 0) return '';
    final seconds = (bytesLeft / speed).toInt();
    if (seconds < 60) return '$seconds sec left';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min left';
    return '${minutes ~/ 60}h ${minutes % 60}m left';
  }
  
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Transfer Error'),
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
  
  void _showTransferCompleteNotification(String fileName, String deviceName, int fileSize) {
    Navigator.of(context, rootNavigator: true).pop(); // Close progress
    
    HapticFeedback.heavyImpact();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF30D158).withOpacity(0.9),
                  const Color(0xFF34C759).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF30D158).withOpacity(0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Transfer Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent "$fileName"\nto $deviceName',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    color: const Color(0xFF30D158).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF30D158),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.xs),
                      Text(
                        'Online',
                        style: iOS18Typography.caption1.copyWith(
                          color: const Color(0xFF30D158),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: iOS18Spacing.md),
                    
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
                              'Tap to select a file to share',
                              style: iOS18Typography.body.copyWith(
                                color: iOS18Colors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: iOS18Spacing.xxl),
                    
                    // Nearby Devices Section
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
                        if (_isDiscovering)
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
                    if (_nearbyDevices.isEmpty)
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
                              'Make sure the other device is nearby',
                              style: iOS18Typography.caption1.copyWith(
                                color: iOS18Colors.getTextTertiary(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._nearbyDevices.map((device) => Padding(
                        padding: EdgeInsets.only(bottom: iOS18Spacing.md),
                        child: GestureDetector(
                          onTap: () => _pickAndShareFile(),
                          child: GlassmorphicCard(
                            padding: EdgeInsets.all(iOS18Spacing.lg),
                            child: Row(
                              children: [
                                // Device Icon
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
                                    device.type == DeviceType.phone
                                        ? CupertinoIcons.device_phone_portrait
                                        : CupertinoIcons.device_laptop,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: iOS18Spacing.lg),
                                // Device Info
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
                                        device.distance,
                                        style: iOS18Typography.caption1.copyWith(
                                          color: iOS18Colors.getTextSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Signal Indicator
                                Icon(
                                  CupertinoIcons.circle_fill,
                                  size: 12,
                                  color: device.signalStrength > 0.7
                                      ? const Color(0xFF30D158)
                                      : device.signalStrength > 0.4
                                          ? const Color(0xFFFF9F0A)
                                          : const Color(0xFFFF453A),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                    
                    SizedBox(height: iOS18Spacing.xl),
                    
                    // Info Card
                    GlassmorphicCard(
                      padding: EdgeInsets.all(iOS18Spacing.lg),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF30D158), Color(0xFF32ADE6)],
                      ).scale(0.1),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(iOS18Spacing.sm),
                            decoration: BoxDecoration(
                              color: const Color(0xFF30D158).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                            ),
                            child: const Icon(
                              CupertinoIcons.wifi,
                              color: Color(0xFF30D158),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: iOS18Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Direct Connection',
                                  style: iOS18Typography.caption1.copyWith(
                                    color: iOS18Colors.getTextPrimary(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'No internet required',
                                  style: iOS18Typography.caption2.copyWith(
                                    color: iOS18Colors.getTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bottom padding
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

// Device Model
class DiscoveredDevice {
  final String id;
  final String name;
  final DeviceType type;
  final String distance;
  final double signalStrength;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.signalStrength,
  });
}

enum DeviceType { phone, laptop, tablet }

// Extension to help with gradient scaling
extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
      stops: stops,
    );
  }
}
