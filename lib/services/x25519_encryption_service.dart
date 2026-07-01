import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'encryption_service.dart';

/// Real end-to-end encryption: X25519 ECDH for key agreement and AES-256-GCM
/// for the payload. Pure Dart, so it runs (and is tested) without any native
/// plugin.
///
/// The identity key pair is held in memory here. A production build persists
/// the private key in the platform keystore (e.g. `flutter_secure_storage`) and
/// publishes only the public key; that storage seam is intentionally left to
/// the integration step so this class stays a pure, testable cipher.
class X25519EncryptionService implements EncryptionService {
  X25519EncryptionService({SimpleKeyPair? identity}) : _identity = identity;

  final _x25519 = X25519();
  final _aes = AesGcm.with256bits();

  SimpleKeyPair? _identity;

  Future<SimpleKeyPair> _keyPair() async =>
      _identity ??= await _x25519.newKeyPair();

  @override
  Future<String> publicKeyBase64() async {
    final pub = await (await _keyPair()).extractPublicKey();
    return base64Encode(pub.bytes);
  }

  Future<SecretKey> _sharedSecret(String peerPublicKeyBase64) async {
    final peer = SimplePublicKey(
      base64Decode(peerPublicKeyBase64),
      type: KeyPairType.x25519,
    );
    return _x25519.sharedSecretKey(
      keyPair: await _keyPair(),
      remotePublicKey: peer,
    );
  }

  @override
  Future<String> encrypt({
    required String plaintext,
    required String peerPublicKeyBase64,
  }) async {
    final box = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: await _sharedSecret(peerPublicKeyBase64),
    );
    // nonce(12) + ciphertext + mac(16), base64-encoded.
    return base64Encode(box.concatenation());
  }

  @override
  Future<String> decrypt({
    required String ciphertext,
    required String peerPublicKeyBase64,
  }) async {
    final box = SecretBox.fromConcatenation(
      base64Decode(ciphertext),
      nonceLength: 12,
      macLength: 16,
    );
    final clear = await _aes.decrypt(
      box,
      secretKey: await _sharedSecret(peerPublicKeyBase64),
    );
    return utf8.decode(clear);
  }
}
