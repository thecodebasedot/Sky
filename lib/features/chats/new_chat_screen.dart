import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/user.dart';
import '../../state/auth_store.dart';
import '../../state/chat_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';
import 'chat_screen.dart';
import 'new_group_screen.dart';

/// Contact picker for starting a new 1:1 conversation (or a group).
class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.read<ChatStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select contact'),
      ),
      body: FutureBuilder<List<SkyUser>>(
        future: store.contacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts = snapshot.data ?? const [];
          return ListView(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.skyBlue,
                  child: Icon(Icons.group_add_rounded, color: Colors.white),
                ),
                title: const Text('New group',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const NewGroupScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              if (contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No contacts on Sky yet.'),
                  ),
                )
              else
                ...contacts.map(
                  (user) => ListTile(
                    leading: Avatar(user: user, showOnlineDot: true),
                    title: Text(user.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      user.about,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _startChat(context, user),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startChat(BuildContext context, SkyUser other) async {
    final store = context.read<ChatStore>();
    final me = context.read<AuthStore>().user ?? MockData.me;
    final navigator = Navigator.of(context);

    final chatId = await store.startDirectChat(me, other);
    if (!context.mounted) return;

    navigator.pop(); // close the picker
    navigator.push(
      MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)),
    );
  }
}
