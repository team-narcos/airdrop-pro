import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class iOS18Colors {
  // Primary AirDrop gradient colors
  static const blueStart = Color(0xFF007AFF);
  static const blueMiddle = Color(0xFF5856D6);
  static const purpleMiddle = Color(0xFFAF52DE);
  static const pinkEnd = Color(0xFFFF2D92);

  // System colors light mode
  static const systemBlue = Color(0xFF007AFF);
  static const systemPurple = Color(0xFF5856D6);
  static const systemPink = Color(0xFFFF2D92);
  static const systemGreen = Color(0xFF28CD41);
  static const systemOrange = Color(0xFFFF9500);
  static const systemRed = Color(0xFFFF3B30);
  static const systemYellow = Color(0xFFFFCC00);
  static const systemGray = Color(0xFF8E8E93);

  // System colors dark mode
  static const systemBlueDark = Color(0xFF0A84FF);
  static const systemPurpleDark = Color(0xFF5E5CE6);
  static const systemPinkDark = Color(0xFFFF2D92);
  static const systemGreenDark = Color(0xFF30D158);
  static const systemOrangeDark = Color(0xFFFF9F0A);
  static const systemRedDark = Color(0xFFFF453A);
  static const systemYellowDark = Color(0xFFFFD60A);

  // Background colors - Light mode (subtle, clean)
  static const backgroundPrimary = Color(0xFFF8F9FA);
  static const backgroundSecondary = Color(0xFFF2F2F7);
  static const backgroundTertiary = Color(0xFFFFFFFF);
  
  // Background colors - Dark mode (rich, deep)
  static const backgroundPrimaryDark = Color(0xFF000000);
  static const backgroundSecondaryDark = Color(0xFF1C1C1E);
  static const backgroundTertiaryDark = Color(0xFF2C2C2E);

  // Glass effect colors - Enhanced for premium look
  static const glassLight = Color(0x26FFFFFF);  // More visible in light mode
  static const glassBorder = Color(0x40FFFFFF);  // Stronger border
  static const glassShadow = Color(0x12000000);  // Softer shadow
  
  static const glassLightDark = Color(0x1FFFFFFF);  // Slightly more visible
  static const glassBorderDark = Color(0x30FFFFFF);  // Better contrast
  static const glassShadowDark = Color(0x50000000);  // Deeper shadows

  // Text colors - Light mode
  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFFC7C7CC);
  
  // Text colors - Dark mode (much brighter for better visibility)
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFE5E5E7);  // Much brighter!
  static const textTertiaryDark = Color(0xFFA8A8A8);   // Much brighter!

  // Gradient definitions
  static const LinearGradient airDropGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueStart, blueMiddle, purpleMiddle, pinkEnd],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient deviceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [systemBlue, systemPurple],
    stops: [0.0, 1.0],
  );

  static const LinearGradient fileGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [systemOrange, systemPink],
    stops: [0.0, 1.0],
  );

  static const LinearGradient historyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [systemGreen, systemBlue],
    stops: [0.0, 1.0],
  );

  static const LinearGradient settingsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [systemPurple, systemPink],
    stops: [0.0, 1.0],
  );
  
  // Theme-aware color getters
  static Color getTextPrimary(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    return brightness == Brightness.dark ? textPrimaryDark : textPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    return brightness == Brightness.dark ? textSecondaryDark : textSecondary;
  }
  
  static Color getTextTertiary(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    return brightness == Brightness.dark ? textTertiaryDark : textTertiary;
  }
  
  static Color getBackgroundPrimary(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    return brightness == Brightness.dark ? backgroundPrimaryDark : backgroundPrimary;
  }
  
  static Color getBackgroundSecondary(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ?? Brightness.light;
    return brightness == Brightness.dark ? backgroundSecondaryDark : backgroundSecondary;
  }
}

class iOS18Typography {
  static const String fontFamily = 'SF Pro Display';
  static const List<String> fontFamilyFallback = [
    'SF Pro Display',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif'
  ];

  // Large titles
  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  // Titles
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle title3 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  // Headlines
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.4,
  );

  static const TextStyle bodyEmphasized = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  // Callout
  static const TextStyle callout = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
  );

  // Subheadline
  static const TextStyle subheadline = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );

  // Footnote
  static const TextStyle footnote = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );

  // Caption
  static const TextStyle caption1 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle caption2 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
}

class iOS18Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Border radius
  static const double radiusXS = 6;
  static const double radiusSM = 12;
  static const double radiusMD = 20;
  static const double radiusLG = 30;
  static const double radiusXL = 40;
}

class iOS18Shadows {
  // Premium glassmorphism shadows - Light mode
  static const List<BoxShadow> glassShadows = [
    BoxShadow(
      color: Color(0x14000000),  // Softer primary shadow
      blurRadius: 30,
      spreadRadius: 0,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x08000000),  // Subtle secondary shadow
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];

  // Premium glassmorphism shadows - Dark mode
  static const List<BoxShadow> glassShadowsDark = [
    BoxShadow(
      color: Color(0x60000000),  // Deeper shadows for depth
      blurRadius: 40,
      spreadRadius: 0,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x30000000),  // Layered shadow
      blurRadius: 16,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];

  // Premium card shadows
  static const List<BoxShadow> cardShadows = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 8,
      spreadRadius: -2,
      offset: Offset(0, 2),
    ),
  ];

  // Premium button shadows
  static const List<BoxShadow> buttonShadows = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];
  
  // Premium card shadows for dark mode
  static const List<BoxShadow> cardShadowsDark = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 30,
      spreadRadius: 0,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x20000000),
      blurRadius: 12,
      spreadRadius: -4,
      offset: Offset(0, 4),
    ),
  ];
}

class iOS18Theme {
  static CupertinoThemeData lightTheme = const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: iOS18Colors.systemBlue,
    primaryContrastingColor: iOS18Colors.backgroundPrimary,
    scaffoldBackgroundColor: iOS18Colors.backgroundPrimary,
    textTheme: CupertinoTextThemeData(
      primaryColor: iOS18Colors.textPrimary,
      textStyle: iOS18Typography.body,
    ),
  );

  static CupertinoThemeData darkTheme = const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: iOS18Colors.systemBlueDark,
    primaryContrastingColor: iOS18Colors.backgroundPrimaryDark,
    scaffoldBackgroundColor: iOS18Colors.backgroundPrimaryDark,
    textTheme: CupertinoTextThemeData(
      primaryColor: iOS18Colors.textPrimaryDark,
      textStyle: iOS18Typography.body,
    ),
  );
}