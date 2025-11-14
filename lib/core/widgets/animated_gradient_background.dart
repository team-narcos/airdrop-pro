import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS 26 Premium animated background with smooth transitions
class AnimatedGradientBackground extends StatelessWidget {
  final Widget child;
  
  const AnimatedGradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Detect current brightness
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),  // iOS 26: Smooth transition
      curve: Curves.easeInOut,  // Apple's signature curve
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
  
  // iOS 26 Light - Apple's refined gradient (visible but sophisticated)
  static const List<Color> _lightGradient = [
    Color(0xFFEEF2FF),  // Soft indigo-white
    Color(0xFFF5F3FF),  // Gentle purple-white
    Color(0xFFFFF1F2),  // Subtle rose-white
    Color(0xFFEFF6FF),  // Soft blue-white
  ];
  
  // iOS 26 Dark - Apple's premium deep gradient
  static const List<Color> _darkGradient = [
    Color(0xFF000000),  // Pure black (Apple's signature)
    Color(0xFF0A0D1E),  // Deep midnight blue
    Color(0xFF0F0A1C),  // Rich purple-black
    Color(0xFF0D0F1A),  // Deep blue-black
  ];
}
