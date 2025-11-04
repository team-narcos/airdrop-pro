import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../core/design_system/ios18_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowScale;
  late Animation<double> _fadeOpacity;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Fade controller for transition
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Logo scale animation
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Logo opacity animation
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    // Glow scale animation
    _glowScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Fade out animation
    _fadeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    
    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();
    
    // Start glow pulse
    _glowController.repeat(reverse: true);
    
    // Wait a bit
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Fade out
    await _fadeController.forward();
    
    // Navigate to home
    if (mounted) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;
    
    return CupertinoPageScaffold(
      backgroundColor: isDark 
          ? iOS18Colors.backgroundPrimaryDark 
          : iOS18Colors.backgroundPrimary,
      child: FadeTransition(
        opacity: _fadeOpacity,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      iOS18Colors.backgroundPrimaryDark,
                      iOS18Colors.backgroundSecondaryDark,
                      iOS18Colors.backgroundPrimaryDark,
                    ]
                  : [
                      iOS18Colors.backgroundPrimary,
                      iOS18Colors.backgroundSecondary,
                      iOS18Colors.backgroundPrimary,
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoController, _glowController]),
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Transform.scale(
                      scale: _glowScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value * 0.3,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: iOS18Colors.airDropGradient,
                            boxShadow: [
                              BoxShadow(
                                color: iOS18Colors.systemBlue.withOpacity(0.5),
                                blurRadius: 80,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Main logo
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: iOS18Colors.airDropGradient,
                            boxShadow: [
                              BoxShadow(
                                color: iOS18Colors.systemBlue.withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: iOS18Colors.systemPurple.withOpacity(0.3),
                                blurRadius: 60,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Radiating rings
                              ...List.generate(3, (index) {
                                return Transform.scale(
                                  scale: 0.4 + (index * 0.25),
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3 - (index * 0.1)),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              
                              // Arrow icon
                              const Icon(
                                CupertinoIcons.arrow_up_circle_fill,
                                size: 60,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // App name
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.25,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: Column(
                          children: [
                            Text(
                              'AirDrop',
                              style: iOS18Typography.largeTitle.copyWith(
                                color: isDark 
                                    ? iOS18Colors.textPrimaryDark 
                                    : iOS18Colors.getTextPrimary(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 42,
                                letterSpacing: -1.5,
                              ),
                            ),
                            SizedBox(height: iOS18Spacing.sm),
                            Text(
                              'Share Instantly',
                              style: iOS18Typography.body.copyWith(
                                color: isDark 
                                    ? iOS18Colors.textSecondaryDark 
                                    : iOS18Colors.getTextSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
