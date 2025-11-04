import 'package:flutter/material.dart';
import 'dart:math' as math;

class SuccessRateChart extends StatefulWidget {
  final double successRate; // 0.0 to 1.0
  final double size;
  
  const SuccessRateChart({
    Key? key,
    required this.successRate,
    this.size = 100,
  }) : super(key: key);

  @override
  State<SuccessRateChart> createState() => _SuccessRateChartState();
}

class _SuccessRateChartState extends State<SuccessRateChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _SuccessRatePainter(
              progress: _animation.value * widget.successRate,
              strokeWidth: 10,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_animation.value * widget.successRate * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Success',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuccessRatePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _SuccessRatePainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc
    if (progress > 0) {
      final Color startColor;
      final Color endColor;
      
      if (progress < 0.5) {
        startColor = const Color(0xFFFF453A);
        endColor = const Color(0xFFFFD60A);
      } else if (progress < 0.8) {
        startColor = const Color(0xFFFFD60A);
        endColor = const Color(0xFF32D74B);
      } else {
        startColor = const Color(0xFF32D74B);
        endColor = const Color(0xFF00D4FF);
      }
      
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
        colors: [startColor, endColor],
        transform: const GradientRotation(-math.pi / 2),
      );
      
      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
      
      // End dot with glow
      final endAngle = -math.pi / 2 + (2 * math.pi * progress);
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);
      
      final glowPaint = Paint()
        ..color = endColor.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2 + 3, glowPaint);
      
      final dotPaint = Paint()
        ..color = endColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SuccessRatePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
