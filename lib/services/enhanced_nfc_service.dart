import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

/// Enhanced NFC service for instant touch-to-touch pairing
/// Similar to iPhone AirDrop's tap-to-pair functionality
class EnhancedNFCService {
  static const platform = MethodChannel('com.airdrop.nfc');
  
  final _pairingStreamController = StreamController<NFCPairingResult>.broadcast();
  Stream<NFCPairingResult> get pairingStream => _pairingStreamController.stream;
  
  bool _isActive = false;
  bool _isWriteMode = false;
  String? _currentSessionId;
  
  /// Start NFC session for pairing
  Future<bool> startPairingSession({bool writeMode = false}) async {
    if (_isActive) {
      print('[EnhancedNFC] Session already active');
      return false;
    }
    
    try {
      print('[EnhancedNFC] Starting NFC pairing session (write: $writeMode)...');
      
      // Check NFC availability
      final available = await isNFCAvailable();
      if (!available) {
        print('[EnhancedNFC] NFC not available on this device');
        return false;
      }
      
      _isActive = true;
      _isWriteMode = writeMode;
      _currentSessionId = _generateSessionId();
      
      if (writeMode) {
        // Writer mode: Share device info via NFC
        await _startNFCWriter();
      } else {
        // Reader mode: Detect other devices via NFC
        await _startNFCReader();
      }
      
      // Setup method call handler for NFC events
      platform.setMethodCallHandler(_handleNFCMethod);
      
      return true;
      
    } catch (e) {
      print('[EnhancedNFC] Error starting session: $e');
      _isActive = false;
      return false;
    }
  }
  
  /// Stop NFC session
  Future<void> stopPairingSession() async {
    if (!_isActive) return;
    
    try {
      print('[EnhancedNFC] Stopping NFC session...');
      
      await platform.invokeMethod('stopNFCSession');
      
      _isActive = false;
      _isWriteMode = false;
      _currentSessionId = null;
      
    } catch (e) {
      print('[EnhancedNFC] Error stopping session: $e');
    }
  }
  
  /// Check if NFC is available
  Future<bool> isNFCAvailable() async {
    try {
      final result = await platform.invokeMethod<bool>('isNFCAvailable');
      return result ?? false;
    } catch (e) {
      print('[EnhancedNFC] Error checking availability: $e');
      return false;
    }
  }
  
  /// Check if NFC is enabled
  Future<bool> isNFCEnabled() async {
    try {
      final result = await platform.invokeMethod<bool>('isNFCEnabled');
      return result ?? false;
    } catch (e) {
      print('[EnhancedNFC] Error checking enabled state: $e');
      return false;
    }
  }
  
  /// Start NFC writer mode (share device info)
  Future<void> _startNFCWriter() async {
    final deviceInfo = await _getDeviceInfo();
    
    final ndefMessage = _createNDEFMessage(deviceInfo);
    
    await platform.invokeMethod('startNFCWriter', {
      'ndefMessage': ndefMessage,
      'timeout': 60000, // 60 seconds
    });
    
    print('[EnhancedNFC] NFC writer started - waiting for tap...');
  }
  
  /// Start NFC reader mode (detect other devices)
  Future<void> _startNFCReader() async {
    await platform.invokeMethod('startNFCReader', {
      'alertMessage': 'Hold near device to connect',
      'timeout': 60000, // 60 seconds
    });
    
    print('[EnhancedNFC] NFC reader started - bring devices close...');
  }
  
  /// Handle NFC method calls from platform
  Future<dynamic> _handleNFCMethod(MethodCall call) async {
    print('[EnhancedNFC] Method call: ${call.method}');
    
    switch (call.method) {
      case 'onNFCTagDetected':
        await _handleTagDetected(call.arguments);
        break;
        
      case 'onNFCTagWritten':
        _handleTagWritten(call.arguments);
        break;
        
      case 'onNFCPairingComplete':
        _handlePairingComplete(call.arguments);
        break;
        
      case 'onNFCError':
        _handleNFCError(call.arguments);
        break;
        
      case 'onNFCSessionTimeout':
        _handleSessionTimeout();
        break;
    }
  }
  
  /// Handle NFC tag detected
  Future<void> _handleTagDetected(dynamic arguments) async {
    try {
      final tagData = arguments as Map<dynamic, dynamic>;
      print('[EnhancedNFC] Tag detected!');
      
      // Parse NDEF message
      final ndefRecords = tagData['ndefRecords'] as List;
      if (ndefRecords.isEmpty) {
        print('[EnhancedNFC] No NDEF records found');
        return;
      }
      
      // Extract device info from first record
      final firstRecord = ndefRecords[0] as Map;
      final payload = firstRecord['payload'] as String;
      
      final deviceInfo = _parseDeviceInfo(payload);
      
      // Validate pairing data
      if (!_validatePairingData(deviceInfo)) {
        print('[EnhancedNFC] Invalid pairing data');
        _pairingStreamController.add(NFCPairingResult(
          success: false,
          error: 'Invalid device information',
        ));
        return;
      }
      
      // Create secure pairing token
      final pairingToken = _createPairingToken(deviceInfo);
      
      // Emit successful pairing
      _pairingStreamController.add(NFCPairingResult(
        success: true,
        deviceInfo: deviceInfo,
        pairingToken: pairingToken,
        sessionId: _currentSessionId,
      ));
      
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      print('[EnhancedNFC] Pairing successful!');
      
    } catch (e) {
      print('[EnhancedNFC] Error handling tag: $e');
      _pairingStreamController.add(NFCPairingResult(
        success: false,
        error: e.toString(),
      ));
    }
  }
  
