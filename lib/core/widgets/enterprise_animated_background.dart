import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enterprise-level animated background with stunning particle effects
class EnterpriseAnimatedBackground extends StatefulWidget {
  final Widget child;
  
  const EnterpriseAnimatedBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<EnterpriseAnimatedBackground> createState() => _EnterpriseAnimatedBackgroundState();
}

class _EnterpriseAnimatedBackgroundState extends State<EnterpriseAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    
    // Particle animation (slow, continuous)
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Gradient shift animation (smooth color transitions)
    _gradientController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _gradientAnimation = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gradientAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? _getDarkGradient(_gradientAnimation.value)
                          : _getLightGradient(_gradientAnimation.value),
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: FloatingParticlesPainter(
                    animation: _particleController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // Mesh gradient overlay for depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    (isDark ? Colors.purple : Colors.blue).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          widget.child,
        ],
      ),
    );
  }

  List<Color> _getLightGradient(double animation) {
    // Smooth color transitions for light mode
    final t = animation;
    return [
      Color.lerp(const Color(0xFFEEF2FF), const Color(0xFFF5F3FF), t)!,
      Color.lerp(const Color(0xFFF5F3FF), const Color(0xFFFFF1F2), t)!,
      Color.lerp(const Color(0xFFFFF1F2), const Color(0xFFEFF6FF), t)!,
      Color.lerp(const Color(0xFFEFF6FF), const Color(0xFFEEF2FF), t)!,
    ];
  }

  List<Color> _getDarkGradient(double animation) {
    // Smooth color transitions for dark mode
    final t = animation;
    return [
      Color.lerp(const Color(0xFF000000), const Color(0xFF0A0D1E), t)!,
      Color.lerp(const Color(0xFF0A0D1E), const Color(0xFF0F0A1C), t)!,
      Color.lerp(const Color(0xFF0F0A1C), const Color(0xFF0D0F1A), t)!,
      Color.lerp(const Color(0xFF0D0F1A), const Color(0xFF000000), t)!,
    ];
  }
}

/// Floating particles painter for ambient animation
class FloatingParticlesPainter extends CustomPainter {
  final double animation;
  final bool isDark;
  static final List<FloatingParticle> _particles = _generateParticles();

  FloatingParticlesPainter({required this.animation, required this.isDark});

  static List<FloatingParticle> _generateParticles() {
    final random = math.Random(123);
    return List.generate(40, (index) {
      return FloatingParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1.5,
        speedX: (random.nextDouble() - 0.5) * 0.1,
        speedY: random.nextDouble() * 0.3 + 0.1,
        opacity: random.nextDouble() * 0.3 + 0.1,
        hue: random.nextDouble() * 60 + (index % 3 * 120),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in _particles) {
      // Calculate animated position with wrapping
      final x = ((particle.x + animation * particle.speedX) % 1.0) * size.width;
      final y = ((particle.y + animation * particle.speedY) % 1.0) * size.height;

      // Fade effect based on position
      final fadeY = 1.0 - (y / size.height) * 0.5;
      final opacity = particle.opacity * fadeY;

      // Color based on particle hue
      final color = HSVColor.fromAHSV(
        opacity,
        particle.hue,
        isDark ? 0.7 : 0.5,
        isDark ? 0.8 : 0.9,
      ).toColor();

      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2);

      canvas.drawCircle(Offset(x, y), particle.size, paint);

      // Draw smaller core for depth
      final corePaint = Paint()
        ..color = color.withOpacity(opacity * 1.5);
      canvas.drawCircle(Offset(x, y), particle.size * 0.5, corePaint);
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) => true;
}

class FloatingParticle {
  final double x;
  final double y;
  final double size;
  final double speedX;
  final double speedY;
  final double opacity;
  final double hue;

  FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.hue,
  });
}
