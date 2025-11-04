import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Telegram-style splash screen - exact replica of Telegram opening
class TelegramSplashScreen extends StatefulWidget {
  const TelegramSplashScreen({Key? key}) : super(key: key);

  @override
  State<TelegramSplashScreen> createState() => _TelegramSplashScreenState();
}

class _TelegramSplashScreenState extends State<TelegramSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Telegram's signature elastic bounce - zooms in with overshoot then settles
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    // Small delay before starting animation
    await Future.delayed(const Duration(milliseconds: 300));
    _controller.forward();

    // Navigate to home after full animation (2 seconds animation + 1 second display)
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1621) : const Color(0xFFFFFFFF),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              // Telegram's exact blue color
              color: const Color(0xFF0088CC),
              borderRadius: BorderRadius.circular(38),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0088CC).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(90, 90),
                painter: TelegramPlanePainter(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for Telegram's paper plane icon
class TelegramPlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Telegram's iconic paper plane shape
    // Main triangle body
    path.moveTo(w * 0.15, h * 0.5);
    path.lineTo(w * 0.85, h * 0.2);
    path.lineTo(w * 0.5, h * 0.48);
    path.lineTo(w * 0.85, h * 0.8);
    path.lineTo(w * 0.15, h * 0.5);
    path.close();

    canvas.drawPath(path, paint);

    // Tail/wing detail
    final path2 = Path();
    path2.moveTo(w * 0.5, h * 0.48);
    path2.lineTo(w * 0.42, h * 0.72);
    path2.lineTo(w * 0.36, h * 0.58);
    path2.lineTo(w * 0.5, h * 0.48);
    path2.close();

    canvas.drawPath(path2, paint);

    // Add shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final shadowPath = Path();
    shadowPath.moveTo(w * 0.5, h * 0.48);
    shadowPath.lineTo(w * 0.85, h * 0.8);
    shadowPath.lineTo(w * 0.42, h * 0.72);
    shadowPath.close();

    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
