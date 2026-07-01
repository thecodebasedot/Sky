import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/mock_data.dart';
import '../models/call.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/story.dart';
import '../models/user.dart';
import '../repositories/chat_repository.dart';
import '../services/conversation_cipher.dart';

/// App state for messaging, backed by a [ChatRepository].
///
/// Call [bind] with the signed-in user id to start streaming their chats, and
/// [bind] with `null` on sign-out to tear the subscriptions down. Calls and
/// stories still come from [MockData] until their own backends land.
///
/// Text in 1:1 chats is end-to-end encrypted via [ConversationCipher] before it
/// leaves the device and decrypted on the way in. On the mock backend the
/// cipher is a no-op passthrough, so behaviour is unchanged.
class ChatStore extends ChangeNotifier {
  ChatStore(this._repo, this._cipher);

  final ChatRepository _repo;
  final ConversationCipher _cipher;
  final _uuid = const Uuid();

  String? _myId;
  List<Chat> _chats = const [];

  // Active conversation message stream.
  String? _activeChatId;
  List<Message> _activeMessages = const [];
  List<String> _typingUserIds = const [];

  StreamSubscription<List<Chat>>? _chatsSub;
  StreamSubscription<List<Message>>? _messagesSub;
  StreamSubscription<List<String>>? _typingSub;
  bool _disposed = false;

  final List<CallLog> _calls = MockData.calls();
  final List<Story> _stories = MockData.stories();

  String get myId => _myId ?? MockData.me.id;
  bool get isReady => _myId != null;

  /// Chats sorted: pinned first, then most-recent activity.
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
  List<Message> get activeMessages => _activeMessages;

  int get totalUnread => _chats.fold(0, (sum, c) => sum + c.unreadCount);

  /// Returns the chat with [id], or null if it hasn't streamed in yet
  /// (e.g. immediately after creating a new conversation).
  Chat? chatById(String id) {
    for (final c in _chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// People the signed-in user can start a chat with.
  Future<List<SkyUser>> contacts() => _repo.fetchContacts(myId);

  /// Open or create a 1:1 chat; returns its id for navigation.
  Future<String> startDirectChat(SkyUser me, SkyUser other) async {
    final chat = await _repo.startDirectChat(me, other);
    return chat.id;
  }

  /// Create a group chat; returns its id for navigation.
  Future<String> createGroup(
    SkyUser me,
    List<SkyUser> members,
    String name,
  ) async {
    final chat = await _repo.createGroup(me: me, members: members, name: name);
    return chat.id;
  }

  /// Begin (or end, when [userId] is null) streaming chats for a user.
  ///
  /// Safe to call from a provider's `update` (build phase): the resulting
  /// notification is deferred to a microtask so it never fires mid-build.
  void bind(String? userId) {
    if (userId == _myId) return;
    _myId = userId;
    _chatsSub?.cancel();
    _chats = const [];

    if (userId != null) {
      _chatsSub = _repo.watchChats(userId).listen((chats) {
        _chats = chats;
        notifyListeners();
      });
    }
    Future.microtask(() {
      if (!_disposed) notifyListeners();
    });
  }

  /// Ids of other participants typing in the open conversation.
  List<String> get typingUserIds => _typingUserIds;

  /// Subscribe to a conversation's messages (and typing) while open.
  void openChat(String chatId) {
    _activeChatId = chatId;
    _activeMessages = const [];
    _typingUserIds = const [];
    _messagesSub?.cancel();
    _typingSub?.cancel();
    _messagesSub = _repo.watchMessages(chatId).listen((messages) async {
      if (_activeChatId != chatId) return;
      final decrypted = await _decryptAll(chatId, messages);
      if (_activeChatId == chatId) {
        _activeMessages = decrypted;
        notifyListeners();
      }
    });
    _typingSub = _repo.watchTyping(chatId, myId).listen((ids) {
      if (_activeChatId == chatId) {
        _typingUserIds = ids;
        notifyListeners();
      }
    });
  }

  void closeChat() {
    final chatId = _activeChatId;
    if (chatId != null) _repo.setTyping(chatId, myId, false);
    _activeChatId = null;
    _activeMessages = const [];
    _typingUserIds = const [];
    _messagesSub?.cancel();
    _messagesSub = null;
    _typingSub?.cancel();
    _typingSub = null;
  }

  /// Report whether the current user is typing in [chatId].
  void setTyping(String chatId, bool isTyping) {
    _repo.setTyping(chatId, myId, isTyping);
  }

  void sendText(String chatId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _sendText(chatId, trimmed);
  }

  Future<void> _sendText(String chatId, String trimmed) async {
    final peerId = _peerId(chatId);
    final payload =
        peerId != null ? await _cipher.encryptFor(peerId, trimmed) : trimmed;
    _repo.sendMessage(Message(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: myId,
      text: payload,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    ));
  }

  /// The other participant in a 1:1 chat, or null for groups / unknown chats
  /// (encryption only applies to 1:1).
  String? _peerId(String chatId) {
    final chat = chatById(chatId);
    if (chat == null || chat.isGroup) return null;
    return chat.otherParticipant(myId).id;
  }

  /// Decrypt the text of 1:1 messages; leave groups and non-text as-is.
  Future<List<Message>> _decryptAll(String chatId, List<Message> messages) {
    final peerId = _peerId(chatId);
    if (peerId == null) return Future.value(messages);
    return Future.wait(messages.map((m) async {
      if (m.type != MessageType.text || m.text.isEmpty) return m;
      final clear = await _cipher.decryptFrom(peerId, m.text);
      return clear == m.text ? m : m.withText(clear);
    }));
  }

  void markRead(String chatId) => _repo.markRead(chatId, myId);

  /// Send an image message. [mediaUrl] points at the (already-uploaded) image;
  /// until device capture + Storage upload land, callers pass a sample URL.
  void sendImage(String chatId, {String? caption, String? mediaUrl}) {
    _send(
      chatId,
      type: MessageType.image,
      text: caption?.trim() ?? '',
      mediaUrl: mediaUrl,
    );
  }

  /// Send a voice note of [seconds] length.
  void sendVoiceNote(String chatId, int seconds) {
    _send(chatId, type: MessageType.voice, durationSeconds: seconds);
  }

  /// Send a file/document message labelled [fileName].
  void sendFile(String chatId, String fileName) {
    _send(chatId, type: MessageType.file, text: fileName);
  }

  void _send(
    String chatId, {
    required MessageType type,
    String text = '',
    String? mediaUrl,
    int? durationSeconds,
  }) {
    _repo.sendMessage(Message(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: myId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    _chatsSub?.cancel();
    _messagesSub?.cancel();
    _typingSub?.cancel();
    _repo.dispose();
    super.dispose();
  }
}
