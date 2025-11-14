import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'dart:math';

/// Cryptography service for secure P2P file transfer
/// Implements ECDH key exchange and AES-256-GCM encryption
class CryptoService {
  // ECDH key pair
  ECPrivateKey? _privateKey;
  ECPublicKey? _publicKey;
  
  // Shared secret
  Uint8List? _sharedSecret;
  
  // AES key derived from shared secret
  Uint8List? _aesKey;
  
  // Secure random generator
  final _secureRandom = FortunaRandom();
  bool _randomInitialized = false;
  
  /// Generate ECDH key pair (P-256 curve)
  Future<void> generateKeyPair() async {
    debugPrint('[Crypto] Generating ECDH key pair...');
    
    // Initialize secure random if needed
    if (!_randomInitialized) {
      _initializeSecureRandom();
    }
    
    // Generate key pair using P-256 (secp256r1) curve
    final keyGen = ECKeyGenerator();
    final params = ECKeyGeneratorParameters(
      ECCurve_secp256r1(),
    );
    
    final parametersWithRandom = ParametersWithRandom(params, _secureRandom);
    keyGen.init(parametersWithRandom);
    
    final keyPair = keyGen.generateKeyPair();
    _privateKey = keyPair.privateKey as ECPrivateKey;
    _publicKey = keyPair.publicKey as ECPublicKey;
    
    debugPrint('[Crypto] Key pair generated');
  }
  
  /// Get public key as Base64 string for transmission
  String getPublicKeyBase64() {
    if (_publicKey == null) {
      throw StateError('Public key not generated. Call generateKeyPair() first.');
    }
    
    // Encode public key point as uncompressed format (0x04 || x || y)
    final q = _publicKey!.Q!;
    final x = _encodeBigInt(q.x!.toBigInteger()!);
    final y = _encodeBigInt(q.y!.toBigInteger()!);
    
    final encoded = Uint8List(1 + x.length + y.length);
    encoded[0] = 0x04; // Uncompressed point format
    encoded.setRange(1, 1 + x.length, x);
    encoded.setRange(1 + x.length, encoded.length, y);
    
    return base64Encode(encoded);
  }
  
  /// Perform ECDH key exchange with peer's public key
  Future<void> performKeyExchange(String peerPublicKeyBase64) async {
    if (_privateKey == null) {
      throw StateError('Private key not generated. Call generateKeyPair() first.');
    }
    
    debugPrint('[Crypto] Performing ECDH key exchange...');
    
    // Decode peer's public key
    final peerPublicKeyBytes = base64Decode(peerPublicKeyBase64);
    final peerPublicKey = _decodePublicKey(peerPublicKeyBytes);
    
    // Perform ECDH
    final agreement = ECDHBasicAgreement();
    agreement.init(_privateKey!);
    final sharedSecretBigInt = agreement.calculateAgreement(peerPublicKey);
    
    // Convert to bytes
    _sharedSecret = _encodeBigInt(sharedSecretBigInt);
    
    // Derive AES key from shared secret using HKDF
    _aesKey = await _deriveAESKey(_sharedSecret!);
    
    debugPrint('[Crypto] Key exchange complete, shared secret derived');
  }
  
  /// Encrypt data using AES-256-GCM
  Future<EncryptedData> encrypt(Uint8List plaintext) async {
    if (_aesKey == null) {
      throw StateError('AES key not available. Perform key exchange first.');
    }
    
    // Generate random IV (12 bytes for GCM)
    final iv = _generateRandomBytes(12);
    
    // Use cryptography package for AES-GCM
    final algorithm = crypto.AesGcm.with256bits();
    final secretKey = crypto.SecretKey(_aesKey!);
    final nonce = iv;
    
    // Encrypt
    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    
    return EncryptedData(
      ciphertext: Uint8List.fromList(secretBox.cipherText),
      iv: iv,
      authTag: Uint8List.fromList(secretBox.mac.bytes),
    );
  }
  
