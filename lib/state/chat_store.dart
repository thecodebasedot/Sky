import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/mock_data.dart';
import '../models/call.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/story.dart';

/// In-memory app state. This is intentionally backend-agnostic: today it serves
/// [MockData]; later, swap these methods for repository calls (REST/WebSocket).
class ChatStore extends ChangeNotifier {
  ChatStore()
      : _chats = MockData.chats(),
        _calls = MockData.calls(),
        _stories = MockData.stories();

  final _uuid = const Uuid();

  List<Chat> _chats;
  final List<CallLog> _calls;
  final List<Story> _stories;

  String get myId => MockData.me.id;

  /// Chats sorted: pinned first, then by most-recent message.
  List<Chat> get chats {
    final list = [..._chats];
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final at = a.lastMessage?.timestamp ?? DateTime(0);
      final bt = b.lastMessage?.timestamp ?? DateTime(0);
      return bt.compareTo(at);
    });
    return list;
  }

  List<CallLog> get calls => _calls;
  List<Story> get stories => _stories;

  int get totalUnread =>
      _chats.fold(0, (sum, c) => sum + c.unreadCount);

  Chat chatById(String id) => _chats.firstWhere((c) => c.id == id);

  /// Append a text message from the current user and fake a "delivered" ack.
  void sendText(String chatId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msg = Message(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: myId,
      text: trimmed,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _updateChat(chatId, addMessage: msg, clearUnread: true);

    // Simulate network round-trip so the UI shows status progression.
    Future.delayed(const Duration(milliseconds: 600), () {
      _setStatus(chatId, msg.id, MessageStatus.sent);
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      _setStatus(chatId, msg.id, MessageStatus.delivered);
    });
  }

  /// Mark a chat as read (clears the unread badge).
  void markRead(String chatId) {
    final i = _chats.indexWhere((c) => c.id == chatId);
    if (i == -1 || _chats[i].unreadCount == 0) return;
    _chats[i] = _copy(_chats[i], unreadCount: 0);
    notifyListeners();
  }

  void _setStatus(String chatId, String messageId, MessageStatus status) {
    final i = _chats.indexWhere((c) => c.id == chatId);
    if (i == -1) return;
    final messages = _chats[i].messages.map((m) {
      return m.id == messageId ? m.copyWith(status: status) : m;
    }).toList();
    _chats[i] = _copy(_chats[i], messages: messages);
    notifyListeners();
  }

  void _updateChat(
    String chatId, {
    Message? addMessage,
    bool clearUnread = false,
  }) {
    final i = _chats.indexWhere((c) => c.id == chatId);
    if (i == -1) return;
    final messages = [..._chats[i].messages, if (addMessage != null) addMessage];
    _chats[i] = _copy(
      _chats[i],
      messages: messages,
      unreadCount: clearUnread ? 0 : null,
    );
    notifyListeners();
  }

  Chat _copy(
    Chat c, {
    List<Message>? messages,
    int? unreadCount,
  }) {
    return Chat(
      id: c.id,
      participants: c.participants,
      isGroup: c.isGroup,
      name: c.isGroup ? c.titleFor(myId) : null,
      avatarUrl: c.avatarUrl,
      messages: messages ?? c.messages,
      unreadCount: unreadCount ?? c.unreadCount,
      isMuted: c.isMuted,
      isPinned: c.isPinned,
    );
  }
}
