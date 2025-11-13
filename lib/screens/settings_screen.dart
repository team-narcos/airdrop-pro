import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/widgets/theme_selector.dart';
import '../providers/services_providers.dart';
import '../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getTextPrimary(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    return brightness == Brightness.dark 
        ? iOS18Colors.textPrimaryDark 
        : iOS18Colors.getTextPrimary(context);
  }
  
  Color _getTextSecondary(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    return brightness == Brightness.dark 
        ? iOS18Colors.textSecondaryDark 
        : iOS18Colors.getTextSecondary(context);
  }
  
  Color _getTextTertiary(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    return brightness == Brightness.dark 
        ? iOS18Colors.textTertiaryDark 
        : iOS18Colors.getTextTertiary(context);
  }

  @override
  Widget build(BuildContext context) {
    // Watch real settings
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );
    
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: iOS18Spacing.lg,
            vertical: iOS18Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: iOS18Spacing.xl),
              
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Settings',
                  style: iOS18Typography.largeTitle.copyWith(
                    color: _getTextPrimary(context),
                  ),
                ),
              ),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Profile Section
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildProfileSection(),
                ),
              ),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // AirDrop Settings
              _buildAirDropSettings(settings),
              
              SizedBox(height: iOS18Spacing.lg),
              
              // Appearance Settings
              if (settings != null) _buildAppearanceSettings(settings.themeMode, ref),
              
              SizedBox(height: iOS18Spacing.lg),
              
              // Connection Settings
              _buildConnectionSettings(),
              
              SizedBox(height: iOS18Spacing.lg),
              
              // Notifications Settings
              _buildNotificationSettings(),
              
              SizedBox(height: iOS18Spacing.lg),
              
              // About Section
              _buildAboutSection(),
              
              // Bottom padding for navigation
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final settingsAsync = ref.watch(appSettingsProvider);
    final deviceName = settingsAsync.maybeWhen(
      data: (settings) => settings.deviceName,
      orElse: () => 'My Device',
    );
    
    final isDiscoverable = settingsAsync.maybeWhen(
      data: (settings) => settings.isDiscoverable,
      orElse: () => true,
    );
    
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.lg),
      gradient: iOS18Colors.settingsGradient.scale(0.1),
      child: Row(
        children: [
          // Profile avatar with gradient
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: iOS18Colors.settingsGradient,
              borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: iOS18Colors.systemPurple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.device_laptop,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(width: iOS18Spacing.lg),
          
          // Profile info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: iOS18Typography.title2.copyWith(
                    color: _getTextPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: iOS18Spacing.xs),
                Text(
                  'AirDrop Device',
                  style: iOS18Typography.callout.copyWith(
                    color: _getTextSecondary(context),
                  ),
                ),
                SizedBox(height: iOS18Spacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: iOS18Spacing.sm,
                    vertical: iOS18Spacing.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isDiscoverable ? iOS18Colors.systemGreen : iOS18Colors.systemOrange).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(iOS18Spacing.radiusXS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDiscoverable ? iOS18Colors.systemGreen : iOS18Colors.systemOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.xs),
                      Text(
                        isDiscoverable ? 'Discoverable' : 'Hidden',
                        style: iOS18Typography.caption2.copyWith(
                          color: isDiscoverable ? iOS18Colors.systemGreen : iOS18Colors.systemOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Edit button
          GestureDetector(
            onTap: () => _showEditDeviceNameDialog(deviceName),
            child: Container(
              padding: EdgeInsets.all(iOS18Spacing.sm),
              decoration: BoxDecoration(
                color: iOS18Colors.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
              ),
              child: const Icon(
                CupertinoIcons.pencil,
                size: 20,
                color: iOS18Colors.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEditDeviceNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Device Name'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Device Name',
            textAlign: TextAlign.center,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final settingsService = ref.read(settingsServiceProvider);
                await settingsService.setDeviceName(controller.text.trim());
                if (mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showPortDialog(int currentPort) {
    final controller = TextEditingController(text: currentPort.toString());
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Port Number'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter port between 1024-65535',
                style: TextStyle(fontSize: 12, color: iOS18Colors.getTextSecondary(context)),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Port',
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final port = int.tryParse(controller.text.trim());
              if (port != null && port >= 1024 && port <= 65535) {
                HapticFeedback.mediumImpact();
                final settingsService = ref.read(settingsServiceProvider);
                await settingsService.setPortNumber(port);
                if (mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showBandwidthDialog(int currentLimit) {
    double sliderValue = currentLimit.toDouble();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Bandwidth Limit'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sliderValue == 0 
                      ? 'Unlimited' 
                      : '${sliderValue.toInt()} MB/s',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: iOS18Colors.systemBlue,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoSlider(
                  value: sliderValue,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      sliderValue = value;
                    });
                    HapticFeedback.selectionClick();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '0 = Unlimited',
                  style: TextStyle(fontSize: 12, color: iOS18Colors.getTextSecondary(context)),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final settingsService = ref.read(settingsServiceProvider);
                await settingsService.setBandwidthLimit(sliderValue.toInt());
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirDropSettings(AppSettings? settings) {
    return _buildSettingsSection(
      title: 'AirDrop',
      children: [
        _buildSwitchItem(
          title: 'Enable AirDrop',
          subtitle: 'Allow this device to be discovered',
          value: settings?.airdropEnabled ?? true,
          onChanged: (value) async {
            HapticFeedback.mediumImpact();
            final settingsService = ref.read(settingsServiceProvider);
            await settingsService.setAirdropEnabled(value);
            
            // Start or stop mDNS service
            final mdnsService = ref.read(mdnsDiscoveryProvider);
            if (value) {
              mdnsService?.start();
            } else {
              mdnsService?.stop();
            }
          },
        ),
        _buildDivider(),
        _buildSwitchItem(
          title: 'Allow Everyone',
          subtitle: 'Accept transfers from any nearby device',
          value: settings?.allowEveryone ?? true,
          onChanged: (value) async {
            final settingsService = ref.read(settingsServiceProvider);
            await settingsService.setAllowEveryone(value);
          },
        ),
        _buildDivider(),
        _buildSwitchItem(
          title: 'Auto-Accept from Contacts',
          subtitle: 'Automatically accept files from contacts',
          value: settings?.autoAcceptFromContacts ?? false,
          onChanged: (value) async {
            final settingsService = ref.read(settingsServiceProvider);
            await settingsService.setAutoAcceptFromContacts(value);
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings(ThemeMode themeMode, WidgetRef ref) {
    return _buildSettingsSection(
      title: 'Appearance',
      children: [
        Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.symmetric(vertical: iOS18Spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: iOS18Typography.bodyEmphasized.copyWith(
                    color: _getTextPrimary(context),
                  ),
                ),
                SizedBox(height: iOS18Spacing.md),
                ThemeSelector(
                  selectedMode: themeMode,
                  onThemeChanged: (value) async {
                    HapticFeedback.mediumImpact();
                    final settingsService = ref.read(settingsServiceProvider);
                    await settingsService.setThemeMode(value);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionSettings() {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );
    
    return _buildSettingsSection(
      title: 'Connection',
      children: [
        _buildNavigationItem(
          title: 'Port Number',
          subtitle: 'Current: ${settings?.portNumber ?? 37777}',
          icon: CupertinoIcons.number,
          onTap: () => _showPortDialog(settings?.portNumber ?? 37777),
        ),
        _buildDivider(),
        _buildNavigationItem(
          title: 'Bandwidth Limit',
          subtitle: settings?.bandwidthLimit != null && settings!.bandwidthLimit > 0
              ? '${settings.bandwidthLimit} MB/s'
              : 'Unlimited',
          icon: CupertinoIcons.speedometer,
          onTap: () => _showBandwidthDialog(settings?.bandwidthLimit ?? 0),
        ),
        _buildDivider(),
        _buildSwitchItem(
          title: 'File Compression',
          subtitle: 'Compress files before transfer',
          value: settings?.compressionEnabled ?? false,
          onChanged: (value) async {
            HapticFeedback.lightImpact();
            final settingsService = ref.read(settingsServiceProvider);
            await settingsService.setCompressionEnabled(value);
          },
        ),
        _buildDivider(),
        _buildSwitchItem(
          title: 'Biometric Authentication',
          subtitle: 'Require auth before transfers',
          value: settings?.biometricEnabled ?? false,
          onChanged: (value) async {
            HapticFeedback.lightImpact();
            final settingsService = ref.read(settingsServiceProvider);
            await settingsService.setBiometricEnabled(value);
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsSection(
      title: 'Notifications',
      children: [
        _buildSwitchItem(
          title: 'Sound',
          subtitle: 'Play sound for transfers',
          value: true,
          onChanged: (value) {
            // Implement sound setting
          },
        ),
        _buildDivider(),
        _buildSwitchItem(
          title: 'Vibration',
          subtitle: 'Vibrate on transfer completion',
          value: true,
          onChanged: (value) {
            // Implement vibration setting
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection(
      title: 'About',
      children: [
        _buildNavigationItem(
          title: 'App Version',
          subtitle: '1.0.0 (Build 1)',
          icon: CupertinoIcons.info_circle,
          onTap: () {
            HapticFeedback.lightImpact();
            showCupertinoDialog(
              context: context,
              builder: (dialogContext) => CupertinoAlertDialog(
                title: const Text('AirDrop Pro'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Version 1.0.0 (Build 1)'),
                    const SizedBox(height: 8),
                    Text(
                      'iOS 18 Style Premium File Sharing',
                      style: TextStyle(fontSize: 12, color: iOS18Colors.getTextSecondary(dialogContext)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2024 AirDrop Pro\nAll rights reserved',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: iOS18Colors.getTextTertiary(dialogContext)),
                    ),
                  ],
                ),
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
        _buildDivider(),
        _buildNavigationItem(
          title: 'Privacy Policy',
          subtitle: 'Learn about data protection',
          icon: CupertinoIcons.lock_shield,
          onTap: () {
            HapticFeedback.lightImpact();
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Privacy Policy'),
                content: const SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Text(
                        'Your privacy is important to us.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text('• All file transfers are encrypted end-to-end'),
                      SizedBox(height: 8),
                      Text('• No data is stored on external servers'),
                      SizedBox(height: 8),
                      Text('• Transfer history stays on your device'),
                      SizedBox(height: 8),
                      Text('• We never collect personal information'),
                      SizedBox(height: 8),
                      Text('• Full control over your data'),
                    ],
                  ),
                ),
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
        _buildDivider(),
        _buildNavigationItem(
          title: 'Help & Support',
          subtitle: 'Get help using AirDrop',
          icon: CupertinoIcons.question_circle,
          onTap: () {
            HapticFeedback.lightImpact();
            showCupertinoDialog(
              context: context,
              builder: (dialogContext) => CupertinoAlertDialog(
                title: const Text('Help & Support'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Quick Start Guide:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text('1. Enable AirDrop in Settings'),
                      const SizedBox(height: 8),
                      const Text('2. Tap the discovery button to start'),
                      const SizedBox(height: 8),
                      const Text('3. Select files to share'),
                      const SizedBox(height: 8),
                      const Text('4. Choose nearby devices'),
                      const SizedBox(height: 8),
                      const Text('5. Files transfer securely!'),
                      const SizedBox(height: 16),
                      Text(
                        'Need more help?\nCheck the Devices tab for tutorials.',
                        style: TextStyle(fontSize: 12, color: iOS18Colors.getTextSecondary(dialogContext)),
                      ),
                    ],
                  ),
                ),
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
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: iOS18Spacing.sm,
            bottom: iOS18Spacing.sm,
          ),
          child: Builder(
            builder: (context) => Text(
              title,
              style: iOS18Typography.title2.copyWith(
                color: _getTextPrimary(context),
              ),
            ),
          ),
        ),
        GlassmorphicCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.all(iOS18Spacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: iOS18Typography.bodyEmphasized.copyWith(
                      color: _getTextPrimary(context),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...
                    [
                      SizedBox(height: iOS18Spacing.xs / 2),
                      Text(
                        subtitle,
                        style: iOS18Typography.caption1.copyWith(
                          color: _getTextSecondary(context),
                        ),
                      ),
                    ],
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: iOS18Colors.systemBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(iOS18Spacing.md),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iOS18Colors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iOS18Colors.systemBlue,
                ),
              ),
              SizedBox(width: iOS18Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: iOS18Typography.bodyEmphasized.copyWith(
                        color: _getTextPrimary(context),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...
                      [
                        SizedBox(height: iOS18Spacing.xs / 2),
                        Text(
                          subtitle,
                          style: iOS18Typography.caption1.copyWith(
                            color: _getTextSecondary(context),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: _getTextTertiary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: EdgeInsets.only(left: iOS18Spacing.md * 3),
      color: iOS18Colors.getTextTertiary(context).withOpacity(0.3),
    );
  }
}

// Extension for gradient scaling (already exists in other files)
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
