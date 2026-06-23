import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/user.dart';
import '../../state/auth_store.dart';
import '../../state/chat_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';
import 'chat_screen.dart';

/// Pick members and a name, then create a group chat.
class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _nameController = TextEditingController();
  final _selected = <SkyUser>{};
  bool _creating = false;
  late final Future<List<SkyUser>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = context.read<ChatStore>().contacts();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _selected.isNotEmpty &&
      _nameController.text.trim().isNotEmpty &&
      !_creating;

  Future<void> _create() async {
    final store = context.read<ChatStore>();
    final me = context.read<AuthStore>().user ?? MockData.me;
    final navigator = Navigator.of(context);

    setState(() => _creating = true);
    final chatId = await store.createGroup(
      me,
      _selected.toList(),
      _nameController.text.trim(),
    );
    if (!mounted) return;

    navigator.pop(); // close the group screen
    navigator.push(
      MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: _create,
              child: _creating
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Group name',
                prefixIcon: Icon(Icons.edit_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _selected
                    .map((u) => _selectedChip(u))
                    .toList(growable: false),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<SkyUser>>(
              future: _contactsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final contacts = snapshot.data ?? const [];
                return ListView(
                  children: contacts.map((user) {
                    final checked = _selected.contains(user);
                    return CheckboxListTile(
                      value: checked,
                      activeColor: AppTheme.skyBlue,
                      controlAffinity: ListTileControlAffinity.trailing,
                      secondary: Avatar(user: user),
                      title: Text(user.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        user.about,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selected.add(user);
                        } else {
                          _selected.remove(user);
                        }
                      }),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedChip(SkyUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Stack(
            children: [
              Avatar(user: user, radius: 22),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _selected.remove(user)),
                  child: const CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              user.name.split(' ').first,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
