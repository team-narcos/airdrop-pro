import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/widgets/qr_corner_brackets.dart';

class QRGenerateScreen extends StatefulWidget {
  final File file;
  final String deviceId;
  final String deviceName;
  final String ipAddress;
  final int port;

  const QRGenerateScreen({
    Key? key,
    required this.file,
    required this.deviceId,
    required this.deviceName,
    required this.ipAddress,
    required this.port,
  }) : super(key: key);

  @override
  State<QRGenerateScreen> createState() => _QRGenerateScreenState();
}

class _QRGenerateScreenState extends State<QRGenerateScreen>
    with TickerProviderStateMixin {
  late Timer _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes
  String? _fileHash;
  String? _transferToken;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _generateQRData();
    _startCountdown();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateQRData() async {
    // Generate file hash for verification
    final bytes = await widget.file.readAsBytes();
    final digest = sha256.convert(bytes);
    _fileHash = digest.toString();

    // Generate secure transfer token
    _transferToken = _generateSecureToken();

    setState(() {});
  }

  String _generateSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final combined = '${widget.deviceId}:$timestamp:${widget.file.path}';
    return sha256.convert(utf8.encode(combined)).toString().substring(0, 16);
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          Navigator.of(context).pop();
        }
      });
    });
  }

  String get _qrData {
    if (_fileHash == null || _transferToken == null) return '';

    return jsonEncode({
      'deviceId': widget.deviceId,
      'deviceName': widget.deviceName,
      'fileName': widget.file.path.split(Platform.pathSeparator).last,
      'fileSize': widget.file.lengthSync(),
      'fileHash': _fileHash,
      'transferToken': _transferToken,
      'ipAddress': widget.ipAddress,
      'port': widget.port,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': DateTime.now().add(Duration(seconds: _secondsRemaining)).millisecondsSinceEpoch,
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split(Platform.pathSeparator).last;
    final fileSize = widget.file.lengthSync();

    return CupertinoPageScaffold(
      backgroundColor: iOS18Colors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: iOS18Colors.backgroundPrimary.withOpacity(0.9),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: iOS18Colors.systemBlue),
        ),
        middle: const Text('Share via QR'),
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

                // File Info Card
                GlassmorphicCard(
                  padding: EdgeInsets.all(iOS18Spacing.lg),
                  gradient: iOS18Colors.airDropGradient.scale(0.1),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: iOS18Colors.airDropGradient,
                          borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                          boxShadow: [
                            BoxShadow(
                              color: iOS18Colors.systemBlue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.doc,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: iOS18Typography.bodyEmphasized.copyWith(
                                color: iOS18Colors.getTextPrimary(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: iOS18Spacing.xs / 2),
                            Text(
                              _formatFileSize(fileSize),
                              style: iOS18Typography.caption1.copyWith(
                                color: iOS18Colors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: iOS18Spacing.xxxl),

                // QR Code with animated brackets
                if (_fileHash != null && _transferToken != null)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: EdgeInsets.all(iOS18Spacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
                                boxShadow: [
                                  BoxShadow(
                                    color: iOS18Colors.systemBlue.withOpacity(0.2),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 48,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: _qrData,
                                version: QrVersions.auto,
                                size: 280,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                              ),
                            ),
                          );
                        },
                      ),
                      const IgnorePointer(
                        child: QRCornerBrackets(
                          size: 340,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  )
                else
                  const CupertinoActivityIndicator(radius: 20),

                SizedBox(height: iOS18Spacing.xxxl),

                // Countdown Timer
                GlassmorphicCard(
                  padding: EdgeInsets.all(iOS18Spacing.lg),
                  child: Column(
                    children: [
                      Text(
                        'Expires in',
                        style: iOS18Typography.caption1.copyWith(
                          color: iOS18Colors.getTextSecondary(context),
                        ),
                      ),
                      SizedBox(height: iOS18Spacing.xs),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: iOS18Typography.largeTitle.copyWith(
                          color: _secondsRemaining < 60
                              ? iOS18Colors.systemRed
                              : iOS18Colors.systemBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: iOS18Spacing.xl),

                // Status Indicator
                AnimatedOpacity(
                  opacity: _secondsRemaining % 2 == 0 ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: iOS18Colors.systemGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: iOS18Colors.systemGreen,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.sm),
                      Text(
                        'Waiting for scanner...',
                        style: iOS18Typography.callout.copyWith(
                          color: iOS18Colors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: iOS18Spacing.xl),

                // Instructions
                GlassmorphicCard(
                  padding: EdgeInsets.all(iOS18Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.info_circle_fill,
                            color: iOS18Colors.systemBlue,
                            size: 20,
                          ),
                          SizedBox(width: iOS18Spacing.sm),
                          Text(
                            'How to Use',
                            style: iOS18Typography.bodyEmphasized.copyWith(
                              color: iOS18Colors.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: iOS18Spacing.md),
                      _buildInstructionStep('1', 'Open AirDrop on receiving device'),
                      SizedBox(height: iOS18Spacing.sm),
                      _buildInstructionStep('2', 'Tap "Scan QR Code"'),
                      SizedBox(height: iOS18Spacing.sm),
                      _buildInstructionStep('3', 'Point camera at this QR code'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iOS18Colors.systemBlue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: iOS18Typography.caption2.copyWith(
                color: iOS18Colors.systemBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: iOS18Spacing.sm),
        Expanded(
          child: Text(
            text,
            style: iOS18Typography.callout.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
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
