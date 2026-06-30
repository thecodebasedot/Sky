import '../models/user.dart';

/// A call ringing on this device, addressed to the current user.
class IncomingCall {
  const IncomingCall({
    required this.callId,
    required this.caller,
    required this.isVideo,
  });

  final String callId;
  final SkyUser caller;
  final bool isVideo;
}

/// Notifies the app of incoming calls for the signed-in user.
///
/// [MockIncomingCallService] never rings (there's no real peer offline);
/// `FirebaseIncomingCallService` watches the `calls` collection.
abstract class IncomingCallService {
  /// Stream of calls ringing for [myId].
  Stream<IncomingCall> watch(String myId);

  /// Decline (or cancel) a ringing call.
  Future<void> decline(String callId);
}

/// No-op implementation for the mock backend.
class MockIncomingCallService implements IncomingCallService {
  @override
  Stream<IncomingCall> watch(String myId) => const Stream<IncomingCall>.empty();

  @override
  Future<void> decline(String callId) async {}
}
