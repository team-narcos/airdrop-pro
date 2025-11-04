import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../services/tcp_transfer_service.dart';

class NfcShareScreen extends StatefulWidget {
  const NfcShareScreen({Key? key}) : super(key: key);

  @override
  State<NfcShareScreen> createState() => _NfcShareScreenState();
}

class _NfcShareScreenState extends State<NfcShareScreen> with TickerProviderStateMixin {
  bool _nfcAvailable = false;
  bool _isScanning = false;
  File? _selectedFile;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopNfcSession();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final available = await NfcManager.instance.isAvailable();
      setState(() {
        _nfcAvailable = available;
      });
      if (!available) {
        _showError('NFC not available on this device');
      }
    } catch (e) {
      print('[NFC] Availability check error: $e');
      setState(() {
        _nfcAvailable = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = File(result.files.first.path!);
        });
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _startNfcSend() async {
    if (_selectedFile == null) {
      _showError('Please select a file first');
      return;
    }

    if (!_nfcAvailable) {
      _showError('NFC not available');
      return;
    }

    setState(() {
      _isScanning = true;
    });
    _pulseController.repeat(reverse: true);

    try {
      final ipAddress = await NetworkInfo().getWifiIP();
      final fileName = _selectedFile!.path.split(Platform.pathSeparator).last;
      final fileSize = await _selectedFile!.length();
      final deviceId = const Uuid().v4();

      final payload = {
        'deviceId': deviceId,
        'deviceName': Platform.isAndroid ? 'Android Device' : 'iOS Device',
        'ipAddress': ipAddress,
        'port': 37777,
        'fileName': fileName,
        'fileSize': fileSize,
        'token': _generateToken(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final jsonPayload = jsonEncode(payload);
      final bytes = utf8.encode(jsonPayload);

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            HapticFeedback.heavyImpact();
            
            var ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              _showError('Tag is not NDEF writable');
              return;
            }

            NdefMessage message = NdefMessage([
              NdefRecord.createMime(
                'application/vnd.airdrop.transfer',
                bytes,
              ),
            ]);

            await ndef.write(message);
            
            // Success feedback
            HapticFeedback.mediumImpact();
            _playSuccessSound();
            
            if (mounted) {
              _stopNfcSession();
              _showSuccess('File info sent via NFC!');
            }
          } catch (e) {
            print('[NFC] Write error: $e');
            _showError('Failed to write NFC tag: $e');
          }
        },
        onError: (error) async {
          print('[NFC] Session error: $error');
          _showError('NFC error: $error');
          _stopNfcSession();
          return Future.value();
        },
      );
    } catch (e) {
      print('[NFC] Send error: $e');
      _showError('NFC send failed: $e');
      _stopNfcSession();
    }
  }

  Future<void> _startNfcReceive() async {
    if (!_nfcAvailable) {
      _showError('NFC not available');
      return;
    }

    setState(() {
      _isScanning = true;
    });
    _pulseController.repeat(reverse: true);

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            HapticFeedback.heavyImpact();
            
            var ndef = Ndef.from(tag);
            if (ndef == null) {
              _showError('Tag is not NDEF formatted');
              return;
            }

            final message = ndef.cachedMessage;
            if (message == null || message.records.isEmpty) {
              _showError('No data on NFC tag');
              return;
            }

            // Read payload
            final record = message.records.first;
            final payload = utf8.decode(record.payload);
            final data = jsonDecode(payload) as Map<String, dynamic>;

            // Validate timestamp (within 5 minutes)
            final timestamp = data['timestamp'] as int;
            final age = DateTime.now().millisecondsSinceEpoch - timestamp;
            if (age > 5 * 60 * 1000) {
              _showError('NFC data expired');
              return;
            }

            HapticFeedback.mediumImpact();
            _playSuccessSound();
            
            if (mounted) {
              _stopNfcSession();
              _handleReceivedData(data);
            }
          } catch (e) {
            print('[NFC] Read error: $e');
            _showError('Failed to read NFC tag: $e');
          }
        },
        onError: (error) async {
          print('[NFC] Session error: $error');
          _showError('NFC error: $error');
          _stopNfcSession();
          return Future.value();
        },
      );
    } catch (e) {
      print('[NFC] Receive error: $e');
      _showError('NFC receive failed: $e');
      _stopNfcSession();
    }
  }

  void _stopNfcSession() {
    setState(() {
      _isScanning = false;
    });
    _pulseController.stop();
    _pulseController.reset();
    NfcManager.instance.stopSession();
  }

  void _handleReceivedData(Map<String, dynamic> data) {
    final fileName = data['fileName'] as String;
    final fileSize = data['fileSize'] as int;
    final ipAddress = data['ipAddress'] as String;
    final deviceName = data['deviceName'] as String;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Receive File'),
        content: Text(
          'Receive "$fileName" (${_formatFileSize(fileSize)}) from $deviceName?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Decline'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _showInfo('File transfer would connect to $ipAddress');
              // TODO: Integrate with TcpTransferService
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  String _generateToken() {
    return const Uuid().v4().substring(0, 16);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _playSuccessSound() async {
    try {
      // Play a simple beep (you can add actual sound file)
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // Sound file not found - ignore
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showInfo(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: iOS18Colors.backgroundPrimary,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(iOS18Spacing.lg),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _stopNfcSession();
                      Navigator.of(context).pop();
                    },
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
                    'NFC Sharing',
                    style: iOS18Typography.title1.copyWith(
                      color: iOS18Colors.getTextPrimary(context),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: !_nfcAvailable
                  ? _buildNfcUnavailable()
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(iOS18Spacing.lg),
                      child: Column(
                        children: [
                          SizedBox(height: iOS18Spacing.xl),

                          // NFC Animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isScanning ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        iOS18Colors.systemOrange,
                                        iOS18Colors.systemYellow,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: _isScanning
                                        ? [
                                            BoxShadow(
                                              color: iOS18Colors.systemOrange.withOpacity(0.5),
                                              blurRadius: 40,
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

                          // Instructions
                          GlassmorphicCard(
                            padding: EdgeInsets.all(iOS18Spacing.lg),
                            child: Column(
                              children: [
                                Text(
                                  _isScanning
                                      ? 'Hold devices back-to-back'
                                      : 'NFC Ready',
                                  style: iOS18Typography.title2.copyWith(
                                    color: iOS18Colors.getTextPrimary(context),
                                  ),
                                ),
                                SizedBox(height: iOS18Spacing.sm),
                                Text(
                                  _isScanning
                                      ? 'Keep devices together until transfer starts'
                                      : 'Select a file to send or tap receive to get files',
                                  style: iOS18Typography.subheadline.copyWith(
                                    color: iOS18Colors.getTextSecondary(context),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: iOS18Spacing.xl),

                          // File Selection (for sending)
                          if (_selectedFile == null && !_isScanning) ...[
                            GestureDetector(
                              onTap: _pickFile,
                              child: Container(
                                padding: EdgeInsets.all(iOS18Spacing.xl),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      iOS18Colors.systemOrange.withOpacity(0.1),
                                      iOS18Colors.systemYellow.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
                                  border: Border.all(
                                    color: iOS18Colors.systemOrange.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      CupertinoIcons.doc_on_doc,
                                      size: 60,
                                      color: iOS18Colors.systemOrange,
                                    ),
                                    SizedBox(height: iOS18Spacing.md),
                                    Text(
                                      'Select File to Send',
                                      style: iOS18Typography.headline.copyWith(
                                        color: iOS18Colors.getTextPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Selected File Info
                          if (_selectedFile != null && !_isScanning) ...[
                            GlassmorphicCard(
                              padding: EdgeInsets.all(iOS18Spacing.lg),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          iOS18Colors.systemOrange,
                                          iOS18Colors.systemYellow,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.doc,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: iOS18Spacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedFile!.path.split(Platform.pathSeparator).last,
                                          style: iOS18Typography.bodyEmphasized.copyWith(
                                            color: iOS18Colors.getTextPrimary(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        FutureBuilder<int>(
                                          future: _selectedFile!.length(),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) return const SizedBox();
                                            return Text(
                                              _formatFileSize(snapshot.data!),
                                              style: iOS18Typography.caption1.copyWith(
                                                color: iOS18Colors.getTextSecondary(context),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFile = null;
                                      });
                                    },
                                    icon: const Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      color: iOS18Colors.systemRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: iOS18Spacing.lg),
                          ],

                          // Action Buttons
                          if (!_isScanning) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _startNfcSend,
                                    child: Container(
                                      padding: EdgeInsets.all(iOS18Spacing.lg),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            iOS18Colors.systemOrange,
                                            iOS18Colors.systemYellow,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.arrow_up_circle_fill,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                          SizedBox(height: iOS18Spacing.sm),
                                          Text(
                                            'Send',
                                            style: iOS18Typography.headline.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: iOS18Spacing.md),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _startNfcReceive,
                                    child: Container(
                                      padding: EdgeInsets.all(iOS18Spacing.lg),
                                      decoration: BoxDecoration(
                                        gradient: iOS18Colors.deviceGradient,
                                        borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.arrow_down_circle_fill,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                          SizedBox(height: iOS18Spacing.sm),
                                          Text(
                                            'Receive',
                                            style: iOS18Typography.headline.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: _stopNfcSession,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(iOS18Spacing.lg),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      iOS18Colors.systemRed,
                                      iOS18Colors.systemRed.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.stop_circle_fill,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: iOS18Spacing.sm),
                                    Text(
                                      'Cancel',
                                      style: iOS18Typography.headline.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcUnavailable() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(iOS18Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 80,
              color: iOS18Colors.systemOrange,
            ),
            SizedBox(height: iOS18Spacing.xl),
            Text(
              'NFC Not Available',
              style: iOS18Typography.title2.copyWith(
                color: iOS18Colors.getTextPrimary(context),
              ),
            ),
            SizedBox(height: iOS18Spacing.md),
            Text(
              'This device does not support NFC or NFC is disabled',
              style: iOS18Typography.body.copyWith(
                color: iOS18Colors.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
