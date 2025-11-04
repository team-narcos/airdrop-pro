import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometrics are enrolled
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool stickyAuth = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  /// Authenticate before sending file
  Future<bool> authenticateForSend(String fileName) async {
    final canAuth = await canCheckBiometrics();
    if (!canAuth) return true; // Allow if biometrics not available

    return await authenticate(
      localizedReason: 'Authenticate to send $fileName',
      biometricOnly: false,
      stickyAuth: true,
    );
  }

  /// Authenticate before receiving file
  Future<bool> authenticateForReceive(String fileName) async {
    final canAuth = await canCheckBiometrics();
    if (!canAuth) return true; // Allow if biometrics not available

    return await authenticate(
      localizedReason: 'Authenticate to receive $fileName',
      biometricOnly: false,
      stickyAuth: true,
    );
  }

  /// Authenticate for settings access
  Future<bool> authenticateForSettings() async {
    final canAuth = await canCheckBiometrics();
    if (!canAuth) return true; // Allow if biometrics not available

    return await authenticate(
      localizedReason: 'Authenticate to access settings',
      biometricOnly: false,
      stickyAuth: false,
    );
  }

  /// Stop authentication
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } on PlatformException {
      // Ignore errors
    }
  }

  /// Get biometric type string for display
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.isEmpty) return 'Biometric';
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }
}
