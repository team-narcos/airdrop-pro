import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/platform/platform_adapter.dart';

class DemoModeScreen extends StatefulWidget {
  const DemoModeScreen({Key? key}) : super(key: key);

  @override
  State<DemoModeScreen> createState() => _DemoModeScreenState();
}

class _DemoModeScreenState extends State<DemoModeScreen>
    with TickerProviderStateMixin {
  String _selectedProtocol = 'WiFi Direct';
  bool _isTransferring = false;
  double _transferProgress = 0.0;
  String _compressionRatio = '0%';
  bool _isEncrypted = true;
  String _aiCategory = 'Document';
  Timer? _progressTimer;
  late AnimationController _pulseController;
  
  final List<String> _protocols = [
    'WiFi Direct',
    'Bluetooth Mesh',
    'WebRTC',
    'BLE',
  ];

  final List<String> _categories = [
    'Document',
    'Image',
    'Video',
    'Audio',
    'Archive',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startDemoTransfer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isTransferring = true;
      _transferProgress = 0.0;
    });

    // Simulate transfer progress
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _transferProgress += 0.02;
        
        // Update compression ratio dynamically
        final compression = (30 + Random().nextInt(40)).toStringAsFixed(0);
        _compressionRatio = '$compression%';
        
        if (_transferProgress >= 1.0) {
          _transferProgress = 1.0;
          _isTransferring = false;
          timer.cancel();
          _showCompletionDialog();
        }
      });
    });
  }

  void _showCompletionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Transfer Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              'Protocol: $_selectedProtocol\nCompression: $_compressionRatio savings\nEncryption: AES-256\nCategory: $_aiCategory',
              textAlign: TextAlign.center,
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : iOS18Colors.backgroundPrimary;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white70 : iOS18Colors.getTextSecondary(context);
    
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(iOS18Spacing.lg),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(iOS18Spacing.sm),
                        decoration: BoxDecoration(
                          color: iOS18Colors.getTextTertiary(context)
                              .withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(iOS18Spacing.radiusSM),
                        ),
                        child: Icon(
                          CupertinoIcons.back,
                          size: 24,
                          color: iOS18Colors.getTextPrimary(context),
                        ),
                      ),
                    ),
                    SizedBox(width: iOS18Spacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interactive Demo',
                          style: iOS18Typography.title1.copyWith(
                            color: iOS18Colors.getTextPrimary(context),
                          ),
                        ),
                        Text(
                          'Test all advanced features',
                          style: iOS18Typography.body.copyWith(
                            fontSize: 12,
                            color: iOS18Colors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Protocol Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Protocol',
                      style: iOS18Typography.headline.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                      ),
                    ),
                    SizedBox(height: iOS18Spacing.md),
                    GlassmorphicCard(
                      child: Padding(
                        padding: EdgeInsets.all(iOS18Spacing.sm),
                        child: Wrap(
                          spacing: iOS18Spacing.sm,
                          runSpacing: iOS18Spacing.sm,
                          children: _protocols.map((protocol) {
                            final isSelected = protocol == _selectedProtocol;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedProtocol = protocol;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: iOS18Spacing.md,
                                  vertical: iOS18Spacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [iOS18Colors.systemBlue, iOS18Colors.systemPurple],
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : iOS18Colors.getTextTertiary(context)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      iOS18Spacing.radiusSM),
                                ),
                                child: Text(
                                  protocol,
                                  style: iOS18Typography.body.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : iOS18Colors.getTextPrimary(context),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: iOS18Spacing.lg)),

            // Transfer Simulation
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.lg),
                child: GlassmorphicCard(
                  child: Padding(
                    padding: EdgeInsets.all(iOS18Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'File Transfer Demo',
                              style: iOS18Typography.headline.copyWith(
                                color: iOS18Colors.getTextPrimary(context),
                              ),
                            ),
                            if (_isTransferring)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (_pulseController.value * 0.4),
                                    child: Icon(
                                      CupertinoIcons.arrow_right_arrow_left_circle_fill,
                                      color: iOS18Colors.systemBlue,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        SizedBox(height: iOS18Spacing.lg),
                        
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(iOS18Spacing.radiusXS),
                          child: LinearProgressIndicator(
                            value: _transferProgress,
                            minHeight: 8,
                            backgroundColor: iOS18Colors.getTextTertiary(context)
                                .withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              iOS18Colors.systemBlue,
                            ),
                          ),
                        ),
                        SizedBox(height: iOS18Spacing.md),
                        
                        Text(
                          '${(_transferProgress * 100).toStringAsFixed(0)}% Complete',
                          style: iOS18Typography.body.copyWith(
                            color: iOS18Colors.getTextSecondary(context),
                          ),
                        ),
                        
                        SizedBox(height: iOS18Spacing.lg),
                        
                        // Start button
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            padding: EdgeInsets.symmetric(
                              vertical: iOS18Spacing.md,
                            ),
                            color: _isTransferring
                                ? iOS18Colors.getTextTertiary(context)
                                : iOS18Colors.systemBlue,
                            onPressed: _isTransferring ? null : _startDemoTransfer,
                            child: Text(
                              _isTransferring
                                  ? 'Transferring...'
                                  : 'Start Demo Transfer',
                              style: iOS18Typography.bodyEmphasized.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: iOS18Spacing.lg)),

            // Real-time Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-time Statistics',
                      style: iOS18Typography.headline.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                      ),
                    ),
                    SizedBox(height: iOS18Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: CupertinoIcons.arrow_2_squarepath,
                            title: 'Compression',
                            value: _compressionRatio,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: iOS18Spacing.sm),
                        Expanded(
                          child: _buildStatCard(
                            icon: CupertinoIcons.lock_shield_fill,
                            title: 'Encryption',
                            value: _isEncrypted ? 'AES-256' : 'None',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: iOS18Spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: CupertinoIcons.lightbulb_fill,
                            title: 'AI Category',
                            value: _aiCategory,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(width: iOS18Spacing.sm),
                        Expanded(
                          child: _buildStatCard(
                            icon: CupertinoIcons.wifi,
                            title: 'Protocol',
                            value: _selectedProtocol.split(' ').first,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: iOS18Spacing.lg)),

            // Feature Toggles
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: iOS18Spacing.lg),
                child: GlassmorphicCard(
                  child: Padding(
                    padding: EdgeInsets.all(iOS18Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feature Controls',
                          style: iOS18Typography.headline.copyWith(
                            color: iOS18Colors.getTextPrimary(context),
                          ),
                        ),
                        SizedBox(height: iOS18Spacing.md),
                        _buildToggleRow(
                          'End-to-End Encryption',
                          _isEncrypted,
                          (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isEncrypted = value;
                            });
                          },
                        ),
                        Divider(height: iOS18Spacing.lg),
                        _buildCategorySelector(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return GlassmorphicCard(
      child: Padding(
        padding: EdgeInsets.all(iOS18Spacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: iOS18Spacing.sm),
            Text(
              title,
              style: iOS18Typography.body.copyWith(
                fontSize: 10,
                color: iOS18Colors.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: iOS18Spacing.xs),
            Text(
              value,
              style: iOS18Typography.bodyEmphasized.copyWith(
                color: iOS18Colors.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: iOS18Typography.body.copyWith(
            color: iOS18Colors.getTextPrimary(context),
          ),
        ),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: iOS18Colors.systemBlue,
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI File Category',
          style: iOS18Typography.body.copyWith(
            color: iOS18Colors.getTextPrimary(context),
          ),
        ),
        SizedBox(height: iOS18Spacing.sm),
        Wrap(
          spacing: iOS18Spacing.sm,
          runSpacing: iOS18Spacing.sm,
          children: _categories.map((category) {
            final isSelected = category == _aiCategory;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _aiCategory = category;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: iOS18Spacing.md,
                  vertical: iOS18Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? iOS18Colors.systemBlue.withOpacity(0.2)
                      : iOS18Colors.getTextTertiary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusXS),
                  border: Border.all(
                    color: isSelected
                        ? iOS18Colors.systemBlue
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  category,
                  style: iOS18Typography.body.copyWith(
                    fontSize: 10,
                    color: isSelected
                        ? iOS18Colors.systemBlue
                        : iOS18Colors.getTextSecondary(context),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
