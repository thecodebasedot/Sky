import '../models/chat.dart';
import '../models/message.dart';

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

  /// Release any resources / subscriptions.
  void dispose();
}
