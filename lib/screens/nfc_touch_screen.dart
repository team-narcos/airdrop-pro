import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';

class NfcTouchScreen extends StatelessWidget {
  const NfcTouchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return CupertinoPageScaffold(
      backgroundColor: isDark 
          ? iOS18Colors.backgroundPrimaryDark 
          : iOS18Colors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDark 
            ? iOS18Colors.backgroundPrimaryDark 
            : iOS18Colors.backgroundPrimary).withOpacity(0.9),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? iOS18Colors.systemBlueDark : iOS18Colors.systemBlue,
          ),
        ),
        middle: Text(
          'NFC Touch to Share',
          style: TextStyle(
            color: isDark ? iOS18Colors.textPrimaryDark : iOS18Colors.getTextPrimary(context),
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(iOS18Spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // NFC Icon with animation
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: iOS18Colors.airDropGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iOS18Colors.systemBlue.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.antenna_radiowaves_left_right,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: iOS18Spacing.xxxl),
                
                GlassmorphicCard(
                  padding: EdgeInsets.all(iOS18Spacing.xl),
                  child: Column(
                    children: [
                      Text(
                        'NFC Feature',
                        style: iOS18Typography.title2.copyWith(
                          color: isDark 
                              ? iOS18Colors.textPrimaryDark 
                              : iOS18Colors.getTextPrimary(context),
                        ),
                      ),
                      SizedBox(height: iOS18Spacing.md),
                      Text(
                        'NFC (Near Field Communication) allows you to share files by simply tapping devices together.',
                        style: iOS18Typography.callout.copyWith(
                          color: isDark 
                              ? iOS18Colors.textSecondaryDark 
                              : iOS18Colors.getTextSecondary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: iOS18Spacing.lg),
                      Container(
                        padding: EdgeInsets.all(iOS18Spacing.md),
                        decoration: BoxDecoration(
                          color: (isDark 
                              ? iOS18Colors.systemOrangeDark 
                              : iOS18Colors.systemOrange).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle_fill,
                              color: isDark 
                                  ? iOS18Colors.systemOrangeDark 
                                  : iOS18Colors.systemOrange,
                            ),
                            SizedBox(width: iOS18Spacing.sm),
                            Expanded(
                              child: Text(
                                'NFC is not available on web browsers. Please use the mobile app on Android or iOS.',
                                style: iOS18Typography.caption1.copyWith(
                                  color: isDark 
                                      ? iOS18Colors.systemOrangeDark 
                                      : iOS18Colors.systemOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: iOS18Spacing.xl),
                
                Text(
                  'To use NFC:\n\n1. Build the mobile app\n2. Enable NFC on both devices\n3. Tap devices back-to-back\n4. Accept the transfer',
                  style: iOS18Typography.footnote.copyWith(
                    color: isDark 
                        ? iOS18Colors.textSecondaryDark 
                        : iOS18Colors.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
