import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/widgets/premium_bottom_nav.dart';
import '../core/widgets/premium_discovery_button.dart';
import '../core/widgets/premium_gradient_card.dart';
import '../core/widgets/animated_gradient_background.dart';
import '../core/widgets/glassmorphic_header.dart';
import '../core/animations/slide_page_route.dart';
import '../providers/services_providers.dart';
import 'devices_screen.dart';
import 'qr_pair_screen.dart';
import 'qr_share_screen.dart';
import 'qr_generate_screen.dart';
import 'room_create_screen.dart';
import 'room_join_screen.dart';
import 'nfc_touch_screen.dart';
// import 'nfc_share_screen.dart';  // Temporarily disabled
import 'files_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'features_status_screen.dart';
import 'demo_mode_screen.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AirDropHomeTab(),
    const DevicesScreen(),
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
                  icon: CustomNavIcons.airdrop,
                  label: 'AirDrop',
                ),
                PremiumBottomNavItem(
                  icon: CustomNavIcons.devices,
                  label: 'Devices',
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

class AirDropHomeTab extends ConsumerStatefulWidget {
  const AirDropHomeTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AirDropHomeTab> createState() => _AirDropHomeTabState();
}

class _AirDropHomeTabState extends ConsumerState<AirDropHomeTab>
    with TickerProviderStateMixin {
  bool _isDiscovering = false;
  String _selectedMode = 'Everyone';
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleDiscovery() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDiscovering = !_isDiscovering;
    });
    
    if (_isDiscovering) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 414;
    
    return SafeArea(
      child: Column(
        children: [
          // Glassmorphic header
          const GlassmorphicHeader(
            deviceName: 'AirDrop Pro',
          ),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: iOS18Spacing.lg,
                  vertical: iOS18Spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
              SizedBox(height: iOS18Spacing.sm),
              
              // Feature Status Banner
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    SlidePageRoute(page: FeaturesStatusScreen()),
                  );
                },
                child: GlassmorphicCard(
                  margin: EdgeInsets.symmetric(horizontal: iOS18Spacing.sm),
                  child: Padding(
                    padding: EdgeInsets.all(iOS18Spacing.md),
                    child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(iOS18Spacing.sm),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF30D158), Color(0xFF32ADE6)],
                          ),
                          borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '9 Advanced Features Active',
                              style: iOS18Typography.bodyEmphasized.copyWith(
                                color: iOS18Colors.getTextPrimary(context),
                              ),
                            ),
                            Text(
                              'WiFi Direct • AI • Encryption',
                              style: iOS18Typography.caption1.copyWith(
                                color: iOS18Colors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        color: iOS18Colors.getTextTertiary(context),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              ),

              SizedBox(height: iOS18Spacing.lg),

              // Premium Discovery Button
              Center(
                child: PremiumDiscoveryButton(
                  size: isLargeScreen ? 220 : 200,
                  isActive: _isDiscovering,
                  onTap: _toggleDiscovery,
                ),
              ),
              
              SizedBox(height: iOS18Spacing.xxl),
              
              // Quick Actions
              GlassmorphicCard(
                padding: EdgeInsets.all(iOS18Spacing.lg),
                margin: EdgeInsets.symmetric(horizontal: iOS18Spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: iOS18Typography.title3.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                      ),
                    ),
                    SizedBox(height: iOS18Spacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            'Features',
                            CupertinoIcons.star_circle_fill,
                            const LinearGradient(
                              colors: [Color(0xFFBF5AF2), Color(0xFFFF2D55)],
                            ),
                            () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                SlidePageRoute(page: FeaturesStatusScreen()),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: iOS18Spacing.md),
                        Expanded(
                          child: _buildQuickAction(
                            'Demo Mode',
                            CupertinoIcons.play_circle_fill,
                            const LinearGradient(
                              colors: [Color(0xFF30D158), Color(0xFF32ADE6)],
                            ),
                            () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                ScalePageRoute(page: DemoModeScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: iOS18Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            'QR Share',
                            CupertinoIcons.qrcode,
                            const LinearGradient(
                              colors: [Color(0xFFFF9F0A), Color(0xFFFFD60A)],
                            ),
                            () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                SlidePageRoute(page: QRShareScreen()),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: iOS18Spacing.md),
                        Expanded(
                          child: _buildQuickAction(
                            'Join Room',
                            CupertinoIcons.arrow_right_square,
                            const LinearGradient(
                              colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
                            ),
                            () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                ScalePageRoute(page: RoomJoinScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Bottom padding to account for navigation
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

  Widget _buildModeCard(
    String title,
    IconData icon,
    String subtitle,
    bool isSelected,
    double width,
    Color accentColor,
  ) {
    // Premium gradient colors based on mode
    final List<Color> gradientColors;
    if (title == 'Off') {
      gradientColors = [const Color(0xFFFF453A), const Color(0xFFFF375F)];
    } else if (title == 'Contacts') {
      gradientColors = [const Color(0xFFFF9F0A), const Color(0xFFFFD60A)];
    } else {
      gradientColors = [const Color(0xFF30D158), const Color(0xFF32ADE6)];
    }

    return PremiumGradientCard(
      width: width,
      gradientColors: gradientColors,
      isSelected: isSelected,
      borderRadius: iOS18Spacing.radiusMD,
      padding: EdgeInsets.symmetric(
        horizontal: iOS18Spacing.xs,
        vertical: iOS18Spacing.md,
      ),
      onTap: () async {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMode = title;
        });
        // Save to settings
        final settingsService = ref.read(settingsServiceProvider);
        if (title == 'Off') {
          await settingsService.setDiscoverable(false);
        } else {
          await settingsService.setDiscoverable(true);
          await settingsService.setAllowEveryone(title == 'Everyone');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? gradientColors
                    : [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradientColors.first.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
          SizedBox(height: iOS18Spacing.sm),
          Text(
            title,
            style: iOS18Typography.caption1.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : iOS18Colors.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: iOS18Spacing.xs / 2),
          Text(
            subtitle,
            style: iOS18Typography.caption2.copyWith(
              color: isSelected 
                  ? Colors.white.withOpacity(0.8) 
                  : iOS18Colors.getTextTertiary(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return AnimatedPressCard(
      onPressed: onTap,
      gradient: gradient.scale(0.1),
      borderRadius: iOS18Spacing.radiusMD,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: iOS18Spacing.md),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
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
                size: 22,
                color: Colors.white,
              ),
            ),
            SizedBox(height: iOS18Spacing.sm),
            Text(
              title,
              style: iOS18Typography.caption1.copyWith(
                fontWeight: FontWeight.w500,
                color: iOS18Colors.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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