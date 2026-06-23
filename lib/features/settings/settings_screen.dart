import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../state/auth_store.dart';
import '../../widgets/avatar.dart';

/// Profile + app settings, including sign-out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (user != null) _profileHeader(context, user),
          const Divider(height: 1),
          _tile(context, Icons.key_rounded, 'Account',
              'Privacy, security, change number'),
          _tile(context, Icons.chat_rounded, 'Chats',
              'Theme, wallpaper, chat history'),
          _tile(context, Icons.notifications_rounded, 'Notifications',
              'Message, group & call tones'),
          _tile(context, Icons.storage_rounded, 'Storage and data',
              'Network usage, auto-download'),
          _tile(context, Icons.help_outline_rounded, 'Help',
              'Help center, contact us, privacy policy'),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Sign out',
                style: TextStyle(color: Colors.red)),
            onTap: () => _confirmSignOut(context),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Sky • v0.1.0',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, SkyUser user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Avatar(user: user, radius: 30),
      title: Text(user.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 18)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('${user.about}\n${user.phoneNumber ?? ''}'),
      ),
      isThreeLine: true,
      trailing: IconButton(
        icon: const Icon(Icons.edit_rounded),
        onPressed: () => _editProfile(context, user),
      ),
    );
  }

  void _editProfile(BuildContext context, SkyUser user) {
    final nameController = TextEditingController(text: user.name);
    final aboutController = TextEditingController(text: user.about);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit profile',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aboutController,
                decoration: const InputDecoration(
                  labelText: 'About',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  context.read<AuthStore>().updateProfile(
                        name: nameController.text.trim(),
                        about: aboutController.text.trim(),
                      );
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to verify your number again to '
            'sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthStore>().signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {},
    );
  }
}
