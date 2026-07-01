import 'package:flutter_test/flutter_test.dart';
import 'package:sky/services/encryption_service.dart';
import 'package:sky/services/x25519_encryption_service.dart';

void main() {
  group('X25519EncryptionService', () {
    test('Alice→Bob round-trips through the shared secret', () async {
      final alice = X25519EncryptionService();
      final bob = X25519EncryptionService();

      final alicePub = await alice.publicKeyBase64();
      final bobPub = await bob.publicKeyBase64();

      const message = 'meet me at the docks 🌊';
      final ciphertext = await alice.encrypt(
        plaintext: message,
        peerPublicKeyBase64: bobPub,
      );

      // The ciphertext must not leak the plaintext.
      expect(ciphertext, isNot(contains('docks')));

      final decrypted = await bob.decrypt(
        ciphertext: ciphertext,
        peerPublicKeyBase64: alicePub,
      );
      expect(decrypted, message);
    });

    test('a third party with the wrong key cannot decrypt', () async {
      final alice = X25519EncryptionService();
      final bob = X25519EncryptionService();
      final eve = X25519EncryptionService();

      final alicePub = await alice.publicKeyBase64();
      final bobPub = await bob.publicKeyBase64();

      final ciphertext = await alice.encrypt(
        plaintext: 'secret',
        peerPublicKeyBase64: bobPub,
      );

      // Eve derives a different shared secret, so decryption fails.
      await expectLater(
        eve.decrypt(ciphertext: ciphertext, peerPublicKeyBase64: alicePub),
        throwsA(anything),
      );
    });

    test('nonce is random: same message encrypts to different ciphertext',
        () async {
      final alice = X25519EncryptionService();
      final bob = X25519EncryptionService();
      final bobPub = await bob.publicKeyBase64();

      final a = await alice.encrypt(plaintext: 'hi', peerPublicKeyBase64: bobPub);
      final b = await alice.encrypt(plaintext: 'hi', peerPublicKeyBase64: bobPub);
      expect(a, isNot(equals(b)));
    });
  });

  test('PlaintextEncryptionService is a passthrough', () async {
    final svc = PlaintextEncryptionService();
    final ct = await svc.encrypt(plaintext: 'hi', peerPublicKeyBase64: '');
    expect(ct, 'hi');
    expect(await svc.decrypt(ciphertext: ct, peerPublicKeyBase64: ''), 'hi');
  });
}