  /// Handle tag written
  void _handleTagWritten(dynamic arguments) {
    print('[EnhancedNFC] Tag written successfully');
    
    _pairingStreamController.add(NFCPairingResult(
      success: true,
      isWriter: true,
    ));
    
    HapticFeedback.mediumImpact();
  }
  
  /// Handle pairing complete
  void _handlePairingComplete(dynamic arguments) {
    print('[EnhancedNFC] Pairing completed');
  }
  
  /// Handle NFC error
  void _handleNFCError(dynamic arguments) {
    final error = arguments as String;
    print('[EnhancedNFC] Error: $error');
    
    _pairingStreamController.add(NFCPairingResult(
      success: false,
      error: error,
    ));
  }
  
  /// Handle session timeout
  void _handleSessionTimeout() {
    print('[EnhancedNFC] Session timeout');
    
    _pairingStreamController.add(NFCPairingResult(
      success: false,
      error: 'NFC session timeout',
      timeout: true,
    ));
    
    stopPairingSession();
  }
  
  /// Get device information for sharing
  Future<NFCDeviceInfo> _getDeviceInfo() async {
    // Get device details
    final deviceId = await _getDeviceId();
    final deviceName = await _getDeviceName();
    final ipAddress = await _getLocalIPAddress();
    
    return NFCDeviceInfo(
      id: deviceId,
      name: deviceName,
      ipAddress: ipAddress,
      port: 37777,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      publicKey: _generatePublicKey(),
    );
  }
  
  /// Create NDEF message from device info
  Map<String, dynamic> _createNDEFMessage(NFCDeviceInfo deviceInfo) {
    final payload = jsonEncode({
      'id': deviceInfo.id,
      'name': deviceInfo.name,
      'ip': deviceInfo.ipAddress,
      'port': deviceInfo.port,
      'timestamp': deviceInfo.timestamp,
      'pubkey': deviceInfo.publicKey,
      'version': '1.0',
    });
    
    return {
      'records': [
        {
          'tnf': 0x02, // MIME Media-type
          'type': 'application/airdrop.pairing',
          'payload': base64Encode(utf8.encode(payload)),
        }
      ],
    };
  }
  
  /// Parse device info from NDEF payload
  NFCDeviceInfo _parseDeviceInfo(String payload) {
    final decoded = utf8.decode(base64Decode(payload));
    final data = jsonDecode(decoded) as Map<String, dynamic>;
    
    return NFCDeviceInfo(
      id: data['id'] as String,
      name: data['name'] as String,
      ipAddress: data['ip'] as String?,
      port: data['port'] as int?,
      timestamp: data['timestamp'] as int,
      publicKey: data['pubkey'] as String?,
    );
  }
  
  /// Validate pairing data
  bool _validatePairingData(NFCDeviceInfo deviceInfo) {
    // Check required fields
    if (deviceInfo.id.isEmpty || deviceInfo.name.isEmpty) {
      return false;
    }
    
    // Check timestamp (must be within 5 minutes)
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - deviceInfo.timestamp;
    if (age > 5 * 60 * 1000) {
      return false;
    }
    
    return true;
  }
  
  /// Create secure pairing token
  String _createPairingToken(NFCDeviceInfo deviceInfo) {
    final data = '${deviceInfo.id}:${deviceInfo.timestamp}:${_currentSessionId}';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  /// Generate session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000).toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }
  
  /// Get device ID (platform-specific)
  Future<String> _getDeviceId() async {
    try {
      final id = await platform.invokeMethod<String>('getDeviceId');
      return id ?? 'unknown-device';
    } catch (e) {
      return 'device-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// Get device name (platform-specific)
  Future<String> _getDeviceName() async {
    try {
      final name = await platform.invokeMethod<String>('getDeviceName');
      return name ?? 'Unknown Device';
    } catch (e) {
      return 'My Device';
    }
  }
  
  /// Get local IP address
  Future<String?> _getLocalIPAddress() async {
    try {
      final ip = await platform.invokeMethod<String>('getLocalIPAddress');
      return ip;
    } catch (e) {
      return null;
    }
  }
  
  /// Generate public key for secure pairing
  String _generatePublicKey() {
    // In production, use real cryptographic key generation
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return sha256.convert(utf8.encode('pubkey-$timestamp')).toString();
  }
  
  /// Dispose resources
  void dispose() {
    stopPairingSession();
    _pairingStreamController.close();
  }
}

/// NFC device information
class NFCDeviceInfo {
  final String id;
  final String name;
  final String? ipAddress;
  final int? port;
  final int timestamp;
  final String? publicKey;
  
  NFCDeviceInfo({
    required this.id,
    required this.name,
    this.ipAddress,
    this.port,
    required this.timestamp,
    this.publicKey,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'timestamp': timestamp,
      'publicKey': publicKey,
    };
  }
}

/// NFC pairing result
class NFCPairingResult {
  final bool success;
  final NFCDeviceInfo? deviceInfo;
  final String? pairingToken;
  final String? sessionId;
  final String? error;
  final bool timeout;
  final bool isWriter;
  
  NFCPairingResult({
    required this.success,
    this.deviceInfo,
    this.pairingToken,
    this.sessionId,
    this.error,
    this.timeout = false,
    this.isWriter = false,
  });
}
