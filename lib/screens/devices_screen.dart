import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/widgets/scanning_animation.dart';
import '../core/widgets/signal_strength_indicator.dart';
import '../core/discovery/discovery_engine.dart';
import '../core/transfer/transfer_manager.dart';
import '../providers/transfer_provider.dart';
import '../providers/services_providers.dart';
import '../services/tcp_transfer_service.dart';
// New services disabled for build
// import '../services/integrated_discovery_service.dart';
// import '../services/enhanced_transfer_service.dart';
import 'qr_pair_screen.dart';
import 'qr_share_screen.dart';
import 'manual_connect_screen.dart';
import 'dart:math' as math;

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRefreshing = false;
  bool _showDiscoveryHelp = false;
  Timer? _discoveryHelpTimer;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _statsAnimationController, curve: Curves.elasticOut),
    );
    
    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _statsAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    _discoveryHelpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 414;
    
    // Watch discovered devices
    final discoveredDevicesAsync = ref.watch(discoveredDevicesStreamProvider);
    final discoveredDevices = discoveredDevicesAsync.maybeWhen(
      data: (devices) => devices,
      orElse: () => <PeerDevice>[],
    );

    // If on iOS and nothing is found for a few seconds, show guidance banner
    if (discoveredDevices.isEmpty) {
      _discoveryHelpTimer ??= Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showDiscoveryHelp = true);
      });
    } else {
      _discoveryHelpTimer?.cancel();
      _discoveryHelpTimer = null;
      if (_showDiscoveryHelp) setState(() => _showDiscoveryHelp = false);
    }
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: iOS18Colors.systemBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: iOS18Spacing.lg,
            vertical: iOS18Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: iOS18Spacing.xl),
              
              // Animated Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Gradient Avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: iOS18Colors.deviceGradient,
                            borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                            boxShadow: [
                              BoxShadow(
                                color: iOS18Colors.systemBlue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.device_laptop,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: iOS18Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Devices',
                                style: iOS18Typography.largeTitle.copyWith(
                                  color: iOS18Colors.getTextPrimary(context),
                                ),
                              ),
                              SizedBox(height: iOS18Spacing.xs / 2),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: iOS18Colors.systemGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: iOS18Spacing.sm),
                                  Text(
                                    'Available for AirDrop',
                                    style: iOS18Typography.subheadline.copyWith(
                                      color: iOS18Colors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Statistics Cards
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - iOS18Spacing.md) / 2;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Discovered',
                              '${discoveredDevices.length}',
                              CupertinoIcons.search,
                              iOS18Colors.deviceGradient,
                            ),
                          ),
                          SizedBox(width: iOS18Spacing.md),
                          Expanded(
                            child: _buildStatCard(
                              'Connected',
                              '0',
                              CupertinoIcons.link,
                              iOS18Colors.historyGradient,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Connected Devices Section
              Text(
                'Connected Devices',
                style: iOS18Typography.title2.copyWith(
                  color: iOS18Colors.getTextPrimary(context),
                ),
              ),
              
              SizedBox(height: iOS18Spacing.md),
              
              _buildEmptyState(
                  'No Connected Devices',
                  'Connect devices to share files instantly',
                  CupertinoIcons.link_circle,
                ),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Discovery help banner (iOS fallback)
              if (_showDiscoveryHelp)
                Padding(
                  padding: EdgeInsets.only(bottom: iOS18Spacing.md),
                  child: GlassmorphicCard(
                    padding: EdgeInsets.all(iOS18Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Can\'t find nearby devices?',
                          style: iOS18Typography.headline.copyWith(color: iOS18Colors.getTextPrimary(context)),
                        ),
                        SizedBox(height: iOS18Spacing.xs),
                        Text(
                          'On iOS/macOS, local discovery may be limited. You can pair by scanning a QR or entering IP manually.',
                          style: iOS18Typography.subheadline.copyWith(color: iOS18Colors.getTextSecondary(context)),
                        ),
                        SizedBox(height: iOS18Spacing.sm),
                        Row(
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.md),
                              color: iOS18Colors.systemBlue,
                              onPressed: () {
                                Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const QrPairScreen()));
                              },
                              child: const Text('Scan QR'),
                            ),
                            SizedBox(width: iOS18Spacing.sm),
                            CupertinoButton(
                              padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.md),
                              color: iOS18Colors.systemGray,
                              onPressed: () {
                                Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ManualConnectScreen()));
                              },
                              child: const Text('Enter IP'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Discovered Devices Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discovered Devices',
                    style: iOS18Typography.title2.copyWith(
                      color: iOS18Colors.getTextPrimary(context),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: iOS18Spacing.md),
              
discoveredDevices.isEmpty
                  ? _buildEmptyStateWithAnimation(
                      'No Devices Found',
                      'Make sure both devices are on the same Wi‑Fi. Or use Quick Actions → Pair Device to Scan QR or Enter IP manually.',
                    )
                  : _buildDiscoveredDevicesList(discoveredDevices),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Quick Actions
              GlassmorphicCard(
                padding: EdgeInsets.all(iOS18Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: iOS18Typography.title3.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                      ),
                    ),
                    SizedBox(height: iOS18Spacing.md),
Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            'Pair Device',
                            CupertinoIcons.plus_circle,
                            iOS18Colors.systemBlue,
                            () {
                              HapticFeedback.lightImpact();
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => CupertinoActionSheet(
                                  title: const Text('Pair New Device'),
                                  message: const Text('Choose a pairing method'),
                                  actions: [
                                    CupertinoActionSheetAction(
                                      child: const Text('Scan QR Code'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (context) => const QrPairScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    CupertinoActionSheetAction(
                                      child: const Text('Show QR Code'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (context) => const QRShareScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    CupertinoActionSheetAction(
                                      child: const Text('Enter IP Manually'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (context) => const ManualConnectScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  cancelButton: CupertinoActionSheetAction(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: iOS18Spacing.md),
                        Expanded(
                          child: _buildQuickActionButton(
                            'Settings',
                            CupertinoIcons.settings,
                            iOS18Colors.getTextSecondary(context),
                            () {
                              HapticFeedback.lightImpact();
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('Settings'),
                                  content: const Text('Please use the Settings tab in the bottom navigation bar to access app settings.'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Bottom padding for navigation
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Trigger device discovery refresh
    final discoveryService = ref.read(mdnsDiscoveryProvider);
    if (discoveryService != null) {
      discoveryService.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      discoveryService.start();
    }
    
    // Wait for results
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    LinearGradient gradient,
  ) {
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.lg),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          SizedBox(height: iOS18Spacing.md),
          Text(
            value,
            style: iOS18Typography.title1.copyWith(
              color: iOS18Colors.getTextPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: iOS18Spacing.xs),
          Text(
            label,
            style: iOS18Typography.caption1.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.xl),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iOS18Colors.getTextTertiary(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
            ),
            child: Icon(
              icon,
              size: 40,
              color: iOS18Colors.getTextSecondary(context),
            ),
          ),
          SizedBox(height: iOS18Spacing.lg),
          Text(
            title,
            style: iOS18Typography.headline.copyWith(
              color: iOS18Colors.getTextPrimary(context),
            ),
          ),
          SizedBox(height: iOS18Spacing.sm),
          Text(
            subtitle,
            style: iOS18Typography.subheadline.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithAnimation(String title, String subtitle) {
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.xl),
      child: Column(
        children: [
          const ScanningAnimation(
            size: 120,
            color: Color(0xFF007AFF),
          ),
          SizedBox(height: iOS18Spacing.lg),
          Text(
            _isRefreshing ? 'Scanning...' : title,
            style: iOS18Typography.headline.copyWith(
              color: iOS18Colors.getTextPrimary(context),
            ),
          ),
          SizedBox(height: iOS18Spacing.sm),
          Text(
            _isRefreshing ? 'Looking for nearby devices' : subtitle,
            style: iOS18Typography.subheadline.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredDevicesList(List<PeerDevice> devices) {
    return Column(
      children: devices.map((d) => _buildDiscoveredDeviceCard(d)).toList(),
    );
  }


  Widget _buildDiscoveredDeviceCard(PeerDevice device) {
    // Check connection status
    final isOnline = _isDeviceOnline(device);
    
    return Padding(
      padding: EdgeInsets.only(bottom: iOS18Spacing.md),
      child: Hero(
        tag: 'device_${device.id}',
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicCard(
            padding: EdgeInsets.all(iOS18Spacing.md),
            child: Row(
              children: [
                // Device avatar with status indicator
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isOnline 
                            ? iOS18Colors.deviceGradient 
                            : LinearGradient(
                                colors: [Colors.grey.shade400, Colors.grey.shade600],
                              ),
                        borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        device.name.isNotEmpty ? device.name[0].toUpperCase() : '?',
                        style: iOS18Typography.headline.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Connection status indicator
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline ? iOS18Colors.systemGreen : iOS18Colors.systemRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
            SizedBox(width: iOS18Spacing.md),
            // Device info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.name,
                          style: iOS18Typography.bodyEmphasized.copyWith(
                            color: iOS18Colors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      SignalStrengthIndicator(
                        strength: _calculateSignalStrength(device),
                        color: iOS18Colors.systemGreen,
                        size: 14,
                      ),
                    ],
                  ),
                  SizedBox(height: iOS18Spacing.xs / 2),
                  Row(
                    children: [
                      // Connection status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: iOS18Spacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOnline 
                              ? iOS18Colors.systemGreen.withOpacity(0.2)
                              : iOS18Colors.systemRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOnline ? 'Online' : 'Offline',
                          style: iOS18Typography.caption2.copyWith(
                            color: isOnline ? iOS18Colors.systemGreen : iOS18Colors.systemRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.xs),
                      Text(
                        device.platform,
                        style: iOS18Typography.caption1.copyWith(
                          color: iOS18Colors.getTextSecondary(context),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: iOS18Typography.caption1.copyWith(
                          color: iOS18Colors.getTextTertiary(context),
                        ),
                      ),
                      Text(
                        _getEstimatedDistance(),
                        style: iOS18Typography.caption1.copyWith(
                          color: iOS18Colors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Send button - only enabled if device is online
            CupertinoButton(
              padding: EdgeInsets.symmetric(
                horizontal: iOS18Spacing.md,
                vertical: iOS18Spacing.xs,
              ),
              color: isOnline ? iOS18Colors.systemBlue : Colors.grey,
              borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
              onPressed: isOnline ? () {
                HapticFeedback.mediumImpact();
                _pickAndSend(device);
              } : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.paperplane, size: 16),
                  SizedBox(width: iOS18Spacing.xs),
                  Text(isOnline ? 'Send' : 'Offline'),
                ],
              ),
            )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSend(PeerDevice device) async {
    try {
      // Use file_picker to select multiple files
      final picker = await FilePicker.platform.pickFiles(
        allowMultiple: true,  // Enable multiple file selection
        type: FileType.any,
      );
      
      if (picker == null || picker.files.isEmpty) {
        print('[DevicesScreen] No file selected');
        return;
      }
      
      final pickedFile = picker.files.first;
      final filePath = pickedFile.path;
      if (filePath == null) {
        _showError('Could not read file path');
        return;
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        _showError('File not found');
        return;
      }
      
      // Get device IP address
      final deviceIP = device.ipAddress;
      if (deviceIP == null || deviceIP.isEmpty) {
        _showError('Device IP address not available');
        return;
      }
      
      // Show sending dialog
      _showSendingDialog(pickedFile.name);
      
      // Use global TCP transfer service for actual file transfer
      final tcpService = ref.read(tcpTransferServiceProvider);
      
      try {
        print('[DevicesScreen] Sending file to $deviceIP');
        
        // Actually send the file using TCP
        await tcpService.sendFile(deviceIP, file);
        
        if (mounted) {
          Navigator.of(context).pop(); // Close sending dialog
          _showSuccess('File sent successfully to ${device.name}');
        }
      } catch (e) {
        // Handle errors
        print('[DevicesScreen] Error during file transfer: $e');
        rethrow;
      }
    } catch (e) {
      print('[DevicesScreen] Error sending file: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close sending dialog
        String errorMsg = 'Failed to send file';
        if (e.toString().contains('No element')) {
          errorMsg = 'Device not ready to receive files';
        } else if (e.toString().contains('timeout')) {
          errorMsg = 'Connection timeout - device may be offline';
        } else if (e.toString().contains('not responding')) {
          errorMsg = 'Device is not responding';
        }
        _showError(errorMsg);
      }
    }
  }

  void _showProgressSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPopupSurface(
        child: SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.all(iOS18Spacing.lg),
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Consumer(
              builder: (context, ref, _) {
                final progress = ref.watch(transferProgressProvider);
                return progress.when(
                  data: (p) {
                    final mgr = ref.read(transferServiceProvider).manager;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transferring ${p.fileName}', style: iOS18Typography.title3.copyWith(color: iOS18Colors.getTextPrimary(context))),
                        SizedBox(height: iOS18Spacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: p.totalBytes == 0 ? null : p.sentBytes / p.totalBytes,
                          ),
                        ),
                        SizedBox(height: iOS18Spacing.sm),
                        Text('${(p.sentBytes / (1024*1024)).toStringAsFixed(1)} / ${(p.totalBytes / (1024*1024)).toStringAsFixed(1)} MB • ${p.speedMbps.toStringAsFixed(1)} Mbps • ETA ${p.eta.inSeconds}s',
                          style: iOS18Typography.caption1.copyWith(color: iOS18Colors.getTextSecondary(context)),
                        ),
                        if (p.error != null) ...[
                          SizedBox(height: iOS18Spacing.xs),
                          Text('Error: ${p.error}', style: iOS18Typography.caption1.copyWith(color: iOS18Colors.systemRed)),
                        ],
                        SizedBox(height: iOS18Spacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (p.state == TransferState.transferring)
                              CupertinoButton(
                                padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.sm),
                                onPressed: () => mgr.pauseTransfer(p.id),
                                child: const Text('Pause'),
                              ),
                            if (p.state == TransferState.paused)
                              CupertinoButton(
                                padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.sm),
                                onPressed: () => mgr.resumeTransfer(p.id),
                                child: const Text('Resume'),
                              ),
                            CupertinoButton(
                              padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.sm),
                              onPressed: () => mgr.cancelTransfer(p.id),
                              child: const Text('Cancel'),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.sm),
                              child: const Text('Close'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  error: (e, st) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: iOS18Spacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            SizedBox(height: iOS18Spacing.sm),
            Text(
              title,
              style: iOS18Typography.caption1.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDeviceOnline(PeerDevice device) {
    // In a real app, this would check actual connection status
    // For now, we consider discovered devices as online
    return device.ipAddress != null && device.ipAddress!.isNotEmpty;
  }
  
  int _calculateSignalStrength(PeerDevice device) {
    // Simulate signal strength (in real app, would use actual RSSI)
    final random = math.Random(device.id.hashCode);
    return 2 + random.nextInt(3); // Returns 2-4
  }

  String _getEstimatedDistance() {
    // Simulate distance calculation
    final random = math.Random();
    final distance = 2 + random.nextInt(15); // 2-16 meters
    return '~${distance}m';
  }
  
  void _showSendingDialog(String fileName) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sending File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: iOS18Spacing.md),
            const CupertinoActivityIndicator(),
            SizedBox(height: iOS18Spacing.md),
            Text('Sending "$fileName"...'),
          ],
        ),
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// Device models (local UI only)
class ConnectedDevice {
  final String name;
  final DeviceType type;
  final String avatar;
  final bool isOnline;

  ConnectedDevice({
    required this.name,
    required this.type,
    required this.avatar,
    this.isOnline = true,
  });
}

class DiscoveredDevice {
  final String name;
  final DeviceType type;
  final String distance;
  final int signalStrength; // 1-5
  final String avatar;

  DiscoveredDevice({
    required this.name,
    required this.type,
    required this.distance,
    required this.signalStrength,
    required this.avatar,
  });
}

enum DeviceType {
  iPhone,
  iPad,
  macBook,
  androidPhone,
  windowsPC;

  String get displayName {
    switch (this) {
      case DeviceType.iPhone:
        return 'iPhone';
      case DeviceType.iPad:
        return 'iPad';
      case DeviceType.macBook:
        return 'MacBook';
      case DeviceType.androidPhone:
        return 'Android Phone';
      case DeviceType.windowsPC:
        return 'Windows PC';
    }
  }
}
