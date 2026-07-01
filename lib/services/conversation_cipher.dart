import 'encryption_service.dart';
import 'public_key_directory.dart';

/// Encrypts/decrypts 1:1 message text for a peer, resolving the peer's public
/// key from a [PublicKeyDirectory]. Falls back to plaintext when no key is
/// available (mock backend, or a peer that hasn't published a key yet), so the
/// pipeline degrades gracefully instead of failing.
///
/// The ECDH shared secret is symmetric, so the same call decrypts both incoming
/// messages and your own sent copies — always keyed by the *other* participant.
class ConversationCipher {
  ConversationCipher(this._encryption, this._directory);

  final EncryptionService _encryption;
  final PublicKeyDirectory _directory;

  Future<String> encryptFor(String peerId, String plaintext) async {
    final key = await _directory.lookup(peerId);
    if (key == null || key.isEmpty) return plaintext;
    return _encryption.encrypt(plaintext: plaintext, peerPublicKeyBase64: key);
  }

  Future<String> decryptFrom(String peerId, String ciphertext) async {
    final key = await _directory.lookup(peerId);
    if (key == null || key.isEmpty) return ciphertext;
    try {
      return await _encryption.decrypt(
        ciphertext: ciphertext,
        peerPublicKeyBase64: key,
      );
    } catch (_) {
      // Legacy/plaintext message or wrong key — show it as-is rather than fail.
      return ciphertext;
    }
  }
}
