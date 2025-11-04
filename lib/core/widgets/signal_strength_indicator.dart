import 'package:flutter/material.dart';

class SignalStrengthIndicator extends StatelessWidget {
  final int strength; // 1-5
  final Color color;
  final double size;

  const SignalStrengthIndicator({
    Key? key,
    required this.strength,
    this.color = const Color(0xFF007AFF),
    this.size = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          final barHeight = (index + 1) * (size / 4);
          final isActive = index < strength;
          
          return Container(
            width: size / 6,
            height: barHeight,
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }
}
