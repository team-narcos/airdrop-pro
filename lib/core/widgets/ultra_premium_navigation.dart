// Ultra-Premium Floating Navigation
// Liquid glass morphing navigation with advanced animations

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design_system/premium_design_system.dart';

class UltraPremiumNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<UltraPremiumNavItem> items;
  
  const UltraPremiumNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);
  
  @override
  State<UltraPremiumNavigation> createState() => _UltraPremiumNavigationState();
}

class _UltraPremiumNavigationState extends State<UltraPremiumNavigation>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _glowController;
  late Animation<double> _morphAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _morphController = AnimationController(
      duration: PremiumAnimations.liquid,
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: PremiumAnimations.smooth,
      vsync: this,
    )..repeat(reverse: true);
    
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: PremiumAnimations.morphEase,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: PremiumAnimations.glassEase,
    ));
  }
  
  @override
  void dispose() {
    _morphController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(PremiumSpacing.xl),
      child: AnimatedBuilder(
        animation: Listenable.merge([_morphAnimation, _glowAnimation]),
        builder: (context, child) {
          return _buildNavigationShell();
        },
      ),
    );
  }
  
  Widget _buildNavigationShell() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusUltra),
        boxShadow: [
          ...PremiumShadows.floatingCard,
          BoxShadow(
            color: PremiumColors.liquidPurple.withOpacity(0.1 * _glowAnimation.value),
            blurRadius: 40 * _glowAnimation.value,
            spreadRadius: 4 * _glowAnimation.value,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusUltra),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: PremiumColors.liquidGlass,
              borderRadius: BorderRadius.circular(PremiumSpacing.radiusUltra),
              border: Border.all(
                color: PremiumColors.glassBorderMedium,
                width: 1.5,
              ),
            ),
            child: _buildNavigationContent(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavigationContent() {
    return Stack(
      children: [
        // Animated background indicator
        AnimatedPositioned(
          duration: PremiumAnimations.liquid,
          curve: PremiumAnimations.morphEase,
          left: _calculateIndicatorPosition(),
          top: PremiumSpacing.md,
          child: _buildActiveIndicator(),
        ),
        // Navigation items
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: widget.items.asMap().entries.map((entry) {
            return _buildNavigationItem(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }
  
  double _calculateIndicatorPosition() {
    final itemWidth = (MediaQuery.of(context).size.width - (PremiumSpacing.xl * 4)) / widget.items.length;
    return (widget.currentIndex * itemWidth) + (itemWidth / 2) - 25;
  }
  
  Widget _buildActiveIndicator() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: PremiumColors.premiumAirDrop,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: PremiumColors.liquidPurple.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: PremiumColors.glassLight,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavigationItem(int index, UltraPremiumNavItem item) {
    final isActive = index == widget.currentIndex;
    
    return GestureDetector(
      onTap: () {
        _morphController.forward().then((_) {
          _morphController.reverse();
        });
        widget.onTap(index);
      },
      child: Container(
        width: 60,
        height: 60,
        child: AnimatedScale(
          scale: isActive ? 1.1 : 1.0,
          duration: PremiumAnimations.quick,
          curve: PremiumAnimations.bounceEase,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: PremiumAnimations.smooth,
                padding: EdgeInsets.all(isActive ? PremiumSpacing.sm : PremiumSpacing.md),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: isActive 
                      ? PremiumColors.textGlass 
                      : PremiumColors.textSecondary,
                ),
              ),
              if (isActive) ...[
                SizedBox(height: PremiumSpacing.xs),
                Text(
                  item.label,
                  style: PremiumTypography.liquidCaption.copyWith(
                    color: PremiumColors.textGlass,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class UltraPremiumNavItem {
  final IconData icon;
  final String label;
  final Color? activeColor;
  
  const UltraPremiumNavItem({
    required this.icon,
    required this.label,
    this.activeColor,
  });
}

// Liquid Morphing Discovery Button
class LiquidDiscoveryButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final double size;
  
  const LiquidDiscoveryButton({
    Key? key,
    required this.isActive,
    this.onTap,
    this.size = 240.0,
  }) : super(key: key);
  
  @override
  State<LiquidDiscoveryButton> createState() => _LiquidDiscoveryButtonState();
}

class _LiquidDiscoveryButtonState extends State<LiquidDiscoveryButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _morphController;
  late AnimationController _particleController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _particleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: PremiumAnimations.morph,
      vsync: this,
    );
    
    _morphController = AnimationController(
      duration: PremiumAnimations.liquid,
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: PremiumAnimations.bounceEase,
    ));
    
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: PremiumAnimations.morphEase,
    ));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));
    
    _startAnimations();
  }
  
  void _startAnimations() {
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
      _particleController.repeat();
    } else {
      _pulseController.stop();
      _particleController.stop();
    }
  }
  
  @override
  void didUpdateWidget(LiquidDiscoveryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _startAnimations();
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _morphController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _morphController.forward(),
      onTapUp: (_) {
        _morphController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _morphController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _morphAnimation,
          _particleAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * (1.0 - 0.05 * _morphAnimation.value),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Particle effects
                if (widget.isActive) _buildParticleEffects(),
                // Main button
                _buildMainButton(),
                // Glow effect
                if (widget.isActive) _buildGlowEffect(),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMainButton() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: widget.isActive 
            ? PremiumColors.premiumAirDrop 
            : PremiumColors.liquidMorph,
        shape: BoxShape.circle,
        boxShadow: [
          ...PremiumShadows.floatingCard,
          if (widget.isActive)
            BoxShadow(
              color: PremiumColors.liquidPurple.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 8,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: PremiumColors.glassLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: PremiumColors.glassBorderStrong,
                width: 2.0,
              ),
            ),
            child: Center(
              child: Icon(
                widget.isActive ? CupertinoIcons.radiowaves_right : CupertinoIcons.wifi,
                size: widget.size * 0.3,
                color: PremiumColors.textGlass,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlowEffect() {
    return Container(
      width: widget.size + 40,
      height: widget.size + 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PremiumColors.glowEffect,
      ),
    );
  }
  
  Widget _buildParticleEffects() {
    return SizedBox(
      width: widget.size + 100,
      height: widget.size + 100,
      child: CustomPaint(
        painter: ParticleEffectPainter(_particleAnimation.value),
      ),
    );
  }
}

class ParticleEffectPainter extends CustomPainter {
  final double animationValue;
  
  ParticleEffectPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PremiumColors.liquidPurple.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    for (int i = 0; i < 8; i++) {
      final angle = (animationValue + (i * math.pi / 4));
      final particleRadius = radius + (20 * math.sin(animationValue * 2));
      final x = center.dx + particleRadius * math.cos(angle);
      final y = center.dy + particleRadius * math.sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        3 + (2 * math.sin(animationValue * 3 + i)),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}