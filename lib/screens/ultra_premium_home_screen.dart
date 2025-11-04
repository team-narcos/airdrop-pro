// Ultra-Premium Home Screen
// Advanced glassmorphism with liquid animations and premium aesthetics

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/design_system/premium_design_system.dart';
import '../core/widgets/ultra_premium_navigation.dart';
import '../core/widgets/ultra_premium_cards.dart';
import '../core/animations/slide_page_route.dart';
import '../providers/services_providers.dart';
import 'devices_screen.dart';
import 'files_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'qr_pair_screen.dart';
import 'qr_share_screen.dart';
import 'room_create_screen.dart';
import 'room_join_screen.dart';

class UltraPremiumHomeScreen extends ConsumerStatefulWidget {
  const UltraPremiumHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UltraPremiumHomeScreen> createState() => _UltraPremiumHomeScreenState();
}

class _UltraPremiumHomeScreenState extends ConsumerState<UltraPremiumHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  final List<Widget> _screens = [
    const UltraPremiumAirDropTab(),
    const DevicesScreen(),
    const FilesScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundController);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: _buildDynamicBackground(),
            ),
            child: Stack(
              children: [
                // Floating particles background
                _buildFloatingParticles(),
                // Main content
                _screens[_selectedIndex],
                // Ultra-premium navigation
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: UltraPremiumNavigation(
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    items: const [
                      UltraPremiumNavItem(
                        icon: CupertinoIcons.radiowaves_left,
                        label: 'AirDrop',
                      ),
                      UltraPremiumNavItem(
                        icon: CupertinoIcons.device_laptop,
                        label: 'Devices',
                      ),
                      UltraPremiumNavItem(
                        icon: CupertinoIcons.folder,
                        label: 'Files',
                      ),
                      UltraPremiumNavItem(
                        icon: CupertinoIcons.clock,
                        label: 'History',
                      ),
                      UltraPremiumNavItem(
                        icon: CupertinoIcons.gear_alt,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buildDynamicBackground() {
    final time = _backgroundAnimation.value;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        PremiumColors.ultraDarkBg,
        PremiumColors.richDarkBg.withOpacity(0.8 + 0.2 * math.sin(time)),
        PremiumColors.ultraDarkBg.withOpacity(0.9 + 0.1 * math.cos(time * 0.7)),
        PremiumColors.richDarkBg,
      ],
      stops: [
        0.0,
        0.3 + 0.1 * math.sin(time * 0.5),
        0.7 + 0.1 * math.cos(time * 0.3),
        1.0,
      ],
    );
  }

  Widget _buildFloatingParticles() {
    return CustomPaint(
      size: Size.infinite,
      painter: FloatingParticlesPainter(_backgroundAnimation.value),
    );
  }
}

class UltraPremiumAirDropTab extends ConsumerStatefulWidget {
  const UltraPremiumAirDropTab({Key? key}) : super(key: key);

  @override
  ConsumerState<UltraPremiumAirDropTab> createState() => _UltraPremiumAirDropTabState();
}

class _UltraPremiumAirDropTabState extends ConsumerState<UltraPremiumAirDropTab>
    with TickerProviderStateMixin {
  bool _isDiscovering = false;
  String _selectedMode = 'Everyone';
  
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: PremiumAnimations.liquid,
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: PremiumAnimations.morphEase,
    ));
    
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  void _toggleDiscovery() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDiscovering = !_isDiscovering;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(PremiumSpacing.xl),
              child: Column(
                children: [
                  // Ultra-Premium Header
                  Transform.translate(
                    offset: Offset(0, 50 * (1 - _headerAnimation.value)),
                    child: Opacity(
                      opacity: _headerAnimation.value,
                      child: _buildPremiumHeader(),
                    ),
                  ),
                  
                  SizedBox(height: PremiumSpacing.ultra),
                  
                  // Liquid Discovery Button
                  Transform.scale(
                    scale: 0.8 + 0.2 * _headerAnimation.value,
                    child: LiquidDiscoveryButton(
                      isActive: _isDiscovering,
                      onTap: _toggleDiscovery,
                      size: 280,
                    ),
                  ),
                  
                  SizedBox(height: PremiumSpacing.ultra),
                  
                  // Premium Mode Selection
                  Transform.translate(
                    offset: Offset(0, 30 * (1 - _headerAnimation.value)),
                    child: Opacity(
                      opacity: _headerAnimation.value,
                      child: _buildModeSelection(),
                    ),
                  ),
                  
                  SizedBox(height: PremiumSpacing.xxl),
                  
                  // Quick Actions Grid
                  Transform.translate(
                    offset: Offset(0, 40 * (1 - _headerAnimation.value)),
                    child: Opacity(
                      opacity: _headerAnimation.value,
                      child: _buildQuickActions(),
                    ),
                  ),
                  
                  SizedBox(height: 120), // Space for navigation
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return UltraPremiumCard(
      gradientColors: [PremiumColors.deepBlue, PremiumColors.liquidPurple],
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: PremiumColors.premiumAirDrop,
              borderRadius: BorderRadius.circular(PremiumSpacing.radiusXL),
            ),
            child: Icon(
              CupertinoIcons.radiowaves_right,
              size: 40,
              color: PremiumColors.textGlass,
            ),
          ),
          SizedBox(width: PremiumSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AirDrop Pro',
                  style: PremiumTypography.premiumTitle.copyWith(
                    color: PremiumColors.textPrimary,
                  ),
                ),
                SizedBox(height: PremiumSpacing.sm),
                Text(
                  'Ultra-premium file sharing experience',
                  style: PremiumTypography.premiumBody.copyWith(
                    color: PremiumColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return UltraPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receiving',
            style: PremiumTypography.glassHeadline.copyWith(
              color: PremiumColors.textPrimary,
            ),
          ),
          SizedBox(height: PremiumSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildModeOption('Everyone', CupertinoIcons.globe),
              ),
              SizedBox(width: PremiumSpacing.md),
              Expanded(
                child: _buildModeOption('Contacts', CupertinoIcons.person_2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(String mode, IconData icon) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: PremiumAnimations.quick,
        padding: EdgeInsets.all(PremiumSpacing.lg),
        decoration: BoxDecoration(
          gradient: isSelected ? PremiumColors.liquidMorph : null,
          color: isSelected ? null : PremiumColors.glassUltraLight,
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusLG),
          border: Border.all(
            color: isSelected 
                ? PremiumColors.glassBorderStrong 
                : PremiumColors.glassBorderSoft,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? PremiumColors.textGlass 
                  : PremiumColors.textSecondary,
            ),
            SizedBox(height: PremiumSpacing.sm),
            Text(
              mode,
              style: PremiumTypography.liquidCaption.copyWith(
                color: isSelected 
                    ? PremiumColors.textGlass 
                    : PremiumColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: PremiumTypography.glassHeadline.copyWith(
            color: PremiumColors.textPrimary,
          ),
        ),
        SizedBox(height: PremiumSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: PremiumSpacing.md,
          crossAxisSpacing: PremiumSpacing.md,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Share Files',
              CupertinoIcons.share,
              [PremiumColors.deepBlue, PremiumColors.electricBlue],
              () => _pickAndShare(),
            ),
            _buildActionCard(
              'QR Pair',
              CupertinoIcons.qrcode,
              [PremiumColors.vibrantPink, PremiumColors.liquidPurple],
              () => _openQRPair(),
            ),
            _buildActionCard(
              'Create Room',
              CupertinoIcons.add_circled,
              [PremiumColors.neonGreen, PremiumColors.deepBlue],
              () => _createRoom(),
            ),
            _buildActionCard(
              'Join Room',
              CupertinoIcons.arrow_right_circle,
              [PremiumColors.luminousOrange, PremiumColors.vibrantPink],
              () => _joinRoom(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, List<Color> colors, VoidCallback onTap) {
    return LiquidStatsCard(
      title: title,
      value: '',
      subtitle: 'Tap to ${title.toLowerCase()}',
      icon: icon,
      gradientColors: colors,
      onTap: onTap,
    );
  }

  Future<void> _pickAndShare() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        // Show sharing options
        _showSharingOptions(result.files);
      }
    } catch (e) {
      _showError('Failed to pick files: $e');
    }
  }

  void _showSharingOptions(List<PlatformFile> files) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Share ${files.length} file${files.length > 1 ? 's' : ''}'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('QR Code'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                SlidePageRoute(page: const QRShareScreen()),
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Nearby Devices'),
            onPressed: () {
              Navigator.pop(context);
              // Switch to devices tab
              // You can implement this navigation logic
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openQRPair() {
    Navigator.of(context).push(
      SlidePageRoute(page: const QrPairScreen()),
    );
  }

  void _createRoom() {
    Navigator.of(context).push(
      SlidePageRoute(page: const RoomCreateScreen()),
    );
  }

  void _joinRoom() {
    Navigator.of(context).push(
      SlidePageRoute(page: const RoomJoinScreen()),
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
}

class FloatingParticlesPainter extends CustomPainter {
  final double animationValue;
  
  FloatingParticlesPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42); // Fixed seed for consistent particles
    
    for (int i = 0; i < 15; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      
      // Create floating motion
      final floatOffset = 20 * math.sin(animationValue + i * 0.5);
      final x = baseX + floatOffset;
      final y = baseY + 10 * math.cos(animationValue * 0.7 + i * 0.3);
      
      // Vary opacity based on animation
      final opacity = 0.1 + 0.05 * math.sin(animationValue * 2 + i);
      
      paint.color = PremiumColors.liquidPurple.withOpacity(opacity);
      
      final radius = 2 + math.sin(animationValue + i) * 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}