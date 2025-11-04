import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScanningAnimation extends StatefulWidget {
  final double size;
  final Color color;
  
  const ScanningAnimation({
    Key? key,
    this.size = 200,
    this.color = const Color(0xFF007AFF),
  }) : super(key: key);

  @override
  State<ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw concentric circles
    final circlePaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, circlePaint);
    }

    // Draw rotating radar beam
    final beamPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.6),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final angle = progress * 2 * math.pi;
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + radius * math.cos(angle - 0.5),
        center.dy + radius * math.sin(angle - 0.5),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        angle - 0.5,
        1.0,
        false,
      )
      ..close();

    canvas.drawPath(path, beamPaint);

    // Draw center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);

    // Draw pulsing ring
    final pulseRadius = radius * (0.5 + 0.5 * math.sin(progress * 4 * math.pi));
    final pulsePaint = Paint()
      ..color = color.withOpacity(0.3 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
