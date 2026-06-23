import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';

/// First-run profile setup: name (required) and an optional "about".
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final v = _nameController.text.trim().isNotEmpty;
      if (v != _valid) setState(() => _valid = v);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = context.watch<AuthStore>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile info')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Add your name and an optional profile photo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 28),
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded,
                      size: 52, color: AppTheme.skyBlue),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.skyBlue,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt_rounded,
                          size: 16, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            TextField(
              key: const Key('name_field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aboutController,
              decoration: const InputDecoration(
                labelText: 'About (optional)',
                hintText: 'Hey there! I am using Sky.',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.skyBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (_valid && !busy)
                    ? () {
                        context.read<AuthStore>().completeProfile(
                              name: _nameController.text,
                              about: _aboutController.text,
                            );
                      }
                    : null,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Next', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
