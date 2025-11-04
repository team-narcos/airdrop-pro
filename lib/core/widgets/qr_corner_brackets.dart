import 'package:flutter/material.dart';
import 'dart:math' as math;

class QRCornerBrackets extends StatefulWidget {
  final double size;
  final Color color;
  
  const QRCornerBrackets({
    Key? key,
    this.size = 300,
    this.color = const Color(0xFF007AFF),
  }) : super(key: key);

  @override
  State<QRCornerBrackets> createState() => _QRCornerBracketsState();
}

class _QRCornerBracketsState extends State<QRCornerBrackets>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BracketsPainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _BracketsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BracketsPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 + 0.4 * progress)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bracketSize = 30.0;
    final offset = 10 * (1 - progress);

    // Top-left
    canvas.drawLine(
      Offset(offset, bracketSize + offset),
      Offset(offset, offset),
      paint,
    );
    canvas.drawLine(
      Offset(offset, offset),
      Offset(bracketSize + offset, offset),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - bracketSize - offset, offset),
      Offset(size.width - offset, offset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - offset, offset),
      Offset(size.width - offset, bracketSize + offset),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(offset, size.height - bracketSize - offset),
      Offset(offset, size.height - offset),
      paint,
    );
    canvas.drawLine(
      Offset(offset, size.height - offset),
      Offset(bracketSize + offset, size.height - offset),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - bracketSize - offset, size.height - offset),
      Offset(size.width - offset, size.height - offset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset, size.height - bracketSize - offset),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BracketsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
