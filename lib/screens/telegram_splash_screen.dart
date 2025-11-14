import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Enterprise-level splash screen with stunning animations
class TelegramSplashScreen extends StatefulWidget {
  const TelegramSplashScreen({Key? key}) : super(key: key);

  @override
  State<TelegramSplashScreen> createState() => _TelegramSplashScreenState();
}

class _TelegramSplashScreenState extends State<TelegramSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _circleAnimation;

  @override
  void initState() {
    super.initState();

    // Main logo animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Particle system animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Rotation animation for accent
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Professional scale animation with smooth curves
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,  // Professional overshoot
      ),
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Circular reveal animation
    _circleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
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
    _particleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [
                    const Color(0xFF0F0F1E),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    const Color(0xFFE3F2FF),
                    const Color(0xFFF0E7FF),
                    const Color(0xFFFFE8F5),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particle system
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    animation: _particleController.value,
                    isDark: isDark,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Rotating accent rings
            Center(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF007AFF).withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main logo with animations
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular progress ring
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: AnimatedBuilder(
                          animation: _circleAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: CircularRingPainter(
                                progress: _circleAnimation.value,
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                      ),

                      // Logo container with glass effect
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF007AFF),
                              Color(0xFF0051D5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withOpacity(0.6),
                              blurRadius: 40,
                              spreadRadius: 0,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: const Color(0xFF007AFF).withOpacity(0.3),
                              blurRadius: 80,
                              spreadRadius: 10,
                              offset: const Offset(0, 40),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Glass shimmer effect
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // WiFi icon
                            Center(
                              child: Icon(
                                Icons.wifi_tethering_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // App name with fade-in
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'AirDrop Pro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enterprise File Sharing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark 
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enterprise-level particle system for background animation
class ParticlePainter extends CustomPainter {
  final double animation;
  final bool isDark;
  final List<Particle> particles = [];

  ParticlePainter({required this.animation, required this.isDark}) {
    // Generate particles
    final random = math.Random(42);  // Fixed seed for consistency
    for (int i = 0; i < 30; i++) {
      particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.5 + 0.2,
        opacity: random.nextDouble() * 0.4 + 0.1,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final y = ((particle.y + animation * particle.speed) % 1.0) * size.height;
      final x = particle.x * size.width;

      final paint = Paint()
        ..color = (isDark ? Colors.blue : Colors.purple)
            .withOpacity(particle.opacity * (1 - (y / size.height)))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size);

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

/// Circular progress ring painter
class CircularRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  CircularRingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.blue).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring with gradient effect
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF007AFF),
          const Color(0xFF5856D6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final progressPath = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,  // Start from top
        2 * math.pi * progress,  // Sweep angle
      );

    canvas.drawPath(progressPath, progressPaint);

    // Glowing endpoint
    if (progress > 0) {
      final endAngle = -math.pi / 2 + (2 * math.pi * progress);
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);

      final glowPaint = Paint()
        ..color = const Color(0xFF007AFF).withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(endX, endY), 6, glowPaint);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endX, endY), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CircularRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
