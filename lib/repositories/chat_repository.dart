import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';

/// Data access for conversations and messages.
///
/// Implementations: [MockChatRepository] (in-memory sample data) and
/// `FirestoreChatRepository` (Cloud Firestore). The UI and [ChatStore] depend
/// only on this interface, so switching backends needs no widget changes.
abstract class ChatRepository {
  /// Streams the current user's conversations, updating in real time.
  /// Each emitted [Chat] carries enough to render the list (title, last
  /// message, unread count).
  Stream<List<Chat>> watchChats(String userId);

  /// Streams the messages within [chatId] in chronological order.
  Stream<List<Message>> watchMessages(String chatId);

  /// Send [message] to its chat.
  Future<void> sendMessage(Message message);

  /// Clear the unread counter for [userId] in [chatId].
  Future<void> markRead(String chatId, String userId);

  /// People [userId] can start a conversation with.
  Future<List<SkyUser>> fetchContacts(String userId);

  /// Open the existing 1:1 chat between [me] and [other], creating it if
  /// needed. Returns the chat.
  Future<Chat> startDirectChat(SkyUser me, SkyUser other);

  /// Create a new group chat owned by [me] with the given [members].
  Future<Chat> createGroup({
    required SkyUser me,
    required List<SkyUser> members,
    required String name,
  });

  /// Stream the ids of participants currently typing in [chatId], excluding
  /// [myId].
  Stream<List<String>> watchTyping(String chatId, String myId);

  /// Mark [userId] as typing (or not) in [chatId].
  void setTyping(String chatId, String userId, bool isTyping);

  /// Release any resources / subscriptions.
  void dispose();
}

