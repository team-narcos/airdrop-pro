import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/ios18_theme.dart';

class PremiumDiscoveryButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  final double size;

  const PremiumDiscoveryButton({
    Key? key,
    required this.isActive,
    required this.onTap,
    this.size = 200,
  }) : super(key: key);

  @override
  State<PremiumDiscoveryButton> createState() => _PremiumDiscoveryButtonState();
}

class _PremiumDiscoveryButtonState extends State<PremiumDiscoveryButton>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _ringController;
  late AnimationController _scaleController;
  
  late Animation<double> _gradientAnimation;
  late Animation<double> _scaleAnimation;
  
  final List<Color> _gradientColors = [
    const Color(0xFF0A84FF), // Blue
    const Color(0xFF5E5CE6), // Indigo
    const Color(0xFFBF5AF2), // Purple
    const Color(0xFFFF2D55), // Pink
  ];

  @override
  void initState() {
    super.initState();
    
    // Gradient rotation animation (8 seconds)
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _gradientAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );
    
    // Pulsing rings animation
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Scale animation for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    if (widget.isActive) {
      _ringController.repeat();
    }
  }

  @override
  void didUpdateWidget(PremiumDiscoveryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _ringController.repeat();
      } else {
        _ringController.stop();
        _ringController.reset();
      }
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _ringController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _scaleController.forward().then((_) => _scaleController.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _ringController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.size + 100,
              height: widget.size + 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated pulsing rings
                  if (widget.isActive) ..._buildPulsingRings(),
                  
                  // Main button with glassmorphism
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(0, 8),
                          blurRadius: 24,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          offset: const Offset(0, 16),
                          blurRadius: 48,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1C1E).withOpacity(0.85)
                                : Colors.white.withOpacity(0.90),
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedBuilder(
                            animation: _gradientAnimation,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    startAngle: _gradientAnimation.value,
                                    endAngle: _gradientAnimation.value + 2 * 3.14159,
                                    colors: [
                                      ..._gradientColors,
                                      _gradientColors[0],
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.isActive
                                            ? CupertinoIcons.antenna_radiowaves_left_right
                                            : CupertinoIcons.arrow_up_circle_fill,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: iOS18Spacing.md),
                                      Text(
                                        widget.isActive ? 'Discovering' : 'Tap to Share',
                                        style: iOS18Typography.headline.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (!widget.isActive) ...[
                                        SizedBox(height: iOS18Spacing.xs),
                                        Text(
                                          'Share files instantly',
                                          style: iOS18Typography.caption1.copyWith(
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPulsingRings() {
    return List.generate(4, (index) {
      final delay = index * 0.25;
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _ringController,
          curve: Interval(
            delay.clamp(0.0, 0.75),
            (delay + 0.25).clamp(0.25, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );

      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final progress = animation.value;
          final size = widget.size + (80 * progress);
          final opacity = 0.6 * (1 - progress);

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _gradientColors[index % _gradientColors.length]
                    .withOpacity(opacity),
                width: 3,
              ),
            ),
          );
        },
      );
    });
  }
}
