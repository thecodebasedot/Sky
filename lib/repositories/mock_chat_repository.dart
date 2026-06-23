import 'dart:async';

import '../data/mock_data.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'chat_repository.dart';

/// In-memory [ChatRepository] backed by [MockData].
///
/// Behaves like a real-time source: sends are appended and re-broadcast, and
/// outgoing messages walk through sending → sent → delivered to mimic a
/// network round-trip. Message streams are derived from the chats stream.
class MockChatRepository implements ChatRepository {
  MockChatRepository() : _chats = MockData.chats();

  List<Chat> _chats;
  final _controller = StreamController<List<Chat>>.broadcast();

  // chatId -> set of user ids currently typing.
  final Map<String, Set<String>> _typing = {};
  final _typingController = StreamController<String>.broadcast();

  static const _autoReplies = [
    'Got it 👍',
    'Haha nice',
    'Sounds good!',
    'On it 🙌',
    'Let me check and get back to you.',
  ];
  int _replyIndex = 0;

  @override
  Stream<List<Chat>> watchChats(String userId) async* {
    yield _chats;
    yield* _controller.stream;
  }

  @override
  Stream<List<Message>> watchMessages(String chatId) async* {
    yield _messagesOf(chatId);
    yield* _controller.stream.map((_) => _messagesOf(chatId));
  }

  @override
  Future<void> sendMessage(Message message) async {
    _appendMessage(message);
    _emit();

    // Simulate delivery acks.
    Future.delayed(const Duration(milliseconds: 600), () {
      _setStatus(message.chatId, message.id, MessageStatus.sent);
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      _setStatus(message.chatId, message.id, MessageStatus.delivered);
    });

    _maybeAutoReply(message);
  }

  /// In a 1:1 chat, make the other person look alive: show them typing for a
  /// beat, then drop in a canned reply. Demonstrates typing + incoming
  /// messages without a real backend.
  void _maybeAutoReply(Message message) {
    if (message.senderId != 'me' || message.type == MessageType.system) return;
    final chat = _indexOf(message.chatId) == -1
        ? null
        : _chats[_indexOf(message.chatId)];
    if (chat == null || chat.isGroup) return;
    final other = chat.participants.firstWhere(
      (u) => u.id != 'me',
      orElse: () => chat.participants.first,
    );

    Future.delayed(const Duration(milliseconds: 700), () {
      setTyping(chat.id, other.id, true);
    });
    Future.delayed(const Duration(milliseconds: 2100), () {
      setTyping(chat.id, other.id, false);
      _appendMessage(Message(
        id: 'auto_${DateTime.now().microsecondsSinceEpoch}',
        chatId: chat.id,
        senderId: other.id,
        text: _autoReplies[_replyIndex++ % _autoReplies.length],
        timestamp: DateTime.now(),
      ));
      _emit();
    });
  }

  @override
  Future<void> markRead(String chatId, String userId) async {
    final i = _indexOf(chatId);
    if (i == -1 || _chats[i].unreadCount == 0) return;
    _chats[i] = _copy(_chats[i], unreadCount: 0);
    _emit();
  }

  @override
  Future<List<SkyUser>> fetchContacts(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.contacts.where((u) => u.id != userId).toList();
  }

  @override
  Future<Chat> startDirectChat(SkyUser me, SkyUser other) async {
    final existing = _existingDirect(other.id);
    if (existing != null) return existing;

    final chat = Chat(
      id: 'dm_${other.id}',
      participants: [me, other],
    );
    _chats = [..._chats, chat];
    _emit();
    return chat;
  }

  @override
  Future<Chat> createGroup({
    required SkyUser me,
    required List<SkyUser> members,
    required String name,
  }) async {
    final chat = Chat(
      id: 'group_${DateTime.now().microsecondsSinceEpoch}',
      participants: [me, ...members],
      isGroup: true,
      name: name,
    );
    _chats = [..._chats, chat];
    _emit();
    return chat;
  }

  @override
  Stream<List<String>> watchTyping(String chatId, String myId) async* {
    yield _typingFor(chatId, myId);
    yield* _typingController.stream
        .where((id) => id == chatId)
        .map((_) => _typingFor(chatId, myId));
  }

  @override
  void setTyping(String chatId, String userId, bool isTyping) {
    final set = _typing.putIfAbsent(chatId, () => <String>{});
    if (isTyping) {
      set.add(userId);
    } else {
      set.remove(userId);
    }
    if (!_typingController.isClosed) _typingController.add(chatId);
  }

  List<String> _typingFor(String chatId, String myId) =>
      (_typing[chatId] ?? const <String>{}).where((u) => u != myId).toList();

  @override
  void dispose() {
    _controller.close();
    _typingController.close();
  }

  Chat? _existingDirect(String otherId) {
    for (final c in _chats) {
      if (!c.isGroup && c.participants.any((u) => u.id == otherId)) return c;
    }
    return null;
  }

  // ---- internals ----

  List<Message> _messagesOf(String chatId) {
    final i = _indexOf(chatId);
    return i == -1 ? const [] : _chats[i].messages;
  }

  int _indexOf(String chatId) => _chats.indexWhere((c) => c.id == chatId);

  void _appendMessage(Message message) {
    final i = _indexOf(message.chatId);
    if (i == -1) return;
    _chats[i] = _copy(
      _chats[i],
      messages: [..._chats[i].messages, message],
      unreadCount: 0,
    );
  }

  void _setStatus(String chatId, String messageId, MessageStatus status) {
    final i = _indexOf(chatId);
    if (i == -1) return;
    final messages = _chats[i].messages
        .map((m) => m.id == messageId ? m.copyWith(status: status) : m)
        .toList();
    _chats[i] = _copy(_chats[i], messages: messages);
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_chats);
  }

  Chat _copy(Chat c, {List<Message>? messages, int? unreadCount}) {
    return Chat(
      id: c.id,
      participants: c.participants,
      isGroup: c.isGroup,
      name: c.isGroup ? c.titleFor('me') : null,
      avatarUrl: c.avatarUrl,
      messages: messages ?? c.messages,
      unreadCount: unreadCount ?? c.unreadCount,
      isMuted: c.isMuted,
      isPinned: c.isPinned,
    );
  }
}
