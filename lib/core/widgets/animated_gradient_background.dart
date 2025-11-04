import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Premium iOS 18 static background with proper dark mode support
class AnimatedGradientBackground extends StatelessWidget {
  final Widget child;
  
  const AnimatedGradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Detect current brightness
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? _darkGradient : _lightGradient,
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
  
  // Premium light mode gradient - subtle, clean iOS 18 style
  static const List<Color> _lightGradient = [
    Color(0xFFF8F9FA),  // Soft white
    Color(0xFFF5F7FA),  // Light blue-gray
    Color(0xFFF0F3F8),  // Subtle blue tint
    Color(0xFFEFF2F7),  // Delicate gradient end
  ];
  
  // Premium dark mode gradient - deep, rich blacks with subtle blue tint
  static const List<Color> _darkGradient = [
    Color(0xFF000000),  // Pure black
    Color(0xFF0A0A0F),  // Deep black with subtle blue
    Color(0xFF0F0F14),  // Slightly lighter
    Color(0xFF1A1A1F),  // Subtle transition
  ];
}
