import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';

class RoomCreateScreen extends StatefulWidget {
  const RoomCreateScreen({Key? key}) : super(key: key);

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  late String _roomCode;
  int _maxParticipants = 5;
  int _durationMinutes = 30;
  bool _requirePassword = false;

  @override
  void initState() {
    super.initState();
    _generateRoomCode();
  }

  void _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    setState(() {
      _roomCode = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    });
  }

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
          'Create Room',
          style: TextStyle(
            color: isDark ? iOS18Colors.textPrimaryDark : iOS18Colors.getTextPrimary(context),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(iOS18Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: iOS18Spacing.xl),

                // Room Code Display
                GlassmorphicCard(
                  padding: EdgeInsets.all(iOS18Spacing.xl),
                  gradient: iOS18Colors.airDropGradient.scale(0.1),
                  child: Column(
                    children: [
                      Text(
                        'Room Code',
                        style: iOS18Typography.callout.copyWith(
                          color: isDark 
                              ? iOS18Colors.textSecondaryDark 
                              : iOS18Colors.getTextSecondary(context),
                        ),
                      ),
                      SizedBox(height: iOS18Spacing.md),
                      
                      // Code in segmented boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _roomCode.split('').map((char) {
                          return Container(
                            width: 48,
                            height: 60,
                            margin: EdgeInsets.symmetric(horizontal: iOS18Spacing.xs / 2),
                            decoration: BoxDecoration(
                              gradient: iOS18Colors.airDropGradient,
                              borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                              boxShadow: [
                                BoxShadow(
                                  color: iOS18Colors.systemBlue.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                char,
                                style: iOS18Typography.largeTitle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      SizedBox(height: iOS18Spacing.md),
                      
                      // Regenerate button
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(
                          horizontal: iOS18Spacing.lg,
                          vertical: iOS18Spacing.sm,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _generateRoomCode();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.refresh, size: 16),
                            SizedBox(width: iOS18Spacing.xs),
                            Text(
                              'Regenerate',
                              style: iOS18Typography.callout.copyWith(
                                color: isDark 
                                    ? iOS18Colors.systemBlueDark 
                                    : iOS18Colors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: iOS18Spacing.xl),

                // Settings
                GlassmorphicCard(
                  padding: EdgeInsets.all(iOS18Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room Settings',
                        style: iOS18Typography.title3.copyWith(
                          color: isDark 
                              ? iOS18Colors.textPrimaryDark 
                              : iOS18Colors.getTextPrimary(context),
                        ),
                      ),
                      SizedBox(height: iOS18Spacing.lg),
                      
                      // Max Participants
                      _buildSettingRow(
                        'Max Participants',
                        '$_maxParticipants people',
                        isDark,
                      ),
                      SizedBox(height: iOS18Spacing.sm),
                      CupertinoSlider(
                        value: _maxParticipants.toDouble(),
                        min: 2,
                        max: 10,
                        divisions: 8,
                        onChanged: (value) {
                          setState(() {
                            _maxParticipants = value.toInt();
                          });
                          HapticFeedback.selectionClick();
                        },
                      ),
                      
                      SizedBox(height: iOS18Spacing.lg),
                      
                      // Duration
                      _buildSettingRow(
                        'Duration',
                        '$_durationMinutes minutes',
                        isDark,
                      ),
                      SizedBox(height: iOS18Spacing.sm),
                      CupertinoSlider(
                        value: _durationMinutes.toDouble(),
                        min: 15,
                        max: 120,
                        divisions: 7,
                        onChanged: (value) {
                          setState(() {
                            _durationMinutes = value.toInt();
                          });
                          HapticFeedback.selectionClick();
                        },
                      ),
                      
                      SizedBox(height: iOS18Spacing.lg),
                      
                      // Password Protection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Require Password',
                                style: iOS18Typography.bodyEmphasized.copyWith(
                                  color: isDark 
                                      ? iOS18Colors.textPrimaryDark 
                                      : iOS18Colors.getTextPrimary(context),
                                ),
                              ),
                              SizedBox(height: iOS18Spacing.xs / 2),
                              Text(
                                'Protect your room',
                                style: iOS18Typography.caption1.copyWith(
                                  color: isDark 
                                      ? iOS18Colors.textSecondaryDark 
                                      : iOS18Colors.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                          CupertinoSwitch(
                            value: _requirePassword,
                            onChanged: (value) {
                              setState(() {
                                _requirePassword = value;
                              });
                              HapticFeedback.lightImpact();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: iOS18Spacing.xxxl),

                // Create Room Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: iOS18Colors.airDropGradient,
                    borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                    boxShadow: [
                      BoxShadow(
                        color: iOS18Colors.systemBlue.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // Show success message
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Room Created!'),
                          content: Text('Room code: $_roomCode\n\nShare this code with others to join.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Create Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: iOS18Spacing.lg),

                // Info text
                Text(
                  'Others can join using this room code',
                  style: iOS18Typography.caption1.copyWith(
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
    );
  }

  Widget _buildSettingRow(String title, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: iOS18Typography.bodyEmphasized.copyWith(
            color: isDark 
                ? iOS18Colors.textPrimaryDark 
                : iOS18Colors.getTextPrimary(context),
          ),
        ),
        Text(
          value,
          style: iOS18Typography.callout.copyWith(
            color: isDark 
                ? iOS18Colors.textSecondaryDark 
                : iOS18Colors.getTextSecondary(context),
          ),
        ),
      ],
    );
  }
}

extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
      stops: stops,
    );
  }
}
