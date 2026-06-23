import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'chat_repository.dart';

/// Cloud Firestore implementation of [ChatRepository].
///
/// Layout:
/// ```
/// chats/{chatId}
///   participantIds: [uid, ...]          // for membership queries
///   participants:   [{id,name,phoneNumber,avatarUrl,about}, ...]
///   isGroup, name, avatarUrl
///   lastMessage:    {text,type,senderId,timestamp}
///   unreadCounts:   {uid: int, ...}
///   updatedAt:      Timestamp
///   chats/{chatId}/messages/{messageId}
///     senderId, text, type, status, timestamp, mediaUrl, durationSeconds
/// ```
/// See `firestore.rules` for the matching security rules.
class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  @override
  Stream<List<Chat>> watchChats(String userId) {
    return _chats
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _chatFromDoc(d, userId)).toList());
  }

  @override
  Stream<List<Message>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _messageFromDoc(chatId, d.id, d.data())).toList());
  }

  @override
  Future<void> sendMessage(Message message) async {
    final chatRef = _chats.doc(message.chatId);
    final msgRef = chatRef.collection('messages').doc(message.id);

    final batch = _db.batch();
    batch.set(msgRef, _messageToMap(message));
    batch.set(
      chatRef,
      {
        'lastMessage': {
          'text': message.text,
          'type': message.type.name,
          'senderId': message.senderId,
          'timestamp': Timestamp.fromDate(message.timestamp),
        },
        'updatedAt': Timestamp.fromDate(message.timestamp),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  @override
  Future<void> markRead(String chatId, String userId) async {
    await _chats.doc(chatId).set(
      {
        'unreadCounts': {userId: 0},
      },
      SetOptions(merge: true),
    );
  }

  @override
  void dispose() {}

  // ---- mapping ----

  Chat _chatFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final data = doc.data() ?? {};
    final participants = (data['participants'] as List? ?? [])
        .map((p) => _userFromMap(Map<String, dynamic>.from(p as Map)))
        .toList();

    final last = data['lastMessage'] as Map?;
    final preview = <Message>[];
    if (last != null) {
      preview.add(Message(
        id: 'preview',
        chatId: doc.id,
        senderId: last['senderId'] as String? ?? '',
        text: last['text'] as String? ?? '',
        type: _typeFromName(last['type'] as String?),
        timestamp: (last['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      ));
    }

    final unread = (data['unreadCounts'] as Map?)?[userId];

    return Chat(
      id: doc.id,
      participants: participants,
      isGroup: data['isGroup'] as bool? ?? false,
      name: data['name'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      messages: preview,
      unreadCount: (unread as num?)?.toInt() ?? 0,
      isMuted: data['isMuted'] as bool? ?? false,
      isPinned: data['isPinned'] as bool? ?? false,
    );
  }

  Message _messageFromDoc(
    String chatId,
    String id,
    Map<String, dynamic> data,
  ) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      type: _typeFromName(data['type'] as String?),
      status: _statusFromName(data['status'] as String?),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrl: data['mediaUrl'] as String?,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> _messageToMap(Message m) {
    return {
      'senderId': m.senderId,
      'text': m.text,
      'type': m.type.name,
      'status': m.status.name,
      'timestamp': Timestamp.fromDate(m.timestamp),
      if (m.mediaUrl != null) 'mediaUrl': m.mediaUrl,
      if (m.durationSeconds != null) 'durationSeconds': m.durationSeconds,
    };
  }

  SkyUser _userFromMap(Map<String, dynamic> m) {
    return SkyUser(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      phoneNumber: m['phoneNumber'] as String?,
      avatarUrl: m['avatarUrl'] as String?,
      about: m['about'] as String? ?? 'Hey there! I am using Sky.',
    );
  }

  MessageType _typeFromName(String? name) {
    return MessageType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => MessageType.text,
    );
  }

  MessageStatus _statusFromName(String? name) {
    return MessageStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => MessageStatus.sent,
    );
  }
}
