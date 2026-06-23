import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/chat_store.dart';
import '../calls/calls_screen.dart';
import '../chats/chats_list_screen.dart';
import '../settings/settings_screen.dart';
import '../status/status_screen.dart';

/// Top-level shell with bottom navigation between Chats, Status and Calls.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Sky', 'Status', 'Calls'];

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<ChatStore>().totalUnread;

    final pages = const [
      ChatsListScreen(),
      StatusScreen(),
      CallsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new_group', child: Text('New group')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: _badged(const Icon(Icons.chat_bubble_outline_rounded), unread),
            selectedIcon:
                _badged(const Icon(Icons.chat_bubble_rounded), unread),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large_rounded),
            label: 'Status',
          ),
          const NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call_rounded),
            label: 'Calls',
          ),
        ],
      ),
    );
  }

  Widget _badged(Widget icon, int count) {
    if (count <= 0) return icon;
    return Badge(label: Text('$count'), child: icon);
  }

  Widget _buildFab() {
    switch (_index) {
      case 0:
        return FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add_comment_rounded),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.camera_alt_rounded),
        );
      default:
        return FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add_call_rounded),
        );
    }
  }
}
