import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/platform/platform_adapter.dart';
import '../services/tcp_transfer_service.dart';

class QRShareScreen extends StatefulWidget {
  const QRShareScreen({Key? key}) : super(key: key);

  @override
  State<QRShareScreen> createState() => _QRShareScreenState();
}

class _QRShareScreenState extends State<QRShareScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  File? _selectedFile;
  String? _qrData;
  Timer? _expiryTimer;
  int _secondsRemaining = 300; // 5 minutes
  String? _deviceId;
  String? _deviceName;
  String? _ipAddress;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeDeviceInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDeviceInfo() async {
    _deviceId = const Uuid().v4();
    if (PlatformAdapter.isWeb) {
      _deviceName = 'Web Device';
      _ipAddress = '127.0.0.1'; // Localhost for web
    } else {
      _deviceName = PlatformAdapter.isAndroid ? 'Android Device' : 'iOS Device';
      try {
        _ipAddress = await NetworkInfo().getWifiIP();
      } catch (e) {
        _ipAddress = '0.0.0.0';
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = File(result.files.first.path!);
        });
        _generateQRCode();
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  void _generateQRCode() async {
    if (_selectedFile == null) return;

    final pathSeparator = PlatformAdapter.isWeb ? '/' : Platform.pathSeparator;
    final fileName = _selectedFile!.path.split(pathSeparator).last;
    final fileSize = await _selectedFile!.length();
    final token = _generateSecureToken();

    final qrPayload = {
      'deviceId': _deviceId,
      'deviceName': _deviceName,
      'fileName': fileName,
      'fileSize': fileSize,
      'ipAddress': _ipAddress,
      'port': 37777,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'token': token,
    };

    setState(() {
      _qrData = jsonEncode(qrPayload);
      _secondsRemaining = 300;
    });

    _startExpiryTimer();
  }

  String _generateSecureToken() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          _generateQRCode(); // Regenerate with new token
        }
      });
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
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(iOS18Spacing.sm),
                      decoration: BoxDecoration(
                        color: iOS18Colors.getTextTertiary(context).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                      ),
                      child: Icon(
                        CupertinoIcons.back,
                        size: 24,
                        color: iOS18Colors.getTextPrimary(context),
                      ),
                    ),
                  ),
                  SizedBox(width: iOS18Spacing.md),
                  Text(
                    'QR Code Sharing',
                    style: iOS18Typography.title1.copyWith(
                      color: iOS18Colors.getTextPrimary(context),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar (Cupertino Style)
            Container(
              margin: EdgeInsets.symmetric(horizontal: iOS18Spacing.lg),
              decoration: BoxDecoration(
                color: iOS18Colors.backgroundSecondary,
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _tabController.index,
                onValueChanged: (value) {
                  if (value != null) {
                    _tabController.animateTo(value);
                  }
                },
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Generate'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Scan'),
                  ),
                },
              ),
            ),

            SizedBox(height: iOS18Spacing.lg),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGenerateTab(),
                  _buildScanTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(iOS18Spacing.lg),
      child: Column(
        children: [
          if (_selectedFile == null) ...[
            SizedBox(height: iOS18Spacing.xxxl),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: EdgeInsets.all(iOS18Spacing.xxxl),
                decoration: BoxDecoration(
                  gradient: iOS18Colors.fileGradient.scale(0.1),
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
                      size: 80,
                      color: iOS18Colors.systemOrange,
                    ),
                    SizedBox(height: iOS18Spacing.lg),
                    Text(
                      'Select File',
                      style: iOS18Typography.title2.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                      ),
                    ),
                    SizedBox(height: iOS18Spacing.sm),
                    Text(
                      'Tap to choose a file to share',
                      style: iOS18Typography.subheadline.copyWith(
                        color: iOS18Colors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // File Info
            GlassmorphicCard(
              padding: EdgeInsets.all(iOS18Spacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: iOS18Colors.fileGradient,
                      borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc,
                      color: Colors.white,
                      size: 30,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: iOS18Spacing.xs / 2),
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
                        _qrData = null;
                        _expiryTimer?.cancel();
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

            SizedBox(height: iOS18Spacing.xl),

            // QR Code
            if (_qrData != null) ...[
              Container(
                padding: EdgeInsets.all(iOS18Spacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
                  boxShadow: iOS18Shadows.cardShadows,
                ),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 280,
                ),
              ),

              SizedBox(height: iOS18Spacing.lg),

              // Expiry Timer
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: iOS18Spacing.lg,
                  vertical: iOS18Spacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iOS18Colors.systemOrange.withOpacity(0.1),
                      iOS18Colors.systemRed.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      color: iOS18Colors.systemOrange,
                      size: 20,
                    ),
                    SizedBox(width: iOS18Spacing.sm),
                    Text(
                      'Expires in ${_formatTime(_secondsRemaining)}',
                      style: iOS18Typography.headline.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: iOS18Spacing.lg),

              // Refresh Button
              GestureDetector(
                onTap: _generateQRCode,
                child: Container(
                  padding: EdgeInsets.all(iOS18Spacing.md),
                  decoration: BoxDecoration(
                    gradient: iOS18Colors.deviceGradient,
                    borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.refresh,
                        color: Colors.white,
                      ),
                      SizedBox(width: iOS18Spacing.sm),
                      Text(
                        'Regenerate QR Code',
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
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return QRScannerWidget(
      onQRScanned: (qrData) {
        _handleScannedQR(qrData);
      },
    );
  }

  Future<void> _handleScannedQR(String qrData) async {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      
      // Validate timestamp (within 5 minutes)
      final timestamp = data['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > 5 * 60 * 1000) {
        _showError('QR code expired');
        return;
      }

      final fileName = data['fileName'] as String;
      final fileSize = data['fileSize'] as int;
      final ipAddress = data['ipAddress'] as String;
      final deviceName = data['deviceName'] as String;

      // Show confirmation dialog
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
                // TODO: Initiate TCP connection and receive file
                _showError('File transfer will be implemented');
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Invalid QR code');
    }
  }
}

class QRScannerWidget extends StatefulWidget {
  final Function(String) onQRScanned;

  const QRScannerWidget({Key? key, required this.onQRScanned}) : super(key: key);

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              HapticFeedback.mediumImpact();
              widget.onQRScanned(barcodes.first.rawValue!);
            }
          },
        ),
        
        // Overlay with scanning frame
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: iOS18Colors.systemBlue,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
              ),
            ),
          ),
        ),
        
        // Instructions
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: iOS18Spacing.lg,
                vertical: iOS18Spacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
              ),
              child: Text(
                'Point camera at QR code',
                style: iOS18Typography.headline.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
      stops: stops,
    );
  }
}
