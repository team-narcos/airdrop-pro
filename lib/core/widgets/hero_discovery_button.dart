import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HeroDiscoveryButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isActive;

  const HeroDiscoveryButton({
    Key? key,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  State<HeroDiscoveryButton> createState() => _HeroDiscoveryButtonState();
}

class _HeroDiscoveryButtonState extends State<HeroDiscoveryButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late List<AnimationController> _ringControllers;
  late List<Animation<double>> _ringAnimations;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Rotating gradient animation (10 seconds)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Scale animation for touch interaction
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    // Create 6 pulsing ring animations with staggered starts
    _ringControllers = List.generate(
      6,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1800),
        vsync: this,
      )..repeat(),
    );

    // Start each ring with a delay
    for (int i = 0; i < _ringControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _ringControllers[i].forward();
        }
      });
    }

    _ringAnimations = _ringControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    for (var controller in _ringControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 340,
          height: 340,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing rings (only show when active)
              if (widget.isActive)
                ...List.generate(6, (index) {
                  return AnimatedBuilder(
                    animation: _ringAnimations[index],
                    builder: (context, child) {
                      final progress = _ringAnimations[index].value;
                      final startRadius = 150.0;
                      final endRadius = 240.0;
                      final currentRadius = startRadius + (endRadius - startRadius) * progress;
                      final opacity = (1.0 - progress) * 0.4;

                      return Container(
                        width: currentRadius,
                        height: currentRadius,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(opacity),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  );
                }),

              // Main rotating gradient circle
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: const [
                            Color(0xFF0093E9),
                            Color(0xFF80D0C7),
                            Color(0xFFa8edea),
                            Color(0xFFfed6e3),
                            Color(0xFF0093E9),
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0093E9).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: const Color(0xFF80D0C7).withOpacity(0.2),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Frosted glass layer
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.ios_share,
                      size: 36,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Discover Devices',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
