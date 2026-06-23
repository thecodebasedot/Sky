import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import 'auth_service.dart';

/// Real [AuthService] backed by Firebase Phone Auth + a Firestore `users`
/// collection for profiles.
///
/// Firebase phone sign-in is callback-based; this adapter bridges it to the
/// app's simple `sendCode` / `verifyCode` interface by stashing the
/// `verificationId` produced by [FirebaseAuth.verifyPhoneNumber].
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String? _verificationId;

  @override
  Future<void> sendCode(String phoneNumber) async {
    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {
        // Android may auto-retrieve the SMS; ignored here so the user always
        // confirms on the OTP screen.
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(
            AuthException(e.message ?? 'Could not send the code.'),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
    return completer.future;
  }

  @override
  Future<SkyUser> verifyCode(String phoneNumber, String code) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw AuthException('Request a code before verifying.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );

    try {
      final result = await _auth.signInWithCredential(credential);
      final uid = result.user!.uid;

      // Returning user with a saved profile?
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      if (doc.exists && (data?['name'] as String?)?.isNotEmpty == true) {
        return _userFromMap(uid, data!);
      }

      // New user → empty name triggers profile setup.
      return SkyUser(id: uid, name: '', phoneNumber: phoneNumber, isOnline: true);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Invalid or expired code.');
    }
  }

  @override
  Future<SkyUser> completeProfile({
    required String userId,
    required String name,
    String? about,
  }) async {
    final user = SkyUser(
      id: userId,
      name: name.trim(),
      phoneNumber: _auth.currentUser?.phoneNumber,
      about: (about == null || about.trim().isEmpty)
          ? 'Hey there! I am using Sky.'
          : about.trim(),
      isOnline: true,
    );

    await _db.collection('users').doc(userId).set({
      'id': user.id,
      'name': user.name,
      'phoneNumber': user.phoneNumber,
      'about': user.about,
      'avatarUrl': user.avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return user;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  SkyUser _userFromMap(String uid, Map<String, dynamic> m) {
    return SkyUser(
      id: uid,
      name: m['name'] as String? ?? '',
      phoneNumber: m['phoneNumber'] as String?,
      avatarUrl: m['avatarUrl'] as String?,
      about: m['about'] as String? ?? 'Hey there! I am using Sky.',
      isOnline: true,
    );
  }
}
