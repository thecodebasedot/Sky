/// Registers the device for push notifications and handles incoming ones.
///
/// [MockNotificationService] is a no-op so the app runs without FCM;
/// `FirebaseNotificationService` registers an FCM token and wires handlers.
/// Actually *sending* a push is server-side — see `functions/` for the Cloud
/// Function that fans messages/calls out to a user's tokens.
abstract class NotificationService {
  /// Request permission, register this device's token for [userId], and start
  /// listening for messages. Safe to call more than once.
  Future<void> init(String userId);

  /// Stop listening and forget the token for [userId] (call on sign-out).
  Future<void> clear(String userId);
}

/// No-op implementation for the mock backend.
class MockNotificationService implements NotificationService {
  @override
  Future<void> init(String userId) async {}

  @override
  Future<void> clear(String userId) async {}
}
