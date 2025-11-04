// Ultra-Premium Design System
// Advanced glassmorphism, liquid animations, and premium aesthetics

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PremiumColors {
  // Ultra-Premium Gradient Colors with depth
  static const deepBlue = Color(0xFF0066FF);
  static const electricBlue = Color(0xFF0099FF);
  static const liquidPurple = Color(0xFF6366F1);
  static const vibrantPink = Color(0xFFEC4899);
  static const neonGreen = Color(0xFF10B981);
  static const luminousOrange = Color(0xFFFF6B35);
  
  // Sophisticated Background System
  static const ultraDarkBg = Color(0xFF0A0A0B);
  static const richDarkBg = Color(0xFF1C1C1E);
  static const premiumLightBg = Color(0xFFFAFAFC);
  static const glassBg = Color(0x0FFFFFFF);
  
  // Advanced Glass Effects
  static const glassUltraLight = Color(0x1AFFFFFF);
  static const glassLight = Color(0x26FFFFFF);
  static const glassMedium = Color(0x33FFFFFF);
  static const glassStrong = Color(0x4DFFFFFF);
  
  // Premium Glass Borders
  static const glassBorderSoft = Color(0x1AFFFFFF);
  static const glassBorderMedium = Color(0x33FFFFFF);
  static const glassBorderStrong = Color(0x4DFFFFFF);
  
  // Liquid Shadow System
  static const liquidShadowSoft = Color(0x0A000000);
  static const liquidShadowMedium = Color(0x1A000000);
  static const liquidShadowStrong = Color(0x33000000);
  static const liquidShadowDeep = Color(0x4D000000);
  
  // Premium Text Colors
  static const textUltraPrimary = Color(0xFF000000);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textGlass = Color(0xCCFFFFFF);
  
  // Ultra-Premium Gradients
  static const LinearGradient liquidGlass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient premiumAirDrop = LinearGradient(
    begin: Alignment(-1.2, -1.2),
    end: Alignment(1.2, 1.2),
    colors: [
      deepBlue,
      electricBlue,
      liquidPurple,
      vibrantPink,
    ],
    stops: [0.0, 0.25, 0.75, 1.0],
  );
  
  static const LinearGradient liquidMorph = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667EEA),
      Color(0xFF764BA2),
      Color(0xFFF093FB),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient holographicShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0x00FFFFFF),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const RadialGradient glowEffect = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [
      Color(0x33FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.7, 1.0],
  );
}

class PremiumShadows {
  // Ultra-Premium Shadow System
  static const List<BoxShadow> liquidGlass = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 16),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> floatingCard = [
    BoxShadow(
      color: Color(0x12000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05000000),
      offset: Offset(0, 32),
      blurRadius: 64,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> premiumButton = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> neonGlow = [
    BoxShadow(
      color: Color(0x4D6366F1),
      offset: Offset(0, 0),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A6366F1),
      offset: Offset(0, 0),
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];
}

class PremiumTypography {
  static const String primaryFont = 'SF Pro Display';
  static const List<String> fontStack = [
    'SF Pro Display',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'system-ui',
    'sans-serif'
  ];
  
  // Ultra-Premium Typography Scale
  static const TextStyle ultraLargeTitle = TextStyle(
    fontFamily: primaryFont,
    fontFamilyFallback: fontStack,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.1,
  );
  
  static const TextStyle premiumTitle = TextStyle(
    fontFamily: primaryFont,
    fontFamilyFallback: fontStack,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.15,
  );
  
  static const TextStyle liquidTitle = TextStyle(
    fontFamily: primaryFont,
    fontFamilyFallback: fontStack,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle glassHeadline = TextStyle(
    fontFamily: primaryFont,
    fontFamilyFallback: fontStack,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  static const TextStyle premiumBody = TextStyle(
    fontFamily: primaryFont,
    fontFamilyFallback: fontStack,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.4,
  );
  
  static const TextStyle liquidCaption = TextStyle(
    fontFamily: primaryFont,
    fontFamilyFallback: fontStack,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.35,
  );
}

class PremiumSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double ultra = 64.0;
  
  // Radius values for liquid design
  static const double radiusXS = 6.0;
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusUltra = 48.0;
  static const double radiusLiquid = 64.0;
}

class PremiumAnimations {
  // Premium Animation Curves
  static const Curve liquidEase = Curves.easeOutCubic;
  static const Curve glassEase = Curves.easeInOutCubic;
  static const Curve morphEase = Curves.easeOutQuart;
  static const Curve bounceEase = Curves.elasticOut;
  
  // Animation Durations
  static const Duration instant = Duration(milliseconds: 150);
  static const Duration quick = Duration(milliseconds: 250);
  static const Duration smooth = Duration(milliseconds: 400);
  static const Duration liquid = Duration(milliseconds: 600);
  static const Duration morph = Duration(milliseconds: 800);
}

// Premium Glass Effect Widget
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Border? border;
  
  const LiquidGlass({
    Key? key,
    required this.child,
    this.blur = 10.0,
    this.color,
    this.borderRadius,
    this.shadows,
    this.border,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(PremiumSpacing.radiusMD),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? PremiumColors.glassLight,
            borderRadius: borderRadius ?? BorderRadius.circular(PremiumSpacing.radiusMD),
            border: border ?? Border.all(
              color: PremiumColors.glassBorderSoft,
              width: 1.0,
            ),
            boxShadow: shadows ?? PremiumShadows.liquidGlass,
          ),
          child: child,
        ),
      ),
    );
  }
}

// Floating Action Button with Premium Effects
class LiquidFloatingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final double size;
  
  const LiquidFloatingButton({
    Key? key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.size = 64.0,
  }) : super(key: key);
  
  @override
  State<LiquidFloatingButton> createState() => _LiquidFloatingButtonState();
}

class _LiquidFloatingButtonState extends State<LiquidFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PremiumAnimations.smooth,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: PremiumAnimations.liquidEase,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: PremiumAnimations.glassEase,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: PremiumColors.premiumAirDrop,
                borderRadius: BorderRadius.circular(widget.size / 2),
                boxShadow: [
                  ...PremiumShadows.premiumButton,
                  BoxShadow(
                    color: PremiumColors.liquidPurple.withOpacity(
                      0.3 * _glowAnimation.value,
                    ),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 2 * _glowAnimation.value,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Center(child: widget.child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}