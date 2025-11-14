import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design_system/ios18_theme.dart';

class PremiumBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<PremiumBottomNavItem> items;
  final double height;
  final Color? backgroundColor;
  final bool floating;

  const PremiumBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.height = 90,
    this.backgroundColor,
    this.floating = true,
  }) : super(key: key);

  @override
  State<PremiumBottomNavigation> createState() => _PremiumBottomNavigationState();
}

class _PremiumBottomNavigationState extends State<PremiumBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers
        .map((controller) => Tween<double>(begin: 1.0, end: 1.2).animate(
              CurvedAnimation(parent: controller, curve: Curves.elasticOut),
            ))
        .toList();

    // Animate the initially selected item
    if (widget.currentIndex >= 0 && widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(PremiumBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Animate out the old selection
      if (oldWidget.currentIndex >= 0 && oldWidget.currentIndex < _controllers.length) {
        _controllers[oldWidget.currentIndex].reverse();
      }
      // Animate in the new selection
      if (widget.currentIndex >= 0 && widget.currentIndex < _controllers.length) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;
    final safeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      height: widget.height + safeArea,
      padding: EdgeInsets.only(
        top: iOS18Spacing.sm,
        bottom: safeArea + iOS18Spacing.sm,
        left: widget.floating ? iOS18Spacing.md : 0,
        right: widget.floating ? iOS18Spacing.md : 0,
      ),
      child: widget.floating ? _buildFloatingNav(isDark) : _buildFixedNav(isDark),
    );
  }

  Widget _buildFloatingNav(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),  // iOS 26: Premium blur
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),  // Smooth transition
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: _getNavGradient(isDark),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.30)   // 30% - Elegant glow
                  : Colors.white.withOpacity(0.40),  // 40% - Refined edge
              width: 1.5,  // iOS 26: Apple's standard
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.20),
                blurRadius: 32,
                offset: const Offset(0, -8),  // Shadow going up
              ),
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, -4),  // Subtle inner shadow
              ),
            ],
          ),
          child: _buildNavContent(),
        ),
      ),
    );
  }

  Widget _buildFixedNav(bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),  // iOS 26: Premium blur
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),  // Smooth transition
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: _getNavGradient(isDark),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.30)  // 30% - Elegant edge
                    : Colors.white.withOpacity(0.40),  // 40% - Refined edge
                width: 1.5,  // iOS 26: Apple's standard
              ),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: _buildNavContent(),
        ),
      ),
    );
  }

  Widget _buildNavContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: widget.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isSelected = index == widget.currentIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onTap(index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: iOS18Spacing.sm),
              child: AnimatedBuilder(
                animation: _scaleAnimations[index],
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _scaleAnimations[index].value,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: isSelected
                              ? BoxDecoration(
                                  gradient: iOS18Colors.airDropGradient,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: iOS18Colors.systemBlue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                )
                              : null,
                          child: Builder(
                            builder: (context) {
                              final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
                              final isDark = brightness == Brightness.dark;
                              
                              return Icon(
                                item.icon,
                                size: 24,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark 
                                        ? iOS18Colors.textSecondaryDark  // Bright gray for dark mode
                                        : Colors.black.withOpacity(0.6)),  // Dark gray for light mode
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: iOS18Spacing.xs),
                      Builder(
                        builder: (context) {
                          final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
                          final isDark = brightness == Brightness.dark;
                          
                          return AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: iOS18Typography.caption2.copyWith(
                              color: isSelected
                                  ? iOS18Colors.systemBlue
                                  : (isDark 
                                      ? iOS18Colors.textSecondaryDark  // Bright for dark mode
                                      : Colors.black.withOpacity(0.6)),  // Dark for light mode
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  LinearGradient _getNavGradient(bool isDark) {
    if (isDark) {
      // iOS 26 Dark: Premium glass with excellent contrast
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.70), // 70% black - Rich glass, great contrast
          Colors.black.withOpacity(0.60), // 60% black - Depth
          Colors.black.withOpacity(0.50), // 50% black - Refined
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    } else {
      // iOS 26 Light: Strong glass for perfect text readability
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.90), // 90% white - Excellent readability
          Colors.white.withOpacity(0.85), // 85% white - Strong background
          Colors.white.withOpacity(0.80), // 80% white - Refined
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    }
  }
}

class PremiumBottomNavItem {
  final IconData icon;
  final String label;
  final LinearGradient? gradient;

  const PremiumBottomNavItem({
    required this.icon,
    required this.label,
    this.gradient,
  });
}

// Custom icons for the navigation
class CustomNavIcons {
  static const IconData airdrop = CupertinoIcons.square_arrow_up;
  static const IconData devices = CupertinoIcons.device_laptop;
  static const IconData files = CupertinoIcons.folder;
  static const IconData history = CupertinoIcons.time;
  static const IconData settings = CupertinoIcons.settings;
}

// Ripple effect widget for enhanced touch feedback
class RippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? rippleColor;
  final Duration duration;

  const RippleEffect({
    Key? key,
    required this.child,
    this.onTap,
    this.rippleColor,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      setState(() {
        _tapPosition = null;
      });
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          widget.child,
          if (_tapPosition != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RipplePainter(
                      center: _tapPosition!,
                      radius: _animation.value * 100,
                      color: widget.rippleColor ?? iOS18Colors.systemBlue.withOpacity(0.2),
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

class RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  RipplePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}