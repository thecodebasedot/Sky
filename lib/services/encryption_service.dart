/// End-to-end encryption for 1:1 message payloads.
///
/// Each user owns an X25519 identity key pair. To message a peer, both sides
/// derive the same shared secret from their own private key + the peer's public
/// key (ECDH), which keys an AES-256-GCM cipher. The server only ever stores
/// ciphertext.
///
/// Implementations: [PlaintextEncryptionService] (no-op passthrough, the
/// default) and `X25519EncryptionService` (real crypto, pure Dart).
abstract class EncryptionService {
  /// This device's public key, base64-encoded, to publish so peers can reach
  /// you. Empty string when encryption is disabled.
  Future<String> publicKeyBase64();

  /// Encrypt [plaintext] for the holder of [peerPublicKeyBase64].
  Future<String> encrypt({
    required String plaintext,
    required String peerPublicKeyBase64,
  });

  /// Decrypt [ciphertext] from the holder of [peerPublicKeyBase64].
  Future<String> decrypt({
    required String ciphertext,
    required String peerPublicKeyBase64,
  });
}

/// Passthrough implementation — used when E2E encryption is off so the app runs
/// with plaintext and zero setup.
class PlaintextEncryptionService implements EncryptionService {
  @override
  Future<String> publicKeyBase64() async => '';

  @override
  Future<String> encrypt({
    required String plaintext,
    required String peerPublicKeyBase64,
  }) async =>
      plaintext;

  @override
  Future<String> decrypt({
    required String ciphertext,
    required String peerPublicKeyBase64,
  }) async =>
      ciphertext;
}
