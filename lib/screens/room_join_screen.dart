import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';

class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({Key? key}) : super(key: key);

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showError('Please enter a room code');
      return;
    }

    if (code.length != 6) {
      _showError('Room code must be 6 characters');
      return;
    }

    setState(() {
      _isJoining = true;
    });

    HapticFeedback.mediumImpact();

    // Simulate join process
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isJoining = false;
      });

      // Show success
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Joined Room'),
          content: Text('Successfully joined room $code'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: iOS18Colors.backgroundPrimary,
      child: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iOS18Colors.backgroundPrimary,
                  iOS18Colors.backgroundSecondary,
                  iOS18Colors.backgroundPrimary,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(iOS18Spacing.lg),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(iOS18Spacing.sm),
                          decoration: BoxDecoration(
                            color: iOS18Colors.getTextTertiary(context).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                          ),
                          child: const Icon(
                            CupertinoIcons.back,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.md),
                      Text(
                        'Join Room',
                        style: iOS18Typography.title1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(iOS18Spacing.lg),
                      child: Column(
                        children: [
                          SizedBox(height: iOS18Spacing.xxxl),
                          
                          // Icon
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    gradient: iOS18Colors.settingsGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: iOS18Colors.systemPurple.withOpacity(0.3),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.number_square,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          SizedBox(height: iOS18Spacing.xxxl),
                          
                          // Instructions
                          GlassmorphicCard(
                            padding: EdgeInsets.all(iOS18Spacing.lg),
                            child: Column(
                              children: [
                                Text(
                                  'Enter Room Code',
                                  style: iOS18Typography.title2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: iOS18Spacing.sm),
                                Text(
                                  'Ask the room creator for the 6-character code',
                                  style: iOS18Typography.subheadline.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: iOS18Spacing.xxl),
                          
                          // Code input
                          GlassmorphicCard(
                            padding: EdgeInsets.all(iOS18Spacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room Code',
                                  style: iOS18Typography.headline.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: iOS18Spacing.md),
                                CupertinoTextField(
                                  controller: _codeController,
                                  placeholder: 'ABC123',
                                  placeholderStyle: iOS18Typography.title1.copyWith(
                                    color: Colors.white.withOpacity(0.3),
                                    letterSpacing: 6,
                                  ),
                                  style: iOS18Typography.title1.copyWith(
                                    color: Colors.white,
                                    letterSpacing: 6,
                                  ),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.text,
                                  maxLength: 6,
                                  decoration: BoxDecoration(
                                    color: iOS18Colors.backgroundSecondary,
                                    borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                                  ),
                                  padding: EdgeInsets.all(iOS18Spacing.lg),
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: iOS18Spacing.xxl),
                          
                          // Join button
                          GestureDetector(
                            onTap: _isJoining ? null : _handleJoin,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(iOS18Spacing.lg),
                              decoration: BoxDecoration(
                                gradient: _isJoining
                                    ? LinearGradient(
                                        colors: [
                                          iOS18Colors.systemGray.withOpacity(0.5),
                                          iOS18Colors.systemGray.withOpacity(0.3),
                                        ],
                                      )
                                    : iOS18Colors.settingsGradient,
                                borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                                boxShadow: _isJoining
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: iOS18Colors.systemPurple.withOpacity(0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: _isJoining
                                  ? const Center(
                                      child: CupertinoActivityIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.arrow_right_circle_fill,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: iOS18Spacing.md),
                                        Text(
                                          'Join Room',
                                          style: iOS18Typography.headline.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
