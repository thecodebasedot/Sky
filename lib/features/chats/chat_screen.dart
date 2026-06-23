import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../state/chat_store.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar.dart';
import '../calls/call_screen.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

/// A single conversation thread.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  late final ChatStore _store;

  @override
  void initState() {
    super.initState();
    _store = context.read<ChatStore>();
    // Start streaming this conversation's messages.
    _store.openChat(widget.chatId);
  }

  @override
  void dispose() {
    _store.closeChat();
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChatStore>();
    final chat = store.chatById(widget.chatId);
    final myId = store.myId;
    final messages = store.activeMessages;
    _jumpToBottom();

    // A freshly created chat may not have streamed into the list yet.
    if (chat == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, chat, myId),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMine = msg.senderId == myId;
                      final prev =
                          index > 0 ? messages[index - 1] : null;
                      final showSender = chat.isGroup &&
                          !isMine &&
                          prev?.senderId != msg.senderId;
                      return MessageBubble(
                        message: msg,
                        isMine: isMine,
                        showSender: showSender,
                        senderName: _senderName(chat, msg.senderId),
                      );
                    },
                  ),
          ),
          MessageComposer(
            onSend: (text) {
              store.sendText(widget.chatId, text);
              _jumpToBottom();
            },
            onSendImage: () {
              // Until device capture + Storage upload land, send a sample
              // image so the flow is exercised end to end.
              store.sendImage(
                widget.chatId,
                mediaUrl:
                    'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/600/400',
              );
              _jumpToBottom();
            },
            onSendFile: () {
              store.sendFile(widget.chatId, 'Document.pdf');
              _jumpToBottom();
            },
            onSendVoice: (seconds) {
              store.sendVoiceNote(widget.chatId, seconds);
              _jumpToBottom();
            },
          ),
        ],
      ),
    );
  }

  String _senderName(Chat chat, String senderId) {
    final user = chat.participants.firstWhere(
      (u) => u.id == senderId,
      orElse: () => chat.participants.first,
    );
    return user.name;
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Chat chat,
    String myId,
  ) {
    final other = chat.isGroup ? null : chat.otherParticipant(myId);
    final subtitle = chat.isGroup
        ? '${chat.participants.length} members'
        : (other!.isOnline
            ? 'online'
            : (other.lastSeen != null
                ? TimeFormat.lastSeen(other.lastSeen!)
                : ''));

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          if (other != null)
            Avatar(user: other, radius: 18)
          else
            const CircleAvatar(
              radius: 18,
              child: Icon(Icons.groups_rounded, size: 20),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat.titleFor(myId),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded),
          onPressed: () => _startCall(context, chat, myId, video: true),
        ),
        IconButton(
          icon: const Icon(Icons.call_rounded),
          onPressed: () => _startCall(context, chat, myId, video: false),
        ),
        PopupMenuButton<String>(
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'view', child: Text('View contact')),
            PopupMenuItem(value: 'media', child: Text('Media & files')),
            PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
            PopupMenuItem(value: 'clear', child: Text('Clear chat')),
          ],
          onSelected: (_) {},
        ),
      ],
    );
  }

  void _startCall(
    BuildContext context,
    Chat chat,
    String myId, {
    required bool video,
  }) {
    final other = chat.isGroup ? chat.participants[1] : chat.otherParticipant(myId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallScreen(user: other, isVideo: video),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'No messages yet.\nSay hello 👋',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
