import 'message.dart';
import 'user.dart';

/// A conversation — either 1:1 or a group.
class Chat {
  Chat({
    required this.id,
    required this.participants,
    this.isGroup = false,
    String? name,
    this.avatarUrl,
    this.messages = const [],
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
  }) : _name = name;

  final String id;
  final List<SkyUser> participants;
  final bool isGroup;
  final String? _name;
  final String? avatarUrl;
  final List<Message> messages;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;

  /// The user we are talking to in a 1:1 chat (excludes [me]).
  SkyUser otherParticipant(String myId) {
    return participants.firstWhere(
      (u) => u.id != myId,
      orElse: () => participants.first,
    );
  }

  /// Display title: group name, or the other person's name for 1:1.
  String titleFor(String myId) {
    if (isGroup) return _name ?? 'Group';
    return otherParticipant(myId).name;
  }

  Message? get lastMessage => messages.isEmpty ? null : messages.last;
}
