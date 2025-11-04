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
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x30FFFFFF),
          Color(0x20FFFFFF),
          Color(0x15FFFFFF),
          Color(0x10FFFFFF),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x40FFFFFF),
          Color(0x30FFFFFF),
          Color(0x20FFFFFF),
          Color(0x15FFFFFF),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      );
    }
  }

  Border _defaultBorder(bool isDark) {
    return Border.all(
      color: isDark ? iOS18Colors.glassBorderDark : iOS18Colors.glassBorder,
      width: 0.5,
    );
  }

  List<BoxShadow> _defaultShadows(bool isDark) {
    return isDark ? iOS18Shadows.glassShadowsDark : iOS18Shadows.glassShadows;
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
                  color: widget.glowGradient.colors.first.withOpacity(_animation.value * 0.4),
                  blurRadius: 30 * _animation.value,
                  spreadRadius: 5 * _animation.value,
                ),
                BoxShadow(
                  color: widget.glowGradient.colors.last.withOpacity(_animation.value * 0.2),
                  blurRadius: 60 * _animation.value,
                  spreadRadius: 10 * _animation.value,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      transform: GradientRotation(_animation.value * 0.2),
                      colors: widget.glowGradient.colors,
                      stops: widget.glowGradient.stops,
                      begin: widget.glowGradient.begin ?? Alignment.centerLeft,
                      end: widget.glowGradient.end ?? Alignment.centerRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
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