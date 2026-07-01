import 'package:flutter_test/flutter_test.dart';
import 'package:sky/services/conversation_cipher.dart';
import 'package:sky/services/encryption_service.dart';
import 'package:sky/services/public_key_directory.dart';
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

  group('ConversationCipher', () {
    test('encrypts for a peer and the peer decrypts via the directory',
        () async {
      final aliceEnc = X25519EncryptionService();
      final bobEnc = X25519EncryptionService();

      final dir = MockPublicKeyDirectory();
      await dir.publish('alice', await aliceEnc.publicKeyBase64());
      await dir.publish('bob', await bobEnc.publicKeyBase64());

      final aliceCipher = ConversationCipher(aliceEnc, dir);
      final bobCipher = ConversationCipher(bobEnc, dir);

      final ct = await aliceCipher.encryptFor('bob', 'submarine');
      expect(ct, isNot(contains('submarine')));

      final pt = await bobCipher.decryptFrom('alice', ct);
      expect(pt, 'submarine');
    });

    test('falls back to plaintext when the peer has no published key',
        () async {
      final cipher = ConversationCipher(
        X25519EncryptionService(),
        MockPublicKeyDirectory(),
      );
      // No key in the directory → passthrough, so the pipeline never blocks.
      expect(await cipher.encryptFor('nobody', 'hello'), 'hello');
      expect(await cipher.decryptFrom('nobody', 'hello'), 'hello');
    });
  });
}