  /// Decrypt data using AES-256-GCM
  Future<Uint8List> decrypt(EncryptedData encrypted) async {
    if (_aesKey == null) {
      throw StateError('AES key not available. Perform key exchange first.');
    }
    
    // Use cryptography package for AES-GCM
    final algorithm = crypto.AesGcm.with256bits();
    final secretKey = crypto.SecretKey(_aesKey!);
    
    // Create SecretBox with ciphertext and MAC
    final secretBox = crypto.SecretBox(
      encrypted.ciphertext,
      nonce: encrypted.iv,
      mac: crypto.Mac(encrypted.authTag),
    );
    
    // Decrypt
    try {
      final plaintext = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
  
  /// Derive AES-256 key from shared secret using HKDF
  Future<Uint8List> _deriveAESKey(Uint8List sharedSecret) async {
    // Use HKDF with SHA-256
    final algorithm = crypto.Hkdf(
      hmac: crypto.Hmac.sha256(),
      outputLength: 32, // 256 bits
    );
    
    final secretKey = crypto.SecretKey(sharedSecret);
    final derivedKey = await algorithm.deriveKey(
      secretKey: secretKey,
      nonce: [],
      info: utf8.encode('airdrop-pro-v1'),
    );
    
    final keyBytes = await derivedKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }
  
  /// Initialize secure random number generator
  void _initializeSecureRandom() {
    final seed = Uint8List(32);
    final random = Random.secure();
    for (var i = 0; i < seed.length; i++) {
      seed[i] = random.nextInt(256);
    }
    
    _secureRandom.seed(KeyParameter(seed));
    _randomInitialized = true;
  }
  
  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    if (!_randomInitialized) {
      _initializeSecureRandom();
    }
    
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextUint8();
    }
    return bytes;
  }
  
  /// Encode BigInt to fixed-size byte array (32 bytes for P-256)
  Uint8List _encodeBigInt(BigInt number) {
    final bytes = Uint8List(32);
    var n = number;
    
    for (var i = bytes.length - 1; i >= 0; i--) {
      bytes[i] = (n & BigInt.from(0xff)).toInt();
      n = n >> 8;
    }
    
    return bytes;
  }
  
  /// Decode public key from bytes
  ECPublicKey _decodePublicKey(Uint8List bytes) {
    if (bytes[0] != 0x04) {
      throw FormatException('Invalid public key format');
    }
    
    // Extract x and y coordinates (32 bytes each for P-256)
    final x = _decodeBigInt(bytes.sublist(1, 33));
    final y = _decodeBigInt(bytes.sublist(33, 65));
    
    // Create EC point
    final curve = ECCurve_secp256r1();
    final params = ECDomainParameters('secp256r1');
    final q = params.curve.createPoint(x, y);
    
    return ECPublicKey(q, params);
  }
  
  /// Decode bytes to BigInt
  BigInt _decodeBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (var byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
  
  /// Clear sensitive data
  void dispose() {
    _privateKey = null;
    _publicKey = null;
    _sharedSecret = null;
    _aesKey = null;
  }
}

/// Encrypted data container
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List authTag;
  
  const EncryptedData({
    required this.ciphertext,
    required this.iv,
    required this.authTag,
  });
  
  /// Total size in bytes
  int get totalSize => ciphertext.length + iv.length + authTag.length;
  
  /// Serialize to bytes for transmission
  Uint8List toBytes() {
    final result = Uint8List(4 + totalSize);
    var offset = 0;
    
    // Write IV length and data
    result[offset++] = iv.length;
    result.setRange(offset, offset + iv.length, iv);
    offset += iv.length;
    
    // Write auth tag length and data
    result[offset++] = authTag.length;
    result.setRange(offset, offset + authTag.length, authTag);
    offset += authTag.length;
    
    // Write ciphertext length (2 bytes) and data
    final ciphertextLength = ciphertext.length;
    result[offset++] = (ciphertextLength >> 8) & 0xff;
    result[offset++] = ciphertextLength & 0xff;
    result.setRange(offset, offset + ciphertext.length, ciphertext);
    
    return result;
  }
  
  /// Deserialize from bytes
  static EncryptedData fromBytes(Uint8List bytes) {
    var offset = 0;
    
    // Read IV
    final ivLength = bytes[offset++];
    final iv = bytes.sublist(offset, offset + ivLength);
    offset += ivLength;
    
    // Read auth tag
    final authTagLength = bytes[offset++];
    final authTag = bytes.sublist(offset, offset + authTagLength);
    offset += authTagLength;
    
    // Read ciphertext
    final ciphertextLength = (bytes[offset] << 8) | bytes[offset + 1];
    offset += 2;
    final ciphertext = bytes.sublist(offset, offset + ciphertextLength);
    
    return EncryptedData(
      ciphertext: ciphertext,
      iv: iv,
      authTag: authTag,
    );
  }
}
