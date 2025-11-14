import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design_system/ios18_theme.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final Border? border;
  final VoidCallback? onTap;
  final bool isDark;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(iOS18Spacing.md),
    this.margin,
    this.borderRadius = iOS18Spacing.radiusMD,
    this.gradient,
    this.backgroundColor,
    this.shadows,
    this.border,
    this.onTap,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Detect dark mode from CupertinoTheme (respects user's app theme setting)
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isSystemDark = brightness == Brightness.dark;
    final effectiveDark = isDark || isSystemDark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),  // iOS 26: Very strong blur
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient ?? _defaultGradient(effectiveDark),
                color: backgroundColor,
                border: border ?? _defaultBorder(effectiveDark),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: shadows ?? _defaultShadows(effectiveDark),
              ),
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _defaultGradient(bool isDark) {
    if (isDark) {
      // iOS 26 Dark: Premium glass with excellent contrast
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.15),  // 15% top - visible glass
          Colors.white.withOpacity(0.10),  // 10% middle
          Colors.white.withOpacity(0.07),  // 7% lower
          Colors.white.withOpacity(0.04),  // 4% bottom - fade
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
    } else {
      // iOS 26 Light: Balanced glass - text readable, glass visible
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.70),  // 70% top - readable text
          Colors.white.withOpacity(0.60),  // 60% middle
          Colors.white.withOpacity(0.50),  // 50% lower
          Colors.white.withOpacity(0.40),  // 40% bottom - gradient
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
    }
  }

  Border _defaultBorder(bool isDark) {
    // iOS 26: Premium luminous borders with Apple polish
    return Border.all(
      color: isDark 
          ? Colors.white.withOpacity(0.25)   // 25% white - elegant glow
          : Colors.white.withOpacity(0.45),  // 45% white - refined shimmer
      width: 1.5,  // iOS 26: Apple's refined thickness
    );
  }

  List<BoxShadow> _defaultShadows(bool isDark) {
    // iOS 26: DRAMATIC shadows for visible depth
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.6),  // Strong shadow
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),  // Visible shadow
          blurRadius: 30,
          spreadRadius: 0,
          offset: const Offset(0, 15),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];
    }
  }
}

class PulsingGlowCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final LinearGradient glowGradient;
  final double borderRadius;
  final Duration animationDuration;
  final bool isActive;
  final VoidCallback? onTap;

  const PulsingGlowCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.glowGradient = iOS18Colors.airDropGradient,
    this.borderRadius = iOS18Spacing.radiusXL,
    this.animationDuration = const Duration(seconds: 2),
    this.isActive = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<PulsingGlowCard> createState() => _PulsingGlowCardState();
}

class _PulsingGlowCardState extends State<PulsingGlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingGlowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: widget.glowGradient.colors.first.withOpacity(_animation.value * 0.35),
                  blurRadius: 24 * _animation.value,
                  spreadRadius: 0,
                  offset: Offset(0, 6 * _animation.value),
                ),
                BoxShadow(
                  color: widget.glowGradient.colors.last.withOpacity(_animation.value * 0.25),
                  blurRadius: 48 * _animation.value,
                  spreadRadius: 0,
                  offset: Offset(0, 12 * _animation.value),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),  // iOS 26: Strong blur
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      transform: GradientRotation(_animation.value * 0.15),
                      colors: widget.glowGradient.colors,
                      stops: widget.glowGradient.stops,
                      begin: widget.glowGradient.begin ?? Alignment.centerLeft,
                      end: widget.glowGradient.end ?? Alignment.centerRight,
                    ),
                    border: Border.all(
                      color: const Color(0x52FFFFFF),  // 32% white - refined glow
                      width: 1.2,  // iOS 26: Refined thickness
                    ),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedPressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final LinearGradient? gradient;
  final bool hapticFeedback;

  const AnimatedPressCard({
    Key? key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(iOS18Spacing.md),
    this.borderRadius = iOS18Spacing.radiusMD,
    this.gradient,
    this.hapticFeedback = true,
  }) : super(key: key);

  @override
  State<AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<AnimatedPressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.hapticFeedback) {
      // Note: In a real app, you'd use HapticFeedback.lightImpact()
      // but it requires proper platform channel setup
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: GlassmorphicCard(
                width: widget.width,
                height: widget.height,
                padding: widget.padding,
                borderRadius: widget.borderRadius,
                gradient: widget.gradient,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ShimmerCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isLoading;

  const ShimmerCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = iOS18Spacing.radiusMD,
    this.isLoading = true,
  }) : super(key: key);

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          widget.child,
          if (widget.isLoading)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_animation.value * 200, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0x20FFFFFF),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}