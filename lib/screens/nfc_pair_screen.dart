import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../services/nfc_pairing_service.dart';

final nfcServiceProvider = Provider<NfcPairingService>((ref) {
  final service = NfcPairingService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

class NfcPairScreen extends ConsumerStatefulWidget {
  const NfcPairScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NfcPairScreen> createState() => _NfcPairScreenState();
}

class _NfcPairScreenState extends ConsumerState<NfcPairScreen> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isReading = false;
  String _statusMessage = 'Ready to pair';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Listen to pairing results
    final nfcService = ref.read(nfcServiceProvider);
    nfcService.pairingStream.listen((result) {
      if (result.success) {
        setState(() {
          _statusMessage = 'Paired with ${result.deviceName}!';
          _isReading = false;
        });
        _pulseController.stop();
        
        // Show success dialog
        _showSuccessDialog(result.deviceName!);
      } else {
        setState(() {
          _statusMessage = result.error ?? 'Pairing failed';
          _isReading = false;
        });
        _pulseController.stop();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    final nfcService = ref.read(nfcServiceProvider);
    nfcService.stopReading();
    super.dispose();
  }

  void _startPairing() async {
    final nfcService = ref.read(nfcServiceProvider);
    
    if (!nfcService.isAvailable) {
      setState(() {
        _statusMessage = 'NFC not available on this device';
      });
      return;
    }

    setState(() {
      _isReading = true;
      _statusMessage = 'Hold your device close...';
    });
    
    _pulseController.repeat(reverse: true);
    await nfcService.startReading();
  }

  void _stopPairing() async {
    final nfcService = ref.read(nfcServiceProvider);
    await nfcService.stopReading();
    
    setState(() {
      _isReading = false;
      _statusMessage = 'Pairing cancelled';
    });
    
    _pulseController.stop();
  }

  void _showSuccessDialog(String deviceName) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Pairing Successful'),
        content: Text('Successfully paired with $deviceName'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: iOS18Colors.backgroundPrimary,
      child: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iOS18Colors.backgroundPrimary,
                  iOS18Colors.backgroundSecondary,
                  iOS18Colors.backgroundPrimary,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(iOS18Spacing.lg),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(iOS18Spacing.sm),
                          decoration: BoxDecoration(
                            color: iOS18Colors.getTextTertiary(context).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                          ),
                          child: const Icon(
                            CupertinoIcons.back,
                            size: 24,
                            color: iOS18Colors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      SizedBox(width: iOS18Spacing.md),
                      Text(
                        'NFC Pairing',
                        style: iOS18Typography.title1.copyWith(
                          color: iOS18Colors.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(iOS18Spacing.lg),
                      child: Column(
                        children: [
                          SizedBox(height: iOS18Spacing.xxxl),
                          
                          // NFC Icon with pulse animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isReading ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: _isReading
                                        ? iOS18Colors.deviceGradient
                                        : LinearGradient(
                                            colors: [
                                              iOS18Colors.getTextTertiary(context).withOpacity(0.5),
                                              iOS18Colors.getTextTertiary(context).withOpacity(0.3),
                                            ],
                                          ),
                                    shape: BoxShape.circle,
                                    boxShadow: _isReading
                                        ? [
                                            BoxShadow(
                                              color: iOS18Colors.systemBlue.withOpacity(0.3),
                                              blurRadius: 30,
                                              spreadRadius: 10,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.antenna_radiowaves_left_right,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          SizedBox(height: iOS18Spacing.xxxl),
                          
                          // Status message
                          Text(
                            _statusMessage,
                            style: iOS18Typography.title2.copyWith(
                              color: iOS18Colors.getTextPrimary(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: iOS18Spacing.xl),
                          
                          // Instructions card
                          GlassmorphicCard(
                            padding: EdgeInsets.all(iOS18Spacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(iOS18Spacing.sm),
                                      decoration: BoxDecoration(
                                        gradient: iOS18Colors.historyGradient,
                                        borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.info,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: iOS18Spacing.md),
                                    Text(
                                      'How to Pair',
                                      style: iOS18Typography.headline.copyWith(
                                        color: iOS18Colors.getTextPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: iOS18Spacing.lg),
                                _buildInstructionStep(
                                  '1',
                                  'Tap "Start Pairing" button below',
                                ),
                                SizedBox(height: iOS18Spacing.md),
                                _buildInstructionStep(
                                  '2',
                                  'Hold your device close to another device',
                                ),
                                SizedBox(height: iOS18Spacing.md),
                                _buildInstructionStep(
                                  '3',
                                  'Wait for the connection to establish',
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: iOS18Spacing.xxxl),
                          
                          // Action button
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              padding: EdgeInsets.all(iOS18Spacing.lg),
                              color: _isReading
                                  ? iOS18Colors.systemRed
                                  : iOS18Colors.systemBlue,
                              borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                              onPressed: _isReading ? _stopPairing : _startPairing,
                              child: Text(
                                _isReading ? 'Stop Pairing' : 'Start Pairing',
                                style: iOS18Typography.headline.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: iOS18Spacing.md),
                          
                          // Alternative options
                          Text(
                            'Or use QR code / Room code to pair',
                            style: iOS18Typography.subheadline.copyWith(
                              color: iOS18Colors.getTextSecondary(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iOS18Colors.systemBlue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: iOS18Typography.callout.copyWith(
              color: iOS18Colors.systemBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: iOS18Spacing.md),
        Expanded(
          child: Text(
            text,
            style: iOS18Typography.body.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}
