import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

/// Background message handler. Must be a top-level (or static) function — FCM
/// invokes it in a separate isolate. With a `notification` payload the OS shows
/// the banner automatically, so there's nothing to do here yet.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// FCM-backed notifications: registers the device token under the user's
/// profile and listens for foreground/opened messages.
class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;

  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  Future<void> init(String userId) async {
    await _messaging.requestPermission();

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(userId, token);

    _subs.add(_messaging.onTokenRefresh.listen((t) => _saveToken(userId, t)));

    // Foreground messages arrive here; with a notification payload the OS does
    // not show a banner while the app is open, so a real app would surface an
    // in-app toast. Left as a hook to avoid pulling another plugin.
    _subs.add(FirebaseMessaging.onMessage.listen((_) {}));
  }

  Future<void> _saveToken(String userId, String token) async {
    await _db.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clear(String userId) async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final token = await _messaging.getToken();
    if (token != null) {
      await _db.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    }
    await _messaging.deleteToken();
  }
}
