// Ultra-Premium Card Components
// Advanced glass morphing cards with liquid animations

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design_system/premium_design_system.dart';

// Ultra-Premium Glassmorphic Card
class UltraPremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool isInteractive;
  final double? width;
  final double? height;
  final List<Color>? gradientColors;
  
  const UltraPremiumCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.isInteractive = false,
    this.width,
    this.height,
    this.gradientColors,
  }) : super(key: key);
  
  @override
  State<UltraPremiumCard> createState() => _UltraPremiumCardState();
}

class _UltraPremiumCardState extends State<UltraPremiumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isHovering = false;
  
  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: PremiumAnimations.smooth,
      vsync: this,
    );
    
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: PremiumAnimations.glassEase,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: PremiumAnimations.liquidEase,
    ));
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: widget.isInteractive ? (_) => _hoverController.forward() : null,
          onTapUp: widget.isInteractive ? (_) => _hoverController.reverse() : null,
          onTapCancel: widget.isInteractive ? () => _hoverController.reverse() : null,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: AnimatedContainer(
              duration: PremiumAnimations.quick,
              curve: PremiumAnimations.bounceEase,
              width: widget.width,
              height: widget.height,
              margin: widget.margin ?? EdgeInsets.all(PremiumSpacing.sm),
              transform: Matrix4.identity()
                ..scale(1.0 + (0.02 * _hoverAnimation.value))
                ..rotateX(0.01 * _hoverAnimation.value)
                ..rotateY(0.01 * _hoverAnimation.value),
              child: _buildCardShell(),
            ),
          ),
        );
      },
    );
  }
  
  void _handleHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
    
    if (widget.isInteractive) {
      if (isHovering) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }
  
  Widget _buildCardShell() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusLG),
        boxShadow: [
          ...PremiumShadows.floatingCard,
          BoxShadow(
            color: PremiumColors.liquidPurple.withOpacity(0.1 * _glowAnimation.value),
            blurRadius: 30 * _glowAnimation.value,
            spreadRadius: 5 * _glowAnimation.value,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusLG),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: _buildCardGradient(),
              borderRadius: BorderRadius.circular(PremiumSpacing.radiusLG),
              border: Border.all(
                color: _isHovering 
                    ? PremiumColors.glassBorderMedium 
                    : PremiumColors.glassBorderSoft,
                width: 1.0 + (0.5 * _hoverAnimation.value),
              ),
            ),
            child: Padding(
              padding: widget.padding ?? EdgeInsets.all(PremiumSpacing.lg),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
  
  Gradient _buildCardGradient() {
    if (widget.gradientColors != null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.gradientColors!.map((c) => c.withOpacity(0.15)).toList(),
      );
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        PremiumColors.glassLight,
        PremiumColors.glassUltraLight,
        PremiumColors.glassMedium,
      ],
      stops: [0.0, 0.5, 1.0],
    );
  }
}

// Morphing Statistics Card
class LiquidStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  
  const LiquidStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.onTap,
  }) : super(key: key);
  
  @override
  State<LiquidStatsCard> createState() => _LiquidStatsCardState();
}

class _LiquidStatsCardState extends State<LiquidStatsCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _morphController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _iconRotation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: PremiumAnimations.morph,
      vsync: this,
    )..repeat(reverse: true);
    
    _morphController = AnimationController(
      duration: PremiumAnimations.liquid,
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: PremiumAnimations.glassEase,
    ));
    
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: PremiumAnimations.morphEase,
    ));
    
    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: PremiumAnimations.bounceEase,
    ));
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _morphController.dispose();
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
        animation: Listenable.merge([_pulseAnimation, _morphAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * (1.0 - 0.03 * _morphAnimation.value),
            child: _buildStatsCard(),
          );
        },
      ),
    );
  }
  
  Widget _buildStatsCard() {
    return Container(
      padding: EdgeInsets.all(PremiumSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusXL),
        boxShadow: [
          ...PremiumShadows.floatingCard,
          BoxShadow(
            color: widget.gradientColors.first.withOpacity(0.2 * _morphAnimation.value),
            blurRadius: 25 * _morphAnimation.value,
            spreadRadius: 3 * _morphAnimation.value,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.gradientColors[0].withOpacity(0.2),
                  widget.gradientColors[1].withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(PremiumSpacing.radiusXL),
              border: Border.all(
                color: PremiumColors.glassBorderMedium,
                width: 1.0,
              ),
            ),
            child: _buildStatsContent(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: PremiumTypography.liquidCaption.copyWith(
                  color: PremiumColors.textSecondary,
                ),
              ),
            ),
            Transform.rotate(
              angle: _iconRotation.value,
              child: Container(
                padding: EdgeInsets.all(PremiumSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(PremiumSpacing.radiusMD),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: PremiumColors.textGlass,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: PremiumSpacing.md),
        Text(
          widget.value,
          style: PremiumTypography.liquidTitle.copyWith(
            color: PremiumColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: PremiumSpacing.xs),
        Text(
          widget.subtitle,
          style: PremiumTypography.liquidCaption.copyWith(
            color: PremiumColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// Holographic Action Card
class HolographicCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  
  const HolographicCard({
    Key? key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // Base card
            ClipRRect(
              borderRadius: BorderRadius.circular(PremiumSpacing.radiusXL),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: PremiumColors.liquidGlass,
                    borderRadius: BorderRadius.circular(PremiumSpacing.radiusXL),
                    border: Border.all(
                      color: PremiumColors.glassBorderMedium,
                      width: 1.0,
                    ),
                    boxShadow: PremiumShadows.floatingCard,
                  ),
                  child: widget.child,
                ),
              ),
            ),
            // Shimmer effect
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(PremiumSpacing.radiusXL),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(_shimmerAnimation.value - 1, 0),
                        end: Alignment(_shimmerAnimation.value + 1, 0),
                        colors: [
                          Colors.transparent,
                          PremiumColors.holographicShimmer.colors[0].withOpacity(0.1),
                          PremiumColors.holographicShimmer.colors[2].withOpacity(0.2),
                          PremiumColors.holographicShimmer.colors[0].withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
