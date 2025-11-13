import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:pointycastle/export.dart';
import '../utils/logger.dart';

/// Secure Transfer Engine with End-to-End Encryption
/// 
/// Features:
/// - AES-256-GCM encryption
/// - ECDH key exchange for secure key generation
/// - Per-transfer ephemeral keys (forward secrecy)
/// - File integrity verification (SHA-256)
/// - Zero-knowledge architecture
class SecureTransferEngine {
  // Ephemeral key pairs (regenerated for each transfer)
  ECPrivateKey? _privateKey;
  ECPublicKey? _publicKey;
  
  // Shared secret after key exchange
  Uint8List? _sharedSecret;
  
  // AES encryption key derived from shared secret
  encrypt_pkg.Key? _aesKey;
  
  // IV for AES-GCM
  encrypt_pkg.IV? _iv;

  /// Generate ephemeral EC key pair for this transfer
  Future<KeyPairInfo> generateEphemeralKeys() async {
    try {
      logInfo('Generating ephemeral ECDH key pair');
      
      // Use secp256r1 (P-256) curve
      final domainParams = ECDomainParameters('secp256r1');
      final secureRandom = _getSecureRandom();
      
      final keyGen = ECKeyGenerator()
        ..init(ParametersWithRandom(
          ECKeyGeneratorParameters(domainParams),
          secureRandom,
        ));
      
      final keyPair = keyGen.generateKeyPair();
      
      _privateKey = keyPair.privateKey as ECPrivateKey;
      _publicKey = keyPair.publicKey as ECPublicKey;
      
      // Serialize public key for transmission
      final publicKeyBytes = _serializePublicKey(_publicKey!);
      
      logInfo('ECDH key pair generated successfully');
      
      return KeyPairInfo(
        publicKeyBytes: publicKeyBytes,
        privateKey: _privateKey!,
        publicKey: _publicKey!,
      );
    } catch (e) {
      logError('Failed to generate key pair', e);
      rethrow;
    }
  }

  /// Perform ECDH key exchange with peer's public key
  Future<bool> performKeyExchange(Uint8List peerPublicKeyBytes) async {
    try {
      logInfo('Performing ECDH key exchange');
      
      if (_privateKey == null) {
        throw Exception('Private key not generated');
      }
      
      // Deserialize peer's public key
      final peerPublicKey = _deserializePublicKey(peerPublicKeyBytes);
      
      // Compute shared secret using ECDH
      final agreement = ECDHBasicAgreement();
      agreement.init(_privateKey!);
      
      final sharedSecretBigInt = agreement.calculateAgreement(peerPublicKey);
      
      // Convert BigInt to bytes
      _sharedSecret = _bigIntToBytes(sharedSecretBigInt);
      
      // Derive AES key from shared secret using HKDF
      _aesKey = _deriveAESKey(_sharedSecret!);
      
      // Generate random IV
      _iv = encrypt_pkg.IV.fromSecureRandom(16);
      
      logInfo('Key exchange completed successfully');
      
      return true;
    } catch (e) {
      logError('Key exchange failed', e);
      return false;
    }
  }

