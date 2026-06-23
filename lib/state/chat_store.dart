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

/// App state for messaging, backed by a [ChatRepository].
///
/// Call [bind] with the signed-in user id to start streaming their chats, and
/// [bind] with `null` on sign-out to tear the subscriptions down. Calls and
/// stories still come from [MockData] until their own backends land.
class ChatStore extends ChangeNotifier {
  ChatStore(this._repo);

  final ChatRepository _repo;
  final _uuid = const Uuid();

  String? _myId;
  List<Chat> _chats = const [];

  // Active conversation message stream.
  String? _activeChatId;
  List<Message> _activeMessages = const [];

  StreamSubscription<List<Chat>>? _chatsSub;
  StreamSubscription<List<Message>>? _messagesSub;
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

  /// Subscribe to a conversation's messages while its screen is open.
  void openChat(String chatId) {
    _activeChatId = chatId;
    _activeMessages = const [];
    _messagesSub?.cancel();
    _messagesSub = _repo.watchMessages(chatId).listen((messages) {
      if (_activeChatId == chatId) {
        _activeMessages = messages;
        notifyListeners();
      }
    });
  }

  void closeChat() {
    _activeChatId = null;
    _activeMessages = const [];
    _messagesSub?.cancel();
    _messagesSub = null;
  }

  void sendText(String chatId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _repo.sendMessage(Message(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: myId,
      text: trimmed,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    ));
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
    _repo.dispose();
    super.dispose();
  }
}
