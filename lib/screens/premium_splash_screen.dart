import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../core/design_system/ios18_theme.dart';

class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({Key? key}) : super(key: key);

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _textController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowPulse;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(begin: -15 * pi / 180, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Glow pulsing animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 20.0, end: 60.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Particle system
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Start animations sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation immediately
    _logoController.forward();

    // Trigger haptic at bounce peak
    await Future.delayed(const Duration(milliseconds: 400));
    HapticFeedback.mediumImpact();

    // Start text animations
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Navigate to home after splash
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F2F7), Color(0xFFFFFFFF)],
          ),
        ),
        child: Stack(
          children: [
            // Particle system background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with glow
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _logoController,
                      _glowController,
                    ]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF007AFF),
                                    Color(0xFF5856D6),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withOpacity(0.6),
                                    blurRadius: _glowPulse.value,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF5856D6).withOpacity(0.4),
                                    blurRadius: _glowPulse.value * 0.75,
                                    spreadRadius: 15,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: _glowPulse.value * 0.5,
                                    spreadRadius: 30,
                                  ),
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: _glowPulse.value * 0.3,
                                    spreadRadius: 50,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.ios_share,
                                  size: 90,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // App name with animation
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Text(
                        'AirDrop Pro',
                        style: iOS18Typography.largeTitle.copyWith(
                          color: iOS18Colors.getTextPrimary(context),
                          fontSize: 32,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Text(
                      'Universal File Sharing',
                      style: iOS18Typography.body.copyWith(
                        color: iOS18Colors.getTextSecondary(context),
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Particle system painter
class ParticlePainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;

  ParticlePainter(this.animationValue) : particles = _generateParticles();

  static List<Particle> _generateParticles() {
    final random = Random(42); // Fixed seed for consistent particles
    return List.generate(100, (index) {
      return Particle(
        x: random.nextDouble(),
        startY: 1.0 + random.nextDouble() * 0.2,
        speed: 0.3 + random.nextDouble() * 0.7,
        size: 2.0 + random.nextDouble() * 2.0,
        delay: random.nextDouble() * 0.5,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF007AFF).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final adjustedAnimation = (animationValue + particle.delay) % 1.0;
      final y = particle.startY - (adjustedAnimation * particle.speed * 1.2);

      if (y >= -0.1 && y <= 1.1) {
        final opacity = (1.0 - adjustedAnimation).clamp(0.0, 1.0);
        paint.color = const Color(0xFF007AFF).withOpacity(opacity * 0.15);

        canvas.drawCircle(
          Offset(
            particle.x * size.width,
            y * size.height,
          ),
          particle.size,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double delay;

  Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.delay,
  });
}
