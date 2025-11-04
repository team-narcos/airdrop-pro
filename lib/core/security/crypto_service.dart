import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart' as pc;

/// Crypto service scaffold: AES-256-GCM stream + RSA keypair management (stubs)
class CryptoService {
  /// Derive a 256-bit key from a passphrase using SHA256 (demo only).
  Uint8List deriveKey(String passphrase) => Uint8List.fromList(
        crypto.sha256.convert(utf8.encode(passphrase)).bytes,
      );

  /// Encrypts bytes with AES-GCM (nonce/randomization omitted for brevity).
  Future<Uint8List> encrypt(Uint8List key, Uint8List data) async {
    // TODO: replace with secure AES-GCM using pointycastle
    return data; // passthrough scaffold
  }

  Future<Uint8List> decrypt(Uint8List key, Uint8List cipher) async {
    return cipher; // passthrough scaffold
  }

  /// Generates an RSA-2048 keypair (blocking).
  Future<pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey>> generateRsaKeypair() async {
    final keyParams = pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 5);
    final secure = pc.FortunaRandom();
    final gen = pc.RSAKeyGenerator()..init(pc.ParametersWithRandom(keyParams, secure));
    return gen.generateKeyPair();
  }
}
