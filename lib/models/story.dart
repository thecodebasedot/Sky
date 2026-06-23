import 'user.dart';

/// A single frame within someone's status (photo or text card).
class StoryItem {
  const StoryItem({
    required this.id,
    required this.timestamp,
    this.imageUrl,
    this.caption,
    this.backgroundColorValue,
  });

  final String id;
  final DateTime timestamp;
  final String? imageUrl;
  final String? caption;

  /// ARGB color value for text-only status cards.
  final int? backgroundColorValue;
}

/// A user's status — a collection of [StoryItem]s that expire after 24h.
class Story {
  const Story({
    required this.user,
    required this.items,
    this.seen = false,
  });

  final SkyUser user;
  final List<StoryItem> items;
  final bool seen;

  DateTime get latest => items
      .map((i) => i.timestamp)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}
