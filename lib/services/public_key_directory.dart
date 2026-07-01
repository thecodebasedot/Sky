/// Publishes and looks up users' E2E public keys.
///
/// [MockPublicKeyDirectory] keeps them in memory (so the plaintext mock path is
/// a no-op); `FirestorePublicKeyDirectory` stores them on `users/{uid}.publicKey`.
abstract class PublicKeyDirectory {
  /// Publish [publicKeyBase64] for [userId]. Empty keys are ignored.
  Future<void> publish(String userId, String publicKeyBase64);

  /// The base64 public key for [userId], or null if none is published.
  Future<String?> lookup(String userId);
}

/// In-memory directory for the mock backend.
class MockPublicKeyDirectory implements PublicKeyDirectory {
  final Map<String, String> _keys = {};

  @override
  Future<void> publish(String userId, String publicKeyBase64) async {
    if (publicKeyBase64.isNotEmpty) _keys[userId] = publicKeyBase64;
  }

  @override
  Future<String?> lookup(String userId) async => _keys[userId];
}