  /// Encrypt a file stream
  Stream<EncryptedChunk> encryptFileStream(
    Stream<Uint8List> fileStream,
    String fileName,
    int fileSize,
  ) async* {
    if (_aesKey == null || _iv == null) {
      throw Exception('Encryption not initialized - perform key exchange first');
    }
    
    logInfo('Starting encrypted file transfer: $fileName');
    
    try {
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(_aesKey!, mode: encrypt_pkg.AESMode.gcm),
      );
      
      int chunkIndex = 0;
      int totalEncrypted = 0;
      
      await for (final chunk in fileStream) {
        // Encrypt chunk
        final encrypted = encrypter.encryptBytes(
          chunk,
          iv: _iv!,
        );
        
        // Calculate chunk hash for integrity
        final chunkHash = sha256.convert(chunk).bytes;
        
        totalEncrypted += chunk.length;
        
        yield EncryptedChunk(
          data: encrypted.bytes,
          index: chunkIndex,
          hash: Uint8List.fromList(chunkHash),
          iv: _iv!.bytes,
        );
        
        chunkIndex++;
      }
      
      logInfo('File encryption completed: $totalEncrypted bytes');
    } catch (e) {
      logError('File encryption failed', e);
      rethrow;
    }
  }

  /// Decrypt a file stream
  Stream<Uint8List> decryptFileStream(
    Stream<EncryptedChunk> encryptedStream,
  ) async* {
    if (_aesKey == null) {
      throw Exception('Decryption not initialized - perform key exchange first');
    }
    
    logInfo('Starting file decryption');
    
    try {
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(_aesKey!, mode: encrypt_pkg.AESMode.gcm),
      );
      
      int chunkIndex = 0;
      
      await for (final encryptedChunk in encryptedStream) {
        // Verify chunk index
        if (encryptedChunk.index != chunkIndex) {
          throw Exception('Chunk order mismatch: expected $chunkIndex, got ${encryptedChunk.index}');
        }
        
        // Decrypt chunk
        final iv = encrypt_pkg.IV(encryptedChunk.iv);
        final encrypted = encrypt_pkg.Encrypted(encryptedChunk.data);
        
        final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
        
        // Verify chunk integrity
        final calculatedHash = sha256.convert(decrypted).bytes;
        if (!_bytesEqual(calculatedHash, encryptedChunk.hash)) {
          throw Exception('Chunk integrity verification failed at index $chunkIndex');
        }
        
        yield Uint8List.fromList(decrypted);
        
        chunkIndex++;
      }
      
      logInfo('File decryption completed successfully');
    } catch (e) {
      logError('File decryption failed', e);
      rethrow;
    }
  }

  /// Encrypt a single file buffer
  Future<EncryptedData> encryptFile(Uint8List fileData) async {
    if (_aesKey == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }
    
    try {
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(_aesKey!, mode: encrypt_pkg.AESMode.gcm),
      );
      
      final encrypted = encrypter.encryptBytes(fileData, iv: _iv!);
      
      // Calculate file hash
      final fileHash = sha256.convert(fileData).bytes;
      
      return EncryptedData(
        encryptedBytes: encrypted.bytes,
        iv: _iv!.bytes,
        hash: Uint8List.fromList(fileHash),
      );
    } catch (e) {
      logError('File encryption failed', e);
      rethrow;
    }
  }

  /// Decrypt a single file buffer
  Future<Uint8List> decryptFile(EncryptedData encryptedData) async {
    if (_aesKey == null) {
      throw Exception('Decryption not initialized');
    }
    
    try {
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(_aesKey!, mode: encrypt_pkg.AESMode.gcm),
      );
      
      final iv = encrypt_pkg.IV(encryptedData.iv);
      final encrypted = encrypt_pkg.Encrypted(encryptedData.encryptedBytes);
      
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      
      // Verify integrity
      final calculatedHash = sha256.convert(decrypted).bytes;
      if (!_bytesEqual(calculatedHash, encryptedData.hash)) {
        throw Exception('File integrity verification failed');
      }
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      logError('File decryption failed', e);
      rethrow;
    }
  }

  /// Generate secure random bytes
  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (var i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Serialize EC public key to bytes
  Uint8List _serializePublicKey(ECPublicKey publicKey) {
    final x = _bigIntToBytes(publicKey.Q!.x!.toBigInteger()!);
    final y = _bigIntToBytes(publicKey.Q!.y!.toBigInteger()!);
    
    // Combine x and y coordinates
    final buffer = BytesBuilder();
    buffer.add([x.length]); // x length prefix
    buffer.add(x);
    buffer.add([y.length]); // y length prefix
    buffer.add(y);
    
    return buffer.toBytes();
  }

  /// Deserialize bytes to EC public key
  ECPublicKey _deserializePublicKey(Uint8List bytes) {
    final buffer = ByteData.sublistView(bytes);
    int offset = 0;
    
    // Read x
    final xLength = buffer.getUint8(offset++);
    final x = BigInt.parse(
      bytes.sublist(offset, offset + xLength).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
    offset += xLength;
    
    // Read y
    final yLength = buffer.getUint8(offset++);
    final y = BigInt.parse(
      bytes.sublist(offset, offset + yLength).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
    
    final domainParams = ECDomainParameters('secp256r1');
    final point = domainParams.curve.createPoint(x, y);
    
    return ECPublicKey(point, domainParams);
  }

  /// Convert BigInt to bytes
  Uint8List _bigIntToBytes(BigInt bigInt) {
    final hex = bigInt.toRadixString(16);
    final paddedHex = hex.length.isOdd ? '0$hex' : hex;
    
    final bytes = <int>[];
    for (var i = 0; i < paddedHex.length; i += 2) {
      bytes.add(int.parse(paddedHex.substring(i, i + 2), radix: 16));
    }
    
    return Uint8List.fromList(bytes);
  }

  /// Derive AES key from shared secret using HKDF
  encrypt_pkg.Key _deriveAESKey(Uint8List sharedSecret) {
    // Use HKDF to derive a 256-bit key
    final hkdf = HKDFKeyDerivator(SHA256Digest());
    hkdf.init(HkdfParameters(sharedSecret, 32, null, utf8.encode('airdrop-pro-v1')));
    
    final derivedKey = Uint8List(32); // 256 bits
    hkdf.deriveKey(null, 0, derivedKey, 0);
    
    return encrypt_pkg.Key(derivedKey);
  }

  /// Compare two byte arrays
  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Clear sensitive data
  void dispose() {
    _privateKey = null;
    _publicKey = null;
    _sharedSecret = null;
    _aesKey = null;
    _iv = null;
  }
}

/// Key pair information
class KeyPairInfo {
  final Uint8List publicKeyBytes;
  final ECPrivateKey privateKey;
  final ECPublicKey publicKey;

  KeyPairInfo({
    required this.publicKeyBytes,
    required this.privateKey,
    required this.publicKey,
  });
}

/// Encrypted chunk of data
class EncryptedChunk {
  final Uint8List data;
  final int index;
  final Uint8List hash;
  final Uint8List iv;

  EncryptedChunk({
    required this.data,
    required this.index,
    required this.hash,
    required this.iv,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': base64.encode(data),
      'index': index,
      'hash': base64.encode(hash),
      'iv': base64.encode(iv),
    };
  }

  factory EncryptedChunk.fromJson(Map<String, dynamic> json) {
    return EncryptedChunk(
      data: base64.decode(json['data']),
      index: json['index'],
      hash: base64.decode(json['hash']),
      iv: base64.decode(json['iv']),
    );
  }
}

/// Encrypted data with metadata
class EncryptedData {
  final Uint8List encryptedBytes;
  final Uint8List iv;
  final Uint8List hash;

  EncryptedData({
    required this.encryptedBytes,
    required this.iv,
    required this.hash,
  });
}

