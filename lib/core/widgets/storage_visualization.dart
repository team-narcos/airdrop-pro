import 'package:flutter/material.dart';
import 'dart:math' as math;

class StorageVisualization extends StatefulWidget {
  final double usedGB;
  final double totalGB;
  final double size;
  
  const StorageVisualization({
    Key? key,
    required this.usedGB,
    required this.totalGB,
    this.size = 140,
  }) : super(key: key);

  @override
  State<StorageVisualization> createState() => _StorageVisualizationState();
}

class _StorageVisualizationState extends State<StorageVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    final percentage = (widget.usedGB / widget.totalGB).clamp(0.0, 1.0);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _StorageCirclePainter(
                  progress: _animation.value * percentage,
                  strokeWidth: 12,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(widget.usedGB * _animation.value).toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'GB',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of ${widget.totalGB.toStringAsFixed(0)} GB',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StorageCirclePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _StorageCirclePainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc with gradient
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
        colors: _getGradientColors(progress),
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
      
      // Glowing dot at the end
      final endAngle = -math.pi / 2 + (2 * math.pi * progress);
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);
      
      final glowPaint = Paint()
        ..color = _getGradientColors(progress).last.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2 + 2, glowPaint);
      
      final dotPaint = Paint()
        ..color = _getGradientColors(progress).last
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2, dotPaint);
    }
  }

  List<Color> _getGradientColors(double progress) {
    if (progress < 0.5) {
      return [const Color(0xFF32D74B), const Color(0xFF00D4FF)];
    } else if (progress < 0.8) {
      return [const Color(0xFF00D4FF), const Color(0xFFFFD60A)];
    } else {
      return [const Color(0xFFFFD60A), const Color(0xFFFF453A)];
    }
  }

  @override
  bool shouldRepaint(_StorageCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
