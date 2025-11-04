import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/ios18_theme.dart';

class PremiumGradientCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final bool isSelected;
  final double borderRadius;

  const PremiumGradientCard({
    Key? key,
    required this.child,
    required this.gradientColors,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.isSelected = false,
    this.borderRadius = 24,
  }) : super(key: key);

  @override
  State<PremiumGradientCard> createState() => _PremiumGradientCardState();
}

class _PremiumGradientCardState extends State<PremiumGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      _scaleController.forward().then((_) => _scaleController.reverse());
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors.first.withOpacity(0.3),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.isSelected ? 35 : 30,
                      sigmaY: widget.isSelected ? 35 : 30,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.isSelected
                              ? widget.gradientColors
                              : widget.gradientColors
                                  .map((c) => c.withOpacity(0.15))
                                  .toList(),
                        ),
                        border: Border.all(
                          color: widget.isSelected
                              ? widget.gradientColors.first.withOpacity(0.5)
                              : (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.3)),
                          width: widget.isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                      ),
                      padding: widget.padding ??
                          EdgeInsets.all(iOS18Spacing.lg),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
