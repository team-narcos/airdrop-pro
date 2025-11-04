import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

class NfcPairingService {
  final _pairingController = StreamController<PairingResult>.broadcast();
  bool _isAvailable = false;
  bool _isReading = false;
  
  Stream<PairingResult> get pairingStream => _pairingController.stream;
  bool get isAvailable => _isAvailable;
  bool get isReading => _isReading;
  
  Future<void> initialize() async {
    try {
      _isAvailable = await NfcManager.instance.isAvailable();
    } catch (e) {
      _isAvailable = false;
    }
  }
  
  Future<void> startReading() async {
    if (!_isAvailable || _isReading) return;
    
    _isReading = true;
    
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          // Extract device info from NFC tag
          final deviceId = _extractDeviceId(tag);
          final deviceName = _extractDeviceName(tag);
          
          if (deviceId != null && deviceName != null) {
            _pairingController.add(PairingResult(
              success: true,
              deviceId: deviceId,
              deviceName: deviceName,
            ));
            
            // Stop session after successful read
            await stopReading();
          } else {
            _pairingController.add(PairingResult(
              success: false,
              error: 'Invalid NFC tag',
            ));
          }
        },
      );
    } catch (e) {
      _pairingController.add(PairingResult(
        success: false,
        error: e.toString(),
      ));
      _isReading = false;
    }
  }
  
  Future<void> stopReading() async {
    if (!_isReading) return;
    
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Ignore errors on stop
    }
    
    _isReading = false;
  }
  
  Future<void> writeDeviceInfo(String deviceId, String deviceName) async {
    if (!_isAvailable) return;
    
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          
          if (ndef == null || !ndef.isWritable) {
            _pairingController.add(PairingResult(
              success: false,
              error: 'Tag is not writable',
            ));
            return;
          }
          
          // Create NDEF message
          final message = NdefMessage([
            NdefRecord.createText('deviceId:$deviceId'),
            NdefRecord.createText('deviceName:$deviceName'),
          ]);
          
          try {
            await ndef.write(message);
            _pairingController.add(PairingResult(
              success: true,
              deviceId: deviceId,
              deviceName: deviceName,
            ));
            await stopReading();
          } catch (e) {
            _pairingController.add(PairingResult(
              success: false,
              error: 'Failed to write: $e',
            ));
          }
        },
      );
    } catch (e) {
      _pairingController.add(PairingResult(
        success: false,
        error: e.toString(),
      ));
    }
  }
  
  String? _extractDeviceId(NfcTag tag) {
    try {
      final ndef = Ndef.from(tag);
      if (ndef == null) return null;
      
      final cachedMessage = ndef.cachedMessage;
      if (cachedMessage == null) return null;
      
      for (final record in cachedMessage.records) {
        final payload = String.fromCharCodes(record.payload);
        if (payload.startsWith('deviceId:')) {
          return payload.substring(9);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
  
  String? _extractDeviceName(NfcTag tag) {
    try {
      final ndef = Ndef.from(tag);
      if (ndef == null) return null;
      
      final cachedMessage = ndef.cachedMessage;
      if (cachedMessage == null) return null;
      
      for (final record in cachedMessage.records) {
        final payload = String.fromCharCodes(record.payload);
        if (payload.startsWith('deviceName:')) {
          return payload.substring(11);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
  
  void dispose() {
    stopReading();
    _pairingController.close();
  }
}

class PairingResult {
  final bool success;
  final String? deviceId;
  final String? deviceName;
  final String? error;
  
  PairingResult({
    required this.success,
    this.deviceId,
    this.deviceName,
    this.error,
  });
}
