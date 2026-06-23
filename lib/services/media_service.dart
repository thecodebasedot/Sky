/// Picks media from the device and returns a URL the chat can reference.
///
/// Implementations: [MockMediaService] (returns a sample image, no device
/// access) and `FirebaseMediaService` (image_picker + Firebase Storage). The
/// UI depends only on this interface.
abstract class MediaService {
  /// Pick an image (from the camera when [fromCamera] is true, otherwise the
  /// gallery), upload it for [chatId], and return its download URL. Returns
  /// null if the user cancels.
  Future<String?> pickAndUploadImage({
    required String chatId,
    required bool fromCamera,
  });
}

/// No-device implementation: returns a deterministic sample image so the
/// in-app flow works without camera/storage permissions.
class MockMediaService implements MediaService {
  int _seed = 0;

  @override
  Future<String?> pickAndUploadImage({
    required String chatId,
    required bool fromCamera,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _seed++;
    return 'https://picsum.photos/seed/${chatId}_$_seed/600/400';
  }
}
