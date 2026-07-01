import 'package:cloud_firestore/cloud_firestore.dart';

import 'public_key_directory.dart';

/// Stores E2E public keys on the user profile document.
class FirestorePublicKeyDirectory implements PublicKeyDirectory {
  FirestorePublicKeyDirectory({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Map<String, String> _cache = {};

  @override
  Future<void> publish(String userId, String publicKeyBase64) async {
    if (publicKeyBase64.isEmpty) return;
    _cache[userId] = publicKeyBase64;
    await _db.collection('users').doc(userId).set(
      {'publicKey': publicKeyBase64},
      SetOptions(merge: true),
    );
  }

  @override
  Future<String?> lookup(String userId) async {
    final cached = _cache[userId];
    if (cached != null) return cached;
    final doc = await _db.collection('users').doc(userId).get();
    final key = doc.data()?['publicKey'] as String?;
    if (key != null) _cache[userId] = key;
    return key;
  }
}
