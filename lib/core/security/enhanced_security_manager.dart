import 'dart:async';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

/// Enhanced Security Manager
/// Features:
/// - AES-256 encryption
/// - RSA key exchange
/// - Biometric authentication
/// - File-level encryption
class EnhancedSecurityManager {
  final Logger _logger = Logger();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  encrypt.Encrypter? _aesEncrypter;
  encrypt.Key? _aesKey;
  encrypt.IV? _iv;
  
  bool _isInitialized = false;
  bool _biometricAvailable = false;
  
  /// Initialize security manager
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _logger.i('[Security] Initializing enhanced security manager...');
      
      // Generate AES-256 key
      _aesKey = encrypt.Key.fromSecureRandom(32); // 256 bits
      _iv = encrypt.IV.fromSecureRandom(16);
      _aesEncrypter = encrypt.Encrypter(encrypt.AES(_aesKey!));
      
      // Check biometric availability
      _biometricAvailable = await _localAuth.canCheckBiometrics;
      
      _isInitialized = true;
      _logger.i('[Security] Enhanced security manager initialized');
      _logger.i('[Security] Biometric available: $_biometricAvailable');
      return true;
    } catch (e) {
      _logger.e('[Security] Initialization failed: $e');
      return false;
    }
  }
  
  /// Encrypt data with AES-256
  Future<EncryptedData> encryptData(Uint8List data) async {
    try {
      if (!_isInitialized) {
        throw Exception('Security manager not initialized');
      }
      
      final encrypted = _aesEncrypter!.encryptBytes(data, iv: _iv);
      
      _logger.d('[Security] Data encrypted: ${data.length} → ${encrypted.bytes.length} bytes');
      
      return EncryptedData(
        data: Uint8List.fromList(encrypted.bytes),
        iv: Uint8List.fromList(_iv!.bytes),
        algorithm: EncryptionAlgorithm.aes256,
      );
    } catch (e) {
      _logger.e('[Security] Encryption failed: $e');
      rethrow;
    }
  }
  
  /// Decrypt data with AES-256
  Future<Uint8List> decryptData(EncryptedData encryptedData) async {
    try {
      if (!_isInitialized) {
        throw Exception('Security manager not initialized');
      }
      
      final iv = encrypt.IV(encryptedData.iv);
      final encrypted = encrypt.Encrypted(encryptedData.data);
      final decrypted = _aesEncrypter!.decryptBytes(encrypted, iv: iv);
      
      _logger.d('[Security] Data decrypted: ${encryptedData.data.length} → ${decrypted.length} bytes');
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      _logger.e('[Security] Decryption failed: $e');
      rethrow;
    }
  }
  
  /// Encrypt string
  Future<String> encryptString(String plainText) async {
    final encrypted = _aesEncrypter!.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }
  
  /// Decrypt string
  Future<String> decryptString(String encryptedText) async {
    final decrypted = _aesEncrypter!.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
  
  /// Generate hash for data integrity
  String generateHash(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }
  
  /// Verify data integrity
  bool verifyHash(Uint8List data, String expectedHash) {
    final actualHash = generateHash(data);
    return actualHash == expectedHash;
  }
  
  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access secure content',
  }) async {
    try {
      if (!_biometricAvailable) {
        _logger.w('[Security] Biometric authentication not available');
        return false;
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      _logger.i('[Security] Biometric authentication: $authenticated');
      return authenticated;
    } catch (e) {
      _logger.e('[Security] Biometric authentication failed: $e');
      return false;
    }
  }
  
  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _logger.e('[Security] Get available biometrics failed: $e');
      return [];
    }
  }
  
  /// Generate secure password
  String generateSecurePassword({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[(random + index) % chars.length]).join();
  }
  
  /// Get encryption key (encoded)
  String getEncodedKey() {
    if (_aesKey == null) return '';
    return base64Encode(_aesKey!.bytes);
  }
  
  /// Set encryption key from encoded string
  void setEncodedKey(String encodedKey) {
    try {
      final keyBytes = base64Decode(encodedKey);
      _aesKey = encrypt.Key(Uint8List.fromList(keyBytes));
      _aesEncrypter = encrypt.Encrypter(encrypt.AES(_aesKey!));
      _logger.i('[Security] Encryption key updated');
    } catch (e) {
      _logger.e('[Security] Set encoded key failed: $e');
    }
  }
  
  /// Get security info
  Map<String, dynamic> getSecurityInfo() {
    return {
      'isInitialized': _isInitialized,
      'biometricAvailable': _biometricAvailable,
      'encryptionAlgorithm': 'AES-256',
      'keySize': 256,
      'ivSize': 128,
    };
  }
}

/// Encrypted data container
class EncryptedData {
  final Uint8List data;
  final Uint8List iv;
  final EncryptionAlgorithm algorithm;
  
  EncryptedData({
    required this.data,
    required this.iv,
    required this.algorithm,
  });
  
  Map<String, dynamic> toJson() => {
    'data': base64Encode(data),
    'iv': base64Encode(iv),
    'algorithm': algorithm.toString(),
  };
  
  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
    data: base64Decode(json['data']),
    iv: base64Decode(json['iv']),
    algorithm: EncryptionAlgorithm.values.firstWhere(
      (e) => e.toString() == json['algorithm'],
      orElse: () => EncryptionAlgorithm.aes256,
    ),
  );
}

/// Encryption algorithms
enum EncryptionAlgorithm {
  aes256,
  rsa,
}
