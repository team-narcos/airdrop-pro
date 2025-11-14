import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design_system/ios18_theme.dart';
import '../platform/platform_adapter.dart';

class GlassmorphicHeader extends StatelessWidget {
  final String deviceName;
  final VoidCallback? onProfileTap;

  const GlassmorphicHeader({
    Key? key,
    this.deviceName = 'AirDrop Pro',
    this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),  // iOS 26: Premium blur
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),  // Smooth transition
          curve: Curves.easeInOut,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.70),  // 70% - Balanced glass
                Colors.white.withOpacity(0.60),  // 60% - Smooth gradient
                Colors.white.withOpacity(0.50),  // 50% - Refined fade
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.4),  // 40% - Apple's refined edge
                width: 1.5,  // Apple's standard thickness
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),  // Soft shadow
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // App logo - more visible in dark mode
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF007AFF),  // iOS Blue
                          Color(0xFF0051D5),  // Deeper blue
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66007AFF),  // 40% blue glow
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Color(0x33007AFF),  // 20% subtle glow
                          blurRadius: 40,
                          spreadRadius: 0,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_rounded,
                      size: 26,
                      color: Colors.white,  // Icon stays white on blue background
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // App name
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: iOS18Typography.title2.copyWith(
                      color: Colors.black,  // iOS 26: Dark text for light background
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(deviceName),
                  ),
                  
                  const Spacer(),
                  
                  // Feature badges
                  _buildFeatureBadge(CupertinoIcons.lock_shield_fill, 'AES-256'),
                  const SizedBox(width: 8),
                  _buildFeatureBadge(CupertinoIcons.arrow_2_squarepath, '70%'),
                  const SizedBox(width: 8),
                  _buildFeatureBadge(CupertinoIcons.lightbulb_fill, 'AI'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.65),  // 65% - Balanced badge
            Colors.white.withOpacity(0.50),  // 50% - Refined depth
          ],
        ),
        borderRadius: BorderRadius.circular(10),  // iOS 26: Slightly smaller radius
        border: Border.all(
          color: Colors.white.withOpacity(0.40),  // 40% - Refined edge
          width: 1.5,  // Apple's standard
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.black.withOpacity(0.7),  // iOS 26: Dark icon
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),  // iOS 26: Dark text
            ),
          ),
        ],
      ),
    );
  }
}
