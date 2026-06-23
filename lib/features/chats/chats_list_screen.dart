import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/chat_store.dart';
import 'chat_screen.dart';
import 'widgets/chat_list_tile.dart';

/// The "Chats" tab — list of all conversations.
class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChatStore>();
    final chats = store.chats;

    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 84,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListTile(
          chat: chat,
          myId: store.myId,
          onTap: () {
            store.markRead(chat.id);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(chatId: chat.id),
              ),
            );
          },
        );
      },
    );
  }
}
