import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeSelector extends StatelessWidget {
  final ThemeMode selectedMode;
  final Function(ThemeMode) onThemeChanged;
  
  const ThemeSelector({
    Key? key,
    required this.selectedMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildThemeCard(
              'Light',
              CupertinoIcons.sun_max_fill,
              ThemeMode.light,
              const LinearGradient(
                colors: [Color(0xFFFFD60A), Color(0xFFFF9500)],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildThemeCard(
              'Auto',
              CupertinoIcons.circle_lefthalf_fill,
              ThemeMode.system,
              const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildThemeCard(
              'Dark',
              CupertinoIcons.moon_fill,
              ThemeMode.dark,
              const LinearGradient(
                colors: [Color(0xFF5856D6), Color(0xFF1C1C1E)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    String label,
    IconData icon,
    ThemeMode mode,
    LinearGradient gradient,
  ) {
    final isSelected = selectedMode == mode;
    
    return GestureDetector(
      onTap: () => onThemeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? gradient.colors.first.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                icon,
                size: 36,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
