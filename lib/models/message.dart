/// Delivery state of an outgoing message.
enum MessageStatus { sending, sent, delivered, read }

/// Kind of payload a message carries.
enum MessageType { text, image, voice, file, system }

/// A single message within a chat.
class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.timestamp,
    this.text = '',
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.mediaUrl,
    this.durationSeconds,
  });

  final String id;
  final String chatId;
  final String senderId;
  final DateTime timestamp;

  final String text;
  final MessageType type;
  final MessageStatus status;

  /// Used for image/voice/file messages.
  final String? mediaUrl;

  /// Length of a voice note, in seconds.
  final int? durationSeconds;

  Message copyWith({MessageStatus? status}) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      timestamp: timestamp,
      text: text,
      type: type,
      status: status ?? this.status,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
    );
  }

  /// A copy with replaced [text] (used to swap ciphertext for cleartext).
  Message withText(String text) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      timestamp: timestamp,
      text: text,
      type: type,
      status: status,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
    );
  }
}
