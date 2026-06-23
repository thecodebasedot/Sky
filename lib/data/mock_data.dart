import 'package:flutter/material.dart';

import '../models/call.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/story.dart';
import '../models/user.dart';

/// Hard-coded sample data so the UI is fully browsable before a backend exists.
class MockData {
  MockData._();

  static DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) {
    return DateTime.now()
        .subtract(Duration(days: days, hours: hours, minutes: minutes));
  }

  // The signed-in user.
  static const me = SkyUser(
    id: 'me',
    name: 'You',
    phoneNumber: '+1 555 0100',
    about: 'On Sky ☁️',
    isOnline: true,
  );

  static final SkyUser amara = SkyUser(
    id: 'u_amara',
    name: 'Amara Okafor',
    phoneNumber: '+1 555 0111',
    about: 'Designing all day.',
    isOnline: true,
  );

  static final SkyUser leo = SkyUser(
    id: 'u_leo',
    name: 'Leo Martins',
    phoneNumber: '+1 555 0112',
    about: 'Coffee first ☕',
    isOnline: false,
    lastSeen: _ago(hours: 2),
  );

  static final SkyUser priya = SkyUser(
    id: 'u_priya',
    name: 'Priya Sharma',
    phoneNumber: '+1 555 0113',
    isOnline: false,
    lastSeen: _ago(minutes: 12),
  );

  static final SkyUser noah = SkyUser(
    id: 'u_noah',
    name: 'Noah Kim',
    phoneNumber: '+1 555 0114',
    isOnline: true,
  );

  static final SkyUser sofia = SkyUser(
    id: 'u_sofia',
    name: 'Sofia Rossi',
    phoneNumber: '+1 555 0115',
    isOnline: false,
    lastSeen: _ago(days: 1),
  );

  static List<SkyUser> get contacts => [amara, leo, priya, noah, sofia];

  // ---- Chats ----
  static List<Chat> chats() {
    return [
      Chat(
        id: 'c_amara',
        participants: [me, amara],
        unreadCount: 2,
        isPinned: true,
        messages: [
          Message(
            id: 'm1',
            chatId: 'c_amara',
            senderId: amara.id,
            text: 'Hey! Did you get a chance to look at the mockups?',
            timestamp: _ago(minutes: 38),
          ),
          Message(
            id: 'm2',
            chatId: 'c_amara',
            senderId: me.id,
            text: 'Just opened them — the new palette looks amazing 🔥',
            timestamp: _ago(minutes: 35),
            status: MessageStatus.read,
          ),
          Message(
            id: 'm3',
            chatId: 'c_amara',
            senderId: amara.id,
            text: 'Right?? Let me send a voice note explaining the flow.',
            timestamp: _ago(minutes: 6),
          ),
          Message(
            id: 'm4',
            chatId: 'c_amara',
            senderId: amara.id,
            type: MessageType.voice,
            durationSeconds: 27,
            timestamp: _ago(minutes: 5),
          ),
        ],
      ),
      Chat(
        id: 'c_team',
        participants: [me, amara, leo, noah],
        isGroup: true,
        name: 'Design Team',
        unreadCount: 5,
        messages: [
          Message(
            id: 'g1',
            chatId: 'c_team',
            senderId: leo.id,
            text: 'Standup in 10 everyone 👋',
            timestamp: _ago(hours: 1, minutes: 20),
          ),
          Message(
            id: 'g2',
            chatId: 'c_team',
            senderId: noah.id,
            text: 'On my way!',
            timestamp: _ago(hours: 1, minutes: 18),
          ),
          Message(
            id: 'g3',
            chatId: 'c_team',
            senderId: me.id,
            text: 'Joining now.',
            timestamp: _ago(hours: 1, minutes: 17),
            status: MessageStatus.delivered,
          ),
        ],
      ),
      Chat(
        id: 'c_leo',
        participants: [me, leo],
        messages: [
          Message(
            id: 'l1',
            chatId: 'c_leo',
            senderId: me.id,
            text: 'Thanks for lunch today!',
            timestamp: _ago(hours: 3),
            status: MessageStatus.read,
          ),
          Message(
            id: 'l2',
            chatId: 'c_leo',
            senderId: leo.id,
            text: 'Anytime 🙌',
            timestamp: _ago(hours: 2, minutes: 58),
          ),
        ],
      ),
      Chat(
        id: 'c_priya',
        participants: [me, priya],
        unreadCount: 1,
        messages: [
          Message(
            id: 'p1',
            chatId: 'c_priya',
            senderId: priya.id,
            type: MessageType.image,
            text: 'Look at this view!',
            timestamp: _ago(minutes: 12),
          ),
        ],
      ),
      Chat(
        id: 'c_sofia',
        participants: [me, sofia],
        isMuted: true,
        messages: [
          Message(
            id: 's1',
            chatId: 'c_sofia',
            senderId: sofia.id,
            text: 'See you next week 😊',
            timestamp: _ago(days: 1, hours: 4),
          ),
        ],
      ),
    ];
  }

  // ---- Calls ----
  static List<CallLog> calls() {
    return [
      CallLog(
        id: 'call1',
        user: amara,
        type: CallType.video,
        direction: CallDirection.incoming,
        timestamp: _ago(hours: 1),
        durationSeconds: 642,
      ),
      CallLog(
        id: 'call2',
        user: leo,
        type: CallType.voice,
        direction: CallDirection.outgoing,
        timestamp: _ago(hours: 5),
        durationSeconds: 95,
      ),
      CallLog(
        id: 'call3',
        user: priya,
        type: CallType.voice,
        direction: CallDirection.missed,
        timestamp: _ago(days: 1, hours: 2),
      ),
      CallLog(
        id: 'call4',
        user: noah,
        type: CallType.video,
        direction: CallDirection.outgoing,
        timestamp: _ago(days: 2),
        durationSeconds: 1820,
      ),
    ];
  }

  // ---- Stories / Status ----
  static List<Story> stories() {
    return [
      Story(
        user: amara,
        items: [
          StoryItem(
            id: 'st1',
            timestamp: _ago(hours: 1),
            caption: 'Late night design session ✨',
            backgroundColorValue: 0xFF1E88E5,
          ),
        ],
      ),
      Story(
        user: noah,
        seen: false,
        items: [
          StoryItem(
            id: 'st2',
            timestamp: _ago(hours: 3),
            caption: 'Weekend hike 🥾',
            backgroundColorValue: 0xFF26C6DA,
          ),
          StoryItem(
            id: 'st3',
            timestamp: _ago(hours: 2, minutes: 30),
            caption: 'Summit!',
            backgroundColorValue: 0xFF2E7D32,
          ),
        ],
      ),
      Story(
        user: sofia,
        seen: true,
        items: [
          StoryItem(
            id: 'st4',
            timestamp: _ago(hours: 9),
            caption: 'Buongiorno 🇮🇹',
            backgroundColorValue: 0xFFEF6C00,
          ),
        ],
      ),
    ];
  }

  /// Stable per-user accent color for avatars.
  static Color colorFor(String userId) {
    const palette = [
      Color(0xFF1E88E5),
      Color(0xFF26C6DA),
      Color(0xFF7E57C2),
      Color(0xFFEF6C00),
      Color(0xFF2E7D32),
      Color(0xFFD81B60),
    ];
    return palette[userId.hashCode.abs() % palette.length];
  }
}
