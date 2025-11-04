import 'package:flutter/widgets.dart';

/// Complete SF Pro typography system matching iOS 18 specifications
class SFProTypography {
  // Font families
  static const String sfProDisplay = 'SF Pro Display';
  static const String sfProText = 'SF Pro Text';
  
  // Fallback fonts for web/cross-platform
  static const List<String> fontFallbacks = [
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];
  
  /// Navigation Bar Title - 34pt Bold
  static const TextStyle navigationTitle = TextStyle(
    fontFamily: sfProDisplay,
    fontFamilyFallback: fontFallbacks,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );
  
  /// Large Title - 28pt Bold
  static const TextStyle largeTitle = TextStyle(
    fontFamily: sfProDisplay,
    fontFamilyFallback: fontFallbacks,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );
  
  /// Title 1 - 28pt Regular
  static const TextStyle title1 = TextStyle(
    fontFamily: sfProDisplay,
    fontFamilyFallback: fontFallbacks,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    height: 1.2,
  );
  
  /// Title 2 - 22pt Regular
  static const TextStyle title2 = TextStyle(
    fontFamily: sfProDisplay,
    fontFamilyFallback: fontFallbacks,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.25,
  );
  
  /// Title 3 - 20pt Regular
  static const TextStyle title3 = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.25,
  );
  
  /// Headline - 17pt Semibold
  static const TextStyle headline = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.3,
  );
  
  /// Body - 17pt Regular
  static const TextStyle body = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.4,
    height: 1.4,
  );
  
  /// Body Emphasized - 17pt Semibold
  static const TextStyle bodyEmphasized = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.4,
  );
  
  /// Callout - 16pt Regular
  static const TextStyle callout = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    height: 1.35,
  );
  
  /// Subheadline - 15pt Regular
  static const TextStyle subheadline = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.35,
  );
  
  /// Footnote - 13pt Regular
  static const TextStyle footnote = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
  );
  
  /// Caption 1 - 12pt Regular
  static const TextStyle caption1 = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.35,
  );
  
  /// Caption 2 - 11pt Regular
  static const TextStyle caption2 = TextStyle(
    fontFamily: sfProText,
    fontFamilyFallback: fontFallbacks,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.35,
  );
}

/// iOS 18 spacing system based on 8-point grid
class iOS18Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  // Corner radius values
  static const double radiusXS = 6;
  static const double radiusSM = 10;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 28;
}
