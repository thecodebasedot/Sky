import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import 'incoming_call_service.dart';

/// Watches Firestore for calls addressed to the current user and surfaces them
/// as [IncomingCall]s. Pairs with [WebRTCCallService], which writes the call
/// doc with `calleeId` + a `ringing` status.
class FirebaseIncomingCallService implements IncomingCallService {
  FirebaseIncomingCallService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Avoid re-ringing the same call across snapshot updates.
  final Set<String> _announced = {};

  @override
  Stream<IncomingCall> watch(String myId) async* {
    final query = _db
        .collection('calls')
        .where('calleeId', isEqualTo: myId)
        .where('status', isEqualTo: 'ringing')
        .snapshots();

    await for (final snap in query) {
      for (final doc in snap.docs) {
        if (_announced.contains(doc.id)) continue;
        _announced.add(doc.id);

        final data = doc.data();
        final callerId = data['callerId'] as String? ?? '';
        final caller = await _fetchCaller(callerId);
        yield IncomingCall(
          callId: doc.id,
          caller: caller,
          isVideo: data['isVideo'] as bool? ?? false,
        );
      }
    }
  }

  Future<SkyUser> _fetchCaller(String callerId) async {
    final doc = await _db.collection('users').doc(callerId).get();
    final data = doc.data();
    return SkyUser(
      id: callerId,
      name: data?['name'] as String? ?? 'Unknown',
      phoneNumber: data?['phoneNumber'] as String?,
      avatarUrl: data?['avatarUrl'] as String?,
    );
  }

  @override
  Future<void> decline(String callId) async {
    await _db.collection('calls').doc(callId).set(
      {'status': 'ended'},
      SetOptions(merge: true),
    );
  }
}
