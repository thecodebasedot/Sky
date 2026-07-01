import '../models/story.dart';
import '../models/user.dart';

/// Data access for status updates (24h "stories").
///
/// Implementations: [MockStatusRepository] (in-memory) and
/// `FirestoreStatusRepository`. Items older than 24h are filtered out.
abstract class StatusRepository {
  /// Streams status updates visible to [userId] (own + contacts'), newest
  /// activity first, excluding items older than 24h.
  Stream<List<Story>> watchStories(String userId);

  /// Post a text status card with a background color.
  Future<void> postText(
    SkyUser me, {
    required String caption,
    required int colorValue,
  });

  /// Post an image status (the image is already uploaded; [mediaUrl] points
  /// at it).
  Future<void> postImage(
    SkyUser me, {
    required String mediaUrl,
    String? caption,
  });

  void dispose();
}
